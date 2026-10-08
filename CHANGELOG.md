# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

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
- `install.sh` and its KeepAlive LaunchAgent. Use Homebrew, or `make install-dev` from source.

[Unreleased]: https://github.com/olujicz/omnikeys/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/olujicz/omnikeys/releases/tag/v0.1.0
