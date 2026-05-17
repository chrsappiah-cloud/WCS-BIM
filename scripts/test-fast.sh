#!/usr/bin/env bash
# Local pre-commit: build + fast unit + contract (no UI).
set -euo pipefail
cd "$(dirname "$0")/.."

DEST="${SIM_DESTINATION:-platform=iOS Simulator,name=iPhone 17 Pro Max,OS=26.5}"

xcodebuild -project WCS-BIM.xcodeproj -scheme WCS-BIM \
  -destination "$DEST" build

xcodebuild -project WCS-BIM.xcodeproj -scheme WCS-BIM \
  -destination "$DEST" \
  -only-testing:WCS-BIMTests/WCS_BIMTests \
  -only-testing:WCS-BIMTests/AppSettingsUpdaterTests \
  -only-testing:WCS-BIMTests/OpenAIResponseContractTests \
  test

echo "Fast suite passed."
