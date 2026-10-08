public enum ColumnLayout {
    /// 0 means automatic: 2 columns when the layout is narrower than 1150 points, otherwise 3.
    public static func columnCount(configured: Int, layoutWidth: Double) -> Int {
        configured > 0 ? configured : (layoutWidth < 1150 ? 2 : 3)
    }

    /// Spreads cards over columns, always adding to the shortest one (rows + 2 for the card heading).
    public static func distribute(_ groups: [ShortcutGroup], columns: Int) -> [[ShortcutGroup]] {
        let count = max(columns, 1)
        var result = Array(repeating: [ShortcutGroup](), count: count)
        var heights = Array(repeating: 0, count: count)
        for group in groups {
            let shortest = heights.indices.min { heights[$0] < heights[$1] } ?? 0
            result[shortest].append(group)
            heights[shortest] += group.rows.count + 2
        }
        return result
    }
}
