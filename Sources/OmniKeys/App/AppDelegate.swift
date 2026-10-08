import AppKit
import OmniKeysCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var controller: AppController?

    func applicationDidFinishLaunching(_: Notification) {
        guard !RuntimeEnvironment.isRunningTests else { return }
        let controller = AppController(paths: .current)
        self.controller = controller
        controller.start()
    }

    /// Opening the app again (Finder, Spotlight) shows the sheet, so it is reachable without a menu-bar icon.
    func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows _: Bool) -> Bool {
        controller?.showSheet()
        return false
    }
}
