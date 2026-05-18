#!/usr/bin/env bash
# Build and install WCS-BIM on a connected iPhone (default: first connected device).
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

echo "Building for device $DEVICE_ID ..."
xcodebuild -project WCS-BIM.xcodeproj -scheme WCS-BIM \
  -configuration Debug \
  -destination "platform=iOS,id=${DEVICE_ID}" \
  -allowProvisioningUpdates \
  build

APP=$(find ~/Library/Developer/Xcode/DerivedData -path "*Debug-iphoneos/WCS-BIM.app" -type d 2>/dev/null | head -1)
if [ -z "$APP" ]; then
  echo "Could not find WCS-BIM.app in DerivedData" >&2
  exit 1
fi

echo "Installing $APP ..."
xcrun devicectl device install app --device "$DEVICE_ID" "$APP"
echo "Installed on device $DEVICE_ID"
