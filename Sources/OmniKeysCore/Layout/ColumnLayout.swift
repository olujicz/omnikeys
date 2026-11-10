public enum ColumnLayout {
    /// Column counts to try: the configured one, or 2–4 when automatic (0).
    public static func candidates(configured: Int) -> [Int] {
        configured > 0 ? [configured] : [2, 3, 4]
    }

    /// Splits items into `min(columns, items.count)` non-empty consecutive runs, keeping their order
    /// (read top to bottom, then left to right) and making the tallest column as short as possible.
    public static func flow<Item>(_ items: [Item], columns: Int, weight: (Item) -> Double) -> [[Item]] {
        guard !items.isEmpty else { return [] }
        // total[i]: summed weight of the first i items, so a run's weight is total[end] - total[start].
        let total = items.reduce(into: [0.0]) { $0.append($0[$0.count - 1] + weight($1)) }
        let count = min(max(columns, 1), items.count)
        // best[k][i]: smallest tallest-column height for the first i items in k columns, and where the last starts.
        var best = Array(
            repeating: Array(repeating: (height: Double.infinity, start: 0), count: items.count + 1),
            count: count + 1
        )
        best[0][0] = (0, 0)
        for column in 1 ... count {
            for end in column ... items.count {
                for start in column - 1 ..< end where best[column - 1][start].height < .infinity {
                    let height = max(best[column - 1][start].height, total[end] - total[start])
                    if height < best[column][end].height {
                        best[column][end] = (height, start)
                    }
                }
            }
        }
        var result: [[Item]] = []
        var end = items.count
        for column in stride(from: count, to: 0, by: -1) {
            let start = best[column][end].start
            result.append(Array(items[start ..< end]))
            end = start
        }
        return result.reversed()
    }
}
