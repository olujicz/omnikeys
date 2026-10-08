import OmniKeysCore
import SwiftUI

struct WorkspacesCard: View {
    let workspaces: [OmniWMWorkspace]
    let floating: [String]

    var body: some View {
        Card(title: "Workspaces") {
            Grid(alignment: .leading, horizontalSpacing: 22, verticalSpacing: 7) {
                ForEach(Array(workspaces.enumerated()), id: \.offset) { _, workspace in
                    GridRow(alignment: .firstTextBaseline) {
                        let label = workspace.displayName.isEmpty
                            ? workspace.name
                            : "\(workspace.name) \(workspace.displayName)"
                        KeyChips(text: label)
                        Text(workspace.display).font(.system(size: 15)).foregroundStyle(.secondary)
                        Text(workspace.apps.joined(separator: ", ")).font(.system(size: 15))
                    }
                }
            }
            if !floating.isEmpty {
                Text("Always floating: " + floating.joined(separator: ", "))
                    .font(.system(size: 13.5))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
