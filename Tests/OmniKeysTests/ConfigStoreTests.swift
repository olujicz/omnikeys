import Foundation
@testable import OmniKeys
import OmniKeysCore
import Testing

@MainActor
struct ConfigStoreTests {
    let paths: ConfigPaths

    init() throws {
        paths = try ConfigPaths(home: makeTemporaryDirectory())
    }

    @Test func writesDefaultsOnFirstRun() throws {
        #expect(ConfigStore(paths: paths).prepare().isEmpty)
        #expect(try String(contentsOf: paths.configFile, encoding: .utf8) == DefaultConfig.template)
    }

    /// Review focus 5: upgrading users keep their settings.
    @Test func movesLegacyFile() throws {
        try FileManager.default.createDirectory(
            at: paths.legacyConfigFile.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try "textSize = 1.5\n".write(to: paths.legacyConfigFile, atomically: true, encoding: .utf8)
        let store = ConfigStore(paths: paths)

        #expect(store.prepare().isEmpty)
        #expect(!FileManager.default.fileExists(atPath: paths.legacyConfigFile.path))
        #expect(try String(contentsOf: paths.configFile, encoding: .utf8).contains("Moved here from"))
        #expect(store.load().config.textSize == 1.5)
    }

    @Test func warnsWhenBothFilesExist() throws {
        let store = ConfigStore(paths: paths)
        _ = store.prepare()
        try FileManager.default.createDirectory(
            at: paths.legacyConfigFile.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try "textSize = 2\n".write(to: paths.legacyConfigFile, atomically: true, encoding: .utf8)
        #expect(store.prepare().count == 1)
    }

    /// Review focus 3: deleting the file brings the defaults back.
    @Test func recreatesDeletedConfig() throws {
        let store = ConfigStore(paths: paths)
        _ = store.prepare()
        try FileManager.default.removeItem(at: paths.configFile)
        #expect(store.prepare().isEmpty)
        #expect(FileManager.default.fileExists(atPath: paths.configFile.path))
    }

    @Test func reportsMissingOmniWMSettings() {
        let store = ConfigStore(paths: paths)
        _ = store.prepare()
        #expect(store.load().issues
            .map(\.message) == ["OmniWM settings not found at \(paths.omniWMSettingsFile.path)."])
    }

    @Test func stampsChangeWhenAFileChanges() throws {
        let store = ConfigStore(paths: paths)
        _ = store.prepare()
        let before = store.fileStamps()
        try FileManager.default.setAttributes(
            [.modificationDate: Date(timeIntervalSinceNow: 60)],
            ofItemAtPath: paths.configFile.path
        )
        #expect(store.fileStamps() != before)
    }
}
