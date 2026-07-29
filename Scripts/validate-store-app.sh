#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
app_path="${1:-"$project_root/.build/app/Screen Recording Cursor.app"}"
binary="$app_path/Contents/MacOS/ScreenRecordCursor"
privacy_manifest="$app_path/Contents/Resources/PrivacyInfo.xcprivacy"

test -d "$app_path"
test -x "$binary"
test -f "$privacy_manifest"
plutil -lint "$privacy_manifest"
cmp -s \
  "$project_root/Resources/PrivacyInfo.xcprivacy" \
  "$privacy_manifest"

entitlements_output="$(mktemp)"
trap 'rm -f "$entitlements_output"' EXIT

prohibited_pattern='CGDisplay(Hide|Show)Cursor|CGCursorIsVisible|CGWindowLevelForKey|SetsCursorInBackground|(^|[^A-Za-z0-9])_?CGS[A-Z_][A-Za-z0-9_]*|(^|[^A-Za-z0-9])_?SLS[A-Z_][A-Za-z0-9_]*|KineticCursorModel|KineticResponse|kineticEnabled|kineticResponse|rotationRadians|CGContextRotateCTM|CGAffineTransformRotate|/System/Library/PrivateFrameworks/'
scanned_mach_o=0

while IFS= read -r -d '' candidate; do
  if ! /usr/bin/file "$candidate" | grep -q 'Mach-O'; then
    continue
  fi

  scanned_mach_o=$((scanned_mach_o + 1))
  scan_output="$(mktemp)"
  /usr/bin/strings -a "$candidate" >> "$scan_output"
  /usr/bin/nm -u "$candidate" >> "$scan_output" 2>/dev/null
  /usr/bin/otool -L "$candidate" >> "$scan_output"

  if grep -nE "$prohibited_pattern" "$scan_output"; then
    echo "Packaged Store app contains a prohibited API, framework, or kinetic symbol: $candidate" >&2
    rm -f "$scan_output"
    exit 1
  fi

  rm -f "$scan_output"
done < <(find "$app_path/Contents" -type f -print0)

if (( scanned_mach_o == 0 )); then
  echo "Packaged Store app contains no Mach-O executable." >&2
  exit 1
fi
codesign --verify --deep --strict "$app_path"
codesign -d --entitlements :- "$app_path" \
  > "$entitlements_output" 2>/dev/null
plutil -lint "$entitlements_output"

test "$(
  /usr/libexec/PlistBuddy \
    -c 'Print :com.apple.security.app-sandbox' \
    "$entitlements_output"
)" = "true"

if [[ "$(
  /usr/libexec/PlistBuddy \
    -c 'Print :com.apple.security.get-task-allow' \
    "$entitlements_output" 2>/dev/null || true
)" == "true" ]]
then
  echo "Store app must not be signed with get-task-allow." >&2
  exit 1
fi

if /usr/libexec/PlistBuddy \
  -c 'Print :com.apple.security.network.client' \
  "$entitlements_output" >/dev/null 2>&1
then
  echo "Store app must not request the network client entitlement." >&2
  exit 1
fi

if /usr/libexec/PlistBuddy \
  -c 'Print :com.apple.security.network.server' \
  "$entitlements_output" >/dev/null 2>&1
then
  echo "Store app must not request the network server entitlement." >&2
  exit 1
fi

echo "Store app validation passed: $app_path"
