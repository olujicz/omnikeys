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

    @Test func fileStampsFollowSymlinks() throws {
        let fileManager = FileManager.default
        let target = paths.configFile.deletingLastPathComponent().appendingPathComponent("elsewhere/real.toml")
        try fileManager.createDirectory(at: target.deletingLastPathComponent(), withIntermediateDirectories: true)
        try "textSize = 1\n".write(to: target, atomically: true, encoding: .utf8)
        try fileManager.createSymbolicLink(at: paths.configFile, withDestinationURL: target)
        let store = ConfigStore(paths: paths)
        let before = store.fileStamps()
        try fileManager.setAttributes([.modificationDate: Date(timeIntervalSinceNow: 100)], ofItemAtPath: target.path)
        #expect(store.fileStamps() != before)
    }

    @Test func unreadableSettingsIsNotReportedAsMissing() throws {
        try FileManager.default.createDirectory(
            at: paths.omniWMSettingsFile.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data([0xFF, 0xFE, 0x00]).write(to: paths.omniWMSettingsFile)
        let issues = ConfigStore(paths: paths).load().issues
        #expect(issues
            .contains { $0.message.hasPrefix("OmniWM settings at") && $0.message.contains("could not be read") })
    }

    @Test func saveRewritesThroughEdit() throws {
        let store = ConfigStore(paths: paths)
        _ = store.prepare()
        try store.save { ConfigEditor.setting("textSize", to: .number(1.5), in: $0) }
        let text = try String(contentsOf: paths.configFile, encoding: .utf8)
        #expect(store.load().config.textSize == 1.5)
        #expect(text.contains("# Text size multiplier"))
    }

    /// Review focus 2.
    @Test func saveRecreatesDeletedFile() throws {
        let store = ConfigStore(paths: paths)
        try store.save { ConfigEditor.setting("theme", to: .string("light"), in: $0) }
        let text = try String(contentsOf: paths.configFile, encoding: .utf8)
        #expect(text.contains("# Colour theme"))
        #expect(store.load().config.theme == .light)
    }

    /// Review focus 1.
    @Test func saveKeepsSymlink() throws {
        let fileManager = FileManager.default
        let target = try makeTemporaryDirectory().appendingPathComponent("dotfiles-config.toml")
        try "theme = \"dark\"\n".write(to: target, atomically: true, encoding: .utf8)
        try fileManager.createDirectory(
            at: paths.configFile.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try fileManager.createSymbolicLink(at: paths.configFile, withDestinationURL: target)

        try ConfigStore(paths: paths).save { ConfigEditor.setting("theme", to: .string("light"), in: $0) }

        #expect(try fileManager.destinationOfSymbolicLink(atPath: paths.configFile.path) == target.path)
        #expect(try String(contentsOf: target, encoding: .utf8) == "theme = \"light\"\n")
    }
}
