import Foundation

/// Reads files from Tests/OmniKeysCoreTests/Fixtures (copied into the test bundle).
enum Fixture {
    private final class Token {}

    struct Missing: Error, CustomStringConvertible {
        let name: String
        var description: String {
            "Fixture \(name) is not in the test bundle"
        }
    }

    static func text(_ name: String) throws -> String {
        guard let url = Bundle(for: Token.self).url(forResource: name, withExtension: nil) else {
            throw Missing(name: name)
        }
        return try String(contentsOf: url, encoding: .utf8)
    }
}
