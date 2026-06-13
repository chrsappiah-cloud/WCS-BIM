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
if [ -f "$ENV_FILE" ]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

if [ -z "${ASC_KEY_ID:-}" ] || [ -z "${ASC_ISSUER_ID:-}" ]; then
  echo "Missing App Store Connect API credentials." >&2
  echo "Set ASC_KEY_ID and ASC_ISSUER_ID in the environment or $ENV_FILE." >&2
  echo "IPA ready: $IPA" >&2
  exit 2
fi

KEY_STORE="$HOME/.appstoreconnect/private_keys"
KEY_TARGET="$KEY_STORE/AuthKey_${ASC_KEY_ID}.p8"
mkdir -p "$KEY_STORE"

if [ -n "${ASC_PRIVATE_KEY_PATH:-}" ] && [ -f "${ASC_PRIVATE_KEY_PATH}" ]; then
  cp "${ASC_PRIVATE_KEY_PATH}" "$KEY_TARGET"
elif [ -n "${ASC_PRIVATE_KEY:-}" ]; then
  printf '%s\n' "${ASC_PRIVATE_KEY}" > "$KEY_TARGET"
else
  echo "Missing ASC private key. Set ASC_PRIVATE_KEY_PATH or ASC_PRIVATE_KEY." >&2
  echo "IPA ready: $IPA" >&2
  exit 2
fi

chmod 600 "$KEY_TARGET"

export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
xcrun altool --upload-app --type ios --file "$IPA" \
  --apiKey "$ASC_KEY_ID" \
  --apiIssuer "$ASC_ISSUER_ID"

echo "Upload submitted. Track processing: https://appstoreconnect.apple.com/apps/6770373495/testflight"
