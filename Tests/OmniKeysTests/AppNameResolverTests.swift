@testable import OmniKeys
import Testing

@MainActor
struct AppNameResolverTests {
    @Test func installedAppUsesItsName() {
        #expect(AppNameResolver.name(for: "com.apple.finder") == "Finder")
    }

    @Test func missingAppIsLeftOffUnlessAsked() {
        let missing = "org.omnikeys.tests.notInstalled"
        #expect(AppNameResolver.name(for: missing).isEmpty)
        #expect(AppNameResolver.name(for: missing, includeMissing: true) == "NotInstalled")
    }
}
