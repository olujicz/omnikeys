import Foundation

/// A value to write into config.toml.
public enum TOMLValue: Equatable, Sendable {
    case string(String)
    case bool(Bool)
    case integer(Int)
    case number(Double)
    case strings([String])

    /// The value as TOML source text.
    public var source: String {
        switch self {
        case let .string(text): ConfigEditor.quoted(text)
        case let .bool(value): value ? "true" : "false"
        case let .integer(value): String(value)
        case let .number(value): ConfigEditor.number(value)
        case let .strings(items): "[" + items.map(ConfigEditor.quoted).joined(separator: ", ") + "]"
        }
    }
}

/// Edits config.toml text in place. Only the lines of the changed setting are rewritten, so comments,
/// order and anything hand-written survive.
public enum ConfigEditor {
    /// Sets a top-level `key = value`: replaces the existing assignment (keeping its indentation and trailing
    /// comment) or adds one after the last top-level setting.
    public static func setting(_ key: String, to value: TOMLValue, in text: String) -> String {
        var lines = text.components(separatedBy: "\n")
        let statements = parse(lines)
        let topLevel = statements.prefix { $0.header == nil }
        if let existing = topLevel.first(where: { $0.key == key }) {
            lines.replaceSubrange(existing.lines, with: [replacement(for: existing, value: value, in: lines)])
        } else {
            let insertAt = topLevel.last { $0.key != nil }.map { $0.lines.upperBound + 1 } ?? 0
            lines.insert("\(key) = \(value.source)", at: insertAt)
        }
        return lines.joined(separator: "\n")
    }

    /// Sets, or with nil removes, one entry of the [labels] table, adding the table when needed.
    public static func label(_ id: String, to value: String?, in text: String) -> String {
        var lines = text.components(separatedBy: "\n")
        let statements = parse(lines)
        guard let headerIndex = statements.firstIndex(where: { $0.header == "labels" }) else {
            guard let value else { return text }
            var result = text
            if !result.isEmpty, !result.hasSuffix("\n") {
                result += "\n"
            }
            if !result.isEmpty {
                result += "\n"
            }
            return result + "[labels]\n\(bareOrQuoted(id)) = \(quoted(value))\n"
        }
        let section = statements[(headerIndex + 1)...].prefix { $0.header == nil }
        let entries = labelEntries(statements)
        let matches = entries.filter { $0.id == id }.map(\.statement)
        guard let value else {
            for match in matches.reversed() {
                lines.removeSubrange(match.lines)
            }
            return lines.joined(separator: "\n")
        }
        if let match = matches.first {
            lines.replaceSubrange(match.lines, with: [replacement(for: match, value: .string(value), in: lines)])
            return lines.joined(separator: "\n")
        }
        var (edits, moved) = roomForLabel(id, entries: entries, statements: statements, lines: lines)
        let after = (section.last?.lines.upperBound ?? statements[headerIndex].lines.upperBound) + 1
        edits.append(Edit(range: after ..< after, lines: moved + ["\(bareOrQuoted(id)) = \(quoted(value))"]))
        // Bottom-up; at the same line, replace before inserting so a removal can't take the inserted line.
        for edit in edits
            .sorted(by: { ($0.range.lowerBound, $0.range.count) > ($1.range.lowerBound, $1.range.count) })
        {
            lines.replaceSubrange(edit.range, with: edit.lines)
        }
        return lines.joined(separator: "\n")
    }

    /// A replacement of whole lines; applied bottom-up so earlier line numbers stay valid.
    private struct Edit {
        var range: Range<Int>
        var lines: [String]
    }

    /// A label assignment with its full id. `table` is "x" inside `[labels.x]`, nil inside [labels].
    private struct LabelEntry {
        var statement: Statement
        var id: String
        var table: String?
    }

    /// Edits so `id = "…"` doesn't collide with labels nested under it (`id.next = …` or `[labels.id]`), which TOML
    /// rejects: nested dotted keys get quoted, and nested tables' labels move into [labels] as quoted keys.
    /// Returns the edits and the moved lines, which go into [labels] just above the new label.
    private static func roomForLabel(
        _ id: String,
        entries: [LabelEntry],
        statements: [Statement],
        lines: [String]
    ) -> (edits: [Edit], moved: [String]) {
        func isNested(_ name: String) -> Bool {
            name == id || name.hasPrefix(id + ".")
        }
        var edits: [Edit] = []
        var moved: [String] = []
        for entry in entries where entry.id.hasPrefix(id + ".") {
            let range = entry.statement.lines.lowerBound ..< entry.statement.lines.upperBound + 1
            if let table = entry.table, isNested(table) {
                moved += requoted(entry.statement, as: entry.id, in: lines)
                edits.append(Edit(range: range, lines: []))
            } else if isBareDotted(entry.statement.rawKey) {
                edits.append(Edit(
                    range: range,
                    lines: requoted(entry.statement, as: entry.statement.key ?? "", in: lines)
                ))
            }
        }
        for statement in statements {
            if let name = statement.header.flatMap(labelTableName), isNested(name) {
                edits.append(Edit(range: statement.lines.lowerBound ..< statement.lines.upperBound + 1, lines: []))
            }
        }
        return (edits, moved)
    }

    /// Every label assignment with its full id, including those in `[labels.x]` tables (`header` is then "x").
    private static func labelEntries(_ statements: [Statement]) -> [LabelEntry] {
        var result: [LabelEntry] = []
        var inLabels = false
        var table: String? // "x" inside [labels.x]
        for statement in statements {
            if let header = statement.header {
                table = labelTableName(header)
                inLabels = header == "labels" || table != nil
            } else if inLabels, let key = statement.key {
                result.append(LabelEntry(statement: statement, id: table.map { "\($0).\(key)" } ?? key, table: table))
            }
        }
        return result
    }

    /// "x.y" for a `[labels.x.y]` header, else nil.
    private static func labelTableName(_ header: String) -> String? {
        let parts = header.split(separator: ".", omittingEmptySubsequences: false)
            .map { unquoted($0.trimmingCharacters(in: .whitespaces)) }
        guard parts.count > 1, parts[0] == "labels" else { return nil }
        return parts.dropFirst().joined(separator: ".")
    }

    private static func isBareDotted(_ rawKey: String) -> Bool {
        rawKey.contains(".") && rawKey.first != "\"" && rawKey.first != "'"
    }

    /// The statement's lines with its key replaced by `key` in quotes.
    private static func requoted(_ statement: Statement, as key: String, in lines: [String]) -> [String] {
        var result = Array(lines[statement.lines])
        let first = result[0]
        let indent = first.prefix { $0 == " " || $0 == "\t" }
        let rest = first.dropFirst(indent.count).dropFirst(statement.rawKey.count)
        result[0] = "\(indent)\(quoted(key))\(rest)"
        return result
    }

    // MARK: - Parsing

    /// A table header or an assignment (possibly spanning lines). Blank and comment lines are skipped.
    private struct Statement {
        var lines: ClosedRange<Int>
        /// "labels" for `[labels]`.
        var header: String?
        /// The assignment's key with quotes removed.
        var key: String?
        /// The key as written, reused when replacing the value.
        var rawKey = ""
    }

    private static func parse(_ lines: [String]) -> [Statement] {
        var statements: [Statement] = []
        var index = 0
        while index < lines.count {
            let trimmed = lines[index].trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                index += 1
            } else if trimmed.hasPrefix("[") {
                let name = trimmed.dropFirst().prefix { $0 != "]" }.trimmingCharacters(in: .whitespaces)
                statements.append(Statement(lines: index ... index, header: name))
                index += 1
            } else if let equals = trimmed.firstIndex(of: "=") {
                let rawKey = trimmed[..<equals].trimmingCharacters(in: .whitespaces)
                var end = index
                var depth = scan(String(trimmed[trimmed.index(after: equals)...])).depth
                while depth > 0, end + 1 < lines.count {
                    end += 1
                    depth += scan(lines[end]).depth
                }
                statements.append(Statement(lines: index ... end, key: unquoted(rawKey), rawKey: rawKey))
                index = end + 1
            } else {
                index += 1
            }
        }
        return statements
    }

    /// Bracket depth change and where a `#` comment starts, ignoring both inside strings.
    private static func scan(_ text: String) -> (depth: Int, comment: String.Index?) {
        var depth = 0
        var quote: Character?
        var escaped = false
        for index in text.indices {
            let character = text[index]
            if let open = quote {
                if escaped {
                    escaped = false
                } else if character == "\\", open == "\"" {
                    escaped = true
                } else if character == open {
                    quote = nil
                }
                continue
            }
            switch character {
            case "\"", "'": quote = character
            case "[": depth += 1
            case "]": depth -= 1
            case "#": return (depth, index)
            default: break
            }
        }
        return (depth, nil)
    }

    private static func replacement(for statement: Statement, value: TOMLValue, in lines: [String]) -> String {
        let first = lines[statement.lines.lowerBound]
        let indent = first.prefix { $0 == " " || $0 == "\t" }
        let last = lines[statement.lines.upperBound]
        var comment = ""
        if let start = scan(last).comment {
            let spacing = last[..<start].reversed().prefix { $0 == " " || $0 == "\t" }
            comment = String(spacing) + last[start...]
        }
        return "\(indent)\(statement.rawKey) = \(value.source)\(comment)"
    }

    // MARK: - Formatting

    static func quoted(_ text: String) -> String {
        var out = "\""
        for character in text {
            switch character {
            case "\\": out += "\\\\"
            case "\"": out += "\\\""
            case "\n": out += "\\n"
            case "\r": out += "\\r"
            case "\t": out += "\\t"
            default: out.append(character)
            }
        }
        return out + "\""
    }

    /// Shortest decimal with at least one fractional digit, like the template (1.0, 0.45).
    static func number(_ value: Double) -> String {
        var text = String(format: "%.4f", value)
        while text.hasSuffix("0") {
            text.removeLast()
        }
        if text.hasSuffix(".") {
            text += "0"
        }
        return text
    }

    private static func unquoted(_ key: String) -> String {
        guard key.count >= 2, let first = key.first, first == "\"" || first == "'", key.last == first else {
            return key
        }
        let inner = String(key.dropFirst().dropLast())
        guard first == "\"" else { return inner }
        return inner.replacingOccurrences(of: "\\\"", with: "\"").replacingOccurrences(of: "\\\\", with: "\\")
    }

    private static func bareOrQuoted(_ id: String) -> String {
        let bare = !id.isEmpty && id.allSatisfy {
            $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "_" || $0 == "-")
        }
        return bare ? id : quoted(id)
    }
}
