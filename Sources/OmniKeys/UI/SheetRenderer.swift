import AppKit
import OmniKeysCore
import SwiftUI

/// Headless rendering for `--render` and tests.
@MainActor
enum SheetRenderer {
    static func render(_ options: RenderOptions) -> Bool {
        let state = ConfigStore(paths: .current).load(
            configFile: options.configFile,
            settingsFile: options.settingsFile,
            includeMissingApps: true
        )
        guard let data = pngData(
            model: state.model,
            config: state.config,
            width: options.width,
            maxHeight: options.height,
            initialScale: options.scale
        ) else { return false }
        do {
            try data.write(to: options.output)
            return true
        } catch {
            FileHandle.standardError
                .write(Data("Could not write \(options.output.path): \(error.localizedDescription)\n".utf8))
            return false
        }
    }

    static func pngData(model: SheetModel, config: Config, width: Double, maxHeight: Double,
                        initialScale: Double = 1) -> Data?
    {
        let layout = SheetLayout.fit(
            model: model,
            config: config,
            width: width,
            maxHeight: maxHeight,
            initialScale: initialScale
        )
        let content = SheetLayout.scaledSheet(model: model, config: config, width: width, layout: layout)
            .background(Color(white: 0.17))
        let renderer = ImageRenderer(content: content)
        renderer.scale = 1
        guard let image = renderer.nsImage, let tiff = image.tiffRepresentation else { return nil }
        return NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:])
    }
}
