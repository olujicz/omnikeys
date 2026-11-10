import AppKit
import OmniKeysCore
import SwiftUI

/// Sizes, builds and shows the cheat-sheet panel.
@MainActor
final class PanelPresenter {
    var onOpenSettings: (@MainActor () -> Void)?
    private var panel: CheatPanel?
    private var previousApp: NSRunningApplication?
    private var lastLayout: (inputs: LayoutInputs, layout: (Double, SheetLayout.Result))?

    var isVisible: Bool {
        panel?.isVisible ?? false
    }

    func present(model: SheetModel, config: Config, on screen: NSScreen) {
        let visible = screen.visibleFrame
        let (width, layout) = layout(model: model, config: config, visible: visible, screen: screen)
        let size = NSSize(width: width, height: layout.fit.height)
        let host = NSHostingView(rootView: SheetLayout.scaledSheet(
            model: model,
            config: config,
            width: width,
            layout: layout
        ))
        host.frame = NSRect(origin: .zero, size: size)
        host.autoresizingMask = [.width, .height]

        let effect = Self.backdrop(hosting: host, config: config)

        let frame = NSRect(
            x: visible.midX - size.width / 2,
            y: visible.midY - size.height / 2,
            width: size.width,
            height: size.height
        )
        let panel = panel ?? CheatPanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.closesOnResignKey = config.closeOnClickOutside
        panel.contentView = effect
        panel.setFrame(frame, display: true)
        panel.onDismiss = { [weak self] restore in self?.dismiss(restoreFocus: restore) }
        panel.onOpenSettings = { [weak self] in self?.onOpenSettings?() }
        self.panel = panel
        rememberPreviousApp()
        NSApp.activate()
        panel.makeKeyAndOrderFront(nil)
    }

    /// Everything the layout depends on; measuring is slow, so the last layout is reused while this is unchanged.
    private struct LayoutInputs: Equatable {
        let model: SheetModel
        let config: Config
        let visible: NSRect
        let pointsPerInch: Double
        let widthMM: Double
    }

    /// Panel width, and the columns and scale that give the biggest text on this screen.
    private func layout(model: SheetModel, config: Config, visible: NSRect,
                        screen: NSScreen) -> (Double, SheetLayout.Result)
    {
        let metrics = ScreenMetrics.density(of: screen)
        let inputs = LayoutInputs(
            model: model,
            config: config,
            visible: visible,
            pointsPerInch: metrics.pointsPerInch,
            widthMM: metrics.widthMM
        )
        if let cached = lastLayout, cached.inputs == inputs {
            return cached.layout
        }
        let width = visible.width * PanelSizing.widthFraction(config.width, physicalWidthMM: metrics.widthMM)
        let densityScale = PanelSizing.densityScale(
            mode: config.density,
            pointsPerInch: metrics.pointsPerInch,
            reference: config.referenceDensity
        )
        let layout = SheetLayout.fit(
            model: model,
            config: config,
            width: width,
            maxHeight: visible.height * config.maxHeight,
            initialScale: config.textSize * densityScale
        )
        lastLayout = (inputs, (width, layout))
        return (width, layout)
    }

    /// Remember who had focus (not when redrawing an open sheet, where that would be us).
    private func rememberPreviousApp() {
        if let front = NSWorkspace.shared.frontmostApplication, front != NSRunningApplication.current {
            previousApp = front
        }
    }

    func dismiss(restoreFocus: Bool) {
        panel?.orderOut(nil)
        if restoreFocus {
            previousApp?.activate()
        }
        previousApp = nil
    }

    private static func backdrop(hosting host: NSView, config: Config) -> NSVisualEffectView {
        let effect = NSVisualEffectView(frame: host.frame)
        effect.appearance = config.appearance
        effect.material = .hudWindow
        effect.blendingMode = .behindWindow
        effect.state = .active
        effect.wantsLayer = true
        effect.layer?.cornerRadius = 18
        effect.layer?.masksToBounds = true
        effect.addSubview(host)
        return effect
    }
}
