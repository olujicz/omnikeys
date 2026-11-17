import TOMLDecoder

public struct OmniWMHotkey: Equatable, Sendable {
    public let id: String
    public let binding: String

    public init(id: String, binding: String) {
        self.id = id
        self.binding = binding
    }
}

public struct OmniWMWorkspace: Equatable, Sendable {
    public var name: String
    public var displayName: String
    /// Monitor name for a specific display, otherwise the assignment type ("main", "secondary").
    public var display: String
    public var apps: [String]

    public init(name: String = "", displayName: String = "", display: String = "", apps: [String] = []) {
        self.name = name
        self.displayName = displayName
        self.display = display
        self.apps = apps
    }
}

/// The parts of OmniWM's settings.toml the cheat sheet shows.
public struct OmniWMSettings: Equatable, Sendable {
    public static let defaultHyperModifiers = "Control+Option+Command"

    public var hotkeys: [OmniWMHotkey]
    /// ⌘Tab / ⌥Tab of OmniWM's window switcher. Kept apart from `hotkeys` so Export never writes them as hotkeys.
    public var switcherHotkeys: [OmniWMHotkey] = []
    /// Single keys (`modeKey`) that run an action in Window or Prefix mode; `binding` holds the mode key ("H",
    /// "Shift+R").
    public var modeKeys: [OmniWMHotkey] = []
    public var workspaces: [OmniWMWorkspace]
    public var floating: [String]
    public var hyperModifiers: String

    public init(
        hotkeys: [OmniWMHotkey] = [],
        workspaces: [OmniWMWorkspace] = [],
        floating: [String] = [],
        hyperModifiers: String = OmniWMSettings.defaultHyperModifiers
    ) {
        self.hotkeys = hotkeys
        self.workspaces = workspaces
        self.floating = floating
        self.hyperModifiers = hyperModifiers
    }

    /// - Parameter appName: display name for a bundle id (the app passes an NSWorkspace lookup).
    public static func parse(_ text: String, appName: (String) -> String) throws -> OmniWMSettings {
        let root = try TOMLTable(source: text)
        var settings = OmniWMSettings()
        if let hyper = root.optionalTable("general")?.optionalString("hyperKeyModifiers") {
            settings.hyperModifiers = hyper
        }
        settings.hotkeys = root.tables("hotkeys").compactMap { table in
            guard let id = table.optionalString("id"), let binding = table.optionalString("binding"),
                  binding != "Unassigned" else { return nil }
            return OmniWMHotkey(id: id, binding: binding)
        }
        settings.modeKeys = root.tables("hotkeys").compactMap { table in
            guard let id = table.optionalString("id"), let key = table.optionalString("modeKey"),
                  !key.isEmpty, key != "Unassigned" else { return nil }
            return OmniWMHotkey(id: id, binding: key)
        }
        if let switcher = root.optionalTable("windowSwitcher") {
            settings.switcherHotkeys = switcherHotkeys(switcher)
        }
        settings.workspaces = root.tables("workspaces").map(workspace)
        for rule in root.tables("appRules") {
            guard let bundleID = rule.optionalString("bundleId") else { continue }
            let name = appName(bundleID)
            // An empty name is an app the sheet can't name (an uninstalled web app): skip it.
            if name.isEmpty {
                continue
            }
            if let target = rule.optionalString("assignToWorkspace"),
               let index = settings.workspaces.firstIndex(where: { $0.name == target })
            {
                if !settings.workspaces[index].apps.contains(name) {
                    settings.workspaces[index].apps.append(name)
                }
            }
            if rule.optionalString("layout") == "float" {
                settings.floating.append(name)
            }
        }
        return settings
    }

    /// Defaults match OmniWM: off; ⌘Tab = active workspace, ⌥Tab = all workspaces.
    private static func switcherHotkeys(_ table: TOMLTable) -> [OmniWMHotkey] {
        guard table.optionalBool("enabled") == true else { return [] }
        let shortcuts = [
            ("Command+Tab", table.optionalString("commandTab") ?? "activeWorkspace"),
            ("Option+Tab", table.optionalString("optionTab") ?? "allWorkspaces"),
        ]
        return shortcuts.compactMap { binding, scope in
            scope == "disabled" ? nil : OmniWMHotkey(id: "windowSwitcher.\(scope)", binding: binding)
        }
    }

    private static func workspace(_ table: TOMLTable) -> OmniWMWorkspace {
        var workspace = OmniWMWorkspace(
            name: table.optionalString("name") ?? "",
            displayName: table.optionalString("displayName") ?? ""
        )
        if let assignment = table.optionalTable("monitorAssignment") {
            let type = assignment.optionalString("type") ?? ""
            workspace.display = type == "specificDisplay"
                ? assignment.optionalTable("output")?.optionalString("name") ?? ""
                : type
        }
        return workspace
    }
}
