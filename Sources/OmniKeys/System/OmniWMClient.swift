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
        let path = ProcessInfo.processInfo.environment["PATH"] ?? "/opt/homebrew/bin:/usr/local/bin:/usr/bin"
        return path.split(separator: ":")
            .map { URL(fileURLWithPath: String($0)).appendingPathComponent("omniwmctl") }
            .first { fileManager.isExecutableFile(atPath: $0.path) }
    }

    /// The display OmniWM considers focused, or nil when OmniWM is missing or doesn't answer in time.
    @MainActor
    func focusedDisplayID(timeout: TimeInterval = 0.5) async -> UInt32? {
        guard let tool = controlURL() else { return nil }
        let data = await Self.run(tool, arguments: ["query", "focused-monitor", "--format", "json"], timeout: timeout)
        return data.flatMap(OmniWMQuery.focusedDisplayID(fromJSON:))
    }

    /// Runs a tool off the main thread; terminates it after `timeout`. Nil when it can't be started.
    static func run(_ tool: URL, arguments: [String], timeout: TimeInterval) async -> Data? {
        await withCheckedContinuation { continuation in
            // Only this call and its handlers touch the process and pipe.
            let process = Process()
            let pipe = Pipe()
            process.executableURL = tool
            process.arguments = arguments
            process.standardOutput = pipe
            process.standardError = FileHandle.nullDevice
            process.terminationHandler = { _ in
                continuation.resume(returning: pipe.fileHandleForReading.readDataToEndOfFile())
            }
            do {
                try process.run()
            } catch {
                continuation.resume(returning: nil)
                return
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
                if process.isRunning {
                    process.terminate()
                }
            }
        }
    }
}
