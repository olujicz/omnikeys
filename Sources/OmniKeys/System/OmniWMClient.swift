import AppKit
import OmniKeysCore

/// Talks to OmniWM through its `omniwmctl` command-line tool.
struct OmniWMClient {
    static let bundleID = "com.barut.OmniWM"

    /// omniwmctl inside OmniWM.app wherever it is installed, otherwise the first one on PATH.
    @MainActor
    func controlURL() -> URL? {
        let fileManager = FileManager.default
        if let app = NSWorkspace.shared.urlForApplication(withBundleIdentifier: Self.bundleID) {
            let tool = app.appendingPathComponent("Contents/MacOS/omniwmctl")
            if fileManager.isExecutableFile(atPath: tool.path) {
                return tool
            }
        }
        // GUI apps get a minimal PATH, so Homebrew's prefixes are searched explicitly.
        let pathEntries = (ProcessInfo.processInfo.environment["PATH"] ?? "").split(separator: ":").map(String.init)
        var seen = Set<String>()
        return (pathEntries + ["/opt/homebrew/bin", "/usr/local/bin"])
            .filter { !$0.isEmpty && seen.insert($0).inserted }
            .map { URL(fileURLWithPath: $0).appendingPathComponent("omniwmctl") }
            .first { fileManager.isExecutableFile(atPath: $0.path) }
    }

    /// The display OmniWM considers focused, or nil when OmniWM is missing or doesn't answer in time.
    @MainActor
    func focusedDisplayID(timeout: TimeInterval = 0.5) async -> UInt32? {
        guard let tool = controlURL() else { return nil }
        let data = await Self.run(tool, arguments: ["query", "focused-monitor", "--format", "json"], timeout: timeout)
        return data.flatMap(OmniWMQuery.focusedDisplayID(fromJSON:))
    }

    /// Runs a tool off the main thread; gives up after `timeout` (SIGTERM, then SIGKILL) and always returns
    /// shortly after it, even if the tool ignores signals or a child keeps the pipe open.
    /// Nil when it can't be started; the output so far when it timed out.
    static func run(_ tool: URL, arguments: [String], timeout: TimeInterval) async -> Data? {
        await withCheckedContinuation { continuation in
            let run = ToolRun(continuation)
            let process = Process()
            let pipe = Pipe()
            process.executableURL = tool
            process.arguments = arguments
            process.standardOutput = pipe
            process.standardError = FileHandle.nullDevice
            // Output is collected only here; nothing ever blocks waiting for EOF.
            pipe.fileHandleForReading.readabilityHandler = { handle in
                let chunk = handle.availableData
                if chunk.isEmpty {
                    handle.readabilityHandler = nil
                    // EOF: everything is buffered. If the tool is still running, termination or the timeout finishes.
                    if !process.isRunning {
                        run.finish()
                    }
                } else {
                    run.append(chunk)
                }
            }
            process.terminationHandler = { _ in
                // Give a tail chunk a moment to arrive; a child holding the pipe open must not delay us further.
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.05) {
                    run.finish()
                }
            }
            do {
                try process.run()
            } catch {
                pipe.fileHandleForReading.readabilityHandler = nil
                run.fail()
                return
            }
            let pid = process.processIdentifier
            DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
                if process.isRunning {
                    process.terminate()
                    DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
                        if process.isRunning {
                            kill(pid, SIGKILL)
                        }
                    }
                }
                pipe.fileHandleForReading.readabilityHandler = nil
                run.finish()
            }
        }
    }
}

/// Collects a tool's output and resumes the continuation exactly once, whichever of
/// termination, timeout or launch failure comes first.
/// Guarded by a lock because the pipe, termination and timer callbacks arrive on different queues.
private final class ToolRun: @unchecked Sendable {
    private let lock = NSLock()
    private var buffer = Data()
    private var continuation: CheckedContinuation<Data?, Never>?

    init(_ continuation: CheckedContinuation<Data?, Never>) {
        self.continuation = continuation
    }

    func append(_ chunk: Data) {
        lock.withLock { buffer.append(chunk) }
    }

    func finish() {
        resume { $0 }
    }

    func fail() {
        resume { _ in nil }
    }

    private func resume(_ result: (inout Data) -> Data?) {
        let taken: (CheckedContinuation<Data?, Never>, Data?)? = lock.withLock {
            guard let continuation else { return nil }
            self.continuation = nil
            return (continuation, result(&buffer))
        }
        taken?.0.resume(returning: taken?.1)
    }
}
