import AppKit
import OmniKeysCore
import os

/// Owns the app's moving parts and keeps them in sync with config.toml and OmniWM's settings.toml.
@MainActor
final class AppController {
    private let paths: ConfigPaths
    private let store: ConfigStore
    private let hotKey = HotKey()
    private let presenter = PanelPresenter()
    private let omniWM = OmniWMClient()
    private var pollTimer: Timer?
    private var stamps: [Date?] = []
    private var registeredHotkey: HotkeySpec?
    private var hotkeyIssue: ConfigIssue?
    private var isPresenting = false
    private(set) var state: LoadedState

    init(paths: ConfigPaths) {
        self.paths = paths
        store = ConfigStore(paths: paths)
        state = store.load()
    }

    func start() {
        hotKey.onPress = { [weak self] in self?.toggle() }
        presenter.onOpenSettings = { [weak self] in self?.openSettingsFile() }
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

    private func reloadIfChanged() {
        guard store.fileStamps() != stamps else { return }
        reload()
    }

    private func reload() {
        let setupIssues = store.prepare() // recreates a deleted config.toml
        var loaded = store.load()
        registerHotkey(loaded.hotkey)
        loaded.issues = setupIssues + loaded.issues + [hotkeyIssue].compactMap(\.self)
        state = loaded
        stamps = store.fileStamps()
        for issue in state.issues {
            Logger.app.warning("\(issue.message, privacy: .public)")
        }
        if presenter.isVisible {
            showSheet()
        } // redraw in place
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
                "The hotkey could not be registered (error \(status)); another app may already use it. "
                    + "Pick a different “hotkey” in config.toml."
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
}
