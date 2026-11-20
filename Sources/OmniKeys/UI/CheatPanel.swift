import AppKit

/// Borderless floating panel. Esc (after clearing any search), the hotkey, or (optionally) a click elsewhere
/// closes it; ⌘F focuses search; ⌘, opens settings; arrows, Page Up/Down, Home and End scroll the results.
final class CheatPanel: NSPanel {
    var closesOnResignKey = true
    /// `restoreFocus`: hand focus back to the app that was active before the sheet opened.
    var onDismiss: (@MainActor (_ restoreFocus: Bool) -> Void)?
    var onOpenSettings: (@MainActor () -> Void)?
    weak var searchField: NSSearchField?

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
        let modifiers = event.modifierFlags.intersection([.command, .option, .control, .shift])
        if modifiers == .command, event.charactersIgnoringModifiers == "f", let searchField {
            searchField.selectText(nil)
            return true
        }
        if event.modifierFlags.contains(.command), event.charactersIgnoringModifiers == "," {
            onDismiss?(false)
            onOpenSettings?()
            return true
        }
        return super.performKeyEquivalent(with: event)
    }

    override func sendEvent(_ event: NSEvent) {
        guard event.type == .keyDown, (firstResponder as? NSTextView)?.hasMarkedText() != true else {
            super.sendEvent(event)
            return
        }
        // Escape clears a search first, then closes the panel. The field editor would otherwise
        // swallow it to clear the field without ever closing.
        if event.charactersIgnoringModifiers == "\u{1B}" {
            if !clearSearch() {
                cancelOperation(nil)
            }
            return
        }
        // The search field keeps focus, so take the navigation keys to scroll the results.
        if let direction = ScrollKey(event), let scrollView = resultsScrollView() {
            scroll(scrollView, direction)
            return
        }
        super.sendEvent(event)
    }

    /// Empties the search field. Returns false when there was nothing to clear.
    private func clearSearch() -> Bool {
        guard let searchField else { return false }
        let editor = searchField.currentEditor()
        guard !(editor?.string ?? searchField.stringValue).isEmpty else { return false }
        editor?.string = ""
        searchField.stringValue = ""
        searchField.sendAction(searchField.action, to: searchField.target)
        return true
    }

    private func resultsScrollView() -> NSScrollView? {
        func find(in view: NSView) -> NSScrollView? {
            if let scrollView = view as? NSScrollView, scrollView.documentView != nil {
                return scrollView
            }
            return view.subviews.lazy.compactMap(find(in:)).first
        }
        return contentView.flatMap(find(in:))
    }

    private func scroll(_ scrollView: NSScrollView, _ key: ScrollKey) {
        guard let document = scrollView.documentView else { return }
        let clip = scrollView.contentView
        let visible = clip.bounds.height
        let maxOffset = max(0, document.frame.height - visible)
        // Work in "distance from the top" so flipped and unflipped documents behave the same.
        let fromTop = document.isFlipped ? clip.bounds.minY : maxOffset - clip.bounds.minY
        let target: Double = switch key {
        case .lineUp: fromTop - 40
        case .lineDown: fromTop + 40
        case .pageUp: fromTop - max(40, visible - 40)
        case .pageDown: fromTop + max(40, visible - 40)
        case .top: 0
        case .bottom: maxOffset
        }
        let clamped = min(max(0, target), maxOffset)
        clip.scroll(to: NSPoint(x: clip.bounds.minX, y: document.isFlipped ? clamped : maxOffset - clamped))
        scrollView.reflectScrolledClipView(clip)
    }
}

/// Keys that scroll the results while the search field has focus.
private enum ScrollKey {
    case lineUp, lineDown, pageUp, pageDown, top, bottom

    init?(_ event: NSEvent) {
        let modifiers = event.modifierFlags.intersection([.command, .option, .control, .shift])
        guard modifiers.isEmpty || modifiers == .command else { return nil }
        let toEnd = modifiers == .command
        switch Int(event.keyCode) {
        case 126: self = toEnd ? .top : .lineUp // ↑
        case 125: self = toEnd ? .bottom : .lineDown // ↓
        case 116 where !toEnd: self = .pageUp
        case 121 where !toEnd: self = .pageDown
        case 115 where !toEnd: self = .top // Home
        case 119 where !toEnd: self = .bottom // End
        default: return nil
        }
    }
}
