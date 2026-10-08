@testable import OmniKeysCore
import Testing

struct ColumnLayoutTests {
    private func group(_ title: String, rows: Int) -> ShortcutGroup {
        ShortcutGroup(title: title, rows: (0 ..< rows).map { ShortcutRow(keys: "K\($0)", action: "A\($0)") })
    }

    @Test func automaticColumnCount() {
        #expect(ColumnLayout.columnCount(configured: 0, layoutWidth: 1000) == 2)
        #expect(ColumnLayout.columnCount(configured: 0, layoutWidth: 1200) == 3)
        #expect(ColumnLayout.columnCount(configured: 4, layoutWidth: 500) == 4)
    }

    @Test func addsEachCardToTheShortestColumn() {
        let groups = [group("a", rows: 5), group("b", rows: 1), group("c", rows: 1), group("d", rows: 1)]
        #expect(ColumnLayout.distribute(groups, columns: 2).map { $0.map(\.title) } == [["a"], ["b", "c", "d"]])
    }

    @Test func zeroColumnsMeansOne() {
        #expect(ColumnLayout.distribute([group("a", rows: 1)], columns: 0).count == 1)
    }
}
