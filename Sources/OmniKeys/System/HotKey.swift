import Carbon.HIToolbox
import OmniKeysCore

/// One global hotkey through Carbon's RegisterEventHotKey, which needs no Accessibility permission.
@MainActor
final class HotKey {
    var onPress: (@MainActor () -> Void)?
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?

    init() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, context in
            guard let context else { return OSStatus(eventNotHandledErr) }
            let hotKey = Unmanaged<HotKey>.fromOpaque(context).takeUnretainedValue()
            Task { @MainActor in hotKey.onPress?() }
            return noErr
        }, 1, &spec, Unmanaged.passUnretained(self).toOpaque(), &handlerRef)
    }

    /// Replaces any previous registration once the new one succeeds. Returns noErr, or the Carbon error
    /// (eventHotKeyExistsErr when taken); on failure the previous hotkey stays registered.
    func register(_ spec: HotkeySpec) -> OSStatus {
        guard let code = CarbonKeys.keyCode(for: spec.key) else { return OSStatus(paramErr) }
        let id = EventHotKeyID(signature: OSType(0x4F4B_4559), id: 1) // 'OKEY'
        var newRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            code,
            CarbonKeys.modifierMask(spec.modifiers),
            id,
            GetApplicationEventTarget(),
            0,
            &newRef
        )
        guard status == noErr else { return status }
        unregister()
        hotKeyRef = newRef
        return noErr
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }
}
