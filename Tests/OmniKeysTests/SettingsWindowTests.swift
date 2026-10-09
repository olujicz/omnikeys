import AppKit
@testable import OmniKeys
import Testing

@MainActor
struct SettingsWindowTests {
    @Test func hasToolbarTabsInOrder() throws {
        let controller = SettingsWindowController(model: SettingsModel())
        let tabs = try #require(controller.window?.contentViewController as? NSTabViewController)
        #expect(tabs.tabStyle == .toolbar)
        #expect(tabs.tabViewItems.map(\.label) == ["General", "Size", "Appearance", "Shortcuts"])
        #expect(tabs.tabViewItems.allSatisfy { $0.image != nil })
        #expect(controller.window?.toolbarStyle == .preference)
    }
}
