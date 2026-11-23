import AppKit
@testable import OmniKeys
import OmniKeysCore
import SwiftUI
import Testing

@MainActor
final class SaveRecorder {
    var calls: [(old: Config, new: Config)] = []
}

@MainActor
struct SettingsModelTests {
    let model = SettingsModel()
    let recorder = SaveRecorder()

    init() {
        load(Config())
        model.save = { [recorder] in recorder.calls.append(($0, $1)) }
    }

    private func load(_ config: Config, issues: [ConfigIssue] = [], shortcuts: [ShortcutEntry] = []) {
        let state = LoadedState(
            config: config,
            hotkey: .fallback,
            model: SheetModel(groups: [], workspaces: [], floating: [], hyperGlyphs: ""),
            issues: issues,
            shortcuts: shortcuts
        )
        model.update(state: state, launchAtLogin: .disabled)
    }

    @Test func togglesSaveImmediately() {
        model.binding(\.closeOnClickOutside).wrappedValue = false
        #expect(recorder.calls.count == 1)
        #expect(recorder.calls.first?.old.closeOnClickOutside == true)
        #expect(recorder.calls.first?.new.closeOnClickOutside == false)
    }

    @Test func commitWithoutChangesDoesNothing() {
        model.commit()
        #expect(recorder.calls.isEmpty)
    }

    @Test func slidersDraftUntilCommitted() {
        model.number(\.textSize, in: 0.5 ... 3, step: 0.05, draft: true).wrappedValue = 1.234
        #expect(model.config.textSize == 1.25)
        #expect(recorder.calls.isEmpty)
        model.commit()
        #expect(recorder.calls.count == 1)
    }

    @Test func numbersAreClamped() {
        model.number(\.referenceDensity, in: 40 ... 300, step: 1).wrappedValue = 500
        #expect(model.config.referenceDensity == 300)
    }

    @Test func hotkeyKeepsAtLeastOneModifier() {
        #expect(model.isOnlyModifier("Hyper"))
        model.modifier("Hyper").wrappedValue = false
        #expect(model.config.hotkey == "Hyper+Slash")
        #expect(recorder.calls.isEmpty)
        model.modifier("Shift").wrappedValue = true
        #expect(model.config.hotkey == "Hyper+Shift+Slash")
        model.hotkeyKey.wrappedValue = "K"
        #expect(model.config.hotkey == "Hyper+Shift+K")
    }

    @Test func widthChoice() {
        model.widthIsCustom = true
        #expect(model.config.width == .fraction(0.75))
        model.widthFraction.wrappedValue = 0.512
        #expect(model.config.width == .fraction(0.51))
        model.widthIsCustom = false
        #expect(model.config.width == .auto)
    }

    @Test func reselectingCustomWidthKeepsTheValue() {
        model.widthIsCustom = true
        model.widthFraction.wrappedValue = 0.5
        model.commit()
        model.widthIsCustom = true
        #expect(model.config.width == .fraction(0.5))
        #expect(recorder.calls.count == 2)
    }

    @Test func accentColorIsStoredAsSRGBHex() throws {
        model.accentColor = Color(.sRGB, red: 76 / 255, green: 141 / 255, blue: 1)
        #expect(try model.config.accent == #require(AccentSetting("#4C8DFF")))
        model.accentIsCustom = false
        #expect(model.config.accent == .system)
    }

    @Test func reselectingCustomAccentKeepsTheColour() throws {
        var config = Config()
        config.accent = try #require(AccentSetting("#112233"))
        load(config)
        model.accentIsCustom = true
        #expect(try model.config.accent == #require(AccentSetting("#112233")))
        #expect(recorder.calls.isEmpty)
    }

    @Test func accentColorSavesOnceAfterADebounce() async throws {
        model.accentColor = Color(.sRGB, red: 1, green: 0, blue: 0)
        model.accentColor = Color(.sRGB, red: 0, green: 0, blue: 1)
        #expect(recorder.calls.isEmpty)
        try await Task.sleep(for: .milliseconds(600))
        let blue = try #require(AccentSetting("#0000FF"))
        #expect(recorder.calls.count == 1)
        #expect(recorder.calls.first?.new.accent == blue)
    }

    @Test func commitFlushesAPendingAccentColour() async throws {
        model.accentColor = Color(.sRGB, red: 1, green: 0, blue: 0)
        model.commit()
        #expect(recorder.calls.count == 1)
        try await Task.sleep(for: .milliseconds(600))
        #expect(recorder.calls.count == 1)
    }

    @Test func syntaxErrorMakesTheFormReadOnly() {
        let issue = ConfigIssue("config.toml has a syntax error", key: ConfigLoader.syntaxErrorKey)
        load(Config(), issues: [issue])
        #expect(model.isEditable == false)
        #expect(model.generalIssues == [issue])
        model.binding(\.closeOnClickOutside).wrappedValue = false
        model.widthIsCustom = true
        model.commit()
        #expect(recorder.calls.isEmpty)
    }

    @Test func otherIssuesKeepTheFormEditable() {
        load(Config(), issues: [ConfigIssue("bad", key: "textSize"), ConfigIssue("general")])
        #expect(model.isEditable)
    }

    @Test func showingARowHiddenByBase() {
        let entry = ShortcutEntry(
            actionID: "switchWorkspace.next",
            base: "switchWorkspace",
            group: "",
            name: "",
            keys: ""
        )
        var config = Config()
        config.hide = ["switchWorkspace"]
        load(config, shortcuts: [entry])
        #expect(model.isVisible(entry).wrappedValue == false)
        model.isVisible(entry).wrappedValue = true
        #expect(model.config.hide.isEmpty)
        #expect(recorder.calls.count == 1)
    }

    @Test func emptyLabelRemovesOverride() {
        let entry = ShortcutEntry(actionID: "focus", base: "focus", group: "", name: "Focus window", keys: "")
        model.label(entry).wrappedValue = "Go"
        #expect(model.config.labels == ["focus": "Go"])
        #expect(recorder.calls.isEmpty) // labels save on commit
        model.label(entry).wrappedValue = "  "
        #expect(model.config.labels.isEmpty)
    }

    @Test func updateKeepsUncommittedDraftsAndSplitsIssues() {
        model.number(\.textSize, in: 0.5 ... 3, step: 0.05, draft: true).wrappedValue = 2
        var loaded = Config()
        loaded.theme = .light
        load(loaded, issues: [ConfigIssue("bad", key: "textSize"), ConfigIssue("general")])
        #expect(model.config.textSize == 2) // a reload (e.g. Launch at Login) must not wipe a slider mid-drag
        #expect(model.config.theme == .light)
        model.commit()
        #expect(model.config.textSize == 2)
        #expect(model.issues(for: "textSize").map(\.message) == ["bad"])
        #expect(model.generalIssues.map(\.message) == ["general"])
    }

    @Test func groupsShortcutsInSheetOrder() {
        let a = ShortcutEntry(actionID: "toggleOverview", base: "toggleOverview", group: "Tools", name: "", keys: "")
        let b = ShortcutEntry(actionID: "focus", base: "focus", group: "Navigate", name: "", keys: "")
        load(Config(), shortcuts: [b, a])
        #expect(model.shortcutGroups.map(\.title) == ["Navigate", "Tools"])
    }
}
