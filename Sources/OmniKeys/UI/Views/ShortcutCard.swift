import OmniKeysCore
import SwiftUI

struct ShortcutCard: View {
    let title: String
    let entries: [SheetEntry]

    var body: some View {
        Card(title: title, symbol: Self.symbol(for: title)) {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(entries) { entry in
                    switch entry {
                    case let .shortcut(row, shifted):
                        VStack(alignment: .leading, spacing: 3) {
                            ShortcutLine(action: row.action) { KeyChips(text: row.keys) }
                            if let shifted {
                                // Same keys plus ⇧, so only "+ ⇧" is drawn.
                                ShortcutLine(action: shifted.action, secondary: true) {
                                    HStack(spacing: 4) {
                                        KeySeparator(symbol: "+")
                                        KeyCap(label: "⇧", compact: true)
                                    }
                                }
                            }
                        }
                    case let .family(name, modifiers, members):
                        FamilyLines(name: name, modifiers: modifiers, members: members)
                    case let .pair(action, modifiers, next, previous):
                        ShortcutLine(action: action) {
                            HStack(spacing: 3) {
                                if !modifiers.isEmpty {
                                    KeyChips(text: modifiers)
                                }
                                KeyCap(label: next)
                                KeySeparator(symbol: "/").padding(.horizontal, 1)
                                KeyCap(label: previous)
                            }
                        }
                    }
                }
            }
        }
    }

    private static func symbol(for group: String) -> String {
        switch group {
        case ActionCatalog.Group.navigate: "arrow.up.and.down.and.arrow.left.and.right"
        case ActionCatalog.Group.workspaces: "rectangle.on.rectangle"
        case ActionCatalog.Group.columns: "rectangle.split.3x1"
        case ActionCatalog.Group.windows: "macwindow"
        case ActionCatalog.Group.tools: "wrench.and.screwdriver"
        case ActionCatalog.Group.windowMode: "keyboard"
        default: "keyboard"
        }
    }
}

/// Action on the left, keys on the right, joined by a dotted leader. A secondary line is smaller,
/// greyed and indented under the line above.
private struct ShortcutLine<Keys: View>: View {
    let action: String
    var secondary = false
    @ViewBuilder let keys: Keys

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Text(action)
                .font(.system(size: secondary ? 13.5 : 15))
                .foregroundStyle(secondary ? .secondary : .primary)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
            DottedLeader()
            keys
        }
        .padding(.leading, secondary ? 14 : 0)
    }
}

/// "Palette ✦ +" then each member as "W windows", wrapping as needed.
private struct FamilyLines: View {
    let name: String
    let modifiers: String
    let members: [ShortcutRow]

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ShortcutLine(action: name) {
                if !modifiers.isEmpty {
                    HStack(spacing: 4) {
                        KeyChips(text: modifiers)
                        KeySeparator(symbol: "+")
                    }
                }
            }
            FlowLayout(spacing: 12, lineSpacing: 5) {
                ForEach(members) { member in
                    KeyHint(keys: member.keys, label: member.action, compact: true)
                }
            }
            .padding(.leading, 14)
        }
    }
}

/// Lays subviews out left to right, wrapping onto new lines.
private struct FlowLayout: Layout {
    let spacing: Double
    let lineSpacing: Double

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
        let frames = place(subviews, width: proposal.width ?? .infinity)
        let width = frames.map(\.maxX).max() ?? 0
        return CGSize(width: proposal.width ?? width, height: frames.map(\.maxY).max() ?? 0)
    }

    func placeSubviews(in bounds: CGRect, proposal _: ProposedViewSize, subviews: Subviews, cache _: inout ()) {
        for (subview, frame) in zip(subviews, place(subviews, width: bounds.width)) {
            subview.place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), proposal: .unspecified)
        }
    }

    private func place(_ subviews: Subviews, width: Double) -> [CGRect] {
        var frames: [CGRect] = []
        var origin = CGPoint.zero
        var lineHeight = 0.0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if origin.x > 0, origin.x + size.width > width {
                origin = CGPoint(x: 0, y: origin.y + lineHeight + lineSpacing)
                lineHeight = 0
            }
            frames.append(CGRect(origin: origin, size: size))
            origin.x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        return frames
    }
}

/// Faint dots that lead the eye from an action to its keys, as in a printed index.
struct DottedLeader: View {
    var body: some View {
        Line()
            .stroke(Color.primary.opacity(0.2), style: StrokeStyle(lineWidth: 1.2, lineCap: .round, dash: [0.1, 5]))
            .frame(minWidth: 12, maxWidth: .infinity)
            .frame(height: 2)
    }

    private struct Line: Shape {
        func path(in rect: CGRect) -> Path {
            Path { path in
                path.move(to: CGPoint(x: rect.minX, y: rect.midY))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            }
        }
    }
}
