import Foundation

/// Command-line options for `--render`, used by `make render` and to check the design without a screenshot.
struct RenderOptions {
    let output: URL
    let configFile: URL?
    let settingsFile: URL?
    let width: Double
    /// Maximum sheet height; the sheet shrinks to fit, as on a screen.
    let height: Double
    /// Text scale before shrinking to fit (textSize × density scale on a real screen).
    let scale: Double

    init?(arguments: [String]) {
        func value(after flag: String) -> String? {
            guard let index = arguments.firstIndex(of: flag), index + 1 < arguments.count else { return nil }
            return arguments[index + 1]
        }
        guard let output = value(after: "--render") else { return nil }
        self.output = URL(fileURLWithPath: output)
        configFile = value(after: "--config").map { URL(fileURLWithPath: $0) }
        settingsFile = value(after: "--settings").map { URL(fileURLWithPath: $0) }
        width = value(after: "--width").flatMap(Double.init) ?? 1440
        height = value(after: "--height").flatMap(Double.init) ?? 900
        scale = value(after: "--scale").flatMap(Double.init) ?? 1
    }
}
