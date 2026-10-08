public enum AppNames {
    /// Name to show for an app that isn't installed: "com.example.myEditor" -> "MyEditor".
    public static func fallback(for bundleID: String) -> String {
        let last = bundleID.split(separator: ".").last.map(String.init) ?? bundleID
        return last.prefix(1).uppercased() + last.dropFirst()
    }
}
