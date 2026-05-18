#!/usr/bin/env bash
# Archive Release build and upload to App Store Connect (TestFlight production).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

BUILD_DIR="${BUILD_DIR:-$ROOT/build/testflight}"
ARCHIVE_PATH="$BUILD_DIR/WCS-BIM.xcarchive"
EXPORT_PATH="$BUILD_DIR/export"
EXPORT_PLIST="$ROOT/scripts/testflight/ExportOptions.plist"

mkdir -p "$BUILD_DIR"
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

if [ ! -d "$ARCHIVE_PATH" ]; then
  echo "Archiving WCS-BIM (Release)..."
  xcodebuild -project WCS-BIM.xcodeproj -scheme WCS-BIM \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    -archivePath "$ARCHIVE_PATH" \
    -allowProvisioningUpdates \
    archive
else
  echo "Using existing archive: $ARCHIVE_PATH"
fi

echo "Exporting IPA for App Store Connect..."
rm -rf "$EXPORT_PATH"
# Homebrew rsync breaks Xcode export (unknown --extended-attributes). Prefer Apple rsync.
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$EXPORT_PLIST" \
  -allowProvisioningUpdates

IPA=$(find "$EXPORT_PATH" -maxdepth 1 -name '*.ipa' | head -1)
if [ -z "$IPA" ]; then
  echo "No IPA found in $EXPORT_PATH" >&2
  exit 1
fi
echo "IPA: $IPA"

# Prefer App Store Connect API key from scripts/testflight/.env
ENV_FILE="$ROOT/scripts/testflight/.env"
if [ -f "$ENV_FILE" ]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

if [ -f "$ENV_FILE" ]; then
  exec "$ROOT/scripts/testflight/upload-ipa.sh" "$IPA"
fi

echo "ASC API key not configured. Set scripts/testflight/.env then run:"
echo "  ./scripts/testflight/upload-ipa.sh \"$IPA\""
echo "Or upload via Xcode Organizer / Transporter."
echo "IPA ready at: $IPA"
open "$EXPORT_PATH" 2>/dev/null || true
exit 0

echo "Upload submitted. Processing in App Store Connect → TestFlight (app 6770373495)."
if [ -f "$ROOT/scripts/testflight/.venv/bin/python" ]; then
  "$ROOT/scripts/testflight/.venv/bin/python" "$ROOT/scripts/testflight/admin_cli.py" testflight list-builds || true
elif command -v python3 >/dev/null; then
  (cd "$ROOT/scripts/testflight" && python3 admin_cli.py testflight list-builds) 2>/dev/null || true
fi
