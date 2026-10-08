/// The commented config.toml written on first run. Every value here must equal Config()'s default.
public enum DefaultConfig {
    public static let template = """
    # ─────────────────────────────────────────────────────────────────────────────
    #  OmniKeys — settings for the OmniWM cheat sheet
    # ─────────────────────────────────────────────────────────────────────────────
    #  • Every option is listed below with its default value.
    #  • Changes apply within a second of saving. No restart needed.
    #  • Press ⌘, while the sheet is open, or use the menu-bar icon, to edit this file.
    #  • Delete this file to get the defaults back (it is recreated automatically).
    #  • The shortcuts themselves are read from OmniWM's settings.toml, so they are
    #    always current. This file only controls how the sheet looks and behaves.

    # ── Opening ──────────────────────────────────────────────────────────────────

    # Shortcut that opens and closes the sheet, written the way OmniWM writes it.
    # "Hyper" = the Hyper modifiers set in OmniWM's settings.
    # Modifiers: Hyper, Control, Option, Shift, Command (at least one is required).
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

    # Show the OmniKeys icon in the menu bar. When hidden, open OmniKeys again
    # from Finder or Spotlight to show the sheet.
    # Default: true
    showMenuBarIcon = true

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
    # "looks like 1440p" ≈ 109, MacBook Pro built-in ≈ 127. Range 40 – 300.
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
}
