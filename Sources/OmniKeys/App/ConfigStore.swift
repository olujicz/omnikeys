import Foundation
import OmniKeysCore
import os

/// File access for config.toml and OmniWM's settings.toml. Parsing lives in OmniKeysCore.
@MainActor
struct ConfigStore {
    let paths: ConfigPaths

    /// Makes sure config.toml exists: moves the pre-0.1 file out of OmniWM's folder, or writes the defaults.
    func prepare() -> [ConfigIssue] {
        let fileManager = FileManager.default
        let config = paths.configFile
        let legacy = paths.legacyConfigFile
        let action = ConfigSetupAction.decide(
            configExists: fileManager.fileExists(atPath: config.path),
            legacyExists: fileManager.fileExists(atPath: legacy.path)
        )
        do {
            switch action {
            case .useExisting:
                return []
            case .useExistingIgnoringLegacy:
                return [
                    ConfigIssue(
                        "\(legacy.path) is no longer read; your settings are in \(config.path). You can delete the old file."
                    ),
                ]
            case .moveLegacy:
                try fileManager.createDirectory(
                    at: config.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                let text = try String(contentsOf: legacy, encoding: .utf8)
                try ConfigMigration.migratedText(text, from: legacy.path).write(
                    to: config,
                    atomically: true,
                    encoding: .utf8
                )
                try fileManager.removeItem(at: legacy)
                Logger.app.notice("Moved \(legacy.path, privacy: .public) to \(config.path, privacy: .public)")
                return []
            case .writeDefault:
                try fileManager.createDirectory(
                    at: config.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                try DefaultConfig.template.write(to: config, atomically: true, encoding: .utf8)
                return []
            }
        } catch {
            Logger.app.error("Config setup failed: \(error.localizedDescription, privacy: .public)")
            return [ConfigIssue("Could not set up \(config.path): \(error.localizedDescription)")]
        }
    }

    /// Rewrites config.toml through `edit`, recreating it first if it was deleted. Writes to the symlink's
    /// target, so a config.toml linked from a dotfiles repo stays a link.
    func save(_ edit: (String) -> String) throws {
        _ = prepare()
        let url = paths.configFile.resolvingSymlinksInPath()
        let text = try String(contentsOf: url, encoding: .utf8)
        try edit(text).write(to: url, atomically: true, encoding: .utf8)
    }

    /// Reads both files. A missing config.toml means defaults; a missing settings.toml becomes an issue.
    /// - Parameters:
    ///   - includeMissingApps: list apps that aren't installed (renders of fixture settings need them).
    ///   - resolvedApps: receives each app rule's bundle id and the name it resolved to.
    func load(configFile: URL? = nil, settingsFile: URL? = nil, includeMissingApps: Bool = false,
              resolvedApps: ((String, String) -> Void)? = nil) -> LoadedState
    {
        let configURL = configFile ?? paths.configFile
        let settingsURL = settingsFile ?? paths.omniWMSettingsFile
        let configText = try? String(contentsOf: configURL, encoding: .utf8)
        let settingsText: Result<String, SettingsProblem> =
            if !FileManager.default.fileExists(atPath: settingsURL.path) {
                .failure(.missing(path: settingsURL.path))
            } else {
                Result { try String(contentsOf: settingsURL, encoding: .utf8) }
                    .mapError { .unreadable(path: settingsURL.path, reason: $0.localizedDescription) }
            }
        return LoadedState.make(configText: configText, settingsText: settingsText, settingsPath: settingsURL.path) {
            let name = AppNameResolver.name(for: $0, includeMissing: includeMissingApps)
            resolvedApps?($0, name)
            return name
        }
    }

    /// Modification dates of both files, for the 1-second change poll (nil = missing).
    func fileStamps() -> [Date?] {
        [paths.configFile, paths.omniWMSettingsFile].map {
            (try? FileManager.default
                .attributesOfItem(atPath: $0.resolvingSymlinksInPath().path))?[.modificationDate] as? Date
        }
    }
}
