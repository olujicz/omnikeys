import Foundation

public struct ShortcutRow: Identifiable, Equatable, Sendable {
    /// Modifier caps, as shown: ["Hyper", "⇧"].
    public let modifiers: [String]
    /// The key cap, or a series of keys: "R", "H/J/K/L", "1–6".
    public let key: String
    /// What the sheet calls the action (a user label wins).
    public let action: String
    /// The OmniWM action id, or the shared base of a collapsed series ("focus" for focus.left…right).
    public let actionID: String
    /// Each key a collapsed series stands for, in order ("1"…"9", "0" for "1–0"); just `key` otherwise.
    /// Search matches these rather than re-reading the shown `key`.
    public let seriesKeys: [String]

    public var id: String {
        "\(keys)|\(action)"
    }

    /// "Hyper ⇧ R"
    public var keys: String {
        (modifiers + [key]).joined(separator: " ")
    }

    public init(modifiers: [String], key: String, action: String, actionID: String, seriesKeys: [String]? = nil) {
        self.modifiers = modifiers
        self.key = key
        self.action = action
        self.actionID = actionID
        self.seriesKeys = seriesKeys ?? [key]
    }

    /// Splits "Hyper ⇧ R" into modifiers and key.
    public init(keys: String, action: String, actionID: String = "") {
        let tokens = Self.tokens(keys)
        self.init(modifiers: tokens.dropLast(), key: tokens.last ?? "", action: action, actionID: actionID)
    }

    /// The keys without ⇧: "Hyper ⇧ R" -> "Hyper R".
    var plainKeys: String {
        (modifiers.filter { $0 != "⇧" } + [key]).joined(separator: " ")
    }

    /// "openCommandPalette" for "openCommandPalette.windows".
    var base: String {
        String(actionID.prefix { $0 != "." })
    }

    /// "windows" for "openCommandPalette.windows"; nil without a dot.
    var member: String? {
        actionID.firstIndex(of: ".").map { String(actionID[actionID.index(after: $0)...]) }
    }

    /// "Hyper ⇧ R" -> ["Hyper", "⇧", "R"].
    public static func tokens(_ keys: String) -> [String] {
        keys.split(separator: " ").map(String.init)
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

    /// - Parameter modeKeys: single keys for Window / Prefix mode. Shown only while a mode can be entered.
    public static func build(hotkeys: [OmniWMHotkey], modeKeys: [OmniWMHotkey] = [],
                             config: Config) -> [ShortcutGroup]
    {
        var grouped: [String: [ShortcutRow]] = [:]
        for bucket in buckets(hotkeys, hide: config.hide) {
            grouped[ActionCatalog.group(for: bucket.base), default: []].append(row(for: bucket, labels: config.labels))
        }
        let canEnterMode = hotkeys.contains { $0.id == "toggleWindowMode" || $0.id == "beginPrefix" }
        let modeRows = canEnterMode ? buckets(modeKeys, hide: config.hide)
            .map { row(for: $0, labels: config.labels) } : []
        if !modeRows.isEmpty {
            grouped[ActionCatalog.Group.windowMode, default: []] += modeRows + [ShortcutRow(
                modifiers: [],
                key: "Esc",
                action: "Leave window mode",
                actionID: ActionCatalog.modeEscapeID
            )]
        }
        let (mods, key) = Binding.split(config.hotkey)
        grouped[ActionCatalog.Group.tools, default: []].append(ShortcutRow(
            modifiers: mods,
            key: key,
            action: "This cheat sheet",
            actionID: ActionCatalog.cheatSheetID
        ))
        return ActionCatalog.groupOrder.compactMap { title in
            grouped[title].map { ShortcutGroup(title: title, rows: shiftVariantsBelowPlain($0)) }
        }
    }

    private static func buckets(_ hotkeys: [OmniWMHotkey], hide: [String]) -> [Bucket] {
        var buckets: [Bucket] = []
        for hotkey in hotkeys {
            let (mods, key) = Binding.split(hotkey.binding)
            let parts = hotkey.id.split(separator: ".", maxSplits: 1).map(String.init)
            let base = parts.first ?? hotkey.id
            let suffix = parts.count > 1 ? parts[1] : ""
            if hide.contains(hotkey.id) || hide.contains(base) {
                continue
            }
            let item = Item(suffix: suffix, key: key, id: hotkey.id)
            let isSeries = Int(suffix) != nil || directions.contains(suffix)
            // Join only a series of the same kind: `switchWorkspace.next` must not swallow `switchWorkspace.0…8`.
            if isSeries, let index = buckets.firstIndex(where: {
                $0.base == base && $0.mods == mods && (Int($0.items[0].suffix) != nil) == (Int(suffix) != nil)
                    && (directions.contains($0.items[0].suffix) == directions.contains(suffix))
            }) {
                buckets[index].items.append(item)
            } else {
                buckets.append(Bucket(base: base, mods: mods, items: [item]))
            }
        }
        // Stable sort: known bases by priority, then everything else in OmniWM's order.
        let rank = { (bucket: Bucket) in
            ActionCatalog.priority.firstIndex(of: bucket.base) ?? ActionCatalog.priority.count
        }
        return buckets.enumerated()
            .sorted { (rank($0.element), $0.offset) < (rank($1.element), $1.offset) }
            .map(\.element)
    }

    /// The Shortcuts tab's rows: every row the sheet could show, ignoring `hide` and `labels`, in sheet order.
    public static func settingsEntries(hotkeys: [OmniWMHotkey]) -> [ShortcutEntry] {
        let entries = buckets(hotkeys, hide: []).map { bucket in
            let row = row(for: bucket, labels: [:])
            let isSeries = bucket.items.count > 1
            return ShortcutEntry(
                actionID: isSeries ? bucket.base : bucket.items[0].id,
                base: bucket.base,
                group: ActionCatalog.group(for: bucket.base),
                name: isSeries ? ActionCatalog.names[bucket.base] ?? ActionCatalog.humanize(bucket.base) : row.action,
                keys: row.keys
            )
        }
        return ActionCatalog.groupOrder.flatMap { group in entries.filter { $0.group == group } }
    }

    /// The numbered items in order of their number, cut where a number is missing.
    private static func numberedRuns(_ items: [Item]) -> [[Item]] {
        let sorted = items.sorted { (Int($0.suffix) ?? 0) < (Int($1.suffix) ?? 0) }
        var runs: [[Item]] = []
        for item in sorted {
            if let previous = runs.last?.last, let number = Int(item.suffix), Int(previous.suffix) == number - 1 {
                runs[runs.count - 1].append(item)
            } else {
                runs.append([item])
            }
        }
        return runs
    }

    private static func row(for bucket: Bucket, labels: [String: String]) -> ShortcutRow {
        func label(_ id: String) -> String? {
            labels[id] ?? ActionCatalog.names[id]
        }
        let first = bucket.items[0]
        let baseName = label(bucket.base) ?? ActionCatalog.humanize(bucket.base)
        let key: String
        let action: String
        var seriesKeys = bucket.items.map(\.key)
        if bucket.items.count > 1, Int(first.suffix) != nil {
            // Shown numbers start at 1 (see zeroBasedSeries). Gaps (a hidden or unassigned item) split the
            // range: "1–3, 5–9".
            let offset = ActionCatalog.zeroBasedSeries.contains(bucket.base)
                || bucket.items.contains { $0.suffix == "0" } ? 1 : 0
            let runs = numberedRuns(bucket.items)
            seriesKeys = runs.flatMap { $0.map(\.key) }
            key = runs.map { $0.count > 1 ? "\($0[0].key)–\($0[$0.count - 1].key)" : $0[0].key }
                .joined(separator: ", ")
            action = "\(baseName) " + runs.map { run in
                let numbers = run.compactMap { Int($0.suffix) }.map { $0 + offset }
                return run.count > 1 ? "\(numbers[0])–\(numbers[numbers.count - 1])" : "\(numbers[0])"
            }.joined(separator: ", ")
        } else if bucket.items.count > 1, directions.contains(first.suffix) {
            let order = { (item: Item) in directions.firstIndex(of: item.suffix) ?? directions.count }
            let sorted = bucket.items.sorted { order($0) < order($1) }
            seriesKeys = sorted.map(\.key)
            let compact = sorted.allSatisfy { $0.key.count == 1 && $0.key.first?.isLetter == true }
            key = sorted.map(\.key).joined(separator: compact ? "/" : "")
            action = "\(baseName) " + sorted.map(\.suffix).joined(separator: "/")
        } else {
            key = first.key
            action = label(first.id)
                ?? label(bucket.base).map { first.suffix.isEmpty ? $0 : "\($0) \(first.suffix)" }
                ?? ActionCatalog.humanize(first.id)
        }
        return ShortcutRow(
            modifiers: bucket.mods,
            key: key,
            action: action,
            actionID: bucket.items.count > 1 ? bucket.base : first.id,
            seriesKeys: seriesKeys
        )
    }

    /// Keep each ⇧ variant directly under its plain shortcut (Hyper Tab, then Hyper ⇧ Tab).
    private static func shiftVariantsBelowPlain(_ rows: [ShortcutRow]) -> [ShortcutRow] {
        var firstSeen: [String: Int] = [:]
        for (index, row) in rows.enumerated() where firstSeen[row.plainKeys] == nil {
            firstSeen[row.plainKeys] = index
        }
        func sortKey(_ entry: (offset: Int, element: ShortcutRow)) -> [Int] {
            [
                firstSeen[entry.element.plainKeys] ?? entry.offset,
                entry.element.keys.contains("⇧") ? 1 : 0,
                entry.offset,
            ]
        }
        return rows.enumerated().sorted { sortKey($0).lexicographicallyPrecedes(sortKey($1)) }.map(\.element)
    }
}
