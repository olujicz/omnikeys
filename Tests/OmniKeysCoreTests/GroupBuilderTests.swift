@testable import OmniKeysCore
import Testing

struct GroupBuilderTests {
    private func hotkeys(_ pairs: [(String, String)]) -> [OmniWMHotkey] {
        pairs.map { OmniWMHotkey(id: $0.0, binding: $0.1) }
    }

    private func rows(_ groups: [ShortcutGroup], _ title: String) -> [String] {
        groups.first { $0.title == title }?.rows.map { "\($0.keys) | \($0.action)" } ?? []
    }

    @Test func collapsesZeroBasedNumberSeries() {
        let groups = GroupBuilder.build(
            hotkeys: hotkeys([
                ("switchWorkspace.0", "Hyper+1"),
                ("switchWorkspace.1", "Hyper+2"),
                ("switchWorkspace.2", "Hyper+3"),
            ]),
            config: Config()
        )
        #expect(rows(groups, "Workspaces & monitors") == ["Hyper 1–3 | Go to workspace 1–3"])
    }

    @Test func collapsesLetterDirectionsCompactly() {
        let groups = GroupBuilder.build(
            hotkeys: hotkeys([
                ("focus.up", "Hyper+K"),
                ("focus.left", "Hyper+H"),
                ("focus.down", "Hyper+J"),
                ("focus.right", "Hyper+L"),
            ]),
            config: Config()
        )
        #expect(rows(groups, "Navigate") == ["Hyper H/J/K/L | Focus window left/down/up/right"])
    }

    @Test func collapsesArrowDirectionsWithoutSlashes() {
        let groups = GroupBuilder.build(
            hotkeys: hotkeys([
                ("move.left", "Hyper+Shift+Left Arrow"), ("move.down", "Hyper+Shift+Down Arrow"),
                ("move.up", "Hyper+Shift+Up Arrow"), ("move.right", "Hyper+Shift+Right Arrow"),
            ]),
            config: Config()
        )
        #expect(rows(groups, "Navigate") == ["Hyper ⇧ ←↓↑→ | Move window left/down/up/right"])
    }

    @Test func shiftVariantFollowsPlainShortcut() {
        let groups = GroupBuilder.build(
            hotkeys: hotkeys([
                ("focusMonitorPrevious", "Hyper+Shift+Tab"),
                ("closeFocusedWindow", "Hyper+Q"),
                ("focusMonitorNext", "Hyper+Tab"),
            ]),
            config: Config()
        )
        #expect(rows(groups, "Workspaces & monitors") == ["Hyper ⇥ | Next monitor", "Hyper ⇧ ⇥ | Previous monitor"])
    }

    @Test func hidesByBaseAndByFullID() {
        var config = Config()
        config.hide = ["toggleScratchpad", "switchWorkspace.next"]
        let groups = GroupBuilder.build(
            hotkeys: hotkeys([
                ("toggleScratchpad.1", "Hyper+S"),
                ("switchWorkspace.next", "Hyper+N"),
                ("switchWorkspace.previous", "Hyper+P"),
            ]),
            config: config
        )
        #expect(rows(groups, "Windows").isEmpty)
        #expect(rows(groups, "Workspaces & monitors") == ["Hyper P | Previous workspace"])
    }

    @Test func labelsOverrideFullIDThenBase() {
        var config = Config()
        config.labels = ["switchWorkspace.next": "Onwards", "toggleQuakeTerminal": "Drop-down"]
        let groups = GroupBuilder.build(
            hotkeys: hotkeys([("switchWorkspace.next", "Hyper+N"), ("toggleQuakeTerminal", "Hyper+Grave")]),
            config: config
        )
        #expect(rows(groups, "Workspaces & monitors") == ["Hyper N | Onwards"])
        #expect(rows(groups, "Tools").first == "Hyper ` | Drop-down")
    }

    @Test func unknownActionIsHumanizedIntoTools() {
        let groups = GroupBuilder.build(hotkeys: hotkeys([("doSomethingCool", "Hyper+D")]), config: Config())
        #expect(rows(groups, "Tools").first == "Hyper D | Do something cool")
    }

    @Test func cheatSheetRowIsLastInTools() {
        var config = Config()
        config.hotkey = "Hyper+Shift+K"
        let groups = GroupBuilder.build(hotkeys: [], config: config)
        #expect(groups.map(\.title) == ["Tools"])
        #expect(rows(groups, "Tools") == ["Hyper ⇧ K | This cheat sheet"])
    }

    @Test func groupsFollowFixedOrder() {
        let groups = GroupBuilder.build(
            hotkeys: hotkeys([
                ("closeFocusedWindow", "Hyper+Q"),
                ("focus.left", "Hyper+H"),
                ("balanceSizes", "Hyper+B"),
            ]),
            config: Config()
        )
        #expect(groups.map(\.title) == ["Navigate", "Columns & sizing", "Windows", "Tools"])
    }

    @Test func detectsShiftToMoveConvention() {
        #expect(GroupBuilder.usesShiftToMove(hotkeys([("focus.left", "Hyper+H"), ("move.left", "Hyper+Shift+H")])))
        #expect(!GroupBuilder.usesShiftToMove(hotkeys([("focus.left", "Hyper+H"), ("move.left", "Control+H")])))
        #expect(!GroupBuilder.usesShiftToMove(hotkeys([("focus.left", "Hyper+H")])))
    }

    @Test func settingsEntriesUseBaseForSeries() {
        let entries = GroupBuilder.settingsEntries(hotkeys: hotkeys([
            ("switchWorkspace.0", "Hyper+1"),
            ("switchWorkspace.1", "Hyper+2"),
            ("switchWorkspace.next", "Hyper+Tab"),
        ]))
        #expect(entries == [
            ShortcutEntry(actionID: "switchWorkspace", base: "switchWorkspace", group: "Workspaces & monitors",
                          name: "Go to workspace", keys: "Hyper 1–2"),
            ShortcutEntry(actionID: "switchWorkspace.next", base: "switchWorkspace", group: "Workspaces & monitors",
                          name: "Next workspace", keys: "Hyper ⇥"),
        ])
    }

    @Test func settingsEntriesIgnoreHide() {
        let keys = hotkeys([("toggleOverview", "Hyper+O")])
        #expect(GroupBuilder.settingsEntries(hotkeys: keys).map(\.actionID) == ["toggleOverview"])
    }

    /// Every entry's id really hides and relabels a row of the sheet.
    @Test func settingsEntriesMatchSheetRows() throws {
        let settings = try OmniWMSettings.parse(Fixture.text("settings.toml"), appName: { $0 })
        let all = GroupBuilder.build(hotkeys: settings.hotkeys, config: Config()).flatMap(\.rows)
        for entry in GroupBuilder.settingsEntries(hotkeys: settings.hotkeys) {
            var hidden = Config()
            hidden.setHidden(true, entry)
            let rows = GroupBuilder.build(hotkeys: settings.hotkeys, config: hidden).flatMap(\.rows)
            #expect(rows.count < all.count, "hiding \(entry.actionID)")
            var labelled = Config()
            labelled.labels[entry.actionID] = "ZZZ"
            let labels = GroupBuilder.build(hotkeys: settings.hotkeys, config: labelled).flatMap(\.rows).map(\.action)
            #expect(labels.contains { $0.contains("ZZZ") }, "labelling \(entry.actionID)")
        }
    }

    @Test func unhidingRemovesBaseToo() {
        let entry = ShortcutEntry(
            actionID: "switchWorkspace.next",
            base: "switchWorkspace",
            group: "",
            name: "",
            keys: ""
        )
        var config = Config()
        config.hide = ["switchWorkspace", "toggleOverview"]
        #expect(config.isHidden(entry))
        config.setHidden(false, entry)
        #expect(config.hide == ["toggleOverview"])
        config.setHidden(true, entry)
        config.setHidden(true, entry)
        #expect(config.hide == ["toggleOverview", "switchWorkspace.next"])
    }
}
