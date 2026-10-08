#!/bin/sh
# Build OmniKeys.app into ~/Applications and start it at login.
set -e
cd "$(dirname "$0")"

APP="$HOME/Applications/OmniKeys.app"
AGENT="$HOME/Library/LaunchAgents/local.omnikeys.plist"

mkdir -p "$APP/Contents/MacOS" "$HOME/Library/LaunchAgents"
swiftc -O -o "$APP/Contents/MacOS/OmniKeys" OmniKeys.swift

cat > "$APP/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleIdentifier</key><string>local.omnikeys</string>
  <key>CFBundleName</key><string>OmniKeys</string>
  <key>CFBundleExecutable</key><string>OmniKeys</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>LSUIElement</key><true/>
</dict></plist>
EOF
codesign --force --sign - "$APP" >/dev/null

cat > "$AGENT" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>local.omnikeys</string>
  <key>ProgramArguments</key><array><string>$APP/Contents/MacOS/OmniKeys</string></array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
</dict></plist>
EOF

launchctl bootout "gui/$(id -u)/local.omnikeys" 2>/dev/null || true
# bootout is asynchronous; wait until the old instance is gone before starting the new one
while launchctl print "gui/$(id -u)/local.omnikeys" >/dev/null 2>&1; do sleep 0.2; done
launchctl bootstrap "gui/$(id -u)" "$AGENT"
echo "OmniKeys installed. Toggle with Hyper+/ (⌃⌥⌘/)."
