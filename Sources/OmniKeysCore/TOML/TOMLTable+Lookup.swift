import TOMLDecoder

/// Lenient lookups for reading files we don't own: a missing key or a value of the wrong type reads as nil.
extension TOMLTable {
    func optionalString(_ key: String) -> String? {
        contains(key: key) ? try? string(forKey: key) : nil
    }

    func optionalTable(_ key: String) -> TOMLTable? {
        contains(key: key) ? try? table(forKey: key) : nil
    }

    /// Every table in an array of tables (`[[key]]`), in file order; empty when missing.
    func tables(_ key: String) -> [TOMLTable] {
        guard contains(key: key), let array = try? array(forKey: key) else { return [] }
        return (0 ..< array.count).compactMap { try? array.table(atIndex: $0) }
    }
}
