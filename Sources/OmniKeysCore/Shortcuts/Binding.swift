/// OmniWM binding strings ("Hyper+Shift+Left Arrow") turned into what the sheet shows.
public enum Binding {
    public static let glyphs: [String: String] = [
        "Shift": "⇧", "Option": "⌥", "Command": "⌘", "Control": "⌃",
        "Left Arrow": "←", "Right Arrow": "→", "Up Arrow": "↑", "Down Arrow": "↓",
        "Grave": "`", "Comma": ",", "Period": ".", "Minus": "−", "Equal": "=", "Slash": "/",
        "Backslash": "\\", "Semicolon": ";", "Quote": "'", "Return": "↩", "Tab": "⇥",
        "Page Up": "PgUp", "Page Down": "PgDn", "Escape": "Esc", "Delete": "⌫",
    ]

    /// "Hyper+Shift+Left Arrow" -> (["Hyper", "⇧"], "←")
    public static func split(_ binding: String) -> (mods: [String], key: String) {
        let parts = binding.components(separatedBy: "+")
        let key = parts.last ?? binding
        return (parts.dropLast().map { glyphs[$0] ?? $0 }, glyphs[key] ?? key)
    }

    /// "Control+Option+Command" -> "⌃⌥⌘", in the order macOS menus use.
    public static func modifierGlyphs(_ modifiers: String) -> String {
        let present = Set(modifiers.components(separatedBy: "+"))
        return ["Control", "Option", "Shift", "Command"].filter(present.contains).compactMap { glyphs[$0] }.joined()
    }
}
