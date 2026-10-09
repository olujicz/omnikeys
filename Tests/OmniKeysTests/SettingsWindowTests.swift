import AppKit
@testable import OmniKeys
import OmniKeysCore
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

    /// A model with a drafted (uncommitted) label, and a recorder of what it saves.
    private func modelWithDraft() -> (SettingsModel, SaveRecorder) {
        let model = SettingsModel()
        let recorder = SaveRecorder()
        model.save = { [recorder] in recorder.calls.append(($0, $1)) }
        let entry = ShortcutEntry(actionID: "focus", base: "focus", group: "", name: "Focus window", keys: "")
        model.label(entry).wrappedValue = "Go"
        #expect(recorder.calls.isEmpty)
        return (model, recorder)
    }

    @Test func closingTheWindowSavesDrafts() throws {
        let (model, recorder) = modelWithDraft()
        let controller = SettingsWindowController(model: model)
        let window = try #require(controller.window)
        #expect(window.delegate === controller)
        controller.windowWillClose(Notification(name: NSWindow.willCloseNotification, object: window))
        #expect(recorder.calls.map(\.new.labels) == [["focus": "Go"]])
    }

    @Test func switchingTabsSavesDrafts() throws {
        let (model, recorder) = modelWithDraft()
        let controller = SettingsWindowController(model: model)
        let tabs = try #require(controller.window?.contentViewController as? NSTabViewController)
        tabs.selectedTabViewItemIndex = 3
        #expect(recorder.calls.map(\.new.labels) == [["focus": "Go"]])
    }
}
