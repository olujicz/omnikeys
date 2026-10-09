import OmniKeysCore
import SwiftUI

struct ShortcutsTab: View {
    @Environment(SettingsModel.self) private var model
    @FocusState private var focusedLabel: String?

    var body: some View {
        Form {
            Section {
                Toggle("Show Workspaces card", isOn: model.binding(\.showWorkspaces))
                Toggle("Show “Always floating” apps", isOn: model.binding(\.showFloating))
                    .disabled(!model.config.showWorkspaces)
            } footer: {
                IssueFooter(
                    issues: ["showWorkspaces", "showFloating", "hide", "labels"].flatMap(model.issues(for:)),
                    help: "Uncheck a shortcut to hide it on the sheet. Type a name to rename it; "
                        + "leave the field empty to keep the default name."
                )
            }
            if let issue = model.settingsIssue {
                Section {
                    Label(issue.message, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                }
            } else {
                ForEach(model.shortcutGroups, id: \.title) { group in
                    Section(group.title) {
                        ForEach(group.entries) { entry in
                            row(entry)
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 560, height: 600)
        .onChange(of: focusedLabel) { model.commit() }
    }

    private func row(_ entry: ShortcutEntry) -> some View {
        LabeledContent {
            TextField("Label", text: model.label(entry), prompt: Text(entry.name))
                .labelsHidden()
                .frame(width: 200)
                .focused($focusedLabel, equals: entry.id)
                .onSubmit { model.commit() }
        } label: {
            Toggle(isOn: model.isVisible(entry)) {
                Text(entry.name)
                Text(entry.keys)
            }
            .toggleStyle(.checkbox)
        }
    }
}
