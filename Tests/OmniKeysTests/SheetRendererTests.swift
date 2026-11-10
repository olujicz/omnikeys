import AppKit
@testable import OmniKeys
import OmniKeysCore
import SwiftUI
import Testing

@MainActor
struct SheetRendererTests {
    static let settings = """
    [[hotkeys]]
    binding = "Hyper+H"
    id = "focus.left"

    [[hotkeys]]
    binding = "Hyper+Shift+H"
    id = "move.left"

    [[hotkeys]]
    binding = "Hyper+Q"
    id = "closeFocusedWindow"

    [[hotkeys]]
    binding = "Hyper+W"
    id = "openCommandPalette.windows"

    [[hotkeys]]
    binding = "Hyper+X"
    id = "openCommandPalette.commands"

    [[hotkeys]]
    binding = "Hyper+R"
    id = "cycleSizeForward"

    [[hotkeys]]
    binding = "Hyper+Shift+R"
    id = "cycleSizeBackward"
    """

    @Test func rendersPNGAtRequestedWidth() throws {
        let state = LoadedState
            .make(configText: "", settingsText: .success(Self.settings), settingsPath: "/fixture") { $0 }
        let data = try #require(SheetRenderer.pngData(
            model: state.model,
            config: state.config,
            width: 1440,
            maxHeight: 900
        ))
        let image = try #require(NSBitmapImageRep(data: data))
        #expect(image.pixelsWide == 1440)
        #expect(image.pixelsHigh > 200)
    }

    /// SheetLayout adds measured card heights up; that must match laying out the whole sheet.
    @Test func measuredHeightMatchesWholeSheet() {
        let state = LoadedState
            .make(configText: "", settingsText: .success(Self.settings), settingsPath: "/fixture") { $0 }
        let measurer = SheetMeasurer(model: state.model, config: state.config)
        for columns in 1 ... 3 {
            let arranged = measurer.arrange(layoutWidth: 1100, columns: columns)
            let sheet = CheatSheet(model: state.model, width: 1100, columns: arranged.columns)
                .environment(\.omniKeysConfig, state.config)
            let actual = NSHostingController(rootView: sheet).sizeThatFits(in: NSSize(width: 1100, height: 100_000))
            #expect(abs(actual.height - arranged.height) < 1, "\(columns) columns")
        }
    }
}
