// swiftlint:disable all
// swiftformat:disable all
// OmniKeys — floating OmniWM cheat sheet.
// Toggle: Hyper+/ (configurable). Close: same key, Esc, or click elsewhere. ⌘, opens the settings file.
// Shortcuts are read live from OmniWM's own ~/.config/omniwm/settings.toml every time the panel opens.
// Look and behaviour come from ~/.config/omniwm/omnikeys.toml (created with defaults on first run).

import AppKit
import Carbon.HIToolbox
import SwiftUI

let configDir = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".config/omniwm")
let settingsFile = configDir.appendingPathComponent("settings.toml")
let configFile = configDir.appendingPathComponent("omnikeys.toml")

// MARK: - omnikeys.toml (our own settings)

let defaultConfig = """
# ─────────────────────────────────────────────────────────────────────────────
#  OmniKeys — settings for the OmniWM cheat sheet
# ─────────────────────────────────────────────────────────────────────────────
#  • Every option is listed below with its default value.
#  • Changes apply the next time you open the sheet; a new hotkey works a few
#    seconds after saving. No restart or rebuild needed.
#  • Press ⌘, while the sheet is open to edit this file.
#  • Delete this file to get the defaults back (it is recreated automatically).
#  • The shortcuts themselves are read from OmniWM's settings.toml, so they are
#    always current. This file only controls how the sheet looks and behaves.

# ── Opening ──────────────────────────────────────────────────────────────────

# Shortcut that opens and closes the sheet, written the way OmniWM writes it.
# "Hyper" = the Hyper modifiers set in OmniWM (Caps Lock on this Mac).
# Modifiers: Hyper, Control, Option, Shift, Command.
# Keys: A–Z, 0–9, F1–F12, Slash, Period, Comma, Semicolon, Quote, Backslash,
#       Grave, Minus, Equal, Space, Return, Tab, Escape.
# Pick a combination OmniWM does not already use.
# Default: "Hyper+Slash"
hotkey = "Hyper+Slash"

# Which screen the sheet opens on.
#   "focused" – the screen with your active window (asks OmniWM)
#   "mouse"   – the screen under the mouse pointer
#   "main"    – the screen with the menu bar
# Default: "focused"
screen = "focused"

# Close the sheet when you click anywhere outside it (Esc and the hotkey
# always close it).
# Default: true
closeOnClickOutside = true

# ── Size ─────────────────────────────────────────────────────────────────────

# Width of the sheet as a fraction of the screen width. Range 0.3 – 1.0,
# or "auto": 0.75 on large screens, 0.95 on small ones (under 45 cm wide,
# e.g. a laptop), so the text can stay big enough to read.
# Default: "auto"
width = "auto"

# Maximum height as a fraction of the screen height. Range 0.3 – 1.0.
# If the content is taller, the whole sheet scales down to fit.
# Default: 0.94
maxHeight = 0.94

# Text size multiplier. 1.0 = normal, 1.2 = 20% bigger. Range 0.5 – 3.0.
# It still shrinks automatically if the sheet would not fit the screen.
# Default: 1.0
textSize = 1.0

# Adapt text size to each screen's pixel density, so the sheet is about
# equally readable on a laptop and on an external monitor.
#   "auto" – measure the screen and scale (denser screens get bigger text)
#   "off"  – same point size everywhere (only textSize applies)
# Default: "auto"
density = "auto"

# Screen density (points per inch) at which text is shown at normal size
# when density = "auto". Lower it to make text bigger everywhere, raise it
# for smaller text. For reference: 27" 1080p monitor ≈ 81, 27" 4K at
# "looks like 1440p" ≈ 109, MacBook Pro built-in ≈ 127.
# Default: 85
referenceDensity = 85

# Number of card columns. 0 = automatic (2 on narrow screens, 3 otherwise),
# or a fixed 1, 2, 3 or 4.
# Default: 0
columns = 0

# ── Look ─────────────────────────────────────────────────────────────────────

# Colour theme: "dark", "light", or "system" (follow macOS appearance).
# Default: "dark"
theme = "dark"

# How solid the background is behind the blur.
# 0.0 = see-through glass, 1.0 = fully solid. Range 0.0 – 1.0.
# Default: 0.45
backgroundOpacity = 0.45

# Colour of section headings and the ✦ Hyper key cap.
# "system" = your macOS accent colour, or a hex colour such as "#4C8DFF".
# Default: "system"
accent = "system"

# ── Content ──────────────────────────────────────────────────────────────────

# Show the Workspaces card (which apps open on which workspace and screen).
# Default: true
showWorkspaces = true

# Show the "Always floating" line under the Workspaces card.
# Default: true
showFloating = true

# Hide shortcuts from the sheet, using OmniWM action ids from settings.toml.
# Use the part before the dot to hide a whole set ("switchWorkspace" hides
# all of Hyper+1–9), or the full id to hide one ("switchWorkspace.next").
# Example: hide = ["toggleScratchpad", "focusWindowInColumn"]
# Default: []
hide = []

# Rename shortcuts on the sheet, using OmniWM action ids (same rules as hide).
# Uncomment a line or add your own:  actionId = "Your label"
[labels]
# toggleQuakeTerminal = "Drop-down terminal"
# switchWorkspace = "Workspace"
# focus = "Focus"
"""

struct Config {
    var hotkey = "Hyper+Slash"
    var screen = "focused"
    var width: CGFloat? = nil  // nil = auto
    var density = "auto"
    var referenceDensity: CGFloat = 85
    var maxHeight: CGFloat = 0.94
    var textSize: CGFloat = 1.0
    var columns = 0
    var theme = "dark"
    var backgroundOpacity: Double = 0.45
    var accent = "system"
    var showWorkspaces = true
    var showFloating = true
    var closeOnClickOutside = true
    var hide: [String] = []
    var labels: [String: String] = [:]

    var accentColor: Color {
        guard accent.hasPrefix("#"), let v = UInt32(accent.dropFirst(), radix: 16), accent.count == 7 else { return .accentColor }
        return Color(red: Double(v >> 16 & 0xFF) / 255, green: Double(v >> 8 & 0xFF) / 255, blue: Double(v & 0xFF) / 255)
    }
    var colorScheme: ColorScheme? { theme == "light" ? .light : theme == "dark" ? .dark : nil }
    var appearance: NSAppearance? {
        theme == "light" ? NSAppearance(named: .aqua) : theme == "dark" ? NSAppearance(named: .darkAqua) : nil
    }
    var background: Color {
        switch theme {
        case "light": return Color.white.opacity(backgroundOpacity)
        case "dark": return Color.black.opacity(backgroundOpacity)
        default: return Color(nsColor: .windowBackgroundColor).opacity(backgroundOpacity)
        }
    }
}

/// Splits `key = value` and returns the raw value without quotes or a trailing comment.
func tomlValue(_ s: Substring) -> String {
    let v = s.trimmingCharacters(in: .whitespaces)
    if v.hasPrefix("\""), let end = v.dropFirst().firstIndex(of: "\"") { return String(v[v.index(after: v.startIndex)..<end]) }
    if v.hasPrefix("["), let end = v.firstIndex(of: "]") { return String(v[...end]) }
    return (v.split(separator: "#", maxSplits: 1).first.map(String.init) ?? v).trimmingCharacters(in: .whitespaces)
}

func loadConfig() -> Config {
    if !FileManager.default.fileExists(atPath: configFile.path) {
        try? defaultConfig.write(to: configFile, atomically: true, encoding: .utf8)
    }
    var c = Config()
    guard let text = try? String(contentsOf: configFile, encoding: .utf8) else { return c }
    var table = ""
    for raw in text.components(separatedBy: .newlines) {
        let line = raw.trimmingCharacters(in: .whitespaces)
        if line.isEmpty || line.hasPrefix("#") { continue }
        if line.hasPrefix("[") { table = line; continue }
        guard let eq = line.firstIndex(of: "=") else { continue }
        let key = line[..<eq].trimmingCharacters(in: .whitespaces).trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        let val = tomlValue(line[line.index(after: eq)...])
        let num = Double(val).map { CGFloat($0) }
        if table == "[labels]" { c.labels[key] = val; continue }
        switch key {
        case "hotkey": c.hotkey = val
        case "screen": c.screen = val
        case "width": c.width = num.map { min(max($0, 0.3), 1) }
        case "density": c.density = val
        case "referenceDensity": c.referenceDensity = min(max(num ?? c.referenceDensity, 40), 300)
        case "maxHeight": c.maxHeight = min(max(num ?? c.maxHeight, 0.3), 1)
        case "textSize": c.textSize = min(max(num ?? c.textSize, 0.5), 3)
        case "columns": c.columns = Int(val) ?? 0
        case "theme": c.theme = val
        case "backgroundOpacity": c.backgroundOpacity = min(max(Double(val) ?? c.backgroundOpacity, 0), 1)
        case "accent": c.accent = val
        case "showWorkspaces": c.showWorkspaces = val == "true"
        case "showFloating": c.showFloating = val == "true"
        case "closeOnClickOutside": c.closeOnClickOutside = val == "true"
        case "hide":
            c.hide = val.trimmingCharacters(in: CharacterSet(charactersIn: "[]")).split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces).trimmingCharacters(in: CharacterSet(charactersIn: "\"")) }
                .filter { !$0.isEmpty }
        default: break
        }
    }
    return c
}

var config = Config()

// MARK: - settings.toml reading (only the bits we need)

struct Hotkey { let id: String; let binding: String }
struct Workspace { var name = ""; var displayName = ""; var display = ""; var apps: [String] = [] }

struct Settings {
    var hotkeys: [Hotkey] = []
    var workspaces: [Workspace] = []
    var floating: [String] = []
    var hyperModifiers = "Control+Option+Command"
}

func appName(_ bundleID: String) -> String {
    if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
        return FileManager.default.displayName(atPath: url.path).replacingOccurrences(of: ".app", with: "")
    }
    let last = bundleID.split(separator: ".").last.map(String.init) ?? bundleID
    return last.prefix(1).uppercased() + last.dropFirst()
}

func readSettings() -> Settings {
    guard let text = try? String(contentsOf: settingsFile, encoding: .utf8) else { return Settings() }
    var s = Settings()
    var table = ""
    var kv: [String: String] = [:]
    var rules: [[String: String]] = []

    func endTable() {
        switch table {
        case "[[hotkeys]]":
            if let id = kv["id"], let b = kv["binding"], b != "Unassigned" { s.hotkeys.append(Hotkey(id: id, binding: b)) }
        case "[[appRules]]":
            rules.append(kv)
        default: break
        }
        kv = [:]
    }
    for raw in text.components(separatedBy: .newlines) {
        let line = raw.trimmingCharacters(in: .whitespaces)
        if line.hasPrefix("[") {
            endTable()
            table = line
            if line == "[[workspaces]]" { s.workspaces.append(Workspace()) }
            continue
        }
        guard let eq = line.firstIndex(of: "=") else { continue }
        let key = line[..<eq].trimmingCharacters(in: .whitespaces)
        var val = line[line.index(after: eq)...].trimmingCharacters(in: .whitespaces)
        if val.hasPrefix("\"") && val.hasSuffix("\"") && val.count >= 2 { val = String(val.dropFirst().dropLast()) }
        kv[key] = val
        if table == "[general]" && key == "hyperKeyModifiers" { s.hyperModifiers = val }
        if table.hasPrefix("[workspaces") || table == "[[workspaces]]", !s.workspaces.isEmpty {
            let i = s.workspaces.count - 1
            switch (table, key) {
            case ("[[workspaces]]", "name"): s.workspaces[i].name = val
            case ("[[workspaces]]", "displayName"): s.workspaces[i].displayName = val
            case ("[workspaces.monitorAssignment]", "type") where val != "specificDisplay": s.workspaces[i].display = val
            case ("[workspaces.monitorAssignment.output]", "name"): s.workspaces[i].display = val
            default: break
            }
        }
    }
    endTable()
    for r in rules {
        guard let bid = r["bundleId"] else { continue }
        if let ws = r["assignToWorkspace"], let i = s.workspaces.firstIndex(where: { $0.name == ws }) {
            let name = appName(bid)
            if !s.workspaces[i].apps.contains(name) { s.workspaces[i].apps.append(name) }
        }
        if r["layout"] == "float" { s.floating.append(appName(bid)) }
    }
    return s
}

// MARK: - Turning hotkeys into readable rows

struct Row: Identifiable { let id = UUID(); let keys: String; let action: String }
struct Group: Identifiable { let id = UUID(); let title: String; let rows: [Row] }

let keyNames: [String: String] = [
    "Shift": "⇧", "Option": "⌥", "Command": "⌘", "Control": "⌃",
    "Left Arrow": "←", "Right Arrow": "→", "Up Arrow": "↑", "Down Arrow": "↓",
    "Grave": "`", "Comma": ",", "Period": ".", "Minus": "−", "Equal": "=", "Slash": "/",
    "Backslash": "\\", "Semicolon": ";", "Quote": "'", "Return": "↩", "Tab": "⇥",
    "Page Up": "PgUp", "Page Down": "PgDn", "Escape": "Esc", "Delete": "⌫",
]

/// "Hyper+Shift+Left Arrow" -> (["Hyper", "⇧"], "←")
func splitBinding(_ b: String) -> (mods: [String], key: String) {
    let parts = b.components(separatedBy: "+")
    let key = parts.last ?? b
    return (parts.dropLast().map { keyNames[$0] ?? $0 }, keyNames[key] ?? key)
}

/// Friendly names for OmniWM action ids; anything missing falls back to the id split into words.
let actionNames: [String: String] = [
    "focus": "Focus window", "move": "Move window",
    "focusPrevious": "Previously focused window",
    "focusColumnFirst": "First column", "focusColumnLast": "Last column",
    "focusColumn": "Focus column", "focusWindowInColumn": "Tab / window in column",
    "moveColumnToFirst": "Move column to first", "moveColumnToLast": "Move column to last",
    "consumeWindowIntoColumn": "Pull window into column", "expelWindowFromColumn": "Push window out of column",
    "centerColumn": "Center column",
    "switchWorkspace": "Go to workspace", "moveToWorkspace": "Send window to workspace",
    "workspaceBackAndForth": "Last workspace on this screen",
    "focusMonitorPrevious": "Previous monitor", "focusMonitorNext": "Next monitor", "focusMonitorLast": "Last workspace (back & forth)",
    "moveWindowToMonitor": "Send window to monitor",
    "moveColumnToWorkspaceUp": "Send column to workspace above", "moveColumnToWorkspaceDown": "Send column to workspace below",
    "toggleFullscreen": "Fullscreen", "toggleNativeFullscreen": "Native fullscreen",
    "toggleContainerFullPrimarySpan": "Maximize column", "expandContainerToAvailablePrimarySpan": "Fill free space",
    "cycleSizeForward": "Cycle column width", "cycleSizeBackward": "Cycle column width back",
    "setContainerPrimarySpan": "Column width", "setWindowSecondarySpan": "Window height",
    "balanceSizes": "Balance sizes", "toggleColumnTabbed": "Tabbed column",
    "toggleFocusedWindowFloating": "Float / tile window", "toggleFloatingFocus": "Focus floating ⇄ tiled",
    "raiseAllFloatingWindows": "Raise floating windows", "closeFocusedWindow": "Close window",
    "toggleScratchpad": "Show scratchpad", "assignFocusedWindowToScratchpad": "Put window in scratchpad",
    "openCommandPalette": "Command palette", "toggleOverview": "Overview", "openMenuAnywhere": "App menu anywhere",
    "toggleHiddenBarPanel": "Hidden menu-bar icons", "toggleQuakeTerminal": "Quake terminal",
    "toggleWorkspaceLayout": "Switch layout niri ⇄ dwindle",
    "switchWorkspace.previous": "Previous workspace", "switchWorkspace.next": "Next workspace",
    "setContainerPrimarySpan.decrease10Percent": "Column narrower", "setContainerPrimarySpan.increase10Percent": "Column wider",
    "setWindowSecondarySpan.decrease10Percent": "Window shorter", "setWindowSecondarySpan.increase10Percent": "Window taller",
]

let groupOrder = ["Navigate", "Workspaces & monitors", "Columns & sizing", "Windows", "Tools"]

func groupFor(_ base: String) -> String {
    switch base {
    case "focus", "move", "focusPrevious", "focusColumnFirst", "focusColumnLast", "focusColumn", "focusWindowInColumn",
         "moveColumnToFirst", "moveColumnToLast", "consumeWindowIntoColumn", "expelWindowFromColumn", "moveColumn":
        return "Navigate"
    case "toggleWorkspaceLayout":
        return "Tools"
    case _ where base.lowercased().contains("workspace") || base.contains("Monitor"):
        return "Workspaces & monitors"
    case _ where base.contains("Span") || base.contains("Size") || base.contains("Fullscreen") || base == "centerColumn" || base == "toggleColumnTabbed":
        return "Columns & sizing"
    case _ where base.contains("Float") || base.contains("Scratchpad") || base == "closeFocusedWindow":
        return "Windows"
    default:
        return "Tools"
    }
}

func humanize(_ id: String) -> String {
    var out = ""
    for c in id.replacingOccurrences(of: ".", with: " ") {
        if c.isUppercase { out += " " + c.lowercased() } else { out.append(c) }
    }
    return out.prefix(1).uppercased() + out.dropFirst()
}

/// User label from omnikeys.toml first, then the built-in name.
func label(_ id: String) -> String? { config.labels[id] ?? actionNames[id] }

let directions = ["left", "down", "up", "right"]

func buildGroups(_ hotkeys: [Hotkey]) -> [Group] {
    // Bucket hotkeys sharing an action base + modifiers, so 1–9 / H/J/K/L series collapse into one row.
    struct Bucket { var base: String; var mods: [String]; var items: [(suffix: String, key: String, id: String)] }
    var buckets: [Bucket] = []
    for hk in hotkeys {
        let (mods, key) = splitBinding(hk.binding)
        let parts = hk.id.split(separator: ".", maxSplits: 1).map(String.init)
        let base = parts[0], suffix = parts.count > 1 ? parts[1] : ""
        if config.hide.contains(hk.id) || config.hide.contains(base) { continue }
        let seriesSuffix = Int(suffix) != nil || directions.contains(suffix)
        if seriesSuffix, let i = buckets.firstIndex(where: { $0.base == base && $0.mods == mods && !$0.items[0].suffix.isEmpty }) {
            buckets[i].items.append((suffix, key, hk.id))
        } else {
            buckets.append(Bucket(base: base, mods: mods, items: [(suffix, key, hk.id)]))
        }
    }

    var grouped: [String: [Row]] = [:]
    for b in buckets {
        let first = b.items[0]
        let modText = b.mods.joined(separator: " ")
        var keys: String
        var action: String
        if b.items.count > 1, Int(first.suffix) != nil {
            let ks = b.items.map(\.key)
            keys = "\(modText) \(ks.first!)–\(ks.last!)"
            let zeroBased = b.items.contains { $0.suffix == "0" }
            let nums = b.items.compactMap { Int($0.suffix) }.map { zeroBased ? $0 + 1 : $0 }
            action = "\(label(b.base) ?? humanize(b.base)) \(nums.min()!)–\(nums.max()!)"
        } else if b.items.count > 1, directions.contains(first.suffix) {
            let sorted = b.items.sorted { directions.firstIndex(of: $0.suffix)! < directions.firstIndex(of: $1.suffix)! }
            let compact = sorted.allSatisfy { $0.key.count == 1 && $0.key.first!.isLetter }
            keys = "\(modText) " + sorted.map(\.key).joined(separator: compact ? "/" : "")
            action = "\(label(b.base) ?? humanize(b.base)) " + sorted.map(\.suffix).joined(separator: "/")
        } else {
            keys = "\(modText) \(first.key)"
            action = label(first.id) ?? label(b.base).map { first.suffix.isEmpty ? $0 : "\($0) \(first.suffix)" } ?? humanize(first.id)
        }
        grouped[groupFor(b.base), default: []].append(Row(keys: keys.trimmingCharacters(in: .whitespaces), action: action))
    }
    let (mods, key) = splitBinding(config.hotkey)
    grouped["Tools", default: []].append(Row(keys: (mods + [key]).joined(separator: " "), action: "This cheat sheet"))
    // Keep each ⇧ variant directly under its plain shortcut (e.g. Hyper Tab, then Hyper ⇧ Tab).
    func plainKeys(_ r: Row) -> String { r.keys.replacingOccurrences(of: "⇧ ", with: "") }
    func ordered(_ rows: [Row]) -> [Row] {
        let firstSeen = Dictionary(rows.enumerated().map { (plainKeys($1), $0) }, uniquingKeysWith: { a, _ in a })
        return rows.enumerated().sorted { a, b in
            let ka = (firstSeen[plainKeys(a.element)]!, a.element.keys.contains("⇧") ? 1 : 0, a.offset)
            let kb = (firstSeen[plainKeys(b.element)]!, b.element.keys.contains("⇧") ? 1 : 0, b.offset)
            return ka < kb
        }.map(\.element)
    }
    return groupOrder.compactMap { name in grouped[name].map { Group(title: name, rows: ordered($0)) } }
}

// MARK: - Views

struct KeyChips: View {
    let text: String
    var body: some View {
        HStack(spacing: 5) {
            ForEach(Array(text.split(separator: " ").enumerated()), id: \.offset) { _, part in
                let isHyper = part == "Hyper"
                Text(isHyper ? "✦ Hyper" : String(part))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(isHyper ? Color.white : Color.primary)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(RoundedRectangle(cornerRadius: 6)
                        .fill(isHyper ? config.accentColor.opacity(0.85) : Color.primary.opacity(0.12)))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.primary.opacity(0.15), lineWidth: 0.5))
            }
        }
        .fixedSize()
    }
}

struct Card<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.system(size: 12.5, weight: .bold)).tracking(0.8)
                .foregroundStyle(config.accentColor)
            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.06)))
    }
}

struct ShortcutCard: View {
    let group: Group
    var body: some View {
        Card(title: group.title) {
            Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 9) {
                ForEach(group.rows) { row in
                    GridRow(alignment: .firstTextBaseline) {
                        KeyChips(text: row.keys)
                        Text(row.action).font(.system(size: 15))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}

struct CheatSheet: View {
    let groups: [Group]
    let settings: Settings
    let width: CGFloat

    // Spread cards over columns, always adding to the shortest one.
    var columns: [[Group]] {
        let n = config.columns > 0 ? config.columns : (width < 1150 ? 2 : 3)
        var cols = Array(repeating: [Group](), count: n)
        var heights = Array(repeating: 0, count: n)
        for g in groups {
            let i = heights.indices.min { heights[$0] < heights[$1] }!
            cols[i].append(g); heights[i] += g.rows.count + 2
        }
        return cols
    }

    var workspaces: [Workspace] { settings.workspaces.filter { !$0.apps.isEmpty } }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("OmniWM").font(.system(size: 26, weight: .bold))
                Text("✦ Hyper = Caps Lock  ·  add ⇧ to move instead of focus").font(.system(size: 14)).foregroundStyle(.secondary)
                Spacer()
                Text("Esc to close  ·  ⌘, settings").font(.system(size: 12.5)).foregroundStyle(.tertiary)
            }
            HStack(alignment: .top, spacing: 16) {
                ForEach(Array(columns.enumerated()), id: \.offset) { _, col in
                    VStack(spacing: 16) { ForEach(col) { ShortcutCard(group: $0) } }
                        .frame(maxWidth: .infinity, alignment: .top)
                }
            }
            if config.showWorkspaces && !workspaces.isEmpty {
                Card(title: "Workspaces") {
                    Grid(alignment: .leading, horizontalSpacing: 22, verticalSpacing: 7) {
                        ForEach(Array(workspaces.enumerated()), id: \.offset) { _, ws in
                            GridRow(alignment: .firstTextBaseline) {
                                KeyChips(text: ws.displayName.isEmpty ? ws.name : "\(ws.name) \(ws.displayName)")
                                Text(ws.display).font(.system(size: 15)).foregroundStyle(.secondary)
                                Text(ws.apps.joined(separator: ", ")).font(.system(size: 15))
                            }
                        }
                    }
                    if config.showFloating && !settings.floating.isEmpty {
                        Text("Always floating: " + settings.floating.joined(separator: ", "))
                            .font(.system(size: 13.5)).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(28)
        .frame(width: width)
        .background(config.background)
        .environment(\.colorScheme, config.colorScheme ?? (NSApp.effectiveAppearance.name == .darkAqua ? .dark : .light))
    }
}

// MARK: - Panel

final class CheatPanel: NSPanel {
    /// Hide the sheet; `restoreFocus` hands focus back to the app that was active before it opened.
    var onDismiss: ((_ restoreFocus: Bool) -> Void)?

    override var canBecomeKey: Bool { true }
    override func cancelOperation(_ sender: Any?) { onDismiss?(true) }  // Esc
    override func resignKey() {  // click elsewhere: that click already chose the app to focus
        super.resignKey()
        if config.closeOnClickOutside && isVisible { onDismiss?(false) }
    }
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.modifierFlags.contains(.command), event.charactersIgnoringModifiers == "," {  // ⌘, opens settings
            onDismiss?(false)
            let open = Process()
            open.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            open.arguments = ["-t", configFile.path]
            try? open.run()
            return true
        }
        return super.performKeyEquivalent(with: event)
    }
}

/// OmniWM key names -> virtual key codes, for the configurable hotkey.
let keyCodes: [String: Int] = {
    var m: [String: Int] = [
        "Slash": kVK_ANSI_Slash, "Period": kVK_ANSI_Period, "Comma": kVK_ANSI_Comma, "Semicolon": kVK_ANSI_Semicolon,
        "Quote": kVK_ANSI_Quote, "Backslash": kVK_ANSI_Backslash, "Grave": kVK_ANSI_Grave, "Minus": kVK_ANSI_Minus,
        "Equal": kVK_ANSI_Equal, "Space": kVK_Space, "Return": kVK_Return, "Tab": kVK_Tab, "Escape": kVK_Escape,
    ]
    let letters: [Int] = [kVK_ANSI_A, kVK_ANSI_B, kVK_ANSI_C, kVK_ANSI_D, kVK_ANSI_E, kVK_ANSI_F, kVK_ANSI_G, kVK_ANSI_H,
                          kVK_ANSI_I, kVK_ANSI_J, kVK_ANSI_K, kVK_ANSI_L, kVK_ANSI_M, kVK_ANSI_N, kVK_ANSI_O, kVK_ANSI_P,
                          kVK_ANSI_Q, kVK_ANSI_R, kVK_ANSI_S, kVK_ANSI_T, kVK_ANSI_U, kVK_ANSI_V, kVK_ANSI_W, kVK_ANSI_X,
                          kVK_ANSI_Y, kVK_ANSI_Z]
    for (i, code) in letters.enumerated() { m[String(UnicodeScalar(UInt8(65 + i)))] = code }
    let digits: [Int] = [kVK_ANSI_0, kVK_ANSI_1, kVK_ANSI_2, kVK_ANSI_3, kVK_ANSI_4, kVK_ANSI_5, kVK_ANSI_6, kVK_ANSI_7, kVK_ANSI_8, kVK_ANSI_9]
    for (i, code) in digits.enumerated() { m[String(i)] = code }
    let fkeys: [Int] = [kVK_F1, kVK_F2, kVK_F3, kVK_F4, kVK_F5, kVK_F6, kVK_F7, kVK_F8, kVK_F9, kVK_F10, kVK_F11, kVK_F12]
    for (i, code) in fkeys.enumerated() { m["F\(i + 1)"] = code }
    return m
}()

/// "Hyper+Slash" -> (keycode, Carbon modifier mask), expanding Hyper from OmniWM's settings.
func parseHotkey(_ binding: String, hyper: String) -> (UInt32, UInt32)? {
    var parts = binding.components(separatedBy: "+")
    guard let key = parts.popLast(), let code = keyCodes[key] else { return nil }
    var mods = 0
    for m in parts.flatMap({ $0 == "Hyper" ? hyper.components(separatedBy: "+") : [$0] }) {
        switch m {
        case "Control": mods |= controlKey
        case "Option": mods |= optionKey
        case "Shift": mods |= shiftKey
        case "Command": mods |= cmdKey
        default: return nil
        }
    }
    return (UInt32(code), UInt32(mods))
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var panel: CheatPanel?
    var previousApp: NSRunningApplication?
    var hotKeyRef: EventHotKeyRef?
    var registered = ""
    var stamps: [Date?] = []

    func applicationDidFinishLaunching(_ note: Notification) {
        installHotKeyHandler()
        reloadConfig()
        // Watch omnikeys.toml and OmniWM's settings.toml: apply hotkey changes and redraw an open sheet.
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in self?.reloadIfChanged() }
    }

    func fileStamps() -> [Date?] {
        [configFile, settingsFile].map { (try? FileManager.default.attributesOfItem(atPath: $0.path))?[.modificationDate] as? Date }
    }

    func reloadIfChanged() {
        guard fileStamps() != stamps else { return }
        reloadConfig()
        if let panel, panel.isVisible { show() }  // redraw in place with the new shortcuts/settings
    }

    func reloadConfig() {
        config = loadConfig()
        stamps = fileStamps()
        registerHotKey()
    }

    func toggle() {
        if let panel, panel.isVisible { dismiss(restoreFocus: true); return }
        show()
    }

    func dismiss(restoreFocus: Bool) {
        panel?.orderOut(nil)
        if restoreFocus { previousApp?.activate() }
        previousApp = nil
    }

    func makeView(width: CGFloat) -> CheatSheet {
        let settings = readSettings()
        return CheatSheet(groups: buildGroups(settings.hotkeys), settings: settings, width: width)
    }

    /// The screen OmniWM considers focused (`omniwmctl query focused-monitor` -> "display:<CGDirectDisplayID>").
    func focusedScreen() -> NSScreen? {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/Applications/OmniWM.app/Contents/MacOS/omniwmctl")
        p.arguments = ["query", "focused-monitor", "--format", "json"]
        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = FileHandle.nullDevice
        guard (try? p.run()) != nil else { return nil }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let result = json["result"] as? [String: Any],
              let payload = result["payload"] as? [String: Any],
              let display = payload["display"] as? [String: Any],
              let id = (display["id"] as? String)?.split(separator: ":").last.flatMap({ UInt32($0) })
        else { return nil }
        return NSScreen.screens.first { ($0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value == id }
    }

    /// Points per inch and physical width (mm) of a screen; (0, 0) if macOS doesn't know its size.
    func density(of screen: NSScreen) -> (CGFloat, CGFloat) {
        guard let id = (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value else { return (0, 0) }
        let mm = CGDisplayScreenSize(id).width
        return mm > 0 ? (screen.frame.width / (mm / 25.4), mm) : (0, 0)
    }

    var mouseScreen: NSScreen? { NSScreen.screens.first { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) } }

    func show() {
        config = loadConfig()
        let screen: NSScreen
        switch config.screen {
        case "mouse": screen = mouseScreen ?? NSScreen.screens[0]
        case "main": screen = NSScreen.screens[0]
        default: screen = focusedScreen() ?? mouseScreen ?? NSScreen.screens[0]
        }
        let vis = screen.visibleFrame
        let (pointsPerInch, widthMM) = density(of: screen)
        let width = vis.width * (config.width ?? (widthMM >= 450 ? 0.75 : 0.95))
        let maxHeight = vis.height * config.maxHeight
        // Denser screens are smaller and viewed closer: scale text by the square root of the density ratio.
        let densityScale = config.density == "auto" && pointsPerInch > 0
            ? min(max((pointsPerInch / config.referenceDensity).squareRoot(), 0.75), 1.6) : 1

        // Lay out at width/scale and scale up by textSize × density; shrink if it would be taller than allowed.
        // Measured at the real layout width so wrapped lines are counted.
        var scale = config.textSize * densityScale
        var view = makeView(width: width)
        var height = width
        for _ in 0..<5 {
            view = makeView(width: width / scale)
            height = NSHostingController(rootView: view).sizeThatFits(in: NSSize(width: width / scale, height: 10_000)).height * scale
            if height <= maxHeight { break }
            scale *= maxHeight / height
        }
        let size = NSSize(width: width, height: min(height, maxHeight))
        let host = NSHostingView(rootView: view
            .scaleEffect(scale, anchor: .topLeading)
            .frame(width: size.width, height: size.height, alignment: .topLeading))
        host.frame = NSRect(origin: .zero, size: size)
        host.autoresizingMask = [.width, .height]

        let effect = NSVisualEffectView(frame: host.frame)
        effect.appearance = config.appearance
        effect.material = .hudWindow
        effect.blendingMode = .behindWindow
        effect.state = .active
        effect.wantsLayer = true
        effect.layer?.cornerRadius = 18
        effect.layer?.masksToBounds = true
        effect.addSubview(host)

        let frame = NSRect(x: vis.midX - size.width / 2, y: vis.midY - size.height / 2, width: size.width, height: size.height)
        let p = panel ?? CheatPanel(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        p.isFloatingPanel = true
        p.level = .floating
        p.backgroundColor = .clear
        p.isOpaque = false
        p.hasShadow = true
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        p.contentView = effect
        p.setFrame(frame, display: true)
        panel = p
        p.onDismiss = { [weak self] restore in self?.dismiss(restoreFocus: restore) }
        // Remember who had focus (not when redrawing an already open sheet, where that would be us).
        if let front = NSWorkspace.shared.frontmostApplication, front != NSRunningApplication.current { previousApp = front }
        NSApp.activate(ignoringOtherApps: true)
        p.makeKeyAndOrderFront(nil)
    }

    /// `OmniKeys --render out.png` draws the sheet to an image (for checking the design without a screenshot).
    @MainActor func render(to path: String) {
        config = loadConfig()
        let renderer = ImageRenderer(content: makeView(width: 1440).background(Color(white: 0.17)))
        renderer.scale = 1
        if let img = renderer.nsImage, let tiff = img.tiffRepresentation,
           let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) {
            try? png.write(to: URL(fileURLWithPath: path))
        }
    }

    func installHotKeyHandler() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, ctx in
            let me = Unmanaged<AppDelegate>.fromOpaque(ctx!).takeUnretainedValue()
            DispatchQueue.main.async { me.toggle() }
            return noErr
        }, 1, &spec, Unmanaged.passUnretained(self).toOpaque(), nil)
    }

    func registerHotKey() {
        let hyper = readSettings().hyperModifiers
        guard config.hotkey + hyper != registered else { return }
        if let ref = hotKeyRef { UnregisterEventHotKey(ref); hotKeyRef = nil }
        let parsed = parseHotkey(config.hotkey, hyper: hyper) ?? parseHotkey("Hyper+Slash", hyper: hyper)!
        let id = EventHotKeyID(signature: OSType(0x4F4B4559), id: 1)  // 'OKEY'
        RegisterEventHotKey(parsed.0, parsed.1, id, GetApplicationEventTarget(), 0, &hotKeyRef)
        registered = config.hotkey + hyper
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
if let i = CommandLine.arguments.firstIndex(of: "--render"), i + 1 < CommandLine.arguments.count {
    MainActor.assumeIsolated { delegate.render(to: CommandLine.arguments[i + 1]) }
    exit(0)
}
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
