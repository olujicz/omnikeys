import AppKit

/// Borderless floating panel. Esc, the hotkey, or (optionally) a click elsewhere closes it; ⌘, opens settings.
final class CheatPanel: NSPanel {
    var closesOnResignKey = true
    /// `restoreFocus`: hand focus back to the app that was active before the sheet opened.
    var onDismiss: (@MainActor (_ restoreFocus: Bool) -> Void)?
    var onOpenSettings: (@MainActor () -> Void)?

    override var canBecomeKey: Bool {
        true
    }

    override func cancelOperation(_: Any?) {
        onDismiss?(true)
    }

    /// A click elsewhere already chose the app to focus, so don't restore focus.
    override func resignKey() {
        super.resignKey()
        if closesOnResignKey, isVisible {
            onDismiss?(false)
        }
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.modifierFlags.contains(.command), event.charactersIgnoringModifiers == "," {
            onDismiss?(false)
            onOpenSettings?()
            return true
        }
        return super.performKeyEquivalent(with: event)
    }
}
