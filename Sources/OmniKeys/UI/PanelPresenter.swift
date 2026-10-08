import AppKit
import OmniKeysCore
import SwiftUI

/// Sizes, builds and shows the cheat-sheet panel.
@MainActor
final class PanelPresenter {
    var onOpenSettings: (@MainActor () -> Void)?
    private var panel: CheatPanel?
    private var previousApp: NSRunningApplication?

    var isVisible: Bool {
        panel?.isVisible ?? false
    }

    func present(model: SheetModel, config: Config, on screen: NSScreen) {
        let visible = screen.visibleFrame
        let metrics = ScreenMetrics.density(of: screen)
        let width = visible.width * PanelSizing.widthFraction(config.width, physicalWidthMM: metrics.widthMM)
        let maxHeight = visible.height * config.maxHeight
        let densityScale = PanelSizing.densityScale(
            mode: config.density,
            pointsPerInch: metrics.pointsPerInch,
            reference: config.referenceDensity
        )
        let fit = PanelSizing
            .fit(width: width, maxHeight: maxHeight, initialScale: config.textSize * densityScale) { layoutWidth in
                NSHostingController(rootView: Self.sheet(model, config, width: layoutWidth))
                    .sizeThatFits(in: NSSize(width: layoutWidth, height: 10000))
                    .height
            }
        let size = NSSize(width: width, height: fit.height)
        let host = NSHostingView(rootView: Self.sheet(model, config, width: width / fit.scale)
            .scaleEffect(fit.scale, anchor: .topLeading)
            .frame(width: size.width, height: size.height, alignment: .topLeading))
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

    private static func sheet(_ model: SheetModel, _ config: Config, width: Double) -> some View {
        CheatSheet(model: model, width: width).environment(\.omniKeysConfig, config)
    }
}
