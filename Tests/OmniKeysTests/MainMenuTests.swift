import AppKit
@testable import OmniKeys
import Testing

@MainActor
struct MainMenuTests {
    private func equivalents(_ menu: NSMenu) -> Set<String> {
        Set(menu.items.flatMap { $0.submenu?.items ?? [] }.map(\.keyEquivalent).filter { !$0.isEmpty })
    }

    /// Without a main menu, ⌘C/⌘V and ⌘W don't reach the Settings window's text fields.
    @Test func hasStandardKeyEquivalents() {
        let menu = MainMenu.make(settings: {}, about: {}, quit: {})
        #expect(equivalents(menu).isSuperset(of: [",", "q", "z", "Z", "x", "c", "v", "a", "w"]))
    }

    @Test func settingsItemRunsAction() throws {
        let fired = Counter()
        let menu = MainMenu.make(settings: { fired.value += 1 }, about: {}, quit: {})
        let appMenu = try #require(menu.items.first?.submenu)
        let settings = try #require(appMenu.items.first { $0.keyEquivalent == "," })
        appMenu.performActionForItem(at: appMenu.index(of: settings))
        #expect(fired.value == 1)
    }
}
