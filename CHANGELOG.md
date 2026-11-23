# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- Settings window (⌘, or Settings… in the menu) for every option, including hiding and renaming shortcuts.
  It saves to `config.toml` and keeps your comments.
- OmniWM 0.8 support: names for the renamed resize actions, command palette modes, volume, media and
  keyboard-mode actions, and the window switcher's ⌘⇥ / ⌥⇥ shortcuts when it is enabled.
- Window mode card: the single keys (OmniWM's `modeKey`) that run commands in Window or Prefix mode,
  with the shortcut that enters the mode and Esc to leave. It appears once Window or Prefix mode has
  a shortcut.
- Names for Mark window / Remove window mark, listed under Windows.
- Search in the cheat sheet: type to filter by action, section, key (`hyper+2`, `⌘⇧K`, `shift left`)
  or workspace app. Esc clears the search, a second Esc closes the sheet, and ⌘F returns to the field.
- Arrow keys, Page Up/Down, Home and End scroll the sheet while you type.

### Fixed
- The Workspaces card and floating list leave out apps that aren't installed on this Mac, and pick up
  apps installed or removed later the next time the sheet opens. `--render` still lists them, with
  readable names (Slack, Microsoft Teams, Bruno, DBeaver…) instead of bundle-id fragments or a web
  app's UUID.
- Renaming a shortcut series in Settings no longer breaks `config.toml` when hand-written labels sit
  under it (`switchWorkspace.next = …` or a `[labels.switchWorkspace]` table).
- Export now includes unassigned shortcuts, so importing clears them on the other Mac. Import also
  handles CRLF line endings, trailing comments and a symlinked `settings.toml`.
- Workspace series show the right numbers when the first one is hidden or unassigned, and a gap
  splits the range ("1–2, 4–5"). Next / previous workspace no longer hides the numbered series.
- Changing a file while the sheet is open no longer takes focus from the app you are using.
- Settings keeps a label you are typing, or a slider you are dragging, when the settings reload.
- A hotkey that another app already owns no longer disables the one that worked.
- Launch at Login shows the same state in the menu and in Settings, also when it waits for approval.
- Export and Import dialogs open in front of other apps. Scrolling search results is smooth again.

### Changed
- Bigger text on laptop screens. Automatic columns now pick 2, 3 or 4, whichever gives the biggest text.
  The Workspaces card joins the columns instead of a full-width row.
- A sheet too tall for the screen shrinks by at most 15% (body text never below 12 pt). Past that it
  keeps its size and scrolls, with a fade and a More button showing there is more below.
- New sheet design: actions on the left with keys right-aligned, drawn as key caps (✦ for Hyper),
  section icons, and a header legend drawn with key caps. Key caps are white in the light theme.
- Less repetition on the sheet: a ⇧ variant sits under its shortcut as "+ ⇧", related shortcuts such
  as the palette modes share one line, and so do next / previous pairs (✦ ↓ / ↑). Cards keep their
  order across columns, and the Workspaces card follows the workspace shortcuts. Tools list the most
  used first.
- ⌘, opens Settings instead of the settings file. Open Settings File… is still in the menu.
- New app icon and menu-bar icon: the ✦ Hyper key cap. On macOS 26 and later the app icon follows the
  Dark, Clear and Tinted icon styles.

## [0.1.0] - 2026-10-08

### Added
- Menu-bar icon with Show Cheat Sheet, Open Settings File…, Launch at Login, About and Quit.
- Launch at login through System Settings › Login Items.
- Problems with your settings (bad values, an unusable hotkey, missing OmniWM settings) are listed in the menu.
- Signed and notarized releases, installable with Homebrew.

### Changed
- Settings moved to `~/.config/omnikeys/config.toml`. An existing
  `~/.config/omniwm/omnikeys.toml` is moved there automatically.
- The header shows your actual Hyper modifiers instead of assuming Caps Lock.

### Removed
- `install.sh` and its KeepAlive LaunchAgent. Use Homebrew, or `make install-dev` from source. If you used the old installer, remove its LaunchAgent (it otherwise keeps relaunching the old app, which competes for the hotkey): `launchctl bootout gui/$(id -u)/local.omnikeys; rm ~/Library/LaunchAgents/local.omnikeys.plist`.

[Unreleased]: https://github.com/olujicz/omnikeys/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/olujicz/omnikeys/releases/tag/v0.1.0
