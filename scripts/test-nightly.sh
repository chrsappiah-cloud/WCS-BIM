#!/usr/bin/env bash
# Nightly locally: Tier 2 + Tier 3 UI (+ optional performance).
set -euo pipefail
cd "$(dirname "$0")/.."

DEST="${SIM_DESTINATION:-platform=iOS Simulator,name=iPhone 17 Pro Max,OS=26.5}"

xcodebuild -project WCS-BIM.xcodeproj -scheme WCS-BIM \
  -destination "$DEST" build

xcodebuild -project WCS-BIM.xcodeproj -scheme WCS-BIM \
  -destination "$DEST" \
  -only-testing:WCS-BIMUITests/Tier2RegressionUITests \
  -only-testing:WCS-BIMUITests/Tier3ScreenUITests \
  test

echo "Nightly UI tiers passed."
