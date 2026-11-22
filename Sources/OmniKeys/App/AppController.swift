import AppKit
import Carbon.HIToolbox
import OmniKeysCore
import os
import UniformTypeIdentifiers

/// Owns the app's moving parts and keeps them in sync with config.toml and OmniWM's settings.toml.
@MainActor
final class AppController {
    private let paths: ConfigPaths
    private let store: ConfigStore
    private let hotKey = HotKey()
    private let presenter = PanelPresenter()
    private let omniWM = OmniWMClient()
    private let settingsModel = SettingsModel()
    private var settingsWindow: SettingsWindowController?
    private var pollTimer: Timer?
    private var statusItem: StatusItem?
    private var stamps: [Date?] = []
    private var registeredHotkey: HotkeySpec?
    private var hotkeyIssue: ConfigIssue?
    private var isPresenting = false
    /// Bundle id -> name of every app rule, as of the last load.
    private var resolvedApps: [String: String] = [:]
    private(set) var state: LoadedState

    init(paths: ConfigPaths) {
        self.paths = paths
        store = ConfigStore(paths: paths)
        var names: [String: String] = [:]
        state = store.load { names[$0] = $1 }
        resolvedApps = names
    }

    private var hotkeyText: String {
        let (mods, key) = Binding.split(state.config.hotkey)
        return (mods + [key]).joined(separator: " ")
    }

    func start() {
        hotKey.onPress = { [weak self] in self?.toggle() }
        presenter.onOpenSettings = { [weak self] in self?.openSettings() }
        statusItem = StatusItem(actions: .init(
            show: { [weak self] in self?.showSheet() },
            openSettings: { [weak self] in self?.openSettings() },
            openSettingsFile: { [weak self] in self?.openSettingsFile() },
            exportShortcuts: { [weak self] in self?.exportShortcuts() },
            importShortcuts: { [weak self] in self?.importShortcuts() },
            toggleLaunchAtLogin: { [weak self] in self?.toggleLaunchAtLogin() },
            about: {
                NSApp.activate()
                NSApp.orderFrontStandardAboutPanel(nil)
            },
            quit: { NSApp.terminate(nil) }
        ))
        settingsModel.save = { [weak self] old, new in self?.saveConfig(from: old, to: new) }
        settingsModel.setLaunchAtLogin = { [weak self] enabled in self?.setLaunchAtLogin(enabled) }
        NSApp.mainMenu = MainMenu.make(
            settings: { [weak self] in self?.openSettings() },
            about: {
                NSApp.activate()
                NSApp.orderFrontStandardAboutPanel(nil)
            },
            quit: { NSApp.terminate(nil) }
        )
        reload()
        // Poll both files' modification dates: cheap, and catches atomic saves and deletion.
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.reloadIfChanged() }
        }
    }

    func toggle() {
        if presenter.isVisible {
            presenter.dismiss(restoreFocus: true)
        } else {
            showSheet()
        }
    }

    func showSheet() {
        guard !isPresenting else { return }
        // Apps installed or removed since the last load change the Workspaces card without touching
        // either file. Reloading redraws a visible sheet itself.
        if appsChanged {
            reload()
            if presenter.isVisible {
                return
            }
        }
        presentSheet()
    }

    private func presentSheet() {
        guard !isPresenting else { return }
        isPresenting = true
        Task {
            defer { isPresenting = false }
            guard let screen = await screenForSheet() else { return }
            presenter.present(model: state.model, config: state.config, on: screen)
        }
    }

    /// Opens config.toml in the default text editor (recreating it first if it was deleted).
    func openSettingsFile() {
        _ = store.prepare()
        let open = Process()
        open.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        open.arguments = ["-t", paths.configFile.path]
        do {
            try open.run()
        } catch {
            Logger.app.error("Could not open settings: \(error.localizedDescription, privacy: .public)")
        }
    }

    func openSettings() {
        let controller = settingsWindow ?? SettingsWindowController(model: settingsModel)
        settingsWindow = controller
        controller.commitEdits() // keeps drafts when the window is already open; update() replaces them
        // Launch at login can change in System Settings, which doesn't tell us.
        settingsModel.update(state: state, launchAtLogin: LoginItem.status)
        controller.show()
    }

    /// Saves a Settings-window edit and reloads at once instead of waiting for the poll.
    private func saveConfig(from old: Config, to new: Config) {
        do {
            try store.save { ConfigValues.apply(from: old, to: new, in: $0) }
        } catch {
            Logger.app.error("Could not save settings: \(error.localizedDescription, privacy: .public)")
            showError("Could not save settings: \(error.localizedDescription)", on: settingsWindow?.sheetHost)
        }
        reload() // on failure this puts the form back to what the file says
    }

    func exportShortcuts() {
        do {
            let text = try String(contentsOf: paths.omniWMSettingsFile, encoding: .utf8)
            let settings = try OmniWMSettings.parse(text) { AppNameResolver.name(for: $0) }
            let data = try ShortcutTransfer.export(settings: settings)
            let panel = NSSavePanel()
            panel.title = "Export OmniKeys Shortcuts"
            panel.nameFieldStringValue = "OmniKeys-shortcuts.json"
            panel.allowedContentTypes = [.json]
            guard panel.runModal() == .OK, let url = panel.url else { return }
            try data.write(to: url, options: .atomic)
            showNotice(title: "Shortcuts Exported", message: "Your OmniKeys shortcuts were exported successfully.")
        } catch {
            showError("Could not export shortcuts: \(error.localizedDescription)")
        }
    }

    func importShortcuts() {
        let panel = NSOpenPanel()
        panel.title = "Import OmniKeys Shortcuts"
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let document = try ShortcutTransfer.import(data: Data(contentsOf: url))
            let current = try String(contentsOf: paths.omniWMSettingsFile, encoding: .utf8)
            let updated = try ShortcutTransfer.apply(document, to: current)
            let backup = try backupSettings()
            try updated.write(to: paths.omniWMSettingsFile, atomically: true, encoding: .utf8)
            reload()
            showNotice(
                title: "Shortcuts Imported",
                message: "Your shortcuts were imported successfully. A backup was saved at \(backup.lastPathComponent)."
            )
        } catch {
            showError("Could not import shortcuts: \(error.localizedDescription)")
        }
    }

    private func updateStatusItem() {
        statusItem?.update(visible: state.config.showMenuBarIcon, hotkey: hotkeyText, issues: state.issues)
    }

    private func toggleLaunchAtLogin() {
        setLaunchAtLogin(LoginItem.status != .enabled)
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            try LoginItem.setEnabled(enabled)
        } catch {
            Logger.app.error("Launch at login change failed: \(error.localizedDescription, privacy: .public)")
            NSApp.activate()
            NSAlert(error: error).runModal()
        }
        updateStatusItem()
        settingsModel.update(state: state, launchAtLogin: LoginItem.status)
    }

    private func reloadIfChanged() {
        guard store.fileStamps() != stamps else { return }
        reload()
    }

    private func reload() {
        let setupIssues = store.prepare() // recreates a deleted config.toml
        var loaded = load()
        registerHotkey(loaded.hotkey)
        loaded.issues = setupIssues + loaded.issues + [hotkeyIssue].compactMap(\.self)
        state = loaded
        stamps = store.fileStamps()
        settingsModel.update(state: state, launchAtLogin: LoginItem.status)
        updateStatusItem()
        for issue in state.issues {
            Logger.app.warning("\(issue.message, privacy: .public)")
        }
        if presenter.isVisible {
            // Redraw in place.
            presentSheet()
        }
    }

    private func registerHotkey(_ spec: HotkeySpec) {
        guard spec != registeredHotkey else { return }
        let status = hotKey.register(spec)
        if status == noErr {
            registeredHotkey = spec
            hotkeyIssue = nil
        } else {
            registeredHotkey = nil
            hotkeyIssue = ConfigIssue(
                status == OSStatus(eventHotKeyExistsErr)
                    ? "The hotkey is already used by another app. Pick a different hotkey in Settings."
                    : "The hotkey could not be registered (error \(status)); another app may already use it. "
                    + "Pick a different hotkey in Settings.",
                key: "hotkey"
            )
        }
    }

    private func screenForSheet() async -> NSScreen? {
        switch state.config.screen {
        case .main:
            return ScreenMetrics.mainScreen
        case .mouse:
            return ScreenMetrics.mouseScreen ?? ScreenMetrics.mainScreen
        case .focused:
            if let id = await omniWM.focusedDisplayID(),
               let screen = ScreenMetrics.screen(displayID: id)
            {
                return screen
            }
            return ScreenMetrics.mouseScreen ?? ScreenMetrics.mainScreen
        }
    }

    private func backupSettings() throws -> URL {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let backup = paths.omniWMSettingsFile.appendingPathExtension("backup-\(formatter.string(from: Date()))")
        try FileManager.default.copyItem(at: paths.omniWMSettingsFile, to: backup)
        return backup
    }

    private func showNotice(title: String, message: String) {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = title
        alert.informativeText = message
        alert.runModal()
    }

    /// Shows the alert as a sheet on `window` when given, otherwise as a modal alert in front of other apps.
    private func showError(_ message: String, on window: NSWindow? = nil) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "OmniKeys"
        alert.informativeText = message
        if let window {
            alert.beginSheetModal(for: window)
        } else {
            NSApp.activate()
            alert.runModal()
        }
    }
}

/// Tracking app names, so an app installed or removed since the last load shows up when the sheet opens.
private extension AppController {
    /// Whether any app rule now resolves to a different name (installed, removed or renamed). Only the
    /// Launch Services lookups, one per app rule; neither file is read.
    var appsChanged: Bool {
        resolvedApps.contains { AppNameResolver.name(for: $0.key) != $0.value }
    }

    /// Reads both files and remembers what each app rule resolved to.
    func load() -> LoadedState {
        var names: [String: String] = [:]
        let loaded = store.load { names[$0] = $1 }
        resolvedApps = names
        return loaded
    }
}
