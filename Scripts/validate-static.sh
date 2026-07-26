#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

required=(
  "Package.swift"
  "Resources/Info.plist"
  "Sources/CursorCore/KineticCursorModel.swift"
  "Sources/ScreenRecordCursor/ScreenRecordCursorApp.swift"
  "Sources/ScreenRecordCursor/CursorOverlayController.swift"
  "Sources/ScreenRecordCursor/GlobalClickMonitor.swift"
  "Tests/CursorCoreTests/KineticCursorModelTests.swift"
  "LICENSE"
  "README.md"
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
  'URLSession|NSURLConnection|import Network|import WebKit|OpenAI|Anthropic|telemetry|analytics|CGEventPost|CGEvent\.post|AXUIElement|CGDisplayHideCursor|CGS[A-Z]|SkyLight' \
  Sources; then
  echo "Unexpected network, AI, telemetry, event-posting, or Accessibility API." >&2
  exit 1
fi

if grep -q '\.package(' Package.swift; then
  echo "External Swift package dependencies are not allowed." >&2
  exit 1
fi

echo "Static validation passed."
