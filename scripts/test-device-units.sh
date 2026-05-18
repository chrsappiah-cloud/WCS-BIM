#!/usr/bin/env bash
# Run full WCS-BIM unit test suite on a connected physical iPhone.
set -euo pipefail
cd "$(dirname "$0")/.."

DEVICE_ID="${DEVICE_ID:-}"
if [ -z "$DEVICE_ID" ]; then
  DEVICE_ID=$(xcodebuild -project WCS-BIM.xcodeproj -scheme WCS-BIM -showdestinations 2>/dev/null \
    | sed -n "s/.*platform:iOS, arch:arm64, id:\([^,]*\), name:.*iPhone.*/\1/p" | head -1)
fi
if [ -z "$DEVICE_ID" ]; then
  DEVICE_ID="00008150-001102643CD2401C"
fi

DEST="platform=iOS,id=${DEVICE_ID}"
echo "Device unit tests → $DEST"

bash scripts/api/validate-integrations.sh

xcodebuild -project WCS-BIM.xcodeproj -scheme WCS-BIM \
  -destination "$DEST" \
  -allowProvisioningUpdates \
  build-for-testing

xcodebuild -project WCS-BIM.xcodeproj -scheme WCS-BIM \
  -destination "$DEST" \
  -allowProvisioningUpdates \
  -only-testing:WCS-BIMTests \
  -skip-testing:WCS-BIMTests/ModelContainerBootstrapTests \
  test-without-building

echo "All device unit tests passed on $DEVICE_ID"
