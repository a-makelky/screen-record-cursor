#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
configuration="${CONFIGURATION:-release}"
app_name="Screen Recording Cursor.app"
output_root="${OUTPUT_DIR:-"$project_root/.build/app"}"
app_path="$output_root/$app_name"
entitlements_path="$project_root/Resources/ScreenRecordCursor.entitlements"

if [[ -n "${SCREEN_RECORD_CURSOR_BINARY:-}" ]]; then
  binary_path="$SCREEN_RECORD_CURSOR_BINARY"
else
  swift build \
    --package-path "$project_root" \
    --configuration "$configuration"
  binary_dir="$(swift build \
    --package-path "$project_root" \
    --configuration "$configuration" \
    --show-bin-path)"
  binary_path="$binary_dir/ScreenRecordCursor"
fi

if [[ ! -x "$binary_path" ]]; then
  echo "Missing executable: $binary_path" >&2
  exit 1
fi

rm -rf "$app_path"
mkdir -p "$app_path/Contents/MacOS" "$app_path/Contents/Resources"
cp "$binary_path" "$app_path/Contents/MacOS/ScreenRecordCursor"
cp "$project_root/Resources/Info.plist" "$app_path/Contents/Info.plist"
cp "$project_root/Resources/PrivacyInfo.xcprivacy" \
  "$app_path/Contents/Resources/PrivacyInfo.xcprivacy"
cp -R "$project_root/Resources/Sounds" "$app_path/Contents/Resources/Sounds"

if [[ -n "${APP_VERSION:-}" ]]; then
  /usr/libexec/PlistBuddy \
    -c "Set :CFBundleShortVersionString $APP_VERSION" \
    "$app_path/Contents/Info.plist"
fi

if [[ -n "${APP_BUILD:-}" ]]; then
  /usr/libexec/PlistBuddy \
    -c "Set :CFBundleVersion $APP_BUILD" \
    "$app_path/Contents/Info.plist"
fi

if command -v codesign >/dev/null 2>&1; then
  code_sign_identity="${CODE_SIGN_IDENTITY:--}"
  codesign \
    --force \
    --sign "$code_sign_identity" \
    --entitlements "$entitlements_path" \
    "$app_path"
fi

echo "$app_path"
