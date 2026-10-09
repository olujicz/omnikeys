import OmniKeysCore
import SwiftUI

struct SizeTab: View {
    @Environment(SettingsModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Form {
            Section {
                Picker("Width", selection: $model.widthIsCustom) {
                    Text("Automatic").tag(false)
                    Text("Custom").tag(true)
                }
                if model.widthIsCustom {
                    percentSlider("Custom width", value: model.widthFraction, in: 0.3 ... 1, step: 0.01)
                }
                percentSlider(
                    "Maximum height",
                    value: model.number(\.maxHeight, in: 0.3 ... 1, step: 0.01, draft: true),
                    in: 0.3 ... 1,
                    step: 0.01
                )
            } footer: {
                IssueFooter(
                    issues: ["width", "maxHeight"].flatMap(model.issues(for:)),
                    help: "Automatic uses 75% of the screen width, or 95% on screens narrower than 45 cm. "
                        + "Content taller than the maximum height is scaled down to fit."
                )
            }
            Section {
                percentSlider(
                    "Text size",
                    value: model.number(\.textSize, in: 0.5 ... 3, step: 0.05, draft: true),
                    in: 0.5 ... 3,
                    step: 0.05
                )
                Toggle("Adapt to screen density", isOn: $model.adaptsToDensity)
                if model.adaptsToDensity {
                    LabeledContent("Reference density") {
                        HStack {
                            TextField(
                                "Reference density",
                                value: model.number(\.referenceDensity, in: 40 ... 300, step: 1),
                                format: .number
                            )
                            .labelsHidden()
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                            Stepper(
                                "Reference density",
                                value: model.number(\.referenceDensity, in: 40 ... 300, step: 1),
                                in: 40 ... 300
                            )
                            .labelsHidden()
                        }
                    }
                }
            } footer: {
                IssueFooter(
                    issues: ["textSize", "density", "referenceDensity"].flatMap(model.issues(for:)),
                    help: "100% is the default size. With density on, text appears at that size on screens of the "
                        + "reference density (points per inch) and bigger on denser ones. For reference: 27\" 1080p ≈ 81, "
                        + "27\" 4K at “looks like 1440p” ≈ 109, MacBook Pro built-in ≈ 127. Lower it for bigger text."
                )
            }
            Section {
                Picker("Columns", selection: model.binding(\.columns)) {
                    Text("Automatic").tag(0)
                    ForEach(1 ... 4, id: \.self) { Text("\($0)").tag($0) }
                }
            } footer: {
                IssueFooter(
                    issues: model.issues(for: "columns"),
                    help: "Automatic uses 2 on narrow screens, 3 otherwise."
                )
            }
        }
        .formStyle(.grouped)
        .frame(width: 520, height: 520)
    }

    private func percentSlider(
        _ title: String,
        value: SwiftUI.Binding<Double>,
        in range: ClosedRange<Double>,
        step: Double
    ) -> some View {
        LabeledContent(title) {
            HStack {
                Slider(value: value, in: range, step: step) {
                    Text(title)
                } onEditingChanged: { editing in
                    if !editing {
                        model.commit()
                    }
                }
                .labelsHidden()
                Text(value.wrappedValue, format: .percent.precision(.fractionLength(0)))
                    .monospacedDigit()
                    .frame(width: 44, alignment: .trailing)
            }
        }
    }
}
