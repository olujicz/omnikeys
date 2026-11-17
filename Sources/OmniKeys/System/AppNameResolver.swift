import AppKit
import OmniKeysCore

@MainActor
enum AppNameResolver {
    /// Installed app's display name. An app that isn't installed is left off the sheet (empty name),
    /// unless `includeMissing` asks for a readable fallback from the bundle id.
    /// One Launch Services lookup per app rule, made only when the settings file is (re)loaded.
    static func name(for bundleID: String, includeMissing: Bool = false) -> String {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return includeMissing ? AppNames.fallback(for: bundleID) : ""
        }
        return FileManager.default.displayName(atPath: url.path).replacingOccurrences(of: ".app", with: "")
    }
}
