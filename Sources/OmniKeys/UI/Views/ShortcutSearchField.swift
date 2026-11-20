import AppKit
import SwiftUI

/// The sheet's search field. It registers itself with the panel, which focuses it and handles Esc and ⌘F.
struct ShortcutSearchField: NSViewRepresentable {
    @SwiftUI.Binding var query: String

    func makeNSView(context: Context) -> PanelSearchField {
        let field = PanelSearchField()
        field.placeholderString = "Search shortcuts"
        field.setAccessibilityLabel("Search shortcuts")
        field.sendsSearchStringImmediately = true
        field.target = context.coordinator
        field.action = #selector(Coordinator.updateQuery(_:))
        return field
    }

    func updateNSView(_ field: PanelSearchField, context: Context) {
        context.coordinator.query = $query
        if field.stringValue != query {
            field.stringValue = query
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(query: $query)
    }

    @MainActor
    final class Coordinator: NSObject {
        var query: SwiftUI.Binding<String>

        init(query: SwiftUI.Binding<String>) {
            self.query = query
        }

        @objc func updateQuery(_ field: NSSearchField) {
            query.wrappedValue = field.stringValue
        }
    }
}

final class PanelSearchField: NSSearchField {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        (window as? CheatPanel)?.searchField = self
    }
}
