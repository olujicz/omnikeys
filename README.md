# OmniKeys

A floating cheat sheet for your [OmniWM](https://github.com/OmniNull/OmniWM) keyboard shortcuts.

![CI](https://github.com/olujicz/omnikeys/actions/workflows/ci.yml/badge.svg)

![OmniKeys](.github/screenshot.png)

OmniKeys reads your shortcuts from OmniWM's settings, so the sheet is always current.

## Install

```sh
brew install --cask olujicz/tap/omnikeys
```

Or download the zip from [Releases](https://github.com/olujicz/omnikeys/releases) and move `OmniKeys.app` to Applications.

Requires macOS 14 or later and OmniWM.

## Use

Press ✦ Hyper + / to open the sheet. Hyper is the set of modifiers that OmniWM's Hyper key sends.

Esc, the same hotkey, or a click outside the sheet closes it. ⌘, opens the settings file.

The menu-bar icon offers the same actions, plus Launch at Login. It also lists any problems with your settings.

## Settings

Settings live in `~/.config/omnikeys/config.toml`. OmniKeys creates the file on first launch, with every option documented inline. Changes apply within a second.

An older `~/.config/omniwm/omnikeys.toml` is moved there automatically.

## Troubleshooting

**The hotkey does nothing.** Another app owns it. The menu shows ⚠︎. Pick another `hotkey` in the settings file.

**"OmniWM settings not found".** Open OmniWM once so it writes its settings.

**Logs.**

```sh
log stream --predicate 'subsystem == "io.github.olujicz.omnikeys"'
```

**Uninstall.**

```sh
brew uninstall --zap --cask omnikeys
```

## Build from source

You need Xcode 16 or later, [mise](https://mise.jdx.dev) and Homebrew.

```sh
make bootstrap     # install tools, generate the project
make run           # build and launch the debug app
make test          # run the tests
make install-dev   # install a Release build to ~/Applications
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for more.

## License

[MIT](LICENSE)
