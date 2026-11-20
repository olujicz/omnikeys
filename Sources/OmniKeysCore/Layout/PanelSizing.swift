import Foundation

/// How the sheet is laid out: `columns` columns, scaled by `scale`, `height` points tall after scaling.
/// When even the smallest readable scale does not fit, the sheet `scrolls`: `height` is the visible part
/// and `contentHeight` the whole sheet.
public struct SheetFit: Equatable, Sendable {
    public let scale: Double
    public let height: Double
    public let columns: Int
    public let contentHeight: Double

    public var scrolls: Bool {
        contentHeight > height
    }

    public init(scale: Double, height: Double, columns: Int, contentHeight: Double? = nil) {
        self.scale = scale
        self.height = height
        self.columns = columns
        self.contentHeight = max(contentHeight ?? height, height)
    }
}

public enum PanelSizing {
    /// "auto": 0.75 on screens at least 45 cm wide, 0.95 on smaller (or unknown) ones.
    public static func widthFraction(_ setting: WidthSetting, physicalWidthMM: Double) -> Double {
        switch setting {
        case .auto: physicalWidthMM >= 450 ? 0.75 : 0.95
        case let .fraction(value): value
        }
    }

    /// Denser screens are smaller and viewed closer: scale text by the square root of the density ratio.
    public static func densityScale(mode: DensityMode, pointsPerInch: Double, reference: Double) -> Double {
        guard mode == .auto, pointsPerInch > 0, reference > 0 else { return 1 }
        return min(max((pointsPerInch / reference).squareRoot(), 0.75), 1.6)
    }

    /// Readable floor for fitting: 85% of the chosen size, and body text (15 pt) no smaller than 12 pt.
    /// Never above `initialScale`, so a deliberately small text size is left alone.
    public static func minimumScale(for initialScale: Double) -> Double {
        min(initialScale, max(initialScale * 0.85, 0.8))
    }

    /// Lays content out at `width / scale` and scales it up; finds the biggest scale up to `initialScale`,
    /// and no smaller than `minimumScale`, at which the content fits `maxHeight`. `fits` is false when
    /// it does not fit even at `minimumScale`.
    /// - Parameter measure: unscaled content height for a given layout width.
    public static func fit(
        width: Double,
        maxHeight: Double,
        initialScale: Double,
        minimumScale: Double = 0,
        measure: (Double) -> Double
    ) -> Fit {
        var scale = initialScale
        var best: (scale: Double, height: Double)?
        var last = (scale: scale, height: 0.0)
        for _ in 0 ..< 6 {
            let height = measure(width / scale) * scale
            last = (scale, height)
            if height <= maxHeight {
                if scale > best?.scale ?? 0 {
                    best = (scale, height)
                }
                if scale >= initialScale || height >= maxHeight * 0.97 {
                    break
                }
                // Growing narrows the layout, so text rewraps and grows taller: step carefully.
                scale = min(initialScale, scale * (maxHeight / height).squareRoot())
            } else {
                if scale <= minimumScale {
                    break
                }
                // Shrinking widens the layout, so the content gets shorter still: this undershoots.
                scale = max(minimumScale, scale * maxHeight / height)
                if let best, scale <= best.scale {
                    break
                }
            }
        }
        if let best {
            return Fit(scale: best.scale, height: best.height, fits: true)
        }
        return Fit(scale: last.scale, height: min(last.height, maxHeight), fits: false)
    }

    /// `fit`'s result: the scale, the scaled height (at most `maxHeight`), and whether the content fits.
    public struct Fit: Equatable, Sendable {
        public let scale: Double
        public let height: Double
        public let fits: Bool
    }

    /// A later (more) column count must give this much bigger text to win: narrower columns wrap more,
    /// which costs more than slightly smaller text.
    static let moreColumnsMinimumGain = 1.06

    /// Runs `fit` for each column count and keeps the one with the biggest text, preferring fewer columns.
    /// When no column count fits at `minimumScale` or above, shrinking further would only make the text
    /// hard to read: the sheet keeps `initialScale` and scrolls, with the shortest of the column counts
    /// that `isReadable` accepts (or the fewest columns if it accepts none).
    /// - Parameters:
    ///   - columnCounts: at least one, fewest first.
    ///   - isReadable: whether columns are wide enough to read at this layout width and column count.
    ///   - measure: unscaled content height for a given layout width and column count.
    public static func bestFit(
        width: Double,
        maxHeight: Double,
        initialScale: Double,
        minimumScale: Double = 0,
        columnCounts: [Int],
        isReadable: (Double, Int) -> Bool = { _, _ in true },
        measure: (Double, Int) -> Double
    ) -> SheetFit {
        precondition(!columnCounts.isEmpty, "bestFit needs at least one column count")
        var best: SheetFit?
        for columns in columnCounts {
            // Scale never exceeds initialScale, so more columns can no longer win.
            if let best, best.scale * moreColumnsMinimumGain >= initialScale {
                break
            }
            let result = fit(width: width, maxHeight: maxHeight, initialScale: initialScale,
                             minimumScale: minimumScale) { measure($0, columns) }
            if result.fits, result.scale > (best?.scale ?? 0) * moreColumnsMinimumGain {
                best = SheetFit(scale: result.scale, height: result.height, columns: columns)
            }
        }
        if let best {
            return best
        }
        let readable = columnCounts.filter { isReadable(width / initialScale, $0) }
        let shortest = (readable.isEmpty ? [columnCounts[0]] : readable)
            .map { (columns: $0, height: measure(width / initialScale, $0) * initialScale) }
            .min { $0.height < $1.height } ?? (columnCounts[0], maxHeight)
        return SheetFit(
            scale: initialScale,
            height: min(shortest.height, maxHeight),
            columns: shortest.columns,
            contentHeight: shortest.height
        )
    }
}
