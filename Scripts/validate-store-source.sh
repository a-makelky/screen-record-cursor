#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

for removed_path in \
  Sources/ScreenRecordCursor/NativeCursorVisibilityController.swift \
  Sources/CursorCore/KineticCursorModel.swift \
  Sources/CursorCore/KineticResponse.swift \
  Tests/CursorCoreTests/KineticCursorModelTests.swift \
  Tests/CursorCoreTests/KineticResponseTests.swift
do
  if [[ -e "$removed_path" ]]; then
    echo "Store source must not include: $removed_path" >&2
    exit 1
  fi
done

prohibited_pattern='CGDisplay(Hide|Show)Cursor|CGCursorIsVisible|CGWindowLevelForKey|SetsCursorInBackground|_?CGS[A-Z_][A-Za-z0-9_]*|SLS[A-Z_][A-Za-z0-9_]*|NativeCursorVisibilityController|aboveSystemCursorLevel|dlopen|dlsym|@_silgen_name|/System/Library/PrivateFrameworks|KineticCursorModel|KineticResponse|kineticEnabled|kineticResponse|rotationRadians|rotate\(by:|rotate\(byDegrees:|rotate\(byRadians:|rotationEffect|rotation3DEffect|CGAffineTransform\(rotationAngle:|CATransform3DMakeRotation|CGContextRotateCTM'

if grep -R -nE \
  "$prohibited_pattern" \
  Sources Tests Package.swift
then
  echo "Store source contains private cursor APIs or kinetic-only code." >&2
  exit 1
fi

echo "Store source validation passed."
