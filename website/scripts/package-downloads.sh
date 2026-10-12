#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="$ROOT/website/dist/downloads"
HTML="$ROOT/website/dist/index.html"
VERSION="$(git -C "$ROOT" rev-parse --short HEAD)"
APP_VERSION="$(
  sed -n 's/.*static let current = "\([^"]*\)".*/\1/p' \
    "$ROOT/Sources/StringScanner/AppVersion.swift" | head -1
)"
APP_VERSION="${APP_VERSION:-0.0.0}"

GUI_NAME="StringScanner-${APP_VERSION}-${VERSION}-macos-arm64.zip"
CLI_NAME="stringscanner-cli-${APP_VERSION}-${VERSION}-macos-arm64.zip"

cd "$ROOT"
swift build -c release

mkdir -p "$OUT"
rm -f "$OUT"/*.zip "$OUT"/latest.json
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

APP="$STAGE/StringScanner.app"
mkdir -p "$APP/Contents/MacOS"
cp "$ROOT/.build/release/StringScanner" "$APP/Contents/MacOS/StringScanner"
cat > "$APP/Contents/Info.plist" <<PLIST
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
  <string>${APP_VERSION}</string>
  <key>CFBundleVersion</key>
  <string>${VERSION}</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

ditto -c -k --sequesterRsrc --keepParent "$APP" "$OUT/$GUI_NAME"

mkdir -p "$STAGE/cli"
cp "$ROOT/.build/release/stringscanner-cli" "$STAGE/cli/stringscanner-cli"
cat > "$STAGE/cli/README.txt" <<EOF
stringscanner-cli (Apple Silicon)

chmod +x stringscanner-cli
sudo mv stringscanner-cli /usr/local/bin/

stringscanner-cli /path/to/project
stringscanner-cli /path/to/project --stdout

Requires: macOS 13+, Apple Silicon (arm64)
Version: ${APP_VERSION}
Build: ${VERSION}
EOF
(cd "$STAGE/cli" && zip -9 "$OUT/$CLI_NAME" stringscanner-cli README.txt)

export HTML GUI_NAME CLI_NAME APP_VERSION VERSION
python3 - <<'PY'
from pathlib import Path
import os, re

html = Path(os.environ["HTML"])
gui = os.environ["GUI_NAME"]
cli = os.environ["CLI_NAME"]
app_ver = os.environ["APP_VERSION"]
build = os.environ["VERSION"]
text = html.read_text(encoding="utf-8")
text = re.sub(r'href="\./downloads/StringScanner-[^"]+\.zip"', f'href="./downloads/{gui}"', text)
text = re.sub(r'href="\./downloads/stringscanner-cli-[^"]+\.zip"', f'href="./downloads/{cli}"', text)

def patch_card(src: str, href_needle: str, label: str) -> str:
    idx = src.find(href_needle)
    if idx < 0:
        return src
    small_start = src.find("<small>", idx)
    small_end = src.find("</small>", small_start)
    if small_start < 0 or small_end < 0:
        return src
    return src[: small_start + len("<small>")] + label + src[small_end:]

text = patch_card(text, f'href="./downloads/{gui}"', f"v{app_ver} · {build} · arm64")
text = patch_card(text, f'href="./downloads/{cli}"', f"v{app_ver} · {build} · arm64")
text = re.sub(
    r'(<section id="download"[\s\S]*?<p>)([^<]+)(</p>)',
    rf"\1当前版本 v{app_ver}（build {build}），面向 Apple Silicon（arm64）。首次打开若被拦截，请右键「打开」，或执行下方 quarantine 命令。\3",
    text,
    count=1,
)
html.write_text(text, encoding="utf-8")
print(f"Updated {html} -> {gui} / {cli}")
PY

cat > "$OUT/latest.json" <<EOF
{
  "version": "${APP_VERSION}",
  "build": "${VERSION}",
  "gui": "${GUI_NAME}",
  "cli": "${CLI_NAME}"
}
EOF

# Update root README download links if present.
README="$ROOT/README.md"
if [[ -f "$README" ]]; then
  perl -0pi -e "s#https://stringscanner\\.findo\\.workers\\.dev/downloads/StringScanner-[^)\\s]+#https://stringscanner.findo.workers.dev/downloads/${GUI_NAME}#g" "$README"
  perl -0pi -e "s#https://stringscanner\\.findo\\.workers\\.dev/downloads/stringscanner-cli-[^)\\s]+#https://stringscanner.findo.workers.dev/downloads/${CLI_NAME}#g" "$README"
fi

ls -lh "$OUT"
echo "Packaged downloads for ${APP_VERSION} (${VERSION})"
