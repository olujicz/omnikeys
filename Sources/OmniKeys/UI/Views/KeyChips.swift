import OmniKeysCore
import SwiftUI

/// "Hyper ⇧ H/J/K/L" drawn as key caps; "Hyper" gets the accent colour.
struct KeyChips: View {
    let text: String
    @Environment(\.omniKeysConfig) private var config

    var body: some View {
        HStack(spacing: 5) {
            ForEach(Array(text.split(separator: " ").enumerated()), id: \.offset) { _, part in
                let isHyper = part == "Hyper"
                Text(isHyper ? "✦ Hyper" : String(part))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(isHyper ? Color.white : Color.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isHyper ? config.accentColor.opacity(0.85) : Color.primary.opacity(0.12))
                    )
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.primary.opacity(0.15), lineWidth: 0.5))
            }
        }
        .fixedSize()
    }
}
