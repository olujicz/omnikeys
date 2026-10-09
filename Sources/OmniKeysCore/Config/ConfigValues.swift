import Foundation

/// Config ⇄ config.toml values, so the Settings window can save just what changed.
public enum ConfigValues {
    /// Every top-level setting as written in config.toml, in template order. `labels` is handled separately.
    public static func values(of config: Config) -> [(key: String, value: TOMLValue)] {
        [
            ("hotkey", .string(config.hotkey)),
            ("screen", .string(config.screen.rawValue)),
            ("closeOnClickOutside", .bool(config.closeOnClickOutside)),
            ("showMenuBarIcon", .bool(config.showMenuBarIcon)),
            ("width", width(config.width)),
            ("maxHeight", .number(config.maxHeight)),
            ("textSize", .number(config.textSize)),
            ("density", .string(config.density.rawValue)),
            ("referenceDensity", wholeOrNumber(config.referenceDensity)),
            ("columns", .integer(config.columns)),
            ("theme", .string(config.theme.rawValue)),
            ("backgroundOpacity", .number(config.backgroundOpacity)),
            ("accent", .string(accent(config.accent))),
            ("showWorkspaces", .bool(config.showWorkspaces)),
            ("showFloating", .bool(config.showFloating)),
            ("hide", .strings(config.hide)),
        ]
    }

    /// Rewrites `text` so it loads as `new`, touching only the settings that differ from `old`.
    public static func apply(from old: Config, to new: Config, in text: String) -> String {
        var result = text
        let before = Dictionary(uniqueKeysWithValues: values(of: old).map { ($0.key, $0.value) })
        for (key, value) in values(of: new) where before[key] != value {
            result = ConfigEditor.setting(key, to: value, in: result)
        }
        for id in Set(old.labels.keys).union(new.labels.keys).sorted() where old.labels[id] != new.labels[id] {
            result = ConfigEditor.label(id, to: new.labels[id], in: result)
        }
        return result
    }

    private static func width(_ width: WidthSetting) -> TOMLValue {
        switch width {
        case .auto: .string("auto")
        case let .fraction(value): .number(value)
        }
    }

    private static func wholeOrNumber(_ value: Double) -> TOMLValue {
        value.rounded() == value ? .integer(Int(value)) : .number(value)
    }

    private static func accent(_ accent: AccentSetting) -> String {
        switch accent {
        case .system:
            "system"
        case let .rgb(red, green, blue):
            String(format: "#%02X%02X%02X", channel(red), channel(green), channel(blue))
        }
    }

    private static func channel(_ value: Double) -> Int {
        Int((min(max(value, 0), 1) * 255).rounded())
    }
}
