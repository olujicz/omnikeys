import Foundation

/// Which screen the sheet opens on.
public enum ScreenChoice: String, CaseIterable, Sendable {
    case focused, mouse, main
}

public enum Theme: String, CaseIterable, Sendable {
    case dark, light, system
}

public enum DensityMode: String, CaseIterable, Sendable {
    case auto, off
}

public enum WidthSetting: Equatable, Sendable {
    case auto
    case fraction(Double)
}

public enum AccentSetting: Equatable, Sendable {
    case system
    case rgb(red: Double, green: Double, blue: Double)

    /// "system" or a "#RRGGBB" hex colour; nil for anything else.
    public init?(_ text: String) {
        if text == "system" {
            self = .system
            return
        }
        guard text.count == 7, text.hasPrefix("#"), let value = UInt32(text.dropFirst(), radix: 16) else { return nil }
        self = .rgb(
            red: Double(value >> 16 & 0xFF) / 255,
            green: Double(value >> 8 & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}

/// OmniKeys' own settings from config.toml. Defaults must match DefaultConfig.template.
public struct Config: Equatable, Sendable {
    public static let defaultHotkey = "Hyper+Slash"

    public var hotkey = Config.defaultHotkey
    public var screen = ScreenChoice.focused
    public var closeOnClickOutside = true
    public var showMenuBarIcon = true
    public var width = WidthSetting.auto
    public var maxHeight = 0.94
    public var textSize = 1.0
    public var density = DensityMode.auto
    public var referenceDensity = 85.0
    public var columns = 0
    public var theme = Theme.dark
    public var backgroundOpacity = 0.45
    public var accent = AccentSetting.system
    public var showWorkspaces = true
    public var showFloating = true
    public var hide: [String] = []
    public var labels: [String: String] = [:]

    public init() {}
}

/// A problem with the user's files, shown in the menu and logged instead of failing silently.
public struct ConfigIssue: Equatable, Sendable, CustomStringConvertible {
    public let message: String
    /// The config.toml setting it is about, so the Settings window can show it next to that control.
    public let key: String?

    public init(_ message: String, key: String? = nil) {
        self.message = message
        self.key = key
    }

    public var description: String {
        message
    }
}
