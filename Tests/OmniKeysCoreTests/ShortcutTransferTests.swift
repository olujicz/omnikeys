@testable import OmniKeysCore
import Foundation
import Testing

struct ShortcutTransferTests {
    private let settings = OmniWMSettings(
        hotkeys: [
            OmniWMHotkey(id: "toggleScratchpad.1", binding: "Hyper+S"),
            OmniWMHotkey(id: "focus.left", binding: "Hyper+H"),
        ],
        hyperModifiers: "Control+Option+Command"
    )

    @Test func exportsAndImportsAssignedShortcuts() throws {
        let data = try ShortcutTransfer.export(settings: settings)
        let imported = try ShortcutTransfer.import(data: data)

        #expect(imported.hotkeys == settings.hotkeys.map { ShortcutTransferHotkey(id: $0.id, binding: $0.binding) })
        #expect(imported.hyperKeyModifiers == settings.hyperModifiers)
    }

    @Test func rejectsUnsupportedVersionAndDuplicateActions() throws {
        let unsupported = Data("{\"formatVersion\":2,\"hyperKeyModifiers\":\"Control\",\"hotkeys\":[]}".utf8)
        #expect(throws: ShortcutTransferError.unsupportedVersion(2)) {
            try ShortcutTransfer.import(data: unsupported)
        }

        let duplicate = Data("{\"formatVersion\":1,\"hyperKeyModifiers\":\"Control\",\"hotkeys\":[{\"id\":\"x\",\"binding\":\"Hyper+X\"},{\"id\":\"x\",\"binding\":\"Hyper+Y\"}]}".utf8)
        #expect(throws: ShortcutTransferError.duplicateAction("x")) {
            try ShortcutTransfer.import(data: duplicate)
        }
    }

    @Test func appliesBindingsWithoutChangingOtherOmniWMSettings() throws {
        let original = """
        [general]
        animationsEnabled = true
        hyperKeyModifiers = "Control+Option+Command"

        [[hotkeys]]
        binding = "Hyper+S"
        id = "toggleScratchpad.1"

        [[hotkeys]]
        binding = "Hyper+H"
        id = "focus.left"

        [borders]
        width = 4.0
        """
        let document = ShortcutTransferDocument(
            hyperKeyModifiers: "Control+Option+Shift",
            hotkeys: [
                ShortcutTransferHotkey(id: "toggleScratchpad.1", binding: "Hyper+T"),
                ShortcutTransferHotkey(id: "focus.left", binding: "Hyper+J"),
            ]
        )

        let updated = try ShortcutTransfer.apply(document, to: original)

        #expect(updated.contains("animationsEnabled = true"))
        #expect(updated.contains("width = 4.0"))
        #expect(updated.contains("hyperKeyModifiers = \"Control+Option+Shift\""))
        #expect(updated.contains("binding = \"Hyper+T\""))
        #expect(updated.contains("binding = \"Hyper+J\""))
        #expect(!updated.contains("binding = \"Hyper+S\""))
        #expect(!updated.contains("binding = \"Hyper+H\""))
    }

    @Test func rejectsActionMissingFromDestinationBeforeWriting() throws {
        let document = ShortcutTransferDocument(
            hyperKeyModifiers: "Control",
            hotkeys: [ShortcutTransferHotkey(id: "missing.action", binding: "Hyper+M")]
        )

        #expect(throws: ShortcutTransferError.actionNotFound("missing.action")) {
            try ShortcutTransfer.apply(document, to: "[[hotkeys]]\nid = \"existing.action\"\nbinding = \"Hyper+E\"\n")
        }
    }
}
