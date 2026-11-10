import OmniKeysCore
import SwiftUI

struct WorkspacesCard: View {
    let workspaces: [OmniWMWorkspace]
    let floating: [String]

    var body: some View {
        Card(title: "Workspaces", symbol: "square.grid.3x2") {
            Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 8) {
                ForEach(Array(workspaces.enumerated()), id: \.offset) { _, workspace in
                    GridRow(alignment: .firstTextBaseline) {
                        KeyCap(label: workspace.name)
                        Text(workspace.displayName).font(.system(size: 15))
                        VStack(alignment: .leading, spacing: 1) {
                            Text(workspace.apps.joined(separator: ", "))
                                .font(.system(size: 15))
                                .fixedSize(horizontal: false, vertical: true)
                            if !workspace.display.isEmpty {
                                Text(workspace.display)
                                    .font(.system(size: 12.5))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            if !floating.isEmpty {
                (Text("Always floating  ").foregroundStyle(.secondary) + Text(floating.joined(separator: ", ")))
                    .font(.system(size: 13))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            }
        }
    }
}
