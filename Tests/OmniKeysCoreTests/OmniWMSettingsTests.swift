@testable import OmniKeysCore
import Testing

struct OmniWMSettingsTests {
    @Test func parsesFixture() throws {
        let text = try Fixture.text("settings.toml")
        let settings = try OmniWMSettings.parse(text, appName: AppNames.fallback(for:))
        let assigned = text.components(separatedBy: "\nbinding = \"").count - 1
        let unassigned = text.components(separatedBy: "\nbinding = \"Unassigned\"").count - 1
        #expect(settings.hotkeys.count == assigned - unassigned)
        #expect(settings.hyperModifiers == "Control+Option+Command")
        #expect(settings.workspaces == [
            OmniWMWorkspace(
                name: "1",
                displayName: "Code",
                display: "Built-in Retina Display",
                apps: ["Editor", "Terminal"]
            ),
            OmniWMWorkspace(name: "2", display: "main", apps: ["Browser"]),
            OmniWMWorkspace(name: "3"),
        ])
        #expect(settings.floating == ["Calculator"])
    }

    @Test func skipsUnassignedAndIncompleteHotkeys() throws {
        let settings = try OmniWMSettings.parse("""
        [[hotkeys]]
        binding = "Hyper+S"
        id = "toggleScratchpad.1"

        [[hotkeys]]
        binding = "Unassigned"
        id = "toggleScratchpad.2"

        [[hotkeys]]
        id = "noBinding"
        """, appName: { $0 })
        #expect(settings.hotkeys == [OmniWMHotkey(id: "toggleScratchpad.1", binding: "Hyper+S")])
    }

    @Test func readsModeKeysEvenWithoutBinding() throws {
        let settings = try OmniWMSettings.parse("""
        [[hotkeys]]
        binding = "Hyper+Minus"
        id = "resizeContainerPrimarySpan.shrink"
        modeKey = "H"

        [[hotkeys]]
        binding = "Unassigned"
        id = "cycleSizeBackward"
        modeKey = "Shift+R"

        [[hotkeys]]
        binding = "Hyper+B"
        id = "balanceSizes"
        """, appName: { $0 })
        #expect(settings.modeKeys == [
            OmniWMHotkey(id: "resizeContainerPrimarySpan.shrink", binding: "H"),
            OmniWMHotkey(id: "cycleSizeBackward", binding: "Shift+R"),
        ])
        #expect(settings.hotkeys.map(\.id) == ["resizeContainerPrimarySpan.shrink", "balanceSizes"])
    }

    @Test func windowSwitcherShortcutsFollowItsSettings() throws {
        let settings = try OmniWMSettings.parse("""
        [windowSwitcher]
        enabled = true
        commandTab = "remembered"
        optionTab = "disabled"
        """, appName: { $0 })
        #expect(settings.switcherHotkeys == [OmniWMHotkey(id: "windowSwitcher.remembered", binding: "Command+Tab")])
        #expect(settings.hotkeys.isEmpty)
    }

    @Test func windowSwitcherDefaultsAndDisabled() throws {
        let enabled = try OmniWMSettings.parse("[windowSwitcher]\nenabled = true", appName: { $0 })
        #expect(enabled.switcherHotkeys == [
            OmniWMHotkey(id: "windowSwitcher.activeWorkspace", binding: "Command+Tab"),
            OmniWMHotkey(id: "windowSwitcher.allWorkspaces", binding: "Option+Tab"),
        ])
        let disabled = try OmniWMSettings.parse("[windowSwitcher]\ncommandTab = \"allWorkspaces\"", appName: { $0 })
        #expect(disabled.switcherHotkeys.isEmpty)
    }

    @Test func emptyFileGivesDefaults() throws {
        #expect(try OmniWMSettings.parse("", appName: { $0 }) == OmniWMSettings())
    }

    @Test func invalidTOMLThrows() {
        #expect(throws: (any Error).self) { try OmniWMSettings.parse("[[hotkeys]\nid = ", appName: { $0 }) }
    }

    @Test func appNameFallbackCapitalisesLastComponent() {
        #expect(AppNames.fallback(for: "com.example.myEditor") == "MyEditor")
        #expect(AppNames.fallback(for: "single") == "Single")
    }
}
