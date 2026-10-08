import AppKit

@MainActor
enum ScreenMetrics {
    /// The screen with the menu bar.
    static var mainScreen: NSScreen? {
        NSScreen.screens.first
    }

    static var mouseScreen: NSScreen? {
        NSScreen.screens.first { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) }
    }

    static func displayID(of screen: NSScreen) -> UInt32? {
        (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
    }

    static func screen(displayID: UInt32) -> NSScreen? {
        NSScreen.screens.first { Self.displayID(of: $0) == displayID }
    }

    /// Points per inch and physical width in mm; (0, 0) when macOS doesn't know the size.
    static func density(of screen: NSScreen) -> (pointsPerInch: Double, widthMM: Double) {
        guard let id = displayID(of: screen) else { return (0, 0) }
        let widthMM = CGDisplayScreenSize(id).width
        return widthMM > 0 ? (screen.frame.width / (widthMM / 25.4), widthMM) : (0, 0)
    }
}
