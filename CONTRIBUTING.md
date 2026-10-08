# Contributing

## Setup

```sh
make bootstrap
```

This installs Tuist (through mise) and SwiftFormat and SwiftLint (through Homebrew), then generates the project. After you edit `Project.swift`, run `make generate`.

## Layout

Logic goes in `OmniKeysCore`, with a Swift Testing test. The app target does I/O and UI.

## Make targets

```
  help         Show this help
  bootstrap    Install Tuist (mise) and SwiftFormat/SwiftLint (Homebrew), then generate the project
  generate     Generate OmniKeys.xcworkspace from Project.swift
  build        Debug build
  test         Run all tests
  lint         Check formatting and lint rules
  format       Apply formatting and autocorrectable lint fixes
  run          Build and launch the debug app (quits a running copy first)
  clean        Remove build output and generated projects
  render       Render the fixture sheet to build/render.png
  install-dev  Build Release into ~/Applications (removes the old LaunchAgent)
  release      Signed + notarized zip and cask: make release VERSION=1.2.3
```

## Style

Run `make format` before you commit. CI runs `make lint test`.

## Releasing

1. Move the Unreleased entries into a `## [x.y.z] - date` section in `CHANGELOG.md` and commit.
2. Build the signed, notarized zip and the cask:

   ```sh
   make release VERSION=x.y.z
   ```

3. Tag the release:

   ```sh
   git tag vx.y.z && git push origin vx.y.z
   ```

4. Publish it on GitHub:

   ```sh
   gh release create vx.y.z build/release/x.y.z/OmniKeys-x.y.z.zip --title "OmniKeys x.y.z" --notes "<changelog section>"
   ```

5. Copy `build/release/x.y.z/omnikeys.rb` to `Casks/omnikeys.rb` in `olujicz/homebrew-tap` and push.

### One-time credential setup

Create `Config/Signing.local.xcconfig` (gitignored):

```
CODE_SIGN_IDENTITY = Developer ID Application
DEVELOPMENT_TEAM = <your team id>
```

You also need a "Developer ID Application" certificate in your keychain. Store notarization credentials once:

```sh
xcrun notarytool store-credentials omnikeys-notary --apple-id <id> --team-id <team>
```
