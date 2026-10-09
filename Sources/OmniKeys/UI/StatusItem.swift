import AppKit
import OmniKeysCore

/// The menu-bar icon and its menu.
@MainActor
final class StatusItem {
    struct Actions {
        var show: @MainActor () -> Void
        var openSettings: @MainActor () -> Void
        var openSettingsFile: @MainActor () -> Void
        var exportShortcuts: @MainActor () -> Void
        var importShortcuts: @MainActor () -> Void
        var toggleLaunchAtLogin: @MainActor () -> Void
        var about: @MainActor () -> Void
        var quit: @MainActor () -> Void
    }

    private let actions: Actions
    private var item: NSStatusItem?

    init(actions: Actions) {
        self.actions = actions
    }

    func update(visible: Bool, hotkey: String, issues: [ConfigIssue]) {
        guard visible else {
            if let item {
                NSStatusBar.system.removeStatusItem(item)
            }
            item = nil
            return
        }
        let item = item ?? NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "OmniKeys")
        item.menu = Self.makeMenu(hotkey: hotkey, issues: issues, launchAtLogin: LoginItem.status, actions: actions)
        self.item = item
    }

    static func makeMenu(hotkey: String, issues: [ConfigIssue], launchAtLogin: LoginItem.Status,
                         actions: Actions) -> NSMenu
    {
        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.addItem(ActionMenuItem("Show Cheat Sheet (\(hotkey))", handler: actions.show))
        menu.addItem(.separator())
        if !issues.isEmpty {
            for issue in issues {
                let item = NSMenuItem(title: "⚠︎ \(issue.message)", action: nil, keyEquivalent: "")
                item.isEnabled = false
                menu.addItem(item)
            }
            menu.addItem(.separator())
        }
        menu.addItem(ActionMenuItem("Settings…", key: ",", handler: actions.openSettings))
        menu.addItem(ActionMenuItem("Open Settings File…", handler: actions.openSettingsFile))
        menu.addItem(ActionMenuItem("Export Shortcuts…", handler: actions.exportShortcuts))
        menu.addItem(ActionMenuItem("Import Shortcuts…", handler: actions.importShortcuts))
        let loginTitle = launchAtLogin == .requiresApproval ? "Launch at Login (approve in System Settings)" : "Launch at Login"
        let login = ActionMenuItem(loginTitle, handler: actions.toggleLaunchAtLogin)
        login.state = launchAtLogin == .enabled ? .on : .off
        menu.addItem(login)
        menu.addItem(.separator())
        menu.addItem(ActionMenuItem("About OmniKeys", handler: actions.about))
        menu.addItem(ActionMenuItem("Quit OmniKeys", key: "q", handler: actions.quit))
        return menu
    }
}
