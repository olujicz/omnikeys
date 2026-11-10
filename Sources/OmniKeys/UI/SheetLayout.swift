import AppKit
import OmniKeysCore
import SwiftUI

/// Picks the column count and scale that give the biggest text within the available space, and balances
/// the columns by measured card heights.
@MainActor
enum SheetLayout {
    struct Result {
        let fit: SheetFit
        let columns: [[SheetCard]]
    }

    static func fit(model: SheetModel, config: Config, width: Double, maxHeight: Double,
                    initialScale: Double) -> Result
    {
        let measurer = SheetMeasurer(model: model, config: config)
        var arranged: [ArrangementKey: [[SheetCard]]] = [:]
        let fit = PanelSizing.bestFit(
            width: width,
            maxHeight: maxHeight,
            initialScale: initialScale,
            columnCounts: ColumnLayout.candidates(configured: config.columns)
        ) { layoutWidth, columns in
            let (height, cards) = measurer.arrange(layoutWidth: layoutWidth, columns: columns)
            arranged[ArrangementKey(layoutWidth: layoutWidth, columns: columns)] = cards
            return height
        }
        let layoutWidth = width / fit.scale
        let columns = arranged[ArrangementKey(layoutWidth: layoutWidth, columns: fit.columns)]
            ?? measurer.arrange(layoutWidth: layoutWidth, columns: fit.columns).columns
        return Result(fit: fit, columns: columns)
    }

    /// The sheet laid out at `width / scale` and scaled up to fill `width` × `fit.height`.
    static func scaledSheet(model: SheetModel, config: Config, width: Double, layout: Result) -> some View {
        CheatSheet(model: model, width: width / layout.fit.scale, columns: layout.columns)
            .environment(\.omniKeysConfig, config)
            .scaleEffect(layout.fit.scale, anchor: .topLeading)
            .frame(width: width, height: layout.fit.height, alignment: .topLeading)
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
    private let host = NSHostingController(rootView: AnyView(EmptyView()))
    private var cardHeights: [Double: [Double]] = [:]

    init(model: SheetModel, config: Config) {
        self.model = model
        self.config = config
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
            of: SheetHeader(hyperGlyphs: model.hyperGlyphs),
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
