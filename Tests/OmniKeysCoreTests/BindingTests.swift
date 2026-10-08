@testable import OmniKeysCore
import Testing

struct BindingTests {
    @Test func splitsAndMapsGlyphs() {
        let split = Binding.split("Hyper+Shift+Left Arrow")
        #expect(split.mods == ["Hyper", "⇧"])
        #expect(split.key == "←")
    }

    @Test func unknownNamesPassThrough() {
        #expect(Binding.split("Hyper+K").key == "K")
    }

    @Test func modifierGlyphsUseMenuOrder() {
        #expect(Binding.modifierGlyphs("Command+Option+Control") == "⌃⌥⌘")
        #expect(Binding.modifierGlyphs("Shift+Control") == "⌃⇧")
    }
}
