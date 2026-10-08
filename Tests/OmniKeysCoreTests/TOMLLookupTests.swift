@testable import OmniKeysCore
import Testing
import TOMLDecoder

struct TOMLLookupTests {
    let table: TOMLTable

    init() throws {
        table = try TOMLTable(source: """
        name = "one"
        count = 3

        [general]
        mode = "fast"

        [[items]]
        id = "a"

        [[items]]
        id = "b"
        """)
    }

    @Test func optionalStringReturnsValue() {
        #expect(table.optionalString("name") == "one")
    }

    @Test func optionalStringIsNilWhenMissingOrWrongType() {
        #expect(table.optionalString("missing") == nil)
        #expect(table.optionalString("count") == nil)
    }

    @Test func optionalTableReturnsNestedTable() {
        #expect(table.optionalTable("general")?.optionalString("mode") == "fast")
        #expect(table.optionalTable("name") == nil)
    }

    @Test func tablesReadsArrayOfTablesInOrder() {
        #expect(table.tables("items").compactMap { $0.optionalString("id") } == ["a", "b"])
        #expect(table.tables("missing").isEmpty)
    }

    @Test func fixtureIsBundled() throws {
        #expect(try Fixture.text("settings.toml").contains("[[hotkeys]]"))
    }
}
