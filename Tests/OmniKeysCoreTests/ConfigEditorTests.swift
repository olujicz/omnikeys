@testable import OmniKeysCore
import Testing

struct ConfigEditorTests {
    @Test func replacesValueKeepingTrailingComment() {
        let text = "a = 1\nb = 2   # note\n"
        #expect(ConfigEditor.setting("b", to: .integer(3), in: text) == "a = 1\nb = 3   # note\n")
    }

    @Test func changesOnlyOneLineOfTheTemplate() {
        let result = ConfigEditor.setting("textSize", to: .number(1.2), in: DefaultConfig.template)
        let before = DefaultConfig.template.components(separatedBy: "\n")
        let after = result.components(separatedBy: "\n")
        #expect(before.count == after.count)
        #expect(zip(before, after).filter { $0 != $1 }.map(\.1) == ["textSize = 1.2"])
        #expect(ConfigLoader.load(result).config.textSize == 1.2)
    }

    @Test func ignoresCommentedOutAssignments() {
        let text = "# hotkey = \"Hyper+K\"\nhotkey = \"Hyper+Slash\""
        #expect(ConfigEditor.setting("hotkey", to: .string("Hyper+J"), in: text)
            == "# hotkey = \"Hyper+K\"\nhotkey = \"Hyper+J\"")
    }

    @Test func insertsMissingKeyAfterLastTopLevelSetting() {
        let text = "theme = \"dark\"\n\n[labels]\nfoo = \"Bar\"\n"
        #expect(ConfigEditor.setting("textSize", to: .number(1.5), in: text)
            == "theme = \"dark\"\ntextSize = 1.5\n\n[labels]\nfoo = \"Bar\"\n")
    }

    @Test func insertsIntoEmptyFile() {
        #expect(ConfigEditor.setting("columns", to: .integer(2), in: "") == "columns = 2\n")
    }

    @Test func neverEditsKeysInsideTables() {
        let text = "[labels]\ntheme = \"x\"\n"
        #expect(ConfigEditor.setting("theme", to: .string("light"), in: text)
            == "theme = \"light\"\n[labels]\ntheme = \"x\"\n")
    }

    /// Review focus 5.
    @Test func replacesMultiLineArrayWithComments() {
        let text = "hide = [\n  \"a\", # first\n  \"b\",\n]  # done\ntheme = \"dark\""
        let result = ConfigEditor.setting("hide", to: .strings(["c"]), in: text)
        #expect(result == "hide = [\"c\"]  # done\ntheme = \"dark\"")
        #expect(ConfigLoader.load(result).config.hide == ["c"])
    }

    @Test func escapesStrings() {
        let result = ConfigEditor.setting("hotkey", to: .string("a\"b\\c"), in: "")
        #expect(ConfigLoader.load(result).config.hotkey == "a\"b\\c")
    }

    @Test func formatsNumbers() {
        #expect(TOMLValue.number(1).source == "1.0")
        #expect(TOMLValue.number(0.45).source == "0.45")
        #expect(TOMLValue.number(0.3).source == "0.3")
        #expect(TOMLValue.number(1.25).source == "1.25")
        #expect(TOMLValue.strings([]).source == "[]")
        #expect(TOMLValue.strings(["a", "b"]).source == "[\"a\", \"b\"]")
    }

    @Test func addsLabelBelowHeaderKeepingCommentedExamples() {
        let result = ConfigEditor.label("toggleQuakeTerminal", to: "Drop", in: DefaultConfig.template)
        #expect(result
            .contains("[labels]\ntoggleQuakeTerminal = \"Drop\"\n# toggleQuakeTerminal = \"Drop-down terminal\""))
        #expect(ConfigLoader.load(result).config.labels == ["toggleQuakeTerminal": "Drop"])
    }

    @Test func changesExistingDottedLabel() {
        let text = "[labels]\nswitchWorkspace.next = \"A\"\n"
        #expect(ConfigEditor.label("switchWorkspace.next", to: "B", in: text)
            == "[labels]\nswitchWorkspace.next = \"B\"\n")
    }

    @Test func removesLabel() {
        let text = "[labels]\nfocus = \"F\"\nmove = \"M\"\n"
        #expect(ConfigEditor.label("focus", to: nil, in: text) == "[labels]\nmove = \"M\"\n")
    }

    @Test func addsLabelsTableWhenMissing() {
        #expect(ConfigEditor.label("focus", to: "F", in: "theme = \"dark\"\n")
            == "theme = \"dark\"\n\n[labels]\nfocus = \"F\"\n")
        #expect(ConfigEditor.label("focus", to: nil, in: "theme = \"dark\"\n") == "theme = \"dark\"\n")
    }

    /// Review focus 4.
    @Test func labelsRoundTripAwkwardText() {
        var text = DefaultConfig.template
        text = ConfigEditor.label("switchWorkspace.next", to: "Next → \"ws\" \\ 🚀", in: text)
        text = ConfigEditor.label("focus", to: "Focus", in: text)
        #expect(ConfigLoader.load(text).config.labels == [
            "switchWorkspace.next": "Next → \"ws\" \\ 🚀",
            "focus": "Focus",
        ])
        #expect(ConfigLoader.load(text).issues.isEmpty)
    }

    @Test func labelForSeriesQuotesHandWrittenDottedKeysUnderIt() {
        let text = "[labels]\nswitchWorkspace.next = \"N\"   # mine\n"
        let result = ConfigEditor.label("switchWorkspace", to: "Go", in: text)
        #expect(result == "[labels]\n\"switchWorkspace.next\" = \"N\"   # mine\nswitchWorkspace = \"Go\"\n")
        #expect(ConfigLoader.load(result).issues.isEmpty)
        #expect(ConfigLoader.load(result).config.labels == ["switchWorkspace.next": "N", "switchWorkspace": "Go"])
    }

    @Test func labelForSeriesMovesNestedLabelTableIntoLabels() {
        let text = "[labels]\nfocus = \"F\"\n\n[labels.switchWorkspace]\nnext = \"N\"\n"
        let result = ConfigEditor.label("switchWorkspace", to: "Go", in: text)
        #expect(ConfigLoader.load(result).issues.isEmpty)
        #expect(ConfigLoader.load(result).config.labels == [
            "focus": "F", "switchWorkspace.next": "N", "switchWorkspace": "Go",
        ])
    }

    @Test func editsAndRemovesLabelsInNestedTables() {
        let text = "[labels]\nfocus = \"F\"\n\n[labels.switchWorkspace]\nnext = \"N\"\n"
        let changed = ConfigEditor.label("switchWorkspace.next", to: "M", in: text)
        #expect(changed == "[labels]\nfocus = \"F\"\n\n[labels.switchWorkspace]\nnext = \"M\"\n")
        let removed = ConfigEditor.label("switchWorkspace.next", to: nil, in: text)
        #expect(ConfigLoader.load(removed).config.labels == ["focus": "F"])
    }
}
