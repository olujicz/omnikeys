import AppKit
import OmniKeysCore
import SwiftUI

/// One card on the sheet.
enum SheetCard: Identifiable {
    case shortcuts(title: String, entries: [SheetEntry])
    case workspaces

    var id: String {
        switch self {
        case let .shortcuts(title, _): "shortcuts-\(title)"
        case .workspaces: "workspaces"
        }
    }

    /// Cards in reading order; the workspace list follows the workspace shortcuts.
    static func cards(for model: SheetModel) -> [SheetCard] {
        var cards = model.groups.map { SheetCard.shortcuts(title: $0.title, entries: SheetEntry.make($0.rows)) }
        if !model.workspaces.isEmpty || !model.floating.isEmpty {
            let after = model.groups.firstIndex { $0.title == ActionCatalog.Group.workspaces }
            cards.insert(.workspaces, at: after.map { $0 + 1 } ?? cards.endIndex)
        }
        return cards
    }
}

struct CheatSheet: View {
    /// Spacing, shared with SheetLayout, which adds up measured card heights the same way.
    enum Metrics {
        static let padding = 22.0
        static let headerSpacing = 14.0
        static let columnSpacing = 12.0
        static let cardSpacing = 12.0

        static func columnWidth(layoutWidth: Double, columns: Int) -> Double {
            (layoutWidth - 2 * padding - columnSpacing * Double(columns - 1)) / Double(columns)
        }
    }

    let model: SheetModel
    let width: Double
    let columns: [[SheetCard]]
    @Environment(\.omniKeysConfig) private var config

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.headerSpacing) {
            SheetHeader(hyperGlyphs: model.hyperGlyphs)
            SheetColumns(model: model, columns: columns)
        }
        .padding(Metrics.padding)
        .frame(width: width)
        .background(config.backgroundColor)
        .environment(\.colorScheme, config.colorScheme ?? Self.systemColorScheme)
    }

    @ViewBuilder
    static func card(_ card: SheetCard, model: SheetModel) -> some View {
        switch card {
        case let .shortcuts(title, entries): ShortcutCard(title: title, entries: entries)
        case .workspaces: WorkspacesCard(workspaces: model.workspaces, floating: model.floating)
        }
    }

    static var systemColorScheme: ColorScheme {
        NSApplication.shared.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? .dark : .light
    }
}

/// Cards in columns, as SheetLayout arranged them.
struct SheetColumns: View {
    typealias Metrics = CheatSheet.Metrics
    let model: SheetModel
    let columns: [[SheetCard]]

    var body: some View {
        HStack(alignment: .top, spacing: Metrics.columnSpacing) {
            ForEach(Array(columns.enumerated()), id: \.offset) { _, column in
                VStack(spacing: Metrics.cardSpacing) {
                    ForEach(column) { CheatSheet.card($0, model: model) }
                }
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
    }
}

struct SheetHeader: View {
    let hyperGlyphs: String
    /// The live panel has a search field; the rendered image does not.
    var showsSearchHint = false

    var body: some View {
        HStack(alignment: .center, spacing: 18) {
            Text("OmniWM").font(.system(size: 22, weight: .bold))
            HStack(spacing: 6) {
                KeyHint(keys: "Hyper", label: "Hyper is")
                KeyChips(text: hyperGlyphs.map(String.init).joined(separator: " "))
            }
            Spacer()
            if showsSearchHint {
                KeyHint(keys: "⌘ F", label: "search")
            }
            KeyHint(keys: "esc", label: "close")
            KeyHint(keys: "⌘ ,", label: "settings")
        }
    }
}
