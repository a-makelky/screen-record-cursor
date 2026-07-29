#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

required=(
  "Package.swift"
  "Resources/Info.plist"
  "Resources/PrivacyInfo.xcprivacy"
  "Resources/ScreenRecordCursor.entitlements"
  "Sources/CursorCore/RingVisibilityMode.swift"
  "Sources/ScreenRecordCursor/ScreenRecordCursorApp.swift"
  "Sources/ScreenRecordCursor/BrandPalette.swift"
  "Sources/ScreenRecordCursor/SettingsView.swift"
  "Sources/ScreenRecordCursor/SettingsWindowController.swift"
  "Sources/ScreenRecordCursor/SettingsWindowView.swift"
  "Sources/ScreenRecordCursor/CursorOverlayController.swift"
  "Sources/ScreenRecordCursor/GlobalHotKeyController.swift"
  "Sources/ScreenRecordCursor/ShortcutRecorderView.swift"
  "Sources/ScreenRecordCursor/LaunchAtLoginController.swift"
  "Sources/ScreenRecordCursor/GlobalClickMonitor.swift"
  "Tests/CursorCoreTests/RingVisibilityModeTests.swift"
  "Scripts/validate-store-source.sh"
  "Scripts/validate-store-app.sh"
  "LICENSE"
  "README.md"
  "TESTING.md"
  "docs/PUBLIC_RELEASE.md"
  "docs/ACCESSIBILITY.md"
  "docs/EDUCATOR_ACCESS.md"
  "docs/SOUND_ASSETS.md"
  "Resources/Sounds/mouse-click.wav"
  "Resources/Sounds/mouse-pop.wav"
  "Resources/Sounds/plop-click.wav"
  "Resources/Sounds/spacebar.wav"
  "Resources/Sounds/typewriter.wav"
)

for path in "${required[@]}"; do
  if [[ ! -f "$path" ]]; then
    echo "Missing required file: $path" >&2
    exit 1
  fi
done

python3 - <<'PY'
from pathlib import Path
import plistlib

path = Path("Resources/Info.plist")
with path.open("rb") as handle:
    plist = plistlib.load(handle)

expected = {
    "CFBundleExecutable": "ScreenRecordCursor",
    "CFBundleIdentifier": "com.aaronmakelky.screen-recording-cursor",
    "CFBundlePackageType": "APPL",
    "LSUIElement": True,
    "ITSAppUsesNonExemptEncryption": False,
}

for key, value in expected.items():
    if plist.get(key) != value:
        raise SystemExit(f"{key} must be {value!r}")

if plist.get("LSMinimumSystemVersion") != "13.0":
    raise SystemExit("LSMinimumSystemVersion must be 13.0")

entitlements_path = Path("Resources/ScreenRecordCursor.entitlements")
with entitlements_path.open("rb") as handle:
    entitlements = plistlib.load(handle)

if entitlements != {"com.apple.security.app-sandbox": True}:
    raise SystemExit("Store entitlements must contain only App Sandbox")

privacy_path = Path("Resources/PrivacyInfo.xcprivacy")
with privacy_path.open("rb") as handle:
    privacy = plistlib.load(handle)

if privacy.get("NSPrivacyTracking") is not False:
    raise SystemExit("Privacy manifest must declare tracking false")
if privacy.get("NSPrivacyCollectedDataTypes") != []:
    raise SystemExit("Privacy manifest must declare no collected data")
if privacy.get("NSPrivacyTrackingDomains") != []:
    raise SystemExit("Privacy manifest must declare no tracking domains")

reasons = {
    entry.get("NSPrivacyAccessedAPIType"):
        entry.get("NSPrivacyAccessedAPITypeReasons")
    for entry in privacy.get("NSPrivacyAccessedAPITypes", [])
}
expected_reasons = {
    "NSPrivacyAccessedAPICategoryUserDefaults": ["CA92.1"],
    "NSPrivacyAccessedAPICategorySystemBootTime": ["35F9.1"],
}
if reasons != expected_reasons:
    raise SystemExit("Privacy manifest required-reason declarations are incorrect")
PY

for script in Scripts/*.sh; do
  bash -n "$script"
done

if grep -R -nE \
  'URLSession|NSURLConnection|import Network|import WebKit|OpenAI|Anthropic|telemetry|analytics|CGEventPost|CGEvent\.post|AXUIElement' \
  Sources; then
  echo "Unexpected network, AI, telemetry, event-posting, or Accessibility API." >&2
  exit 1
fi

if grep -R -nE 'NSEvent\.addGlobalMonitorForEvents.*key|CGEvent\.tapCreate' \
  Sources/ScreenRecordCursor; then
  echo "Global shortcuts must not require keyboard monitoring permissions." >&2
  exit 1
fi

if grep -q '\.package(' Package.swift; then
  echo "External Swift package dependencies are not allowed." >&2
  exit 1
fi

if grep -R -nE 'makeClickWAV|deterministicNoise' Sources/ScreenRecordCursor; then
  echo "Click sounds must come from the bundled WAV resources." >&2
  exit 1
fi

if ! grep -q 'accessibilityPerformPress' \
  Sources/ScreenRecordCursor/ShortcutRecorderView.swift; then
  echo "The custom shortcut control must expose an accessibility action." >&2
  exit 1
fi

if ! grep -q 'BrandPalette.brightBlue' \
  Sources/ScreenRecordCursor/ScreenRecordCursorApp.swift; then
  echo "The active menu-bar item must retain the bright-blue status indicator." >&2
  exit 1
fi

./Scripts/validate-store-source.sh

echo "Static validation passed."
