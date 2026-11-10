@testable import OmniKeysCore
import Testing

struct LoadedStateTests {
    let settingsText = """
    [general]
    hyperKeyModifiers = "Control+Option"

    [[hotkeys]]
    binding = "Hyper+H"
    id = "focus.left"
    """

    @Test func combinesConfigAndSettings() {
        let state = LoadedState.make(
            configText: "textSize = 1.5",
            settingsText: .success(settingsText),
            settingsPath: "/s"
        ) { $0 }
        #expect(state.config.textSize == 1.5)
        #expect(state.hotkey == HotkeySpec(key: "Slash", modifiers: [.control, .option]))
        #expect(state.model.hyperGlyphs == "⌃⌥")
        #expect(state.issues.isEmpty)
    }

    @Test func missingConfigMeansDefaults() {
        let state = LoadedState.make(configText: nil, settingsText: .success(settingsText), settingsPath: "/s") { $0 }
        #expect(state.config == Config())
    }

    /// Review focus 4: OmniWM not installed.
    @Test func missingSettings() {
        let state = LoadedState
            .make(configText: "", settingsText: .failure(.missing(path: "/s")), settingsPath: "/s") { $0 }
        #expect(state.issues.map(\.message) == ["OmniWM settings not found at /s."])
        #expect(state.model.groups.map(\.title) == ["Tools"])
        #expect(state.hotkey == HotkeySpec(key: "Slash", modifiers: [.control, .option, .command]))
    }

    @Test func unreadableSettingsAreReported() {
        let state = LoadedState.make(configText: "", settingsText: .success("[[broken"), settingsPath: "/s") { $0 }
        #expect(state.issues.count == 1)
        #expect(state.issues[0].message.hasPrefix("OmniWM settings at /s could not be read"))
    }

    @Test func invalidHotkeyFallsBackAndSheetShowsDefault() throws {
        let state = LoadedState.make(
            configText: "hotkey = \"Slash\"",
            settingsText: .success(settingsText),
            settingsPath: "/s"
        ) { $0 }
        #expect(state.config.hotkey == Config.defaultHotkey)
        #expect(state.issues.count == 1)
        let last = try #require(state.model.groups.last?.rows.last)
        #expect(last.keys == "Hyper /")
        #expect(last.action == "This cheat sheet")
        #expect(last.actionID == ActionCatalog.cheatSheetID)
    }

    @Test func carriesShortcutEntriesAndSettingsIssue() {
        let ok = LoadedState.make(
            configText: nil,
            settingsText: .success("[[hotkeys]]\nid = \"toggleOverview\"\nbinding = \"Hyper+O\"\n"),
            settingsPath: "/x"
        ) { $0 }
        #expect(ok.shortcuts.map(\.actionID) == ["toggleOverview"])
        #expect(ok.settingsIssue == nil)

        let missing = LoadedState.make(
            configText: nil,
            settingsText: .failure(.missing(path: "/x")),
            settingsPath: "/x"
        ) { $0 }
        #expect(missing.shortcuts.isEmpty)
        #expect(missing.settingsIssue?.message == "OmniWM settings not found at /x.")
    }
}
