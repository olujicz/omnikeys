import Foundation
import OmniKeysCore
import os

extension Logger {
    static let app = Logger(subsystem: Bundle.main.bundleIdentifier ?? "rs.in.olujic.omnikeys", category: "app")
}

extension ConfigPaths {
    static var current: ConfigPaths {
        ConfigPaths(home: FileManager.default.homeDirectoryForCurrentUser)
    }
}
