import Foundation
import TOMLDecoder

/// Turns config.toml text into a Config. Never fails: bad values fall back to defaults and are reported.
public enum ConfigLoader {
    static let knownKeys: Set<String> = [
        "hotkey", "screen", "closeOnClickOutside", "showMenuBarIcon", "width", "maxHeight", "textSize", "density",
        "referenceDensity", "columns", "theme", "backgroundOpacity", "accent", "showWorkspaces", "showFloating",
        "hide", "labels",
    ]

    public static func load(_ text: String) -> (config: Config, issues: [ConfigIssue]) {
        let table: TOMLTable
        do {
            table = try TOMLTable(source: text)
        } catch {
            return (Config(), [ConfigIssue("config.toml has a syntax error, so all defaults are used: \(error)")])
        }
        var reader = ConfigReader(table: table)
        var config = Config()
        readOpening(&reader, into: &config)
        readSize(&reader, into: &config)
        readLook(&reader, into: &config)
        readContent(&reader, into: &config)
        for key in table.keys.sorted() where !knownKeys.contains(key) {
            reader.issues.append(ConfigIssue("Unknown setting “\(key)” in config.toml is ignored."))
        }
        return (config, reader.issues)
    }

    private static func readOpening(_ reader: inout ConfigReader, into config: inout Config) {
        if let value = reader.string("hotkey") {
            config.hotkey = value
        }
        config.screen = reader.choice("screen", default: config.screen)
        if let value = reader.bool("closeOnClickOutside") {
            config.closeOnClickOutside = value
        }
        if let value = reader.bool("showMenuBarIcon") {
            config.showMenuBarIcon = value
        }
    }

    private static func readSize(_ reader: inout ConfigReader, into config: inout Config) {
        config.width = reader.width("width")
        if let value = reader.number("maxHeight", in: 0.3 ... 1) {
            config.maxHeight = value
        }
        if let value = reader.number("textSize", in: 0.5 ... 3) {
            config.textSize = value
        }
        config.density = reader.choice("density", default: config.density)
        if let value = reader.number("referenceDensity", in: 40 ... 300) {
            config.referenceDensity = value
        }
        if let value = reader.integer("columns", in: 0 ... 4) {
            config.columns = value
        }
    }

    private static func readLook(_ reader: inout ConfigReader, into config: inout Config) {
        config.theme = reader.choice("theme", default: config.theme)
        if let value = reader.number("backgroundOpacity", in: 0 ... 1) {
            config.backgroundOpacity = value
        }
        config.accent = reader.accent("accent")
    }

    private static func readContent(_ reader: inout ConfigReader, into config: inout Config) {
        if let value = reader.bool("showWorkspaces") {
            config.showWorkspaces = value
        }
        if let value = reader.bool("showFloating") {
            config.showFloating = value
        }
        if let value = reader.stringArray("hide") {
            config.hide = value
        }
        if let value = reader.labels("labels") {
            config.labels = value
        }
    }
}

/// Reads typed values and records an issue for every value it has to reject or clamp.
private struct ConfigReader {
    let table: TOMLTable
    var issues: [ConfigIssue] = []

    mutating func string(_ key: String) -> String? {
        guard table.contains(key: key) else { return nil }
        guard let value = try? table.string(forKey: key) else {
            report(key, "should be text in quotes")
            return nil
        }
        return value
    }

    mutating func bool(_ key: String) -> Bool? {
        guard table.contains(key: key) else { return nil }
        guard let value = try? table.bool(forKey: key) else {
            report(key, "should be true or false")
            return nil
        }
        return value
    }

    mutating func number(_ key: String, in range: ClosedRange<Double>) -> Double? {
        guard table.contains(key: key) else { return nil }
        guard let value = try? table.float(forKey: key), value.isFinite else {
            report(key, "should be a number between \(format(range.lowerBound)) and \(format(range.upperBound))")
            return nil
        }
        return clamp(key, value, to: range)
    }

    mutating func integer(_ key: String, in range: ClosedRange<Int>) -> Int? {
        guard table.contains(key: key) else { return nil }
        guard let value = try? table.integer(forKey: key) else {
            report(key, "should be a whole number from \(range.lowerBound) to \(range.upperBound)")
            return nil
        }
        let clamped = min(max(Int(value), range.lowerBound), range.upperBound)
        if clamped != Int(value) {
            report(key, "must be from \(range.lowerBound) to \(range.upperBound); using \(clamped)")
        }
        return clamped
    }

    mutating func choice<T: RawRepresentable & CaseIterable>(_ key: String, default fallback: T) -> T
        where T.RawValue == String
    {
        guard let text = string(key) else { return fallback }
        if let value = T(rawValue: text) {
            return value
        }
        let options = T.allCases.map { "“\($0.rawValue)”" }.joined(separator: ", ")
        report(key, "must be one of \(options); using “\(fallback.rawValue)”")
        return fallback
    }

    mutating func width(_ key: String) -> WidthSetting {
        guard table.contains(key: key) else { return .auto }
        if let text = try? table.string(forKey: key), text == "auto" {
            return .auto
        }
        if let value = try? table.float(forKey: key), value.isFinite {
            return .fraction(clamp(key, value, to: 0.3 ... 1))
        }
        report(key, "should be “auto” or a number between 0.3 and 1")
        return .auto
    }

    mutating func accent(_ key: String) -> AccentSetting {
        guard let text = string(key) else { return .system }
        if let accent = AccentSetting(text) {
            return accent
        }
        report(key, "should be “system” or a colour like “#4C8DFF”")
        return .system
    }

    mutating func stringArray(_ key: String) -> [String]? {
        guard table.contains(key: key) else { return nil }
        guard let array = try? table.array(forKey: key) else {
            report(key, "should be a list like [\"toggleScratchpad\"]")
            return nil
        }
        var values: [String] = []
        for index in 0 ..< array.count {
            if let value = try? array.string(atIndex: index) {
                values.append(value)
            } else {
                report(key, "item \(index + 1) should be text in quotes")
            }
        }
        return values.filter { !$0.isEmpty }
    }

    /// The [labels] table. Unquoted dotted keys (`switchWorkspace.next = "…"`) arrive as nested tables; flatten them.
    mutating func labels(_ key: String) -> [String: String]? {
        guard table.contains(key: key) else { return nil }
        guard let labels = try? table.table(forKey: key) else {
            report(key, "should be a [labels] section")
            return nil
        }
        var result: [String: String] = [:]
        collect(labels, prefix: "", into: &result)
        return result
    }

    private mutating func collect(_ table: TOMLTable, prefix: String, into result: inout [String: String]) {
        for key in table.keys {
            let id = prefix + key
            if let value = try? table.string(forKey: key) {
                result[id] = value
            } else if let nested = try? table.table(forKey: key) {
                collect(nested, prefix: id + ".", into: &result)
            } else {
                issues.append(ConfigIssue("Label for “\(id)” should be text in quotes."))
            }
        }
    }

    private mutating func clamp(_ key: String, _ value: Double, to range: ClosedRange<Double>) -> Double {
        let clamped = min(max(value, range.lowerBound), range.upperBound)
        if clamped != value {
            report(
                key,
                "must be between \(format(range.lowerBound)) and \(format(range.upperBound)); using \(format(clamped))"
            )
        }
        return clamped
    }

    private mutating func report(_ key: String, _ problem: String) {
        issues.append(ConfigIssue("“\(key)” \(problem)."))
    }

    private func format(_ value: Double) -> String {
        String(format: "%g", value)
    }
}
