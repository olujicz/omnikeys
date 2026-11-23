# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

## [1.0.0] - 2026-11-23

First public release.

### Added
- A floating cheat sheet of your OmniWM keyboard shortcuts, read live from OmniWM's `settings.toml`.
  Open it with ✦ Hyper + / (configurable); Esc, the hotkey or a click outside closes it.
- Shortcuts grouped into cards (Navigate, Workspaces & monitors, Columns & sizing, Windows, Tools),
  with series collapsed into one row (✦ 1–9, ✦ H/J/K/L) and next / previous pairs on one line.
- Workspaces card with each workspace's display and assigned apps, plus the always-floating apps.
  Apps that aren't installed are left out.
- Window mode card for OmniWM's single-key `modeKey` commands in Window or Prefix mode.
- Search: type to filter by action, section, key (`hyper+2`, `⌘⇧K`, `shift left`) or workspace app.
  Esc clears the search, a second Esc closes the sheet, and ⌘F returns to the field.
- A layout that picks the columns and text size that fit your screen, adapts to screen density, and
  scrolls when the sheet is too tall.
- Settings window (⌘, or Settings… in the menu) for every option: hotkey, screen, size, theme, accent
  colour, and hiding or renaming shortcuts. It saves to `~/.config/omnikeys/config.toml` and keeps
  your comments; edits to the file apply within a second.
- Export and import of shortcut bindings and Hyper modifiers between Macs, with a backup of
  OmniWM's settings before each import.
- Menu-bar icon with Show Cheat Sheet, Settings, Export / Import, Launch at Login, and any problems
  with your settings.
- Signed and notarized build, installable with Homebrew.

[Unreleased]: https://github.com/olujicz/omnikeys/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/olujicz/omnikeys/releases/tag/v1.0.0
