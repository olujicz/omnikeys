import Foundation

/// Where OmniKeys and OmniWM keep their files.
public struct ConfigPaths: Equatable, Sendable {
    public let configFile: URL
    /// Where versions before 0.1 kept their settings, inside OmniWM's folder.
    public let legacyConfigFile: URL
    public let omniWMSettingsFile: URL

    public init(home: URL) {
        let dotConfig = home.appendingPathComponent(".config", isDirectory: true)
        configFile = dotConfig.appendingPathComponent("omnikeys/config.toml")
        omniWMSettingsFile = dotConfig.appendingPathComponent("omniwm/settings.toml")
        legacyConfigFile = dotConfig.appendingPathComponent("omniwm/omnikeys.toml")
    }
}

/// What to do about config.toml at launch (and on every reload, so a deleted file comes back).
public enum ConfigSetupAction: Equatable, Sendable {
    case useExisting
    /// Both files exist: use the new one and tell the user the old one is ignored.
    case useExistingIgnoringLegacy
    case moveLegacy
    case writeDefault

    public static func decide(configExists: Bool, legacyExists: Bool) -> ConfigSetupAction {
        switch (configExists, legacyExists) {
        case (true, false): .useExisting
        case (true, true): .useExistingIgnoringLegacy
        case (false, true): .moveLegacy
        case (false, false): .writeDefault
        }
    }
}

public enum ConfigMigration {
    public static func migratedText(_ legacyText: String, from legacyPath: String) -> String {
        "# Moved here from \(legacyPath) by OmniKeys. That file is no longer read.\n\n" + legacyText
    }
}
