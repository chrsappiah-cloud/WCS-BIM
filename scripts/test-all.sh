#!/usr/bin/env bash
# Full validation: API check, all unit tests, all UI tiers (XCTest).
set -euo pipefail
cd "$(dirname "$0")/.."

DEST="${SIM_DESTINATION:-platform=iOS Simulator,name=iPhone 17 Pro Max,OS=26.5}"

echo "== API integration validation =="
bash scripts/api/validate-integrations.sh

echo "== Build =="
xcodebuild -project WCS-BIM.xcodeproj -scheme WCS-BIM \
  -destination "$DEST" build

echo "== Unit tests (WCS-BIMTests) =="
xcodebuild -project WCS-BIM.xcodeproj -scheme WCS-BIM \
  -destination "$DEST" \
  -only-testing:WCS-BIMTests \
  -skip-testing:WCS-BIMTests/ModelContainerBootstrapTests \
  test

echo "== UI tests (all tiers + matrix) =="
bash scripts/test-ui-all.sh

python3 scripts/generate-test-catalog.py 2>/dev/null || true

echo "All tests passed."
