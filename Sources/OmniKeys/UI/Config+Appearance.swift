import AppKit
import OmniKeysCore
import SwiftUI

extension EnvironmentValues {
    @Entry var omniKeysConfig = Config()
}

extension Config {
    var accentColor: Color {
        switch accent {
        case .system: .accentColor
        case let .rgb(red, green, blue): Color(red: red, green: green, blue: blue)
        }
    }

    var colorScheme: ColorScheme? {
        switch theme {
        case .light: .light
        case .dark: .dark
        case .system: nil
        }
    }

    var appearance: NSAppearance? {
        switch theme {
        case .light: NSAppearance(named: .aqua)
        case .dark: NSAppearance(named: .darkAqua)
        case .system: nil
        }
    }

    var backgroundColor: Color {
        switch theme {
        case .light: Color.white.opacity(backgroundOpacity)
        case .dark: Color.black.opacity(backgroundOpacity)
        case .system: Color(nsColor: .windowBackgroundColor).opacity(backgroundOpacity)
        }
    }
}
