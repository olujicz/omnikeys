import OmniKeysCore
import SwiftUI

struct Card<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    @Environment(\.omniKeysConfig) private var config

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.system(size: 12.5, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(config.accentColor)
            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.06)))
    }
}
