import AppKit
import SwiftUI

/// The Settings window: AppKit's toolbar-tab preferences window, one SwiftUI form per tab.
@MainActor
final class SettingsWindowController: NSWindowController, NSWindowDelegate {
    private let model: SettingsModel
    private var isClosing = false

    init(model: SettingsModel) {
        self.model = model
        let tabs = TabsController()
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
        window.delegate = self
        tabs.willSelectTab = { [weak self] in self?.commitEdits() }
        window.center()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    /// Brings the window forward; OmniKeys is a menu-bar app, so it must activate first.
    func show() {
        isClosing = false
        NSApp.activate()
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }

    /// The window to attach alerts to as a sheet: nil when it is hidden or closing.
    var sheetHost: NSWindow? {
        guard let window, window.isVisible, !isClosing else { return nil }
        return window
    }

    /// Saves drafts (text being typed, a colour still being picked): ending text editing pushes the field's
    /// value into the model, then the model writes whatever changed.
    func commitEdits() {
        window?.makeFirstResponder(nil)
        model.commit()
    }

    func windowWillClose(_: Notification) {
        isClosing = true
        commitEdits()
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

/// Tells the window controller before the tab changes, while the old tab's text field still has focus.
private final class TabsController: NSTabViewController {
    var willSelectTab: () -> Void = {}

    override func tabView(_ tabView: NSTabView, willSelect tabViewItem: NSTabViewItem?) {
        willSelectTab()
        super.tabView(tabView, willSelect: tabViewItem)
    }
}
