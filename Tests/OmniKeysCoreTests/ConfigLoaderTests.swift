@testable import OmniKeysCore
import Testing

struct ConfigLoaderTests {
    @Test func nanTextSizeFallsBackToDefault() {
        let (config, issues) = ConfigLoader.load("textSize = nan")
        #expect(config.textSize == 1.0)
        #expect(issues.count == 1)
    }

    @Test func emptyFileGivesDefaultsWithoutIssues() {
        let (config, issues) = ConfigLoader.load("")
        #expect(config == Config())
        #expect(issues.isEmpty)
    }

    @Test func defaultTemplateParsesToDefaults() {
        let (config, issues) = ConfigLoader.load(DefaultConfig.template)
        #expect(config == Config())
        #expect(issues.isEmpty)
    }

    @Test func readsEveryKey() {
        let (config, issues) = ConfigLoader.load("""
        hotkey = "Hyper+K"
        screen = "mouse"
        closeOnClickOutside = false
        showMenuBarIcon = false
        width = 0.6
        maxHeight = 0.8
        textSize = 1.25
        density = "off"
        referenceDensity = 110
        columns = 4
        theme = "light"
        backgroundOpacity = 0.9
        accent = "#4C8DFF"
        showWorkspaces = false
        showFloating = false
        hide = ["toggleScratchpad", "focusWindowInColumn"]

        [labels]
        toggleQuakeTerminal = "Drop-down terminal"
        """)
        #expect(issues.isEmpty)
        #expect(config.hotkey == "Hyper+K")
        #expect(config.screen == .mouse)
        #expect(config.closeOnClickOutside == false)
        #expect(config.showMenuBarIcon == false)
        #expect(config.width == .fraction(0.6))
        #expect(config.maxHeight == 0.8)
        #expect(config.textSize == 1.25)
        #expect(config.density == .off)
        #expect(config.referenceDensity == 110)
        #expect(config.columns == 4)
        #expect(config.theme == .light)
        #expect(config.backgroundOpacity == 0.9)
        let expectedAccent: AccentSetting = .rgb(red: 0x4C / 255.0, green: 0x8D / 255.0, blue: 0xFF / 255.0)
        #expect(config.accent == expectedAccent)
        #expect(config.showWorkspaces == false)
        #expect(config.showFloating == false)
        #expect(config.hide == ["toggleScratchpad", "focusWindowInColumn"])
        #expect(config.labels == ["toggleQuakeTerminal": "Drop-down terminal"])
    }

    @Test func integerWorksWhereANumberIsExpected() {
        let (config, issues) = ConfigLoader.load("textSize = 2\nwidth = 1")
        #expect(config.textSize == 2)
        #expect(config.width == .fraction(1))
        #expect(issues.isEmpty)
    }

    @Test func outOfRangeNumbersAreClampedAndReported() {
        let (config, issues) = ConfigLoader.load("textSize = 9\nmaxHeight = 0.1\nwidth = 0.1\ncolumns = 7")
        #expect(config.textSize == 3)
        #expect(config.maxHeight == 0.3)
        #expect(config.width == .fraction(0.3))
        #expect(config.columns == 4)
        #expect(issues.count == 4)
        #expect(issues.contains { $0.message.contains("textSize") })
    }

    @Test func wrongTypeFallsBackToDefaultAndIsReported() {
        let (config, issues) = ConfigLoader.load("textSize = \"big\"\nshowWorkspaces = \"yes\"")
        #expect(config.textSize == 1)
        #expect(config.showWorkspaces == true)
        #expect(issues.count == 2)
    }

    @Test func unknownChoiceFallsBackAndListsOptions() {
        let (config, issues) = ConfigLoader.load("theme = \"solarized\"")
        #expect(config.theme == .dark)
        #expect(issues.count == 1)
        #expect(issues[0].message.contains("“light”"))
    }

    @Test func widthAcceptsAuto() {
        #expect(ConfigLoader.load("width = \"auto\"").config.width == .auto)
    }

    @Test func invalidAccentFallsBackToSystem() {
        let (config, issues) = ConfigLoader.load("accent = \"blue\"")
        #expect(config.accent == .system)
        #expect(issues.count == 1)
    }

    @Test func hideIgnoresEmptyStringsAndReportsNonStrings() {
        let (config, issues) = ConfigLoader.load("hide = [\"a\", \"\", 3]")
        #expect(config.hide == ["a"])
        #expect(issues.count == 1)
    }

    /// Review focus 2: unquoted dotted keys become nested tables in TOML.
    @Test func labelsAcceptDottedKeys() {
        let (config, issues) = ConfigLoader.load("""
        [labels]
        "switchWorkspace.previous" = "Back"
        switchWorkspace.next = "Next"
        focus = "Focus"
        """)
        #expect(issues.isEmpty)
        #expect(config.labels == ["switchWorkspace.previous": "Back", "switchWorkspace.next": "Next", "focus": "Focus"])
    }

    @Test func unknownKeyIsReported() {
        let (config, issues) = ConfigLoader.load("colour = \"red\"")
        #expect(config == Config())
        #expect(issues.map(\.message) == ["Unknown setting “colour” in config.toml is ignored."])
    }

    @Test func syntaxErrorGivesDefaultsAndOneIssueWithLine() {
        let (config, issues) = ConfigLoader.load("textSize = 2\nhotkey = ")
        #expect(config == Config())
        #expect(issues.count == 1)
        #expect(issues[0].message.contains("Line 2"))
    }

    @Test func accentParsesHexAndSystem() {
        #expect(AccentSetting("system") == .system)
        #expect(AccentSetting("#FF0000") == .rgb(red: 1, green: 0, blue: 0))
        #expect(AccentSetting("#FF00") == nil)
        #expect(AccentSetting("FF0000") == nil)
    }

    @Test func issuesNameTheirSetting() {
        let (_, issues) = ConfigLoader.load("textSize = 9\n[labels]\nfocus = 3\n")
        #expect(issues.map(\.key) == ["textSize", "labels"])
    }
}
