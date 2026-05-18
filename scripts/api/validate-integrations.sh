#!/usr/bin/env bash
# Validates API integration sources and catalog completeness for CI.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

REQUIRED=(
  WCS-BIM/APIIntegration/Catalog/APIProviderCatalog.swift
  WCS-BIM/APIIntegration/Protocols/APIIntegrationProtocols.swift
  WCS-BIM/APIIntegration/Hub/APIIntegrationHub.swift
  WCS-BIM/APIIntegration/Apple/AppleMotionSensorService.swift
  WCS-BIM/APIIntegration/Apple/AppleCameraCaptureView.swift
  WCS-BIM/APIIntegration/External/OpenAIGenerationProvider.swift
  WCS-BIM/APIIntegration/External/HuggingFaceInferenceProvider.swift
  WCS-BIM/APIIntegration/External/OfflineTemplateAIProvider.swift
  WCS-BIM/Presentation/FieldSystems/FieldSystemsView.swift
)

for file in "${REQUIRED[@]}"; do
  if [[ ! -f "$file" ]]; then
    echo "Missing required integration file: $file" >&2
    exit 1
  fi
done

python3 - <<'PY'
import pathlib
import sys

root = pathlib.Path("WCS-BIM/APIIntegration/Catalog/APIProviderCatalog.swift")
text = root.read_text()
required_ids = [
    "apple.corelocation",
    "apple.coremotion",
    "apple.uikit.camera",
    "apple.vision.ocr",
    "openai.chat",
    "huggingface.inference",
    "offline.templates",
]
missing = [i for i in required_ids if i not in text]
if missing:
    print("Catalog missing provider IDs:", ", ".join(missing), file=sys.stderr)
    sys.exit(1)
print("API integration catalog OK (%d providers checked)" % len(required_ids))
PY

if ! grep -q "NSCameraUsageDescription" WCS-BIM/Info.plist; then
  echo "Info.plist missing NSCameraUsageDescription" >&2
  exit 1
fi

if ! grep -q "NSMotionUsageDescription" WCS-BIM/Info.plist; then
  echo "Info.plist missing NSMotionUsageDescription" >&2
  exit 1
fi

echo "validate-integrations.sh passed."
