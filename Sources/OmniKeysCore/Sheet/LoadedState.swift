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

    public init(config: Config, hotkey: HotkeySpec, model: SheetModel, issues: [ConfigIssue]) {
        self.config = config
        self.hotkey = hotkey
        self.model = model
        self.issues = issues
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
        switch settingsText {
        case let .success(text):
            do {
                settings = try OmniWMSettings.parse(text, appName: appName)
            } catch {
                issues.append(ConfigIssue(SettingsProblem.unreadable(
                    path: settingsPath,
                    reason: String(describing: error)
                ).message))
            }
        case let .failure(problem):
            issues.append(ConfigIssue(problem.message))
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
            issues: issues
        )
    }
}
