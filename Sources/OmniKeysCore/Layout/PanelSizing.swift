import Foundation

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

    /// Lays content out at `width / scale` and scales it up; shrinks the scale until it fits `maxHeight`.
    /// - Parameter measure: unscaled content height for a given layout width.
    public static func fit(
        width: Double,
        maxHeight: Double,
        initialScale: Double,
        measure: (Double) -> Double
    ) -> (scale: Double, height: Double) {
        var scale = initialScale
        var height = measure(width / scale) * scale
        for _ in 0 ..< 5 where height > maxHeight {
            scale *= maxHeight / height
            height = measure(width / scale) * scale
        }
        return (scale, min(height, maxHeight))
    }
}
