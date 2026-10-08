import Foundation

public struct ShortcutRow: Identifiable, Equatable, Sendable {
    public let keys: String
    public let action: String
    public var id: String {
        "\(keys)|\(action)"
    }

    public init(keys: String, action: String) {
        self.keys = keys
        self.action = action
    }
}

public struct ShortcutGroup: Identifiable, Equatable, Sendable {
    public let title: String
    public let rows: [ShortcutRow]
    public var id: String {
        title
    }

    public init(title: String, rows: [ShortcutRow]) {
        self.title = title
        self.rows = rows
    }
}

/// Turns OmniWM hotkeys into the sheet's groups: numbered and directional series collapse into one row.
public enum GroupBuilder {
    static let directions = ["left", "down", "up", "right"]

    private struct Item {
        let suffix: String
        let key: String
        let id: String
    }

    private struct Bucket {
        let base: String
        let mods: [String]
        var items: [Item]
    }

    public static func build(hotkeys: [OmniWMHotkey], config: Config) -> [ShortcutGroup] {
        var buckets: [Bucket] = []
        for hotkey in hotkeys {
            let (mods, key) = Binding.split(hotkey.binding)
            let parts = hotkey.id.split(separator: ".", maxSplits: 1).map(String.init)
            let base = parts.first ?? hotkey.id
            let suffix = parts.count > 1 ? parts[1] : ""
            if config.hide.contains(hotkey.id) || config.hide.contains(base) {
                continue
            }
            let item = Item(suffix: suffix, key: key, id: hotkey.id)
            let isSeries = Int(suffix) != nil || directions.contains(suffix)
            if isSeries, let index = buckets.firstIndex(where: {
                $0.base == base && $0.mods == mods && !$0.items[0].suffix.isEmpty
            }) {
                buckets[index].items.append(item)
            } else {
                buckets.append(Bucket(base: base, mods: mods, items: [item]))
            }
        }

        var grouped: [String: [ShortcutRow]] = [:]
        for bucket in buckets {
            grouped[ActionCatalog.group(for: bucket.base), default: []].append(row(for: bucket, labels: config.labels))
        }
        let (mods, key) = Binding.split(config.hotkey)
        grouped["Tools", default: []].append(ShortcutRow(
            keys: (mods + [key]).joined(separator: " "),
            action: "This cheat sheet"
        ))
        return ActionCatalog.groupOrder.compactMap { title in
            grouped[title].map { ShortcutGroup(title: title, rows: shiftVariantsBelowPlain($0)) }
        }
    }

    /// True when focus.<x> and move.<x> differ only by ⇧, so the header can say "add ⇧ to move".
    public static func usesShiftToMove(_ hotkeys: [OmniWMHotkey]) -> Bool {
        let bindings = Dictionary(hotkeys.map { ($0.id, $0.binding) }, uniquingKeysWith: { first, _ in first })
        return bindings.contains { id, binding in
            guard id.hasPrefix("focus."),
                  let move = bindings["move." + id.dropFirst("focus.".count)] else { return false }
            let focusKeys = Binding.split(binding)
            let moveKeys = Binding.split(move)
            return focusKeys.key == moveKeys.key && Set(moveKeys.mods) == Set(focusKeys.mods).union(["⇧"])
        }
    }

    private static func row(for bucket: Bucket, labels: [String: String]) -> ShortcutRow {
        func label(_ id: String) -> String? {
            labels[id] ?? ActionCatalog.names[id]
        }
        let first = bucket.items[0]
        let modText = bucket.mods.joined(separator: " ")
        let baseName = label(bucket.base) ?? ActionCatalog.humanize(bucket.base)
        let keys: String
        let action: String
        if bucket.items.count > 1, Int(first.suffix) != nil, let lastKey = bucket.items.last?.key {
            keys = "\(modText) \(first.key)–\(lastKey)"
            let offset = bucket.items.contains { $0.suffix == "0" } ? 1 : 0
            let numbers = bucket.items.compactMap { Int($0.suffix) }.map { $0 + offset }
            action = "\(baseName) \(numbers.min() ?? 0)–\(numbers.max() ?? 0)"
        } else if bucket.items.count > 1, directions.contains(first.suffix) {
            let order = { (item: Item) in directions.firstIndex(of: item.suffix) ?? directions.count }
            let sorted = bucket.items.sorted { order($0) < order($1) }
            let compact = sorted.allSatisfy { $0.key.count == 1 && $0.key.first?.isLetter == true }
            keys = "\(modText) " + sorted.map(\.key).joined(separator: compact ? "/" : "")
            action = "\(baseName) " + sorted.map(\.suffix).joined(separator: "/")
        } else {
            keys = "\(modText) \(first.key)"
            action = label(first.id)
                ?? label(bucket.base).map { first.suffix.isEmpty ? $0 : "\($0) \(first.suffix)" }
                ?? ActionCatalog.humanize(first.id)
        }
        return ShortcutRow(keys: keys.trimmingCharacters(in: .whitespaces), action: action)
    }

    /// Keep each ⇧ variant directly under its plain shortcut (Hyper Tab, then Hyper ⇧ Tab).
    private static func shiftVariantsBelowPlain(_ rows: [ShortcutRow]) -> [ShortcutRow] {
        func plainKeys(_ row: ShortcutRow) -> String {
            row.keys.replacingOccurrences(of: "⇧ ", with: "")
        }
        var firstSeen: [String: Int] = [:]
        for (index, row) in rows.enumerated() where firstSeen[plainKeys(row)] == nil {
            firstSeen[plainKeys(row)] = index
        }
        func sortKey(_ entry: (offset: Int, element: ShortcutRow)) -> [Int] {
            [
                firstSeen[plainKeys(entry.element)] ?? entry.offset,
                entry.element.keys.contains("⇧") ? 1 : 0,
                entry.offset,
            ]
        }
        return rows.enumerated().sorted { sortKey($0).lexicographicallyPrecedes(sortKey($1)) }.map(\.element)
    }
}
