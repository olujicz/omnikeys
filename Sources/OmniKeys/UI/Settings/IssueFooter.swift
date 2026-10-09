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
                ForEach(Array(issues.enumerated()), id: \.offset) { Text($0.element.message) }
            }
            .foregroundStyle(.red)
        }
    }
}

/// The top section of every tab: problems not tied to one setting, such as a syntax error in config.toml.
struct GeneralIssuesSection: View {
    @Environment(SettingsModel.self) private var model
    /// An issue the tab already shows elsewhere.
    var excluding: ConfigIssue?

    var body: some View {
        let issues = model.generalIssues.filter { $0 != excluding }
        if !issues.isEmpty {
            Section {
                ForEach(Array(issues.enumerated()), id: \.offset) { item in
                    Label(item.element.message, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                }
            }
        }
    }
}
