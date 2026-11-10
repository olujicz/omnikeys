@testable import OmniKeysCore
import Testing

struct SheetEntryTests {
    private func row(_ keys: String, _ action: String, _ id: String = "") -> ShortcutRow {
        ShortcutRow(keys: keys, action: action, actionID: id)
    }

    @Test func foldsShiftVariantUnderPlainShortcut() {
        let plain = row("Hyper R", "Cycle column width", "cycleSizeForward")
        let shifted = row("Hyper ⇧ R", "Cycle column width back", "cycleSizeBackward")
        #expect(SheetEntry.make([plain, shifted]) == [.shortcut(plain, shifted: shifted)])
    }

    @Test func leavesUnrelatedShiftShortcutAlone() {
        let rows = [row("Hyper R", "Cycle"), row("Hyper ⇧ M", "Fill")]
        #expect(SheetEntry.make(rows) == rows.map { .shortcut($0, shifted: nil) })
    }

    @Test func foldsFamilyWithSharedModifiers() {
        let rows = [
            row("Hyper W", "Palette: windows", "openCommandPalette.windows"),
            row("Hyper X", "Palette: commands", "openCommandPalette.commands"),
            row("Hyper Q", "Close", "closeFocusedWindow"),
        ]
        #expect(SheetEntry.make(rows) == [
            .family(name: "Palette", modifiers: "Hyper", members: [
                row("W", "windows", "openCommandPalette.windows"),
                row("X", "commands", "openCommandPalette.commands"),
            ]),
            .shortcut(rows[2], shifted: nil),
        ])
    }

    @Test func familyFollowsIdsNotLabels() {
        let rows = [
            row("Hyper W", "Find a window", "openCommandPalette.windows"),
            row("Hyper X", "Palette: commands", "openCommandPalette.commands"),
        ]
        #expect(SheetEntry.make(rows) == [
            .family(name: "Palette", modifiers: "Hyper", members: [
                row("W", "Find a window", "openCommandPalette.windows"),
                row("X", "commands", "openCommandPalette.commands"),
            ]),
        ])
        let lookalikes = [row("Hyper A", "Note: one", "a"), row("Hyper B", "Note: two", "b")]
        #expect(SheetEntry.make(lookalikes) == lookalikes.map { .shortcut($0, shifted: nil) })
    }

    @Test func familyWithoutSharedModifiersKeepsFullKeys() {
        let rows = [
            row("⌘ ⇥", "Window switcher: this workspace", "windowSwitcher.activeWorkspace"),
            row("⌥ ⇥", "Window switcher: all workspaces", "windowSwitcher.allWorkspaces"),
        ]
        #expect(SheetEntry.make(rows) == [
            .family(name: "Window switcher", modifiers: "", members: [
                row("⌘ ⇥", "this workspace", "windowSwitcher.activeWorkspace"),
                row("⌥ ⇥", "all workspaces", "windowSwitcher.allWorkspaces"),
            ]),
        ])
    }

    @Test func singleFamilyMemberStaysAShortcut() {
        let only = row("Hyper W", "Palette: windows", "openCommandPalette.windows")
        #expect(SheetEntry.make([only]) == [.shortcut(only, shifted: nil)])
    }

    @Test func foldsNextAndPreviousIntoOneLine() {
        let rows = [
            row("Hyper ↑", "Previous workspace", "switchWorkspace.previous"),
            row("Hyper ↓", "Next workspace", "switchWorkspace.next"),
        ]
        #expect(SheetEntry.make(rows) == [
            .pair(action: "Next / previous workspace", modifiers: "Hyper", next: "↓", previous: "↑"),
        ])
    }

    @Test func relabelledPairKeepsBothLabels() {
        let rows = [
            row("Hyper ↓", "Workspace down", "switchWorkspace.next"),
            row("Hyper ↑", "Previous workspace", "switchWorkspace.previous"),
        ]
        #expect(SheetEntry.make(rows) == [
            .pair(action: "Workspace down / Previous workspace", modifiers: "Hyper", next: "↓", previous: "↑"),
        ])
    }

    @Test func keepsPairApartWhenModifiersDiffer() {
        let rows = [
            row("Hyper ↓", "Next workspace", "switchWorkspace.next"),
            row("Control ↑", "Previous workspace", "switchWorkspace.previous"),
        ]
        #expect(SheetEntry.make(rows) == rows.map { .shortcut($0, shifted: nil) })
    }

    @Test func shiftVariantWinsOverPair() {
        let next = row("Hyper ⇥", "Next monitor", "focusMonitorNext")
        let previous = row("Hyper ⇧ ⇥", "Previous monitor", "focusMonitorPrevious")
        #expect(SheetEntry.make([next, previous]) == [.shortcut(next, shifted: previous)])
    }

    @Test func pairLeavesSecondRowWithItsShiftVariant() {
        let rows = [
            row("Hyper N", "Next monitor", "focusMonitorNext"),
            row("Hyper P", "Previous monitor", "focusMonitorPrevious"),
            row("Hyper ⇧ P", "Move to monitor", "moveWindowToMonitor"),
        ]
        #expect(SheetEntry.make(rows) == [
            .shortcut(rows[0], shifted: nil),
            .shortcut(rows[1], shifted: rows[2]),
        ])
    }
}
