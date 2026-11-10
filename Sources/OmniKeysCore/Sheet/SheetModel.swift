/// Everything the cheat sheet shows, already filtered by the config.
public struct SheetModel: Equatable, Sendable {
    public var groups: [ShortcutGroup]
    public var workspaces: [OmniWMWorkspace]
    public var floating: [String]
    public var hyperGlyphs: String

    public init(
        groups: [ShortcutGroup],
        workspaces: [OmniWMWorkspace],
        floating: [String],
        hyperGlyphs: String
    ) {
        self.groups = groups
        self.workspaces = workspaces
        self.floating = floating
        self.hyperGlyphs = hyperGlyphs
    }

    public static func make(config: Config, settings: OmniWMSettings) -> SheetModel {
        let workspaces = config.showWorkspaces ? settings.workspaces.filter { !$0.apps.isEmpty } : []
        return SheetModel(
            groups: GroupBuilder.build(hotkeys: settings.hotkeys + settings.switcherHotkeys, config: config),
            workspaces: workspaces,
            floating: config.showFloating && !workspaces.isEmpty ? settings.floating : [],
            hyperGlyphs: Binding.modifierGlyphs(settings.hyperModifiers)
        )
    }
}
