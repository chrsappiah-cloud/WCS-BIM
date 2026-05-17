#!/usr/bin/env bash
# Copy App Store assets and operational manual PDF to ~/Desktop/WCS-BIM-Production
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DESKTOP="${HOME}/Desktop/WCS-BIM-Production"
mkdir -p "${DESKTOP}/AppStore" "${DESKTOP}/AppIcon"
cp "${ROOT}/Marketing/AppIcon-1024.png" "${DESKTOP}/AppIcon/AppIcon-1024.png"
cp "${ROOT}/Marketing/AppStore/"promo-*.png "${DESKTOP}/AppStore/"
"${ROOT}/.venv-manual/bin/python" "${ROOT}/scripts/generate-operational-manual-pdf.py" 2>/dev/null \
  || python3 "${ROOT}/scripts/generate-operational-manual-pdf.py"
cp "${DESKTOP}/WCS-BIM-Operational-Manual-50pg.pdf" "${HOME}/Desktop/" 2>/dev/null || true
echo "Assets packaged at ${DESKTOP}"
