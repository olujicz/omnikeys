import Foundation

public struct ShortcutTransferHotkey: Codable, Equatable, Sendable {
    public let id: String
    public let binding: String

    public init(id: String, binding: String) {
        self.id = id
        self.binding = binding
    }
}

public struct ShortcutTransferDocument: Codable, Equatable, Sendable {
    public static let currentFormatVersion = 1

    public let formatVersion: Int
    public let hyperKeyModifiers: String
    public let hotkeys: [ShortcutTransferHotkey]

    public init(
        formatVersion: Int = ShortcutTransferDocument.currentFormatVersion,
        hyperKeyModifiers: String,
        hotkeys: [ShortcutTransferHotkey]
    ) {
        self.formatVersion = formatVersion
        self.hyperKeyModifiers = hyperKeyModifiers
        self.hotkeys = hotkeys
    }
}

public enum ShortcutTransferError: Error, Equatable, Sendable, LocalizedError {
    case invalidDocument(String)
    case unsupportedVersion(Int)
    case duplicateAction(String)
    case actionNotFound(String)
    case invalidSettings(String)

    public var errorDescription: String? {
        switch self {
        case let .invalidDocument(message), let .invalidSettings(message): message
        case let .unsupportedVersion(version): "This shortcut export uses an unsupported format version (\(version))."
        case let .duplicateAction(id): "The export contains the shortcut action “\(id)” more than once."
        case let .actionNotFound(id): "The destination OmniWM settings do not contain the shortcut action “\(id)”."
        }
    }
}

/// Encodes shortcut bindings for transfer between OmniWM installations.
public enum ShortcutTransfer {
    public static func export(settings: OmniWMSettings) throws -> Data {
        let document = ShortcutTransferDocument(
            hyperKeyModifiers: settings.hyperModifiers,
            hotkeys: settings.hotkeys.map { ShortcutTransferHotkey(id: $0.id, binding: $0.binding) }
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(document)
    }

    public static func `import`(data: Data) throws -> ShortcutTransferDocument {
        let document: ShortcutTransferDocument
        do {
            document = try JSONDecoder().decode(ShortcutTransferDocument.self, from: data)
        } catch {
            throw ShortcutTransferError.invalidDocument("The file is not a valid OmniKeys shortcut export.")
        }
        guard document.formatVersion == ShortcutTransferDocument.currentFormatVersion else {
            throw ShortcutTransferError.unsupportedVersion(document.formatVersion)
        }
        guard !document.hyperKeyModifiers.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ShortcutTransferError.invalidDocument("Hyper key modifiers cannot be empty.")
        }
        var ids = Set<String>()
        for hotkey in document.hotkeys {
            guard !hotkey.id.isEmpty, !hotkey.binding.isEmpty,
                  !hotkey.id.contains("\n"), !hotkey.binding.contains("\n")
            else {
                throw ShortcutTransferError
                    .invalidDocument("Every shortcut must have a non-empty, single-line id and binding.")
            }
            guard ids.insert(hotkey.id).inserted else {
                throw ShortcutTransferError.duplicateAction(hotkey.id)
            }
        }
        return document
    }

    /// Updates only `[general].hyperKeyModifiers` and `[[hotkeys]]` bindings.
    /// All other OmniWM settings remain byte-for-byte unchanged apart from line endings.
    public static func apply(_ document: ShortcutTransferDocument, to settingsText: String) throws -> String {
        do {
            _ = try OmniWMSettings.parse(settingsText, appName: { $0 })
        } catch {
            throw ShortcutTransferError.invalidSettings("OmniWM settings.toml is not valid TOML.")
        }

        var lines = settingsText.components(separatedBy: "\n")
        let bindingLines = hotkeyBindingLines(in: lines)
        for hotkey in document.hotkeys where bindingLines[hotkey.id] == nil {
            throw ShortcutTransferError.actionNotFound(hotkey.id)
        }
        for hotkey in document.hotkeys {
            guard let lineIndex = bindingLines[hotkey.id] else { continue }
            lines[lineIndex] = replacingQuotedValue(in: lines[lineIndex], key: "binding", value: hotkey.binding)
        }
        setHyperKeyModifiers(document.hyperKeyModifiers, in: &lines)
        return lines.joined(separator: "\n")
    }

    /// The line holding `binding = "…"` for each `[[hotkeys]]` block, by action id (first block wins).
    private static func hotkeyBindingLines(in lines: [String]) -> [String: Int] {
        var result: [String: Int] = [:]
        var index = 0
        while index < lines.count {
            guard lines[index].trimmingCharacters(in: .whitespaces) == "[[hotkeys]]" else {
                index += 1
                continue
            }
            let end = sectionEnd(after: index, in: lines)
            var id: String?
            var bindingLine: Int?
            for lineIndex in (index + 1) ..< end {
                if let value = quotedValue(in: lines[lineIndex], key: "id") {
                    id = value
                }
                if quotedValue(in: lines[lineIndex], key: "binding") != nil {
                    bindingLine = lineIndex
                }
            }
            if let id, let bindingLine, result[id] == nil {
                result[id] = bindingLine
            }
            index = end
        }
        return result
    }

    /// Sets `[general].hyperKeyModifiers`, adding the key or the whole table when missing.
    private static func setHyperKeyModifiers(_ modifiers: String, in lines: inout [String]) {
        guard let header = lines.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == "[general]" }) else {
            lines.insert(contentsOf: ["[general]", "hyperKeyModifiers = \(tomlString(modifiers))", ""], at: 0)
            return
        }
        let end = sectionEnd(after: header, in: lines)
        if let line = (header + 1 ..< end)
            .first(where: { quotedValue(in: lines[$0], key: "hyperKeyModifiers") != nil })
        {
            lines[line] = replacingQuotedValue(in: lines[line], key: "hyperKeyModifiers", value: modifiers)
        } else {
            lines.insert("hyperKeyModifiers = \(tomlString(modifiers))", at: header + 1)
        }
    }

    /// Index of the next table header after `header`, or the end of the file.
    private static func sectionEnd(after header: Int, in lines: [String]) -> Int {
        lines[(header + 1)...].firstIndex { $0.trimmingCharacters(in: .whitespaces).hasPrefix("[") } ?? lines.count
    }

    private static func quotedValue(in line: String, key: String) -> String? {
        let prefix = "\(key) = \""
        guard let start = line.range(of: prefix), line.hasSuffix("\"") else { return nil }
        let valueStart = start.upperBound
        let valueEnd = line.index(before: line.endIndex)
        return String(line[valueStart ..< valueEnd]).replacingOccurrences(of: "\\\"", with: "\"")
            .replacingOccurrences(of: "\\\\", with: "\\")
    }

    private static func replacingQuotedValue(in line: String, key: String, value: String) -> String {
        let indentation = line.prefix { $0 == " " || $0 == "\t" }
        return "\(indentation)\(key) = \(tomlString(value))"
    }

    private static func tomlString(_ value: String) -> String {
        "\"" + value.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"") + "\""
    }
}
