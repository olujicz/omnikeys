import Foundation

enum RuntimeEnvironment {
    /// True when the app only hosts unit tests; it must not register hotkeys or show UI then.
    static var isRunningTests: Bool {
        ProcessInfo.processInfo
            .environment["XCTestConfigurationFilePath"] != nil || NSClassFromString("XCTestCase") != nil
    }
}
