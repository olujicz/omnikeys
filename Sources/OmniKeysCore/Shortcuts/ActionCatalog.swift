/// Friendly names and groups for OmniWM action ids.
public enum ActionCatalog {
    /// Anything missing falls back to `humanize`.
    public static let names: [String: String] = [
        "focus": "Focus window", "move": "Move window",
        "focusPrevious": "Previously focused window",
        "focusColumnFirst": "First column", "focusColumnLast": "Last column",
        "focusColumn": "Focus column", "focusWindowInColumn": "Tab / window in column",
        "moveColumnToFirst": "Move column to first", "moveColumnToLast": "Move column to last",
        "consumeWindowIntoColumn": "Pull window into column", "expelWindowFromColumn": "Push window out of column",
        "centerColumn": "Center column",
        "switchWorkspace": "Go to workspace", "moveToWorkspace": "Send window to workspace",
        "workspaceBackAndForth": "Last workspace on this screen",
        "focusMonitorPrevious": "Previous monitor", "focusMonitorNext": "Next monitor",
        "focusMonitorLast": "Last workspace (back & forth)",
        "moveWindowToMonitor": "Send window to monitor",
        "moveColumnToWorkspaceUp": "Send column to workspace above",
        "moveColumnToWorkspaceDown": "Send column to workspace below",
        "toggleFullscreen": "Fullscreen", "toggleNativeFullscreen": "Native fullscreen",
        "toggleContainerFullPrimarySpan": "Maximize column", "expandContainerToAvailablePrimarySpan": "Fill free space",
        "cycleSizeForward": "Cycle column width", "cycleSizeBackward": "Cycle column width back",
        "setContainerPrimarySpan": "Column width", "setWindowSecondarySpan": "Window height",
        "balanceSizes": "Balance sizes", "toggleColumnTabbed": "Tabbed column",
        "toggleFocusedWindowFloating": "Float / tile window", "toggleFloatingFocus": "Focus floating ⇄ tiled",
        "raiseAllFloatingWindows": "Raise floating windows", "closeFocusedWindow": "Close window",
        "toggleScratchpad": "Show scratchpad", "assignFocusedWindowToScratchpad": "Put window in scratchpad",
        "openCommandPalette": "Command palette", "toggleOverview": "Overview", "openMenuAnywhere": "App menu anywhere",
        "toggleHiddenBarPanel": "Hidden menu-bar icons", "toggleQuakeTerminal": "Quake terminal",
        "toggleWorkspaceLayout": "Switch layout niri ⇄ dwindle",
        "switchWorkspace.previous": "Previous workspace", "switchWorkspace.next": "Next workspace",
        "setContainerPrimarySpan.decrease10Percent": "Column narrower",
        "setContainerPrimarySpan.increase10Percent": "Column wider",
        "setWindowSecondarySpan.decrease10Percent": "Window shorter",
        "setWindowSecondarySpan.increase10Percent": "Window taller",
        // OmniWM 0.8 renamed the resize actions.
        "resizeContainerPrimarySpan.shrink": "Column narrower", "resizeContainerPrimarySpan.grow": "Column wider",
        "resizeWindowPrimarySpan.shrink": "Window narrower", "resizeWindowPrimarySpan.grow": "Window wider",
        "resizeWindowSecondarySpan.shrink": "Window shorter", "resizeWindowSecondarySpan.grow": "Window taller",
        "openCommandPalette.windows": "Palette: windows", "openCommandPalette.menu": "Palette: app menu",
        "openCommandPalette.clipboard": "Palette: clipboard", "openCommandPalette.commands": "Palette: commands",
        "openCommandPalette.applications": "Palette: launcher", "openCommandPalette.files": "Palette: files",
        "volumeUp": "Volume up", "volumeDown": "Volume down", "volumeMute": "Mute",
        "mediaPlayPause": "Play / pause", "mediaNext": "Next track", "mediaPrevious": "Previous track",
        "toggleShortcutPause": "Pause shortcuts", "beginPrefix": "Prefix mode (next key only)",
        "toggleWindowMode": "Enter / leave window mode", "exitKeyboardMode": "Exit keyboard mode",
        "setWindowMark": "Mark window", "removeWindowMark": "Remove window mark",
        // Not OmniWM hotkeys: synthesized from [windowSwitcher] by OmniWMSettings.
        "windowSwitcher.activeWorkspace": "Window switcher: this workspace",
        "windowSwitcher.allWorkspaces": "Window switcher: all workspaces",
        "windowSwitcher.remembered": "Window switcher: last scope",
    ]

    /// The sheet's own row, which is not an OmniWM action.
    public static let cheatSheetID = "omnikeys.cheatSheet"

    /// The Window mode card's Esc row, which OmniWM hard-wires.
    public static let modeEscapeID = "omnikeys.modeEscape"

    /// Bases whose dotted actions share one line: "Palette ✦ +" then W windows, X commands, …
    static let families = ["openCommandPalette": "Palette", "windowSwitcher": "Window switcher"]

    /// Opposite actions that share one line when only their key differs.
    static let pairs = [
        (next: "switchWorkspace.next", previous: "switchWorkspace.previous", name: "Next / previous workspace"),
        (next: "focusMonitorNext", previous: "focusMonitorPrevious", name: "Next / previous monitor"),
    ]

    /// Bases listed first within their group, most used first; others follow in OmniWM's order.
    static let priority = [
        "openCommandPalette", "windowSwitcher", "toggleOverview", "openMenuAnywhere",
        "toggleHiddenBarPanel", "toggleQuakeTerminal", "toggleWorkspaceLayout",
    ]

    /// Group titles, which also identify the groups.
    public enum Group {
        public static let navigate = "Navigate"
        public static let workspaces = "Workspaces & monitors"
        public static let columns = "Columns & sizing"
        public static let windows = "Windows"
        public static let tools = "Tools"
        /// The mode actions plus the single keys that work inside Window / Prefix mode.
        public static let windowMode = "Window mode"
    }

    public static let groupOrder = [
        Group.navigate, Group.workspaces, Group.columns, Group.windows, Group.tools, Group.windowMode,
    ]

    /// Actions that enter or leave a keyboard mode; they head the Window mode card.
    /// Series OmniWM numbers from 0 (`switchWorkspace.0` is workspace 1). Others (`focusWindowInColumn.1`) start
    /// at 1. Known here so the label stays right when the `.0` item is hidden or unassigned.
    static let zeroBasedSeries: Set<String> = [
        "switchWorkspace",
        "moveToWorkspace",
        "moveColumnToWorkspace",
        "focusColumn",
    ]

    static let modeActions: Set<String> = ["toggleWindowMode", "beginPrefix", "exitKeyboardMode"]

    private static let navigation: Set<String> = [
        "focus", "move", "focusPrevious", "focusColumnFirst", "focusColumnLast", "focusColumn", "focusWindowInColumn",
        "moveColumnToFirst", "moveColumnToLast", "consumeWindowIntoColumn", "expelWindowFromColumn", "moveColumn",
    ]

    public static func group(for base: String) -> String {
        if navigation.contains(base) {
            return Group.navigate
        }
        if modeActions.contains(base) {
            return Group.windowMode
        }
        if base.hasSuffix("WindowMark") {
            return Group.windows
        }
        if base == "toggleWorkspaceLayout" {
            return Group.tools
        }
        if base.lowercased().contains("workspace") || base.contains("Monitor") {
            return Group.workspaces
        }
        if base.contains("Span") || base.contains("Size") || base.contains("Fullscreen")
            || base == "centerColumn" || base == "toggleColumnTabbed"
        {
            return Group.columns
        }
        if base.contains("Float") || base.contains("Scratchpad") || base == "closeFocusedWindow" {
            return Group.windows
        }
        return Group.tools
    }

    /// "switchWorkspace.next" -> "Switch workspace next"
    public static func humanize(_ id: String) -> String {
        var out = ""
        for character in id.replacingOccurrences(of: ".", with: " ") {
            if character.isUppercase {
                out += " " + character.lowercased()
            } else {
                out.append(character)
            }
        }
        return out.prefix(1).uppercased() + out.dropFirst()
    }
}
