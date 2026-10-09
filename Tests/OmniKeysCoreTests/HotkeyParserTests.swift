@testable import OmniKeysCore
import Testing

struct HotkeyParserTests {
    let hyper = "Control+Option+Command"

    @Test func expandsHyper() {
        #expect(HotkeyParser.parse("Hyper+Slash", hyper: hyper) == HotkeySpec(
            key: "Slash",
            modifiers: [.control, .option, .command]
        ))
    }

    @Test func combinesHyperWithShift() {
        #expect(HotkeyParser.parse("Hyper+Shift+K", hyper: hyper)?.modifiers == [.control, .option, .command, .shift])
    }

    @Test func plainModifiers() {
        #expect(HotkeyParser.parse("Control+Option+F5", hyper: hyper) == HotkeySpec(
            key: "F5",
            modifiers: [.control, .option]
        ))
    }

    /// Review focus 1: never register a bare key or an unknown key.
    @Test(arguments: ["Slash", "Hyper+Ü", "Hyper+", "", "Super+K", "Hyper+slash"])
    func rejects(_ binding: String) {
        #expect(HotkeyParser.parse(binding, hyper: hyper) == nil)
    }

    @Test func resolveFallsBackWithIssue() {
        let resolved = HotkeyParser.resolve("Slash", hyper: hyper)
        #expect(resolved.spec == HotkeySpec(key: "Slash", modifiers: [.control, .option, .command]))
        #expect(resolved.issue?.message.contains("“Slash”") == true)
    }

    @Test func resolveSurvivesBrokenHyperSetting() {
        #expect(HotkeyParser.resolve("Hyper+Slash", hyper: "CapsLock").spec == .fallback)
    }

    @Test func everyDocumentedKeyIsSupported() {
        for key in ["A", "Z", "0", "9", "F1", "F12", "Slash", "Period", "Comma", "Semicolon", "Quote", "Backslash",
                    "Grave", "Minus", "Equal", "Space", "Return", "Tab", "Escape"]
        {
            #expect(HotkeyParser.supportedKeys.contains(key), "\(key)")
        }
    }

    @Test func invalidHotkeyIssueNamesSetting() {
        #expect(HotkeyParser.resolve("Slash", hyper: "Control+Option+Command").issue?.key == "hotkey")
    }

    @Test func hotkeyFieldsSplitAndJoin() {
        let fields = HotkeyFields("Shift+Hyper+K")
        #expect(fields.modifiers == ["Hyper", "Shift"])
        #expect(fields.key == "K")
        #expect(fields.binding == "Hyper+Shift+K")
        #expect(HotkeyFields(modifiers: ["Command", "Control", "Option"], key: "Slash").binding
            == "Control+Option+Command+Slash")
    }
}
