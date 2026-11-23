import Foundation
@testable import OmniKeysCore
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

        let duplicate = Data("""
        {"formatVersion":1,"hyperKeyModifiers":"Control","hotkeys":[\
        {"id":"x","binding":"Hyper+X"},{"id":"x","binding":"Hyper+Y"}]}
        """.utf8)
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

    @Test func exportCarriesUnassignedActionsSoImportClearsThem() throws {
        let source = try OmniWMSettings.parse(
            "[[hotkeys]]\nid = \"focus.left\"\nbinding = \"Unassigned\"\n",
            appName: { $0 }
        )
        let document = try ShortcutTransfer.import(data: ShortcutTransfer.export(settings: source))
        let updated = try ShortcutTransfer.apply(
            document,
            to: "[[hotkeys]]\nid = \"focus.left\"\nbinding = \"Hyper+H\"\n"
        )
        #expect(updated.contains("binding = \"Unassigned\""))
        #expect(!updated.contains("Hyper+H"))
    }

    @Test func appliesToCRLFFilesAndLinesWithComments() throws {
        let original = "[general]\r\nhyperKeyModifiers=\"Control\"\r\n\r\n[[hotkeys]]\r\nid = \"focus.left\"\r\n"
            + "binding = \"Hyper+H\"  # mine\r\n"
        let document = ShortcutTransferDocument(
            hyperKeyModifiers: "Option",
            hotkeys: [ShortcutTransferHotkey(id: "focus.left", binding: "Hyper+J")]
        )
        let updated = try ShortcutTransfer.apply(document, to: original)
        #expect(updated == "[general]\r\nhyperKeyModifiers=\"Option\"\r\n\r\n[[hotkeys]]\r\nid = \"focus.left\"\r\n"
            + "binding = \"Hyper+J\"  # mine\r\n")
    }

    @Test func addsGeneralTableWithoutCapturingRootKeys() throws {
        let original = "rootKey = 1\n\n[[hotkeys]]\nid = \"focus.left\"\nbinding = \"Hyper+H\"\n"
        let document = ShortcutTransferDocument(hyperKeyModifiers: "Option", hotkeys: [])
        let updated = try ShortcutTransfer.apply(document, to: original)
        #expect(updated.hasPrefix("rootKey = 1\n"))
        #expect(try OmniWMSettings.parse(updated, appName: { $0 }).hyperModifiers == "Option")
    }
}
