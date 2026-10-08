import AppKit
@testable import OmniKeys
import OmniKeysCore
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
    """

    @Test func rendersPNGAtRequestedWidth() throws {
        let state = LoadedState
            .make(configText: "", settingsText: .success(Self.settings), settingsPath: "/fixture") { $0 }
        let data = try #require(SheetRenderer.pngData(model: state.model, config: state.config, width: 1440))
        let image = try #require(NSBitmapImageRep(data: data))
        #expect(image.pixelsWide == 1440)
        #expect(image.pixelsHigh > 200)
    }
}
