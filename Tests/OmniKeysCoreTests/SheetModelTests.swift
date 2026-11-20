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

    @Test func searchMatchesVisibleLabelsAndGroups() {
        var config = Config()
        config.labels = ["focus.left": "Jump to neighboring window"]
        config.hide = ["move.left"]
        let model = SheetModel.make(config: config, settings: settings)

        #expect(model.shortcutGroups(matching: "  \n") == model.groups)
        #expect(model.shortcutGroups(matching: "NAVIGATE Néighbor").flatMap(\.rows).map(\.action) == [
            "Jump to neighboring window",
        ])
        #expect(model.shortcutGroups(matching: "move window").isEmpty)
    }

    @Test func searchFindsIndividualBindingsInsideCollapsedRows() {
        let settings = OmniWMSettings(hotkeys: [
            OmniWMHotkey(id: "switchWorkspace.0", binding: "Hyper+1"),
            OmniWMHotkey(id: "switchWorkspace.1", binding: "Hyper+2"),
            OmniWMHotkey(id: "switchWorkspace.2", binding: "Hyper+3"),
            OmniWMHotkey(id: "move.left", binding: "Hyper+Shift+Left Arrow"),
            OmniWMHotkey(id: "move.right", binding: "Hyper+Shift+Right Arrow"),
        ])
        let model = SheetModel.make(config: Config(), settings: settings)

        #expect(model.shortcutGroups(matching: "hyper+2").flatMap(\.rows).map(\.keys) == ["Hyper 1–3"])
        #expect(model.shortcutGroups(matching: "Hyper ⇧←").flatMap(\.rows).map(\.keys) == ["Hyper ⇧ ←→"])
        #expect(model.shortcutGroups(matching: "shift left arrow").flatMap(\.rows).map(\.keys) == ["Hyper ⇧ ←→"])
        #expect(model.shortcutGroups(matching: "hyper+1+3").isEmpty)
    }

    @Test func lastSearchTermMatchesKeyNamesByPrefix() {
        let settings = OmniWMSettings(hotkeys: [
            OmniWMHotkey(id: "focus.left", binding: "Hyper+H"),
            OmniWMHotkey(id: "move.left", binding: "Control+Shift+J"),
        ])
        let model = SheetModel.make(config: Config(), settings: settings)
        let keys = { (query: String) in model.shortcutGroups(matching: query).flatMap(\.rows).map(\.keys) }

        // Every partial spelling of "hyper" keeps the Hyper rows visible.
        for query in ["hy", "hyp", "hype", "hyper"] {
            #expect(keys(query).contains("Hyper H"), "\(query)")
        }
        #expect(keys("shi") == ["⌃ ⇧ J"])
        #expect(keys("ct") == ["⌃ ⇧ J"])
        // Only the term being typed matches by prefix, and a lone letter stays an exact key.
        #expect(keys("hy j").isEmpty)
        #expect(keys("j") == ["⌃ ⇧ J"])
    }

    @Test func searchFiltersWorkspacesAndFloatingApps() {
        let settings = OmniWMSettings(
            workspaces: [
                OmniWMWorkspace(
                    name: "1",
                    displayName: "Code",
                    display: "Studio Display",
                    apps: ["Editor", "Terminal"]
                ),
                OmniWMWorkspace(name: "2", display: "main", apps: ["Safari"]),
            ],
            floating: ["Calculator", "System Settings"]
        )
        let model = SheetModel.make(config: Config(), settings: settings)

        #expect(model.workspaces(matching: "").map(\.name) == ["1", "2"])
        #expect(model.workspaces(matching: "termi").map(\.name) == ["1"])
        #expect(model.workspaces(matching: "studio code").map(\.name) == ["1"])
        #expect(model.workspaces(matching: "2").map(\.name) == ["2"])
        #expect(model.workspaces(matching: "hyper+2").isEmpty)
        #expect(model.workspaces(matching: "workspace").map(\.name) == ["1", "2"])
        #expect(model.floating(matching: "calc") == ["Calculator"])
        #expect(model.floating(matching: "safari").isEmpty)
    }

    @Test func filteredModelKeepsOnlyMatches() {
        let model = SheetModel.make(config: Config(), settings: settings)
        #expect(model.filtered(matching: " ") == model)
        let filtered = model.filtered(matching: "calc")
        #expect(filtered.groups.isEmpty)
        #expect(filtered.workspaces.isEmpty)
        #expect(filtered.floating == ["Calculator"])
    }

    @Test func seriesKeysExpandToSingleKeys() {
        #expect(SheetSearch.keys(in: "1–3") == ["1", "2", "3"])
        #expect(SheetSearch.keys(in: "H/J/K/L") == ["H", "J", "K", "L"])
        #expect(SheetSearch.keys(in: "←↓↑→") == ["←", "↓", "↑", "→"])
        #expect(SheetSearch.keys(in: "/") == ["/"])
        #expect(SheetSearch.keys(in: "PgUp") == ["PgUp"])
    }
}
