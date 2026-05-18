#!/usr/bin/env bash
# Upload an exported IPA to App Store Connect (TestFlight). Requires scripts/testflight/.env
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

IPA="${1:-$(find "$ROOT/build/testflight/export" -maxdepth 1 -name '*.ipa' 2>/dev/null | head -1)}"
if [ -z "$IPA" ] || [ ! -f "$IPA" ]; then
  echo "Usage: $0 [path/to/WCS-BIM.ipa]" >&2
  echo "Export first: ./scripts/testflight/archive-and-upload.sh" >&2
  exit 1
fi

ENV_FILE="$ROOT/scripts/testflight/.env"
if [ ! -f "$ENV_FILE" ]; then
  echo "Missing $ENV_FILE — copy config.example.env and add your App Store Connect API key." >&2
  echo "IPA ready: $IPA" >&2
  echo "Or upload with Transporter / Xcode Organizer → Distribute App." >&2
  exit 2
fi

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
xcrun altool --upload-app --type ios --file "$IPA" \
  --apiKey "$ASC_KEY_ID" \
  --apiIssuer "$ASC_ISSUER_ID"

echo "Upload submitted. Track processing: https://appstoreconnect.apple.com/apps/6770373495/testflight"
