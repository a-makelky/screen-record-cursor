#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

required=(
  "Package.swift"
  "Resources/Info.plist"
  "Sources/CursorCore/KineticCursorModel.swift"
  "Sources/ScreenRecordCursor/ScreenRecordCursorApp.swift"
  "Sources/ScreenRecordCursor/SettingsView.swift"
  "Sources/ScreenRecordCursor/SettingsWindowController.swift"
  "Sources/ScreenRecordCursor/SettingsWindowView.swift"
  "Sources/ScreenRecordCursor/CursorOverlayController.swift"
  "Sources/ScreenRecordCursor/GlobalHotKeyController.swift"
  "Sources/ScreenRecordCursor/ShortcutRecorderView.swift"
  "Sources/ScreenRecordCursor/LaunchAtLoginController.swift"
  "Sources/ScreenRecordCursor/NativeCursorVisibilityController.swift"
  "Sources/ScreenRecordCursor/GlobalClickMonitor.swift"
  "Tests/CursorCoreTests/KineticCursorModelTests.swift"
  "LICENSE"
  "README.md"
  "TESTING.md"
  "docs/PUBLIC_RELEASE.md"
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
    "CFBundlePackageType": "APPL",
    "LSUIElement": True,
}

for key, value in expected.items():
    if plist.get(key) != value:
        raise SystemExit(f"{key} must be {value!r}")

if plist.get("LSMinimumSystemVersion") != "13.0":
    raise SystemExit("LSMinimumSystemVersion must be 13.0")
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

cursor_api_uses="$(grep -R -lE 'CGDisplay(Hide|Show)Cursor|SetsCursorInBackground|CGS[A-Z]|SLS[A-Z]' Sources || true)"
if [[ "$cursor_api_uses" != "Sources/ScreenRecordCursor/NativeCursorVisibilityController.swift" ]]; then
  echo "Cursor visibility APIs must remain isolated in NativeCursorVisibilityController.swift." >&2
  printf '%s\n' "$cursor_api_uses" >&2
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

echo "Static validation passed."
