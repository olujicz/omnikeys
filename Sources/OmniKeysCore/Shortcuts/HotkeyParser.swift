public enum HotkeyModifier: String, CaseIterable, Sendable {
    case control = "Control"
    case option = "Option"
    case shift = "Shift"
    case command = "Command"
}

/// A validated global hotkey; the app maps `key` to a virtual key code.
public struct HotkeySpec: Equatable, Sendable {
    public let key: String
    public let modifiers: Set<HotkeyModifier>

    public init(key: String, modifiers: Set<HotkeyModifier>) {
        self.key = key
        self.modifiers = modifiers
    }

    /// ⌃⌥⌘/, used when even the default can't be built from OmniWM's Hyper setting.
    public static let fallback = HotkeySpec(key: "Slash", modifiers: [.control, .option, .command])
}

public enum HotkeyParser {
    public static let supportedKeys: [String] =
        (65 ... 90).map { String(UnicodeScalar(UInt8($0))) }
            + (0 ... 9).map { String($0) }
            + (1 ... 12).map { "F\($0)" }
            + ["Slash", "Period", "Comma", "Semicolon", "Quote", "Backslash", "Grave", "Minus", "Equal",
               "Space", "Return", "Tab", "Escape"]

    /// "Hyper+Shift+K" -> HotkeySpec, expanding Hyper from OmniWM's settings. Nil when invalid or modifier-less.
    public static func parse(_ binding: String, hyper: String) -> HotkeySpec? {
        var parts = binding.components(separatedBy: "+")
        guard let key = parts.popLast(), supportedKeys.contains(key) else { return nil }
        var modifiers: Set<HotkeyModifier> = []
        for name in parts.flatMap({ $0 == "Hyper" ? hyper.components(separatedBy: "+") : [$0] }) {
            guard let modifier = HotkeyModifier(rawValue: name) else { return nil }
            modifiers.insert(modifier)
        }
        return modifiers.isEmpty ? nil : HotkeySpec(key: key, modifiers: modifiers)
    }

    /// The hotkey to register, plus an issue when the configured one had to be replaced by the default.
    public static func resolve(_ binding: String, hyper: String) -> (spec: HotkeySpec, issue: ConfigIssue?) {
        if let spec = parse(binding, hyper: hyper) {
            return (spec, nil)
        }
        let issue = ConfigIssue(
            "Hotkey “\(binding)” is not valid, so \(Config.defaultHotkey) is used. "
                + "Use at least one modifier (Hyper, Control, Option, Shift, Command) plus a key such as Slash or K."
        )
        return (parse(Config.defaultHotkey, hyper: hyper) ?? .fallback, issue)
    }
}
