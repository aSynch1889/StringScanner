#!/usr/bin/env bash
# Optional Apple notarization helper.
# Requires a local keychain profile created with:
#   xcrun notarytool store-credentials "StringScanner-Notary" \
#     --apple-id "YOU@example.com" --team-id "TEAMID" --password "app-specific-password"
set -euo pipefail

PROFILE="${NOTARY_PROFILE:-StringScanner-Notary}"
APP_ZIP="${1:-website/dist/downloads/StringScanner-macos-arm64.zip}"

if [[ ! -f "$APP_ZIP" ]]; then
  echo "Missing zip: $APP_ZIP" >&2
  echo "Run ./website/scripts/package-downloads.sh first." >&2
  exit 1
fi

if ! xcrun notarytool history --keychain-profile "$PROFILE" >/dev/null 2>&1; then
  cat >&2 <<EOF
Notary profile '$PROFILE' is not configured.
Skipping automatic notarization.
See docs/RELEASE.md for Apple Developer setup and Sparkle signing.
EOF
  exit 0
fi

echo "Submitting $APP_ZIP for notarization..."
xcrun notarytool submit "$APP_ZIP" --keychain-profile "$PROFILE" --wait
echo "Notarization finished. Staple the .app before redistributing if you unpack the zip."
