import AppKit
import SwiftUI

/// The Settings window: AppKit's toolbar-tab preferences window, one SwiftUI form per tab.
@MainActor
final class SettingsWindowController: NSWindowController {
    init(model: SettingsModel) {
        let tabs = NSTabViewController()
        tabs.tabStyle = .toolbar
        tabs.addTabViewItem(Self.tab("General", symbol: "gearshape", GeneralTab(), model))
        tabs.addTabViewItem(Self.tab("Size", symbol: "arrow.up.left.and.arrow.down.right", SizeTab(), model))
        tabs.addTabViewItem(Self.tab("Appearance", symbol: "paintpalette", AppearanceTab(), model))
        tabs.addTabViewItem(Self.tab("Shortcuts", symbol: "keyboard", ShortcutsTab(), model))
        let window = NSWindow(contentViewController: tabs)
        window.styleMask = [.titled, .closable]
        window.toolbarStyle = .preference
        window.isReleasedWhenClosed = false
        super.init(window: window)
        window.center()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    /// Brings the window forward; OmniKeys is a menu-bar app, so it must activate first.
    func show() {
        NSApp.activate()
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }

    private static func tab(_ title: String, symbol: String, _ view: some View,
                            _ model: SettingsModel) -> NSTabViewItem
    {
        let host = NSHostingController(rootView: view.environment(model))
        host.sizingOptions = .preferredContentSize
        host.title = title
        let item = NSTabViewItem(viewController: host)
        item.label = title
        item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: title)
        return item
    }
}
