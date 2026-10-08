#!/usr/bin/env bash
# Builds a Release copy into ~/Applications and starts it. Removes the LaunchAgent that old versions installed.
set -euo pipefail
cd "$(dirname "$0")/.."

AGENT="$HOME/Library/LaunchAgents/local.omnikeys.plist"
if [[ -f "$AGENT" ]]; then
  launchctl bootout "gui/$(id -u)/local.omnikeys" 2>/dev/null || true
  rm "$AGENT"
  echo "Removed the old LaunchAgent ($AGENT)."
fi

mise exec -- tuist generate --no-open
xcodebuild -workspace OmniKeys.xcworkspace -scheme OmniKeys -configuration Release -destination 'platform=macOS' \
  -derivedDataPath build/DerivedData -quiet build

pkill -x OmniKeys || true
mkdir -p "$HOME/Applications"
rm -rf "$HOME/Applications/OmniKeys.app"
ditto build/DerivedData/Build/Products/Release/OmniKeys.app "$HOME/Applications/OmniKeys.app"
open "$HOME/Applications/OmniKeys.app"
echo "Installed ~/Applications/OmniKeys.app. Use the menu-bar icon to turn on Launch at Login."
