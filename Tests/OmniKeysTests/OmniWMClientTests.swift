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

    @Test func runReturnsNilForMissingTool() async {
        #expect(await OmniWMClient.run(URL(fileURLWithPath: "/nonexistent/tool"), arguments: [], timeout: 1) == nil)
    }
}
