@testable import OmniKeysCore
import Testing

struct PanelSizingTests {
    @Test func autoWidthDependsOnPhysicalSize() {
        #expect(PanelSizing.widthFraction(.auto, physicalWidthMM: 600) == 0.75)
        #expect(PanelSizing.widthFraction(.auto, physicalWidthMM: 300) == 0.95)
        #expect(PanelSizing.widthFraction(.auto, physicalWidthMM: 0) == 0.95)
        #expect(PanelSizing.widthFraction(.fraction(0.5), physicalWidthMM: 600) == 0.5)
    }

    @Test func densityScale() {
        #expect(PanelSizing.densityScale(mode: .off, pointsPerInch: 200, reference: 85) == 1)
        #expect(PanelSizing.densityScale(mode: .auto, pointsPerInch: 0, reference: 85) == 1)
        #expect(PanelSizing.densityScale(mode: .auto, pointsPerInch: 85, reference: 85) == 1)
        #expect(abs(PanelSizing.densityScale(mode: .auto, pointsPerInch: 127, reference: 85) - 1.2223) < 0.001)
        #expect(PanelSizing.densityScale(mode: .auto, pointsPerInch: 1000, reference: 85) == 1.6)
        #expect(PanelSizing.densityScale(mode: .auto, pointsPerInch: 10, reference: 85) == 0.75)
    }

    @Test func fitKeepsScaleWhenContentFits() {
        let fit = PanelSizing.fit(width: 1000, maxHeight: 2000, initialScale: 1) { _ in 500 }
        #expect(fit.scale == 1)
        #expect(fit.height == 500)
    }

    @Test func fitShrinksUntilItFits() {
        let fit = PanelSizing.fit(width: 1000, maxHeight: 250, initialScale: 1) { _ in 500 }
        #expect(fit.scale == 0.5)
        #expect(fit.height == 250)
    }

    @Test func fitAccountsForRewrapping() {
        // Constant area: narrower layout -> taller content. Height = 500 * scale².
        let fit = PanelSizing.fit(width: 1000, maxHeight: 250, initialScale: 1) { layoutWidth in 500_000 / layoutWidth }
        #expect(abs(fit.scale - 0.5.squareRoot()) < 0.001)
        #expect(fit.height <= 250)
        #expect(fit.height > 240)
    }

    @Test func fitNeverGrowsPastInitialScale() {
        let fit = PanelSizing.fit(width: 1000, maxHeight: 2000, initialScale: 1.5) { _ in 500 }
        #expect(fit.scale == 1.5)
        #expect(fit.height == 750)
    }

    @Test func fitNeverExceedsMaxHeight() {
        let fit = PanelSizing.fit(width: 1000, maxHeight: 300, initialScale: 1) { _ in 1_000_000_000 }
        #expect(fit.height == 300)
    }

    @Test func bestFitPicksColumnCountWithBiggestText() {
        // Area-constant content: more columns make it shorter, until columns get too narrow.
        let heights = [2: 1600.0, 3: 1200, 4: 1300]
        let fit = PanelSizing.bestFit(width: 1000, maxHeight: 600, initialScale: 1, columnCounts: [
            2,
            3,
            4,
        ]) { _, columns in
            heights[columns] ?? 0
        }
        #expect(fit.columns == 3)
        #expect(fit.scale == 0.5)
    }

    @Test func bestFitPrefersFewerColumnsOnATie() {
        let fit = PanelSizing
            .bestFit(width: 1000, maxHeight: 2000, initialScale: 1, columnCounts: [2, 3, 4]) { _, _ in 500 }
        #expect(fit.columns == 2)
        #expect(fit.scale == 1)
    }
}
