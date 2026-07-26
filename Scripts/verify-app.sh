#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
app_path="${1:-"$project_root/.build/app/Screen Record Cursor.app"}"
plist="$app_path/Contents/Info.plist"
binary="$app_path/Contents/MacOS/ScreenRecordCursor"

test -d "$app_path"
test -f "$plist"
test -x "$binary"

plutil -lint "$plist"
plist_value() {
  /usr/libexec/PlistBuddy -c "Print :$1" "$plist"
}

test "$(plist_value CFBundleExecutable)" = "ScreenRecordCursor"
test "$(plist_value CFBundlePackageType)" = "APPL"
test "$(plist_value CFBundleIdentifier)" = "com.aaronmakelky.screen-record-cursor"
test "$(plist_value LSMinimumSystemVersion)" = "13.0"
test "$(plist_value LSUIElement)" = "true"

if [[ -n "${EXPECTED_APP_VERSION:-}" ]]; then
  test "$(plist_value CFBundleShortVersionString)" = "$EXPECTED_APP_VERSION"
fi

if [[ -n "${EXPECTED_APP_BUILD:-}" ]]; then
  test "$(plist_value CFBundleVersion)" = "$EXPECTED_APP_BUILD"
fi

if command -v codesign >/dev/null 2>&1; then
  codesign --verify --deep --strict "$app_path"
fi

echo "Verified: $app_path"
