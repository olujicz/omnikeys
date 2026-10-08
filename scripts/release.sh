#!/usr/bin/env bash
# Builds a signed, notarized, stapled OmniKeys-<version>.zip and the matching Homebrew cask.
#
# Usage: scripts/release.sh 1.2.3
# Needs:
#   - a "Developer ID Application" certificate in the keychain
#   - DEVELOPMENT_TEAM, or DEVELOPMENT_TEAM = … in Config/Signing.local.xcconfig
#   - a notarytool keychain profile ($NOTARY_PROFILE, default omnikeys-notary), created once with
#       xcrun notarytool store-credentials omnikeys-notary --apple-id <id> --team-id <team>
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${1:?usage: scripts/release.sh <version>}"
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "Version must look like 1.2.3" >&2; exit 1; }
[[ -z "$(git status --porcelain)" ]] || { echo "Working tree is not clean; commit first." >&2; exit 1; }
grep -q "^## \[$VERSION\]" CHANGELOG.md || { echo "CHANGELOG.md has no '## [$VERSION]' section." >&2; exit 1; }

TEAM="${DEVELOPMENT_TEAM:-$(sed -n 's/^DEVELOPMENT_TEAM *= *//p' Config/Signing.local.xcconfig 2>/dev/null || true)}"
[[ -n "$TEAM" ]] || { echo "Set DEVELOPMENT_TEAM or add it to Config/Signing.local.xcconfig." >&2; exit 1; }

BUILD_NUMBER="$(git rev-list --count HEAD)"
OUT="build/release/$VERSION"
rm -rf "$OUT"
mkdir -p "$OUT"

echo "==> Archiving $VERSION ($BUILD_NUMBER)"
mise exec -- tuist generate --no-open
xcodebuild -workspace OmniKeys.xcworkspace -scheme OmniKeys -configuration Release \
  -destination 'generic/platform=macOS' -archivePath "$OUT/OmniKeys.xcarchive" -quiet archive \
  CODE_SIGNING_ALLOWED=YES CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY="Developer ID Application" DEVELOPMENT_TEAM="$TEAM" \
  OTHER_CODE_SIGN_FLAGS="--timestamp" MARKETING_VERSION="$VERSION" CURRENT_PROJECT_VERSION="$BUILD_NUMBER"

echo "==> Exporting"
cp packaging/ExportOptions.plist "$OUT/ExportOptions.plist"
plutil -replace teamID -string "$TEAM" "$OUT/ExportOptions.plist"
xcodebuild -exportArchive -archivePath "$OUT/OmniKeys.xcarchive" -exportPath "$OUT/export" \
  -exportOptionsPlist "$OUT/ExportOptions.plist" -quiet

APP="$OUT/export/OmniKeys.app"
ZIP="$OUT/OmniKeys-$VERSION.zip"
ditto -c -k --keepParent "$APP" "$ZIP"

echo "==> Notarizing (this can take a few minutes)"
RESULT="$(xcrun notarytool submit "$ZIP" --wait --output-format json --keychain-profile "${NOTARY_PROFILE:-omnikeys-notary}")" || {
  echo "$RESULT" >&2
  echo "notarytool failed" >&2
  exit 1
}
STATUS="$(plutil -extract status raw -o - - <<<"$RESULT")"
if [[ "$STATUS" != "Accepted" ]]; then
  echo "$RESULT" >&2
  echo "Notarization status: $STATUS. Details: xcrun notarytool log <id> --keychain-profile ${NOTARY_PROFILE:-omnikeys-notary}" >&2
  exit 1
fi

echo "==> Stapling and verifying"
xcrun stapler staple "$APP"
rm "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"
spctl --assess --type execute -vv "$APP"

SHA="$(shasum -a 256 "$ZIP" | cut -d' ' -f1)"
sed -e "s/@VERSION@/$VERSION/g" -e "s/@SHA256@/$SHA/g" packaging/omnikeys.rb.template > "$OUT/omnikeys.rb"
echo
echo "Built  $ZIP"
echo "SHA256 $SHA"
echo "Cask   $OUT/omnikeys.rb"
