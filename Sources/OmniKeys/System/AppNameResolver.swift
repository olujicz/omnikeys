import AppKit
import OmniKeysCore

@MainActor
enum AppNameResolver {
    /// Installed app's display name, or a readable fallback from the bundle id.
    static func name(for bundleID: String) -> String {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return AppNames.fallback(for: bundleID)
        }
        return FileManager.default.displayName(atPath: url.path).replacingOccurrences(of: ".app", with: "")
    }
}
