import AppKit
@testable import OmniKeys
import OmniKeysCore
import Testing

@MainActor
struct PanelSearchTests {
    @Test func tallShortcutListScrollsBelowSearch() throws {
        let screen = try #require(NSScreen.main)
        let presenter = PanelPresenter()
        defer { presenter.dismiss(restoreFocus: true) }
        var config = Config()
        config.maxHeight = 0.3
        config.textSize = 2
        let rows = (1 ... 50).map { ShortcutRow(keys: "Hyper ⇧ K", action: "Shortcut \($0)") }
        let model = SheetModel(
            groups: [ShortcutGroup(title: "Tools", rows: rows)],
            workspaces: [],
            floating: [],
            hyperGlyphs: "⌘⇧"
        )
        presenter.present(model: model, config: config, on: screen)

        let panel = try #require(NSApp.windows.compactMap { $0 as? CheatPanel }.first { $0.isVisible })
        let content = try #require(panel.contentView)
        let search = try #require(panel.searchField)
        let scroll = try #require(findScrollView(in: content))
        let document = try #require(scroll.documentView)
        #expect(abs(panel.frame.height - screen.visibleFrame.height * config.maxHeight) <= 1)
        #expect(document.frame.height > scroll.contentView.bounds.height)
        #expect(!search.isDescendant(of: scroll))

        // Navigation keys scroll the results while the search field keeps focus.
        let editor = try #require(search.currentEditor())
        let top = distanceFromTop(scroll)
        try panel.sendEvent(keyEvent("", keyCode: 121, in: panel)) // Page Down
        let paged = distanceFromTop(scroll)
        #expect(paged > top)
        try panel.sendEvent(keyEvent("", keyCode: 125, in: panel)) // ↓
        #expect(distanceFromTop(scroll) > paged)
        try panel.sendEvent(keyEvent("", keyCode: 115, in: panel)) // Home
        #expect(distanceFromTop(scroll) == top)
        try panel.sendEvent(keyEvent("", keyCode: 125, modifiers: [.command], in: panel)) // ⌘↓
        let maxOffset = document.frame.height - scroll.contentView.bounds.height
        #expect(abs(distanceFromTop(scroll) - maxOffset) <= 1)
        #expect(panel.firstResponder === editor)
    }

    private func distanceFromTop(_ scroll: NSScrollView) -> Double {
        let clip = scroll.contentView
        guard let document = scroll.documentView else { return 0 }
        let maxOffset = document.frame.height - clip.bounds.height
        return document.isFlipped ? clip.bounds.minY : maxOffset - clip.bounds.minY
    }

    private func findScrollView(in view: NSView) -> NSScrollView? {
        (view as? NSScrollView) ?? view.subviews.lazy.compactMap { findScrollView(in: $0) }.first
    }

    @Test func searchReceivesKeyboardInputAndEscapeClearsThenCloses() throws {
        let screen = try #require(NSScreen.main)
        let presenter = PanelPresenter()
        defer { presenter.dismiss(restoreFocus: true) }
        let model = SheetModel.make(config: Config(), settings: OmniWMSettings())
        presenter.present(model: model, config: Config(), on: screen)

        let panel = try #require(NSApp.windows.compactMap { $0 as? CheatPanel }.first { $0.isVisible })
        let search = try #require(panel.searchField)
        let editor = try #require(search.currentEditor())
        #expect(panel.firstResponder === editor)

        try panel.sendEvent(keyEvent("q", keyCode: 12, in: panel))
        #expect(editor.string == "q")

        presenter.present(model: model, config: Config(), on: screen)
        let reloadedSearch = try #require(panel.searchField)
        #expect(reloadedSearch.stringValue == "q")
        // A redraw keeps the caret after the query instead of selecting it.
        let reloadedEditor = try #require(reloadedSearch.currentEditor() as? NSTextView)
        #expect(reloadedEditor.selectedRange() == NSRange(location: 1, length: 0))

        panel.makeFirstResponder(nil)
        let find = try keyEvent("f", keyCode: 3, modifiers: [.command], in: panel)
        #expect(panel.performKeyEquivalent(with: find))
        #expect(panel.firstResponder === reloadedSearch.currentEditor())

        // The first Escape clears the search; the second closes the panel.
        try panel.sendEvent(keyEvent("\u{1B}", keyCode: 53, in: panel))
        #expect(presenter.isVisible)
        #expect(reloadedSearch.currentEditor()?.string == "")
        #expect(reloadedSearch.stringValue == "")
        try panel.sendEvent(keyEvent("\u{1B}", keyCode: 53, in: panel))
        #expect(!presenter.isVisible)

        presenter.present(model: model, config: Config(), on: screen)
        #expect(panel.searchField?.stringValue == "")
    }

    private func keyEvent(
        _ characters: String,
        keyCode: UInt16,
        modifiers: NSEvent.ModifierFlags = [],
        in panel: CheatPanel
    ) throws -> NSEvent {
        try #require(NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: modifiers,
            timestamp: 0,
            windowNumber: panel.windowNumber,
            context: nil,
            characters: characters,
            charactersIgnoringModifiers: characters,
            isARepeat: false,
            keyCode: keyCode
        ))
    }
}
