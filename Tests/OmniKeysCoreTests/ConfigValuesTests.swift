@testable import OmniKeysCore
import Testing

struct ConfigValuesTests {
    @Test func coversEveryKnownKey() {
        let keys = Set(ConfigValues.values(of: Config()).map(\.key)).union(["labels"])
        #expect(keys == ConfigLoader.knownKeys)
    }

    @Test func unchangedConfigLeavesTextIdentical() {
        #expect(ConfigValues.apply(from: Config(), to: Config(), in: DefaultConfig.template) == DefaultConfig.template)
    }

    @Test func everyFieldRoundTrips() throws {
        var custom = Config()
        custom.hotkey = "Hyper+Shift+K"
        custom.screen = .mouse
        custom.closeOnClickOutside = false
        custom.showMenuBarIcon = false
        custom.width = .fraction(0.8)
        custom.maxHeight = 0.9
        custom.textSize = 1.25
        custom.density = .off
        custom.referenceDensity = 109
        custom.columns = 3
        custom.theme = .light
        custom.backgroundOpacity = 0.6
        custom.accent = try #require(AccentSetting("#4C8DFF"))
        custom.showWorkspaces = false
        custom.showFloating = false
        custom.hide = ["toggleScratchpad", "switchWorkspace.next"]
        custom.labels = ["focus": "Focus", "switchWorkspace.next": "Next →"]

        let text = ConfigValues.apply(from: Config(), to: custom, in: DefaultConfig.template)
        let loaded = ConfigLoader.load(text)
        #expect(loaded.config == custom)
        #expect(loaded.issues.isEmpty)
        #expect(text.contains("# Default: \"Hyper+Slash\"")) // documentation kept
    }

    @Test func writesOnlyChangedSettings() {
        var custom = Config()
        custom.theme = .light
        let before = DefaultConfig.template.components(separatedBy: "\n")
        let after = ConfigValues.apply(from: Config(), to: custom, in: DefaultConfig.template)
            .components(separatedBy: "\n")
        #expect(zip(before, after).filter { $0 != $1 }.map(\.1) == ["theme = \"light\""])
    }

    @Test func writesWidthAndAccentChoices() {
        var custom = Config()
        custom.width = .fraction(0.5)
        var text = ConfigValues.apply(from: Config(), to: custom, in: "")
        #expect(text.contains("width = 0.5"))
        let old = custom
        custom.width = .auto
        custom.accent = .system
        text = ConfigValues.apply(from: old, to: custom, in: text)
        #expect(text.contains("width = \"auto\""))
    }

    /// Review focus 3.
    @Test func leavesInvalidUnrelatedValueAlone() {
        let text = "textSize = \"big\"\ntheme = \"dark\"\n"
        let (loaded, _) = ConfigLoader.load(text)
        var changed = loaded
        changed.theme = .light
        #expect(ConfigValues.apply(from: loaded, to: changed, in: text) == "textSize = \"big\"\ntheme = \"light\"\n")
    }

    @Test func removesLabel() {
        var old = Config()
        old.labels = ["focus": "F"]
        let text = ConfigValues.apply(from: Config(), to: old, in: DefaultConfig.template)
        let back = ConfigValues.apply(from: old, to: Config(), in: text)
        #expect(ConfigLoader.load(back).config.labels.isEmpty)
    }
}
