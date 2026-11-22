/// One line on the sheet, after folding repeated shortcuts together. Folding goes by action id,
/// so it survives user labels.
public enum SheetEntry: Equatable, Sendable, Identifiable {
    /// A shortcut, with the ⇧ variant of the same keys underneath ("Cycle column width", ⇧ "… back").
    case shortcut(ShortcutRow, shifted: ShortcutRow?)
    /// Consecutive actions of one family (`ActionCatalog.families`, "openCommandPalette.windows", …):
    /// the shared modifiers once, then each member with only its own keys.
    case family(name: String, modifiers: String, members: [ShortcutRow])
    /// A next/previous pair (`ActionCatalog.pairs`) on the same modifiers: "Next / previous workspace", ✦ ↓ / ↑.
    case pair(action: String, modifiers: String, next: String, previous: String)

    public var id: String {
        switch self {
        case let .shortcut(row, _): row.id
        case let .family(name, _, _): "family-\(name)"
        case let .pair(action, _, _, _): "pair-\(action)"
        }
    }

    public static func make(_ rows: [ShortcutRow]) -> [SheetEntry] {
        func row(_ index: Int) -> ShortcutRow? {
            rows.indices.contains(index) ? rows[index] : nil
        }
        var entries: [SheetEntry] = []
        var index = 0
        while let current = row(index) {
            if let name = ActionCatalog.families[current.base], current.member != nil {
                let end = rows[index...].firstIndex { $0.base != current.base || $0.member == nil } ?? rows.endIndex
                if end - index > 1 {
                    entries.append(family(name: name, rows: Array(rows[index ..< end])))
                    index = end
                    continue
                }
            }
            if let next = row(index + 1), next.isShiftVariant(of: current) {
                entries.append(.shortcut(current, shifted: next))
                index += 2
            } else if let next = row(index + 1), let pair = pair(current, next),
                      row(index + 2)?.isShiftVariant(of: next) != true
            {
                entries.append(pair)
                index += 2
            } else {
                entries.append(.shortcut(current, shifted: nil))
                index += 1
            }
        }
        return entries
    }

    /// Folds a next/previous pair (either order) when only their key differs. Keeps the catalog's
    /// combined name unless the user relabelled one of them.
    private static func pair(_ first: ShortcutRow, _ second: ShortcutRow) -> SheetEntry? {
        let ids: Set = [first.actionID, second.actionID]
        guard let match = ActionCatalog.pairs.first(where: { [$0.next, $0.previous] == ids }) else { return nil }
        let (next, previous) = first.actionID == match.next ? (first, second) : (second, first)
        guard next.modifiers == previous.modifiers else { return nil }
        let relabelled = [next, previous].contains { $0.action != ActionCatalog.names[$0.actionID] }
        return .pair(
            action: relabelled ? "\(next.action) / \(previous.action)" : match.name,
            modifiers: next.modifiers.joined(separator: " "),
            next: next.key,
            previous: previous.key
        )
    }

    private static func family(name: String, rows: [ShortcutRow]) -> SheetEntry {
        let modifiers = rows.map(\.modifiers)
        // Modifiers every member shares, in the same position.
        var shared = 0
        while let first = modifiers.first, shared < first.count,
              modifiers.allSatisfy({ shared < $0.count && $0[shared] == first[shared] })
        {
            shared += 1
        }
        let prefix = "\(name): "
        let members = rows.map { row in
            ShortcutRow(
                modifiers: Array(row.modifiers.dropFirst(shared)),
                key: row.key,
                action: row.action.hasPrefix(prefix) ? String(row.action.dropFirst(prefix.count)) : row.action,
                actionID: row.actionID,
                seriesKeys: row.seriesKeys
            )
        }
        return .family(
            name: name,
            modifiers: (modifiers.first ?? []).prefix(shared).joined(separator: " "),
            members: members
        )
    }
}

extension ShortcutRow {
    /// "Hyper ⇧ R" is the ⇧ variant of "Hyper R".
    func isShiftVariant(of plain: ShortcutRow) -> Bool {
        key == plain.key && !plain.modifiers.contains("⇧") && Set(modifiers) == Set(plain.modifiers + ["⇧"])
    }
}
