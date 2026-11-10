@testable import OmniKeysCore
import Testing

struct ColumnLayoutTests {
    @Test func columnCandidates() {
        #expect(ColumnLayout.candidates(configured: 0) == [2, 3, 4])
        #expect(ColumnLayout.candidates(configured: 3) == [3])
    }

    @Test func flowKeepsOrderAndBalances() {
        let columns = ColumnLayout.flow([3, 1, 1, 1, 2, 2], columns: 3) { Double($0) }
        #expect(columns == [[3], [1, 1, 1], [2, 2]])
    }

    @Test func flowNeverMakesEmptyColumns() {
        #expect(ColumnLayout.flow([5, 1], columns: 4) { Double($0) } == [[5], [1]])
        #expect(ColumnLayout.flow([Int](), columns: 3) { Double($0) }.isEmpty)
    }
}
