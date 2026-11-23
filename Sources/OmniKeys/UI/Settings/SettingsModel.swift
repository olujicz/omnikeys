import AppKit
import Observation
import OmniKeysCore
import SwiftUI

/// What the Settings window shows and edits. Controls change `config` (the draft); `commit()` hands the change to
/// AppController, which writes config.toml and pushes the reloaded state back through `update`.
@MainActor
@Observable
final class SettingsModel {
    var config = Config()
    /// The config as last loaded from disk; commit() saves the difference.
    private(set) var saved = Config()
    private(set) var issues: [ConfigIssue] = []
    private(set) var shortcuts: [ShortcutEntry] = []
    private(set) var settingsIssue: ConfigIssue?
    private(set) var launchAtLogin = LoginItem.Status.disabled

    /// Writes the change from the first config (on disk) to the second.
    @ObservationIgnored var save: @MainActor (Config, Config) -> Void = { _, _ in }
    @ObservationIgnored var setLaunchAtLogin: @MainActor (Bool) -> Void = { _ in }
    /// The colour panel changes the colour continuously; it is saved once it has rested this long.
    @ObservationIgnored var accentDebounce = Duration.milliseconds(300)
    @ObservationIgnored private var pendingCommit: Task<Void, Never>?

    private static let defaultCustomWidth = 0.75

    func update(state: LoadedState, launchAtLogin: LoginItem.Status) {
        let draft = config
        let draftBase = saved
        saved = state.config
        config = state.config
        // Keep edits not committed yet (a label being typed, a slider mid-drag): a reload must not wipe them.
        func keep(_ keyPath: WritableKeyPath<Config, some Equatable>) {
            if draft[keyPath: keyPath] != draftBase[keyPath: keyPath] {
                config[keyPath: keyPath] = draft[keyPath: keyPath]
            }
        }
        keep(\.width)
        keep(\.maxHeight)
        keep(\.textSize)
        keep(\.backgroundOpacity)
        keep(\.accent)
        for id in Set(draft.labels.keys).union(draftBase.labels.keys) where draft.labels[id] != draftBase.labels[id] {
            config.labels[id] = draft.labels[id]
        }
        issues = state.issues
        shortcuts = state.shortcuts
        settingsIssue = state.settingsIssue
        self.launchAtLogin = launchAtLogin
    }

    /// False when config.toml has a syntax error: the form shows defaults, and saving them would overwrite the file.
    var isEditable: Bool {
        !issues.contains { $0.key == ConfigLoader.syntaxErrorKey }
    }

    func commit() {
        pendingCommit?.cancel()
        pendingCommit = nil
        guard isEditable, config != saved else { return }
        let old = saved
        saved = config
        save(old, config)
    }

    func issues(for key: String) -> [ConfigIssue] {
        issues.filter { $0.key == key }
    }

    /// Problems not tied to one setting, such as a syntax error or missing OmniWM settings.
    var generalIssues: [ConfigIssue] {
        issues.filter { $0.key == nil || $0.key == ConfigLoader.syntaxErrorKey }
    }

    // MARK: - Plain values

    func binding<Value>(_ keyPath: WritableKeyPath<Config, Value>) -> SwiftUI.Binding<Value> {
        SwiftUI.Binding {
            self.config[keyPath: keyPath]
        } set: {
            self.config[keyPath: keyPath] = $0
            self.commit()
        }
    }

    /// Rounded to `step` and kept in `range`. With `draft`, only commit() saves (sliders, when the drag ends).
    func number(
        _ keyPath: WritableKeyPath<Config, Double>,
        in range: ClosedRange<Double>,
        step: Double,
        draft: Bool = false
    ) -> SwiftUI.Binding<Double> {
        SwiftUI.Binding {
            self.config[keyPath: keyPath]
        } set: {
            self.config[keyPath: keyPath] = Self.snap($0, to: range, step: step)
            if !draft {
                self.commit()
            }
        }
    }

    private static func snap(_ value: Double, to range: ClosedRange<Double>, step: Double) -> Double {
        let scale = (1 / step).rounded()
        return min(max((value * scale).rounded() / scale, range.lowerBound), range.upperBound)
    }

    // MARK: - Size and look

    var widthIsCustom: Bool {
        get {
            if case .fraction = config.width {
                return true
            }
            return false
        }
        set {
            guard newValue != widthIsCustom else { return }
            config.width = newValue ? .fraction(Self.defaultCustomWidth) : .auto
            commit()
        }
    }

    /// Draft: the slider commits when the drag ends.
    var widthFraction: SwiftUI.Binding<Double> {
        SwiftUI.Binding {
            if case let .fraction(value) = self.config.width {
                return value
            }
            return Self.defaultCustomWidth
        } set: {
            self.config.width = .fraction(Self.snap($0, to: 0.3 ... 1, step: 0.01))
        }
    }

    var adaptsToDensity: Bool {
        get { config.density == .auto }
        set {
            config.density = newValue ? .auto : .off
            commit()
        }
    }

    var accentIsCustom: Bool {
        get { config.accent != .system }
        set {
            guard newValue != accentIsCustom else { return }
            config.accent = newValue ? AccentSetting("#4C8DFF") ?? .system : .system
            commit()
        }
    }

    var accentColor: Color {
        get {
            if case let .rgb(red, green, blue) = config.accent {
                return Color(.sRGB, red: red, green: green, blue: blue)
            }
            return Color.accentColor
        }
        set {
            guard let rgb = NSColor(newValue).usingColorSpace(.sRGB) else { return }
            func channel(_ value: CGFloat) -> Double {
                (Double(value) * 255).rounded() / 255
            }
            config.accent = .rgb(
                red: channel(rgb.redComponent),
                green: channel(rgb.greenComponent),
                blue: channel(rgb.blueComponent)
            )
            scheduleCommit()
        }
    }

    /// Commits after `accentDebounce` unless another change (or a commit) comes first.
    private func scheduleCommit() {
        pendingCommit?.cancel()
        pendingCommit = Task { [weak self, accentDebounce] in
            try? await Task.sleep(for: accentDebounce)
            guard !Task.isCancelled else { return }
            self?.commit()
        }
    }

    // MARK: - Hotkey and login

    var hotkey: HotkeyFields {
        HotkeyFields(config.hotkey)
    }

    func modifier(_ name: String) -> SwiftUI.Binding<Bool> {
        SwiftUI.Binding {
            self.hotkey.modifiers.contains(name)
        } set: { isOn in
            var fields = self.hotkey
            if isOn {
                fields.modifiers.insert(name)
            } else {
                fields.modifiers.remove(name)
            }
            guard !fields.modifiers.isEmpty else { return }
            self.config.hotkey = fields.binding
            self.commit()
        }
    }

    /// The last checked modifier can't be unchecked: a hotkey needs at least one.
    func isOnlyModifier(_ name: String) -> Bool {
        hotkey.modifiers == [name]
    }

    var hotkeyKey: SwiftUI.Binding<String> {
        SwiftUI.Binding {
            self.hotkey.key
        } set: {
            var fields = self.hotkey
            fields.key = $0
            self.config.hotkey = fields.binding
            self.commit()
        }
    }

    var launchAtLoginEnabled: SwiftUI.Binding<Bool> {
        SwiftUI.Binding {
            self.launchAtLogin != .disabled
        } set: {
            self.setLaunchAtLogin($0)
        }
    }

    // MARK: - Shortcuts

    func isVisible(_ entry: ShortcutEntry) -> SwiftUI.Binding<Bool> {
        SwiftUI.Binding {
            !self.config.isHidden(entry)
        } set: {
            self.config.setHidden(!$0, entry)
            self.commit()
        }
    }

    /// Draft: the text field commits on Return, when it loses focus, or when the window closes or changes tab.
    /// Empty removes the override.
    func label(_ entry: ShortcutEntry) -> SwiftUI.Binding<String> {
        SwiftUI.Binding {
            self.config.labels[entry.actionID] ?? ""
        } set: {
            let isEmpty = $0.trimmingCharacters(in: .whitespaces).isEmpty
            self.config.labels[entry.actionID] = isEmpty ? nil : $0
        }
    }

    var shortcutGroups: [(title: String, entries: [ShortcutEntry])] {
        ActionCatalog.groupOrder.compactMap { title in
            let entries = shortcuts.filter { $0.group == title }
            return entries.isEmpty ? nil : (title, entries)
        }
    }
}
