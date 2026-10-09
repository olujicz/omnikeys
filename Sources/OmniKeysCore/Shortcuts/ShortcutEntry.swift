/// One row of the Settings window's Shortcuts tab: the id that `hide` and `labels` act on for a sheet row.
public struct ShortcutEntry: Identifiable, Equatable, Sendable {
    /// What to write into hide/labels: the base id for a collapsed series, otherwise the full action id.
    public let actionID: String
    /// Hiding the base ("switchWorkspace") hides this row too.
    public let base: String
    public let group: String
    /// The name the sheet shows when there is no custom label.
    public let name: String
    /// The key combination as the sheet shows it, e.g. "Hyper 1–9".
    public let keys: String

    /// Two series can share a base (same action, different modifiers), so include the keys.
    public var id: String {
        "\(actionID)|\(keys)"
    }

    public init(actionID: String, base: String, group: String, name: String, keys: String) {
        self.actionID = actionID
        self.base = base
        self.group = group
        self.name = name
        self.keys = keys
    }
}

public extension Config {
    func isHidden(_ entry: ShortcutEntry) -> Bool {
        hide.contains(entry.actionID) || hide.contains(entry.base)
    }

    /// Showing a row also removes a base-wide hide, which shows the base's other rows too.
    mutating func setHidden(_ hidden: Bool, _ entry: ShortcutEntry) {
        if hidden {
            if !isHidden(entry) {
                hide.append(entry.actionID)
            }
        } else {
            hide.removeAll { $0 == entry.actionID || $0 == entry.base }
        }
    }
}
