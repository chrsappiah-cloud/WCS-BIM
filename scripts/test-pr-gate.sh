#!/usr/bin/env bash
# PR gate locally: unit (minus flaky integration) + Tier 1 UI smoke.
set -euo pipefail
cd "$(dirname "$0")/.."

DEST="${SIM_DESTINATION:-platform=iOS Simulator,name=iPhone 17 Pro Max,OS=26.5}"

xcodebuild -project WCS-BIM.xcodeproj -scheme WCS-BIM \
  -destination "$DEST" build

xcodebuild -project WCS-BIM.xcodeproj -scheme WCS-BIM \
  -destination "$DEST" \
  -only-testing:WCS-BIMTests \
  -skip-testing:WCS-BIMTests/ModelContainerBootstrapTests \
  test

xcodebuild -project WCS-BIM.xcodeproj -scheme WCS-BIM \
  -destination "$DEST" \
  -only-testing:WCS-BIMUITests/Tier1SmokeUITests \
  test

python3 scripts/generate-test-catalog.py >/dev/null 2>&1 || true

echo "PR gate passed."
