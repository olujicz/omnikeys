import AppKit
import OmniKeysCore
import SwiftUI

/// Picks the column count and scale that give the biggest text within the available space, and balances
/// the columns by measured card heights. Text shrinks no further than `PanelSizing.minimumScale`;
/// past that the sheet keeps its size and scrolls.
@MainActor
enum SheetLayout {
    /// When the sheet has to scroll anyway, narrower columns than this (unscaled) would only add wrapping.
    static let minimumColumnWidth = 340.0

    struct Result {
        let fit: SheetFit
        let columns: [[SheetCard]]
    }

    /// - Parameter searchable: lay out the live panel's header, which has a ⌘F hint.
    static func fit(model: SheetModel, config: Config, width: Double, maxHeight: Double,
                    initialScale: Double, searchable: Bool = false) -> Result
    {
        let measurer = SheetMeasurer(model: model, config: config, searchable: searchable)
        var arranged: [ArrangementKey: [[SheetCard]]] = [:]
        let fit = PanelSizing.bestFit(
            width: width,
            maxHeight: maxHeight,
            initialScale: initialScale,
            minimumScale: PanelSizing.minimumScale(for: initialScale),
            columnCounts: ColumnLayout.candidates(configured: config.columns),
            isReadable: { layoutWidth, columns in
                CheatSheet.Metrics.columnWidth(layoutWidth: layoutWidth, columns: columns) >= minimumColumnWidth
            },
            measure: { layoutWidth, columns in
                let (height, cards) = measurer.arrange(layoutWidth: layoutWidth, columns: columns)
                arranged[ArrangementKey(layoutWidth: layoutWidth, columns: columns)] = cards
                return height
            }
        )
        let layoutWidth = width / fit.scale
        let columns = arranged[ArrangementKey(layoutWidth: layoutWidth, columns: fit.columns)]
            ?? measurer.arrange(layoutWidth: layoutWidth, columns: fit.columns).columns
        return Result(fit: fit, columns: columns)
    }

    /// The whole sheet laid out at `width / scale` and scaled up to fill `width`, for `--render`.
    static func scaledSheet(model: SheetModel, config: Config, width: Double, layout: Result) -> some View {
        CheatSheet(model: model, width: width / layout.fit.scale, columns: layout.columns)
            .environment(\.omniKeysConfig, config)
            .scaleEffect(layout.fit.scale, anchor: .topLeading)
            .frame(width: width, height: layout.fit.contentHeight, alignment: .topLeading)
    }
}

private struct ArrangementKey: Hashable {
    let layoutWidth: Double
    let columns: Int
}

/// Measures header and cards with one reused hosting controller, and adds them up like CheatSheet does.
@MainActor
final class SheetMeasurer {
    private typealias Metrics = CheatSheet.Metrics
    private let model: SheetModel
    private let config: Config
    private let cards: [SheetCard]
    private let searchable: Bool
    private let host = NSHostingController(rootView: AnyView(EmptyView()))
    private var cardHeights: [Double: [Double]] = [:]

    init(model: SheetModel, config: Config, searchable: Bool = false) {
        self.model = model
        self.config = config
        self.searchable = searchable
        cards = SheetCard.cards(for: model)
    }

    /// Unscaled sheet height and the cards per column, at this layout width and column count.
    func arrange(layoutWidth: Double, columns requested: Int) -> (height: Double, columns: [[SheetCard]]) {
        let columns = max(1, min(requested, cards.count))
        let columnWidth = Metrics.columnWidth(layoutWidth: layoutWidth, columns: columns)
        let heights = heights(columnWidth: columnWidth)
        let indices = ColumnLayout.flow(Array(cards.indices), columns: columns) { heights[$0] }
        let tallest = indices.map { column -> Double in
            let cards: Double = column.map { heights[$0] }.reduce(0, +)
            return cards + Metrics.cardSpacing * Double(column.count - 1)
        }.max() ?? 0
        let header = height(
            of: SheetHeader(hyperGlyphs: model.hyperGlyphs, showsSearchHint: searchable),
            width: layoutWidth - 2 * Metrics.padding
        )
        let total = 2 * Metrics.padding + header + (cards.isEmpty ? 0 : Metrics.headerSpacing + tallest)
        return (total, indices.map { $0.map { cards[$0] } })
    }

    private func heights(columnWidth: Double) -> [Double] {
        if let cached = cardHeights[columnWidth] {
            return cached
        }
        let heights = cards.map { height(of: CheatSheet.card($0, model: model), width: columnWidth) }
        cardHeights[columnWidth] = heights
        return heights
    }

    private func height(of view: some View, width: Double) -> Double {
        host.rootView = AnyView(view.environment(\.omniKeysConfig, config))
        return host.sizeThatFits(in: NSSize(width: width, height: 100_000)).height
    }
}
