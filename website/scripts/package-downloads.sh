#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="$ROOT/website/dist/downloads"
VERSION="$(git -C "$ROOT" rev-parse --short HEAD)"

cd "$ROOT"
swift build -c release

mkdir -p "$OUT"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

APP="$STAGE/StringScanner.app"
mkdir -p "$APP/Contents/MacOS"
cp "$ROOT/.build/release/StringScanner" "$APP/Contents/MacOS/StringScanner"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>StringScanner</string>
  <key>CFBundleIdentifier</key>
  <string>com.asynch.stringscanner</string>
  <key>CFBundleName</key>
  <string>StringScanner</string>
  <key>CFBundleDisplayName</key>
  <string>StringScanner</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

ditto -c -k --sequesterRsrc --keepParent "$APP" "$OUT/StringScanner-macos-arm64.zip"

mkdir -p "$STAGE/cli"
cp "$ROOT/.build/release/stringscanner-cli" "$STAGE/cli/stringscanner-cli"
cat > "$STAGE/cli/README.txt" <<EOF
stringscanner-cli (Apple Silicon)

chmod +x stringscanner-cli
sudo mv stringscanner-cli /usr/local/bin/

stringscanner-cli /path/to/project
stringscanner-cli /path/to/project --stdout

Requires: macOS 13+, Apple Silicon (arm64)
Build: ${VERSION}
EOF
(cd "$STAGE/cli" && zip -9 "$OUT/stringscanner-cli-macos-arm64.zip" stringscanner-cli README.txt)

ls -lh "$OUT"
echo "Packaged downloads for ${VERSION}"
