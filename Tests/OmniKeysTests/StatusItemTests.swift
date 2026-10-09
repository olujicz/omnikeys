import AppKit
@testable import OmniKeys
import OmniKeysCore
import Testing

@MainActor
struct StatusItemTests {
    let actions = StatusItem.Actions(
        show: {}, openSettings: {}, openSettingsFile: {}, exportShortcuts: {}, importShortcuts: {},
        toggleLaunchAtLogin: {}, about: {}, quit: {}
    )

    @Test func menuListsActions() {
        let menu = StatusItem.makeMenu(hotkey: "Hyper /", issues: [], launchAtLogin: .disabled, actions: actions)
        let titles = menu.items.filter { !$0.isSeparatorItem }.map(\.title)
        #expect(titles == [
            "Show Cheat Sheet (Hyper /)",
            "Settings…",
            "Open Settings File…",
            "Export Shortcuts…",
            "Import Shortcuts…",
            "Launch at Login",
            "About OmniKeys",
            "Quit OmniKeys",
        ])
        #expect(menu.items.first { $0.title == "Settings…" }?.keyEquivalent == ",")
        #expect(menu.items.first { $0.title == "Open Settings File…" }?.keyEquivalent == "")
        #expect(menu.items.first { $0.title == "Launch at Login" }?.state == .off)
    }

    @Test func menuShowsIssuesAndLoginState() {
        let menu = StatusItem.makeMenu(
            hotkey: "Hyper /",
            issues: [ConfigIssue("Bad thing.")],
            launchAtLogin: .enabled,
            actions: actions
        )
        #expect(menu.items.contains { $0.title == "⚠︎ Bad thing." && !$0.isEnabled })
        #expect(menu.items.first { $0.title == "Launch at Login" }?.state == .on)
    }

    @Test func menuExplainsPendingApproval() {
        let menu = StatusItem.makeMenu(
            hotkey: "Hyper /",
            issues: [],
            launchAtLogin: .requiresApproval,
            actions: actions
        )
        #expect(menu.items.contains { $0.title == "Launch at Login (approve in System Settings)" })
    }

    @Test func itemsRunTheirActions() throws {
        let fired = Counter()
        let actions = StatusItem.Actions(
            show: { fired.value += 1 },
            openSettings: {}, openSettingsFile: {}, exportShortcuts: {}, importShortcuts: {},
            toggleLaunchAtLogin: {},
            about: {},
            quit: {}
        )
        let menu = StatusItem.makeMenu(hotkey: "Hyper /", issues: [], launchAtLogin: .disabled, actions: actions)
        let show = try #require(menu.items.first)
        menu.performActionForItem(at: menu.index(of: show))
        #expect(fired.value == 1)
    }
}
