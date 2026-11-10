import Foundation

/// How the sheet is laid out: `columns` columns, scaled by `scale`, `height` points tall after scaling.
public struct SheetFit: Equatable, Sendable {
    public let scale: Double
    public let height: Double
    public let columns: Int

    public init(scale: Double, height: Double, columns: Int) {
        self.scale = scale
        self.height = height
        self.columns = columns
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

    /// Lays content out at `width / scale` and scales it up; finds the biggest scale up to `initialScale`
    /// at which the content fits `maxHeight`.
    /// - Parameter measure: unscaled content height for a given layout width.
    public static func fit(
        width: Double,
        maxHeight: Double,
        initialScale: Double,
        measure: (Double) -> Double
    ) -> (scale: Double, height: Double) {
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
                // Shrinking widens the layout, so the content gets shorter still: this undershoots.
                scale *= maxHeight / height
                if let best, scale <= best.scale {
                    break
                }
            }
        }
        return best ?? (last.scale, min(last.height, maxHeight))
    }

    /// A later (more) column count must give this much bigger text to win: narrower columns wrap more,
    /// which costs more than slightly smaller text.
    static let moreColumnsMinimumGain = 1.06

    /// Runs `fit` for each column count and keeps the one with the biggest text, preferring fewer columns.
    /// - Parameters:
    ///   - columnCounts: at least one.
    ///   - measure: unscaled content height for a given layout width and column count.
    public static func bestFit(
        width: Double,
        maxHeight: Double,
        initialScale: Double,
        columnCounts: [Int],
        measure: (Double, Int) -> Double
    ) -> SheetFit {
        precondition(!columnCounts.isEmpty, "bestFit needs at least one column count")
        var best = SheetFit(scale: 0, height: 0, columns: columnCounts[0])
        for columns in columnCounts {
            // Scale never exceeds initialScale, so more columns can no longer win.
            if best.scale * moreColumnsMinimumGain >= initialScale {
                break
            }
            let result = fit(width: width, maxHeight: maxHeight, initialScale: initialScale) { measure($0, columns) }
            if result.scale > best.scale * moreColumnsMinimumGain {
                best = SheetFit(scale: result.scale, height: result.height, columns: columns)
            }
        }
        return best
    }
}
