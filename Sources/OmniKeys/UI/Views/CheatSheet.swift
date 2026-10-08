import AppKit
import OmniKeysCore
import SwiftUI

struct CheatSheet: View {
    let model: SheetModel
    let width: Double
    @Environment(\.omniKeysConfig) private var config

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("OmniWM").font(.system(size: 26, weight: .bold))
                Text(subtitle).font(.system(size: 14)).foregroundStyle(.secondary)
                Spacer()
                Text("Esc to close  ·  ⌘, settings").font(.system(size: 12.5)).foregroundStyle(.tertiary)
            }
            HStack(alignment: .top, spacing: 16) {
                ForEach(Array(columns.enumerated()), id: \.offset) { _, column in
                    VStack(spacing: 16) {
                        ForEach(column) { ShortcutCard(group: $0) }
                    }
                    .frame(maxWidth: .infinity, alignment: .top)
                }
            }
            if !model.workspaces.isEmpty {
                WorkspacesCard(workspaces: model.workspaces, floating: model.floating)
            }
        }
        .padding(28)
        .frame(width: width)
        .background(config.backgroundColor)
        .environment(\.colorScheme, config.colorScheme ?? Self.systemColorScheme)
    }

    private var subtitle: String {
        var text = "✦ Hyper = \(model.hyperGlyphs)"
        if model.showShiftHint {
            text += "  ·  add ⇧ to move instead of focus"
        }
        return text
    }

    private var columns: [[ShortcutGroup]] {
        ColumnLayout.distribute(
            model.groups,
            columns: ColumnLayout.columnCount(configured: config.columns, layoutWidth: width)
        )
    }

    private static var systemColorScheme: ColorScheme {
        NSApplication.shared.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? .dark : .light
    }
}
