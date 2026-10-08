import Foundation
import OmniKeysCore
import os

extension Logger {
    static let app = Logger(subsystem: Bundle.main.bundleIdentifier ?? "io.github.olujicz.omnikeys", category: "app")
}

extension ConfigPaths {
    static var current: ConfigPaths {
        ConfigPaths(home: FileManager.default.homeDirectoryForCurrentUser)
    }
}
