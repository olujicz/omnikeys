import Foundation
@testable import OmniKeys
import Testing

struct OmniWMClientTests {
    @Test func runReturnsOutput() async {
        let data = await OmniWMClient.run(URL(fileURLWithPath: "/bin/echo"), arguments: ["hello"], timeout: 2)
        #expect(data.flatMap { String(bytes: $0, encoding: .utf8) } == "hello\n")
    }

    /// Review focus 4: a hung omniwmctl must not freeze the panel.
    @Test func runGivesUpAfterTimeout() async {
        let start = ContinuousClock.now
        let data = await OmniWMClient.run(URL(fileURLWithPath: "/bin/sleep"), arguments: ["5"], timeout: 0.3)
        #expect(ContinuousClock.now - start < .seconds(2))
        #expect(data?.isEmpty ?? true)
    }

    /// A background child that inherits stdout must not keep the caller waiting past the timeout.
    @Test func runReturnsWhenChildKeepsPipeOpen() async {
        let start = ContinuousClock.now
        _ = await OmniWMClient.run(
            URL(fileURLWithPath: "/bin/sh"),
            arguments: ["-c", "echo hi; sleep 5 & exit 0"],
            timeout: 0.3
        )
        #expect(ContinuousClock.now - start < .seconds(2))
    }

    /// A tool that ignores SIGTERM must still not hold the caller hostage.
    @Test func runGivesUpOnTermIgnoringTool() async {
        let start = ContinuousClock.now
        _ = await OmniWMClient.run(
            URL(fileURLWithPath: "/bin/sh"),
            arguments: ["-c", "trap \"\" TERM; sleep 5"],
            timeout: 0.3
        )
        #expect(ContinuousClock.now - start < .seconds(2))
    }

    @Test func runReturnsNilForMissingTool() async {
        #expect(await OmniWMClient.run(URL(fileURLWithPath: "/nonexistent/tool"), arguments: [], timeout: 1) == nil)
    }
}
