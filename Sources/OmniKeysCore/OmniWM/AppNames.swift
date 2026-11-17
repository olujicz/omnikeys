public enum AppNames {
    /// Apps whose bundle id reads badly ("com.tinyspeck.slackmacgap"); used only when the app isn't installed.
    static let known: [String: String] = [
        "com.tinyspeck.slackmacgap": "Slack",
        "com.microsoft.teams2": "Microsoft Teams",
        "com.microsoft.teams": "Microsoft Teams",
        "com.microsoft.Outlook": "Microsoft Outlook",
        "com.microsoft.VSCode": "Visual Studio Code",
        "com.hnc.Discord": "Discord",
        "app.zen-browser.zen": "Zen",
        "org.mozilla.firefox": "Firefox",
        "company.thebrowser.dia": "Dia",
        "company.thebrowser.Browser": "Arc",
        "com.usebruno.app": "Bruno",
        "org.jkiss.dbeaver.core.product": "DBeaver",
        "app.supabit.supacode": "Supacode",
        "com.openai.codex": "ChatGPT",
        "com.openai.chat": "ChatGPT Classic",
        "com.anthropic.claudefordesktop": "Claude",
        "com.spotify.client": "Spotify",
        "com.mitchellh.ghostty": "Ghostty",
        "com.viber.osx": "Viber",
        "net.whatsapp.WhatsApp": "WhatsApp",
        "com.apple.MobileSMS": "Messages",
        "com.apple.systempreferences": "System Settings",
        "com.1password.1password": "1Password",
    ]

    /// Last bundle-id parts that say nothing about the app ("com.usebruno.app").
    private static let generic: Set<String> = [
        "app", "apps", "desktop", "product", "client", "mac", "macos", "osx",
    ]

    /// Name to show for an app that isn't installed: "com.example.myEditor" -> "MyEditor".
    /// Empty means "leave it off the sheet".
    public static func fallback(for bundleID: String) -> String {
        if let name = known[bundleID] {
            return name
        }
        // Sites added to the Dock from Safari / Chrome end in a UUID or hash; without the app there's no name.
        if bundleID.hasPrefix("com.apple.Safari.WebApp.") || bundleID.hasPrefix("com.google.Chrome.app.") {
            return ""
        }
        let parts = bundleID.split(separator: ".").map(String.init)
        let last = parts.last ?? bundleID
        let meaningful = parts.count > 2 && generic.contains(last.lowercased()) ? parts[parts.count - 2] : last
        return meaningful.prefix(1).uppercased() + meaningful.dropFirst()
    }
}
