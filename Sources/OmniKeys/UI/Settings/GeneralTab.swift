import OmniKeysCore
import SwiftUI

struct GeneralTab: View {
    @Environment(SettingsModel.self) private var model

    var body: some View {
        Form {
            GeneralIssuesSection()
            Section {
                LabeledContent("Modifiers") {
                    HStack {
                        ForEach(HotkeyFields.modifierNames, id: \.self) { name in
                            Toggle(Self.modifierTitle(name), isOn: model.modifier(name))
                                .toggleStyle(.checkbox)
                                .disabled(model.isOnlyModifier(name))
                        }
                    }
                }
                Picker("Key", selection: model.hotkeyKey) {
                    ForEach(HotkeyParser.supportedKeys, id: \.self) { key in
                        Text(Self.keyTitle(key)).tag(key)
                    }
                }
            } header: {
                Text("Hotkey")
            } footer: {
                IssueFooter(
                    issues: model.issues(for: "hotkey"),
                    help: "Opens and closes the cheat sheet. Hyper is the set of modifiers OmniWM's Hyper key sends."
                )
            }
            .disabled(!model.isEditable)
            Section {
                Group {
                    Picker("Open on", selection: model.binding(\.screen)) {
                        Text("Screen with the focused window").tag(ScreenChoice.focused)
                        Text("Screen under the pointer").tag(ScreenChoice.mouse)
                        Text("Main screen").tag(ScreenChoice.main)
                    }
                    Toggle("Close when clicking outside", isOn: model.binding(\.closeOnClickOutside))
                    Toggle("Show menu-bar icon", isOn: model.binding(\.showMenuBarIcon))
                }
                .disabled(!model.isEditable)
                // Launch at login is not stored in config.toml, so it stays usable.
                Toggle("Launch at login", isOn: model.launchAtLoginEnabled)
            } footer: {
                IssueFooter(
                    issues: ["screen", "closeOnClickOutside", "showMenuBarIcon"].flatMap(model.issues(for:)),
                    help: model.launchAtLogin == .requiresApproval
                        ? "Approve OmniKeys in System Settings › General › Login Items."
                        : "Without the menu-bar icon, open OmniKeys from Finder or Spotlight to show the sheet."
                )
            }
        }
        .formStyle(.grouped)
        .frame(width: 520, height: 440)
    }

    private static func modifierTitle(_ name: String) -> String {
        name == "Hyper" ? "✦ Hyper" : "\(OmniKeysCore.Binding.glyphs[name] ?? "") \(name)"
    }

    private static func keyTitle(_ key: String) -> String {
        guard let glyph = OmniKeysCore.Binding.glyphs[key], glyph != key else { return key }
        return "\(glyph)  \(key)"
    }
}
