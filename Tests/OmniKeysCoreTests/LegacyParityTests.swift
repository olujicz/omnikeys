@testable import OmniKeysCore
import Testing

/// legacy-golden.txt was produced by the original single-file app (Task 1). This must never change by accident.
struct LegacyParityTests {
    @Test func matchesLegacyOutputForFixture() throws {
        let settings = try OmniWMSettings.parse(Fixture.text("settings.toml"), appName: AppNames.fallback(for:))
        var out = ""
        for group in GroupBuilder.build(hotkeys: settings.hotkeys, config: Config()) {
            out += "## \(group.title)\n"
            for row in group.rows {
                out += "\(row.keys)\t\(row.action)\n"
            }
        }
        out += "## Workspaces\n"
        for workspace in settings.workspaces {
            out += "\(workspace.name)\t\(workspace.displayName)\t\(workspace.display)\t\(workspace.apps.joined(separator: ","))\n"
        }
        out += "## Floating\n\(settings.floating.joined(separator: ","))\n"
        out += "## Hyper\n\(settings.hyperModifiers)\n"
        #expect(try out == Fixture.text("legacy-golden.txt"))
    }
}
