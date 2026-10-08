import Carbon.HIToolbox
@testable import OmniKeys
import OmniKeysCore
import Testing

struct CarbonKeysTests {
    @Test func everySupportedKeyHasAKeyCode() {
        for key in HotkeyParser.supportedKeys {
            #expect(CarbonKeys.keyCode(for: key) != nil, "\(key)")
        }
    }

    @Test func knownKeyCodes() {
        #expect(CarbonKeys.keyCode(for: "Slash") == UInt32(kVK_ANSI_Slash))
        #expect(CarbonKeys.keyCode(for: "A") == UInt32(kVK_ANSI_A))
        #expect(CarbonKeys.keyCode(for: "F12") == UInt32(kVK_F12))
    }

    @Test func modifierMask() {
        #expect(CarbonKeys.modifierMask([.control, .option, .command]) == UInt32(controlKey | optionKey | cmdKey))
        #expect(CarbonKeys.modifierMask([.shift]) == UInt32(shiftKey))
    }
}
