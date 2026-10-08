import Foundation
@testable import OmniKeysCore
import Testing

struct ConfigPathsTests {
    @Test func pathsLiveUnderDotConfig() {
        let paths = ConfigPaths(home: URL(fileURLWithPath: "/Users/someone", isDirectory: true))
        #expect(paths.configFile.path == "/Users/someone/.config/omnikeys/config.toml")
        #expect(paths.omniWMSettingsFile.path == "/Users/someone/.config/omniwm/settings.toml")
        #expect(paths.legacyConfigFile.path == "/Users/someone/.config/omniwm/omnikeys.toml")
    }

    @Test func setupDecisionMatrix() {
        #expect(ConfigSetupAction.decide(configExists: true, legacyExists: false) == .useExisting)
        #expect(ConfigSetupAction.decide(configExists: true, legacyExists: true) == .useExistingIgnoringLegacy)
        #expect(ConfigSetupAction.decide(configExists: false, legacyExists: true) == .moveLegacy)
        #expect(ConfigSetupAction.decide(configExists: false, legacyExists: false) == .writeDefault)
    }

    @Test func migratedTextKeepsContentAndNotesOrigin() {
        let text = ConfigMigration.migratedText("textSize = 1.5\n", from: "/old/omnikeys.toml")
        #expect(text.hasPrefix("# Moved here from /old/omnikeys.toml"))
        #expect(ConfigLoader.load(text).config.textSize == 1.5)
    }
}
