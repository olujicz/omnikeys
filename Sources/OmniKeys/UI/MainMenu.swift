import AppKit

/// The app's main menu. OmniKeys never shows a menu bar, but the menu still routes ⌘, ⌘Q, ⌘W and the
/// Edit shortcuts (⌘C, ⌘V…) to the Settings window.
@MainActor
enum MainMenu {
    static func make(
        settings: @escaping @MainActor () -> Void,
        about: @escaping @MainActor () -> Void,
        quit: @escaping @MainActor () -> Void
    ) -> NSMenu {
        let app = NSMenu(title: "OmniKeys")
        app.addItem(ActionMenuItem("About OmniKeys", handler: about))
        app.addItem(.separator())
        app.addItem(ActionMenuItem("Settings…", key: ",", handler: settings))
        app.addItem(.separator())
        app.addItem(ActionMenuItem("Quit OmniKeys", key: "q", handler: quit))

        let edit = NSMenu(title: "Edit")
        edit.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        edit.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        edit.addItem(.separator())
        edit.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        edit.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        edit.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        edit.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")

        let window = NSMenu(title: "Window")
        window.addItem(withTitle: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")

        let main = NSMenu()
        for submenu in [app, edit, window] {
            let item = NSMenuItem(title: submenu.title, action: nil, keyEquivalent: "")
            item.submenu = submenu
            main.addItem(item)
        }
        return main
    }
}
