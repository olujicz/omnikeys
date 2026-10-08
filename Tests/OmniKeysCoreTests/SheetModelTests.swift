@testable import OmniKeysCore
import Testing

struct SheetModelTests {
    let settings = OmniWMSettings(
        hotkeys: [
            OmniWMHotkey(id: "focus.left", binding: "Hyper+H"),
            OmniWMHotkey(id: "move.left", binding: "Hyper+Shift+H"),
        ],
        workspaces: [OmniWMWorkspace(name: "1", apps: ["Editor"]), OmniWMWorkspace(name: "2")],
        floating: ["Calculator"],
        hyperModifiers: "Control+Option+Command"
    )

    @Test func showsWorkspacesWithAppsAndFloating() {
        let model = SheetModel.make(config: Config(), settings: settings)
        #expect(model.workspaces.map(\.name) == ["1"])
        #expect(model.floating == ["Calculator"])
        #expect(model.hyperGlyphs == "⌃⌥⌘")
        #expect(model.showShiftHint)
    }

    @Test func respectsShowWorkspacesAndShowFloating() {
        var config = Config()
        config.showFloating = false
        #expect(SheetModel.make(config: config, settings: settings).floating.isEmpty)
        config.showWorkspaces = false
        let model = SheetModel.make(config: config, settings: settings)
        #expect(model.workspaces.isEmpty)
        #expect(model.floating.isEmpty)
    }

    @Test func floatingNeedsAVisibleWorkspacesCard() {
        let noApps = OmniWMSettings(workspaces: [OmniWMWorkspace(name: "1")], floating: ["Calculator"])
        #expect(SheetModel.make(config: Config(), settings: noApps).floating.isEmpty)
    }
}
