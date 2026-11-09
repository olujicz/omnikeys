public enum SettingsProblem: Error, Equatable, Sendable {
    case missing(path: String)
    case unreadable(path: String, reason: String)

    public var message: String {
        switch self {
        case let .missing(path): "OmniWM settings not found at \(path)."
        case let .unreadable(path, reason): "OmniWM settings at \(path) could not be read: \(reason)"
        }
    }
}

/// The result of reading both files: what to register, what to show, and what went wrong.
public struct LoadedState: Equatable, Sendable {
    public var config: Config
    public var hotkey: HotkeySpec
    public var model: SheetModel
    /// Shown as ⚠︎ items in the menu and logged.
    public var issues: [ConfigIssue]
    /// Rows for the Settings window's Shortcuts tab.
    public var shortcuts: [ShortcutEntry]
    /// Why OmniWM's settings couldn't be read, if they couldn't.
    public var settingsIssue: ConfigIssue?

    public init(
        config: Config,
        hotkey: HotkeySpec,
        model: SheetModel,
        issues: [ConfigIssue],
        shortcuts: [ShortcutEntry] = [],
        settingsIssue: ConfigIssue? = nil
    ) {
        self.config = config
        self.hotkey = hotkey
        self.model = model
        self.issues = issues
        self.shortcuts = shortcuts
        self.settingsIssue = settingsIssue
    }

    /// - Parameters:
    ///   - configText: config.toml contents, or nil when the file doesn't exist (defaults apply).
    ///   - settingsText: OmniWM's settings.toml contents, or why it couldn't be read.
    public static func make(
        configText: String?,
        settingsText: Result<String, SettingsProblem>,
        settingsPath: String,
        appName: (String) -> String
    ) -> LoadedState {
        var config = Config()
        var issues: [ConfigIssue] = []
        if let configText {
            (config, issues) = ConfigLoader.load(configText)
        }
        var settings = OmniWMSettings()
        var settingsIssue: ConfigIssue?
        switch settingsText {
        case let .success(text):
            do {
                settings = try OmniWMSettings.parse(text, appName: appName)
            } catch {
                let issue = ConfigIssue(SettingsProblem.unreadable(
                    path: settingsPath,
                    reason: String(describing: error)
                ).message)
                settingsIssue = issue
                issues.append(issue)
            }
        case let .failure(problem):
            let issue = ConfigIssue(problem.message)
            settingsIssue = issue
            issues.append(issue)
        }
        let resolved = HotkeyParser.resolve(config.hotkey, hyper: settings.hyperModifiers)
        if let issue = resolved.issue {
            issues.append(issue)
            config.hotkey = Config.defaultHotkey
        }
        return LoadedState(
            config: config,
            hotkey: resolved.spec,
            model: SheetModel.make(config: config, settings: settings),
            issues: issues,
            shortcuts: GroupBuilder.settingsEntries(hotkeys: settings.hotkeys + settings.switcherHotkeys),
            settingsIssue: settingsIssue
        )
    }
}
