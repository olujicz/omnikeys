import OmniKeysCore
import SwiftUI

/// A section footer: the setting's problems in red when there are any, otherwise the help text.
struct IssueFooter: View {
    let issues: [ConfigIssue]
    var help: String?

    var body: some View {
        if issues.isEmpty {
            if let help {
                Text(help)
            }
        } else {
            VStack(alignment: .leading) {
                ForEach(issues, id: \.message) { Text($0.message) }
            }
            .foregroundStyle(.red)
        }
    }
}
