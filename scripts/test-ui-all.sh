#!/usr/bin/env bash
# Run all UI XCTest suites (tiers 1–4, matrix, design system, E2E, launch).
set -euo pipefail
cd "$(dirname "$0")/.."

DEST="${SIM_DESTINATION:-platform=iOS Simulator,name=iPhone 17 Pro Max,OS=26.5}"
INCLUDE_PERF="${INCLUDE_PERF:-0}"

ARGS=(
  -project WCS-BIM.xcodeproj
  -scheme WCS-BIM
  -destination "$DEST"
  -parallel-testing-enabled NO
  test
  -only-testing:WCS-BIMUITests/Tier1SmokeUITests
  -only-testing:WCS-BIMUITests/Tier2RegressionUITests
  -only-testing:WCS-BIMUITests/Tier3ScreenUITests
  -only-testing:WCS-BIMUITests/Tier4FeaturesUITests
  -only-testing:WCS-BIMUITests/UIFunctionMatrixUITests
  -only-testing:WCS-BIMUITests/DesignSystemUITests
  -only-testing:WCS-BIMUITests/AllUIUnitsUITests
  -only-testing:WCS-BIMUITests/WCS_BIMUITestsLaunchTests
)

if [[ "$INCLUDE_PERF" == "1" ]]; then
  ARGS+=(-only-testing:WCS-BIMUITests/Tier5PerformanceUITests)
fi

xcodebuild "${ARGS[@]}"
echo "UI suite passed."
