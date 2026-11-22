import Foundation

/// Search for the cheat sheet. A query is split into terms that must all match. Shortcuts match by
/// group, action or key, where a collapsed series ("Hyper 1–9") matches each of its keys on their own
/// ("hyper+2"); workspaces match by name, monitor or app.
public extension SheetModel {
    /// This model with only what matches `query`; the whole model for an empty query.
    func filtered(matching query: String) -> SheetModel {
        guard !SheetSearch.terms(query).isEmpty else { return self }
        return SheetModel(
            groups: shortcutGroups(matching: query),
            workspaces: workspaces(matching: query),
            floating: floating(matching: query),
            hyperGlyphs: hyperGlyphs
        )
    }

    /// Rows whose label, group or keys match every term. The last term also matches key names by
    /// prefix, so results stay put while a key name ("hyp…", "shi…") is being typed.
    func shortcutGroups(matching query: String) -> [ShortcutGroup] {
        let terms = SheetSearch.terms(query)
        guard !terms.isEmpty else { return groups }
        // "hyper+2" names a chord: match keys only, not labels that happen to contain "2", and only
        // bindings whose every modifier the chord names.
        let isChord = query.contains("+")
        // A pasted Hyper chord ("⌃⌥⌘2") also reads as "hyper 2", since rows show Hyper as one cap.
        let readings = [terms] + [SheetSearch.hyperReading(of: terms, hyperGlyphs: hyperGlyphs)].compactMap(\.self)

        return groups.compactMap { group in
            let rows = group.rows.filter { row in
                let label = SheetSearch.Text(SheetSearch.fold("\(group.title) \(row.action)"))
                if !isChord, terms.allSatisfy(label.matches) {
                    return true
                }
                // Match the key terms against one binding at a time, even when the row shows a series.
                let bindings = SheetSearch.bindings(of: row)
                return readings.contains { terms in
                    bindings.contains { binding in
                        SheetSearch.matches(terms, binding: binding, label: isChord ? nil : label)
                            && (!isChord || SheetSearch.namesEveryModifier(of: binding, terms: terms))
                    }
                }
            }
            return rows.isEmpty ? nil : ShortcutGroup(title: group.title, rows: rows)
        }
    }

    /// Workspaces whose name, display name, monitor or apps match every term; "workspaces" (the card's
    /// title) matches them all, as a group title matches its shortcuts.
    func workspaces(matching query: String) -> [OmniWMWorkspace] {
        let terms = SheetSearch.terms(query)
        guard !terms.isEmpty else { return workspaces }
        guard !query.contains("+") else { return [] }
        return workspaces.filter { workspace in
            let fields = ["Workspaces", workspace.name, workspace.displayName, workspace.display] + workspace.apps
            let text = SheetSearch.Text(SheetSearch.fold(fields.joined(separator: " ")))
            return terms.allSatisfy(text.matches)
        }
    }

    /// Always-floating apps whose name matches every term.
    func floating(matching query: String) -> [String] {
        let terms = SheetSearch.terms(query)
        guard !terms.isEmpty else { return floating }
        guard !query.contains("+") else { return [] }
        // "workspaces" names the card the floating apps are listed on, as it does for the workspaces.
        return floating.filter { app in
            terms.allSatisfy(SheetSearch.Text(SheetSearch.fold("Workspaces \(app)")).matches)
        }
    }
}

enum SheetSearch {
    /// Folded text to search in. Single-character terms match whole words; longer ones match anywhere.
    struct Text {
        let text: String
        let words: [Substring]

        init(_ text: String) {
            self.text = text
            words = text.split { !$0.isLetter && !$0.isNumber }
        }

        func matches(_ term: String) -> Bool {
            term.count == 1 ? words.contains(Substring(term)) : text.contains(term)
        }
    }

    static let modifierAliases = ["cmd": "command", "ctrl": "control", "opt": "option", "alt": "option"]
    private static let glyphNames = Dictionary(Binding.glyphs.map { ($1, $0) }) { first, _ in first }
    private static let arrows: Set<Character> = ["←", "↓", "↑", "→"]

    /// Query terms: case- and accent-insensitive, split on spaces and "+", with modifier and arrow
    /// glyphs pulled apart so a pasted "⌘⇧K" becomes three terms.
    static func terms(_ value: String) -> [String] {
        let separated = value.reduce(into: "") { result, character in
            if "⌃⌥⇧⌘←↓↑→".contains(character) {
                result += " \(character) "
            } else {
                result.append(character)
            }
        }
        // The Minus key shows as "−"; a typed "-" means it.
        return fold(separated).split { $0.isWhitespace || $0 == "+" }.map { $0 == "-" ? "−" : String($0) }
    }

    /// `terms` with a complete set of Hyper's modifier glyphs replaced by "hyper"; nil when they
    /// don't hold all of them.
    static func hyperReading(of terms: [String], hyperGlyphs: String) -> [String]? {
        let glyphs = hyperGlyphs.map(String.init)
        guard glyphs.count > 1, let first = terms.firstIndex(where: glyphs.contains) else { return nil }
        var rest = terms
        for glyph in glyphs {
            guard let index = rest.firstIndex(of: glyph) else { return nil }
            rest.remove(at: index)
        }
        rest.insert("hyper", at: min(first, rest.count))
        return rest
    }

    static func fold(_ value: String) -> String {
        value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    /// One single binding a row stands for, as search terms.
    struct KeyBinding {
        /// Every cap's terms: the glyphs and their names ("⇧", "shift").
        let terms: [String]
        /// Each modifier's terms on their own.
        let modifiers: [[String]]
    }

    /// Each single binding a row stands for: "Hyper ⇧ 1–3" gives one per number.
    static func bindings(of row: ShortcutRow) -> [KeyBinding] {
        let modifiers = row.modifiers.map(names)
        // Rows built by GroupBuilder list their series' keys; others are read from the shown key.
        let keys = row.seriesKeys == [row.key] ? keys(in: row.key) : row.seriesKeys
        return keys.map { KeyBinding(terms: modifiers.flatMap(\.self) + names($0), modifiers: modifiers) }
    }

    /// Every term matches the binding's keys, or the row's label when one is given.
    static func matches(_ terms: [String], binding: KeyBinding, label: Text?) -> Bool {
        terms.enumerated().allSatisfy { index, term in
            keyMatches(term, keys: binding.terms, allowsPrefix: index == terms.count - 1)
                || label?.matches(term) == true
        }
    }

    /// The terms name each of the binding's modifiers, so "hyper+2" isn't taken for Hyper ⇧ 2.
    static func namesEveryModifier(of binding: KeyBinding, terms: [String]) -> Bool {
        binding.modifiers.allSatisfy { modifier in
            terms.enumerated().contains { index, term in
                keyMatches(term, keys: modifier, allowsPrefix: index == terms.count - 1)
            }
        }
    }

    /// "1–3" -> 1, 2, 3; "H/J/K/L" -> H, J, K, L; "←→" -> ←, →; anything else as is.
    static func keys(in key: String) -> [String] {
        let ends = key.components(separatedBy: "–")
        if ends.count == 2 {
            if let first = Int(ends[0]), let last = Int(ends[1]), first <= last, last - first < 100 {
                return (first ... last).map(String.init)
            }
            return ends
        }
        if key.count > 1, key.contains("/") {
            return key.components(separatedBy: "/").filter { !$0.isEmpty }
        }
        if key.count > 1, key.allSatisfy(arrows.contains) {
            return key.map(String.init)
        }
        return [key]
    }

    /// A cap's own terms plus its name's: "⇧" -> ⇧, shift; "←" -> ←, left, arrow; "Hyper" -> hyper.
    private static func names(_ cap: String) -> [String] {
        terms(cap) + (glyphNames[cap].map(terms) ?? [])
    }

    static func keyMatches(_ term: String, keys: [String], allowsPrefix: Bool) -> Bool {
        if keys.contains(modifierAliases[term] ?? term) {
            return true
        }
        // A single character is usually a key name ("h"), so only longer terms match by prefix.
        guard allowsPrefix, term.count > 1 else { return false }
        return keys.contains { $0.hasPrefix(term) }
            || modifierAliases.contains { $0.key.hasPrefix(term) && keys.contains($0.value) }
    }
}
