import OmniKeysCore
import SwiftUI

/// One key drawn as a physical key cap: a lit top face over a darker lip.
struct KeyCap: View {
    let label: String
    var isHyper = false
    /// Smaller cap for secondary lines.
    var compact = false
    @Environment(\.omniKeysConfig) private var config
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text(label)
            .font(.system(size: compact ? 11.5 : 13, weight: .semibold, design: .rounded))
            .foregroundStyle(isHyper ? Color.white : Color.primary.opacity(0.9))
            .lineLimit(1)
            .padding(.horizontal, compact ? 5 : 7)
            .frame(minWidth: compact ? 19 : 24, minHeight: compact ? 18 : 22)
            .background(face)
            .padding(.bottom, compact ? 1.5 : 2)
            .background(lip)
            .fixedSize()
    }

    private var face: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(LinearGradient(
                colors: isHyper
                    ? [config.accentColor, config.accentColor.opacity(0.82)]
                    : colorScheme == .light
                    ? [Color.white, Color.white.opacity(0.85)]
                    : [Color.primary.opacity(0.17), Color.primary.opacity(0.11)],
                startPoint: .top,
                endPoint: .bottom
            ))
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(edge, lineWidth: 0.5)
            )
    }

    private var lip: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(isHyper ? config.accentColor.opacity(0.45) : Color.primary
                .opacity(colorScheme == .light ? 0.2 : 0.09))
    }

    private var edge: Color {
        if isHyper {
            return Color.white.opacity(0.25)
        }
        return colorScheme == .light ? Color.black.opacity(0.12) : Color.white.opacity(0.08)
    }
}

/// "Hyper ⇧ H/J/K/L" drawn as key caps; "Hyper" becomes an accent-coloured ✦ (the header explains it).
struct KeyChips: View {
    let text: String
    var compact = false

    var body: some View {
        HStack(spacing: 3) {
            ForEach(Array(ShortcutRow.tokens(text).enumerated()), id: \.offset) { _, part in
                KeyCap(label: part == "Hyper" ? "✦" : part, isHyper: part == "Hyper", compact: compact)
            }
        }
        .fixedSize()
    }
}

/// "+" or "/" between key caps.
struct KeySeparator: View {
    let symbol: String

    var body: some View {
        Text(symbol).font(.system(size: 13, weight: .medium)).foregroundStyle(.secondary)
    }
}

/// Key caps followed by what they do: "esc close", "W windows".
struct KeyHint: View {
    let keys: String
    let label: String
    var compact = false

    var body: some View {
        HStack(spacing: compact ? 5 : 6) {
            KeyChips(text: keys, compact: compact)
            Text(label).font(.system(size: 13.5)).foregroundStyle(.secondary)
        }
    }
}
