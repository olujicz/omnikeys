import OmniKeysCore
import SwiftUI

struct AppearanceTab: View {
    @Environment(SettingsModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Form {
            Section {
                Picker("Theme", selection: model.binding(\.theme)) {
                    Text("Dark").tag(Theme.dark)
                    Text("Light").tag(Theme.light)
                    Text("System").tag(Theme.system)
                }
                LabeledContent("Background opacity") {
                    HStack {
                        Slider(
                            value: model.number(\.backgroundOpacity, in: 0 ... 1, step: 0.01, draft: true),
                            in: 0 ... 1
                        ) {
                            Text("Background opacity")
                        } minimumValueLabel: {
                            Text("Glass")
                        } maximumValueLabel: {
                            Text("Solid")
                        } onEditingChanged: { editing in
                            if !editing {
                                model.commit()
                            }
                        }
                        .labelsHidden()
                    }
                }
            } footer: {
                IssueFooter(issues: ["theme", "backgroundOpacity"].flatMap(model.issues(for:)))
            }
            Section {
                Picker("Accent colour", selection: $model.accentIsCustom) {
                    Text("System").tag(false)
                    Text("Custom").tag(true)
                }
                if model.accentIsCustom {
                    ColorPicker("Custom colour", selection: $model.accentColor, supportsOpacity: false)
                }
            } footer: {
                IssueFooter(
                    issues: model.issues(for: "accent"),
                    help: "Used for section headings and the ✦ Hyper key cap."
                )
            }
        }
        .formStyle(.grouped)
        .frame(width: 520, height: 320)
    }
}
