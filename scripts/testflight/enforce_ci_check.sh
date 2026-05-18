#!/usr/bin/env bash
# CI validation for TestFlight admin scripts (no API secrets required).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

python3 -m py_compile asc_client.py access_registry.py admin_cli.py

python3 admin_cli.py --dry-run catalog >/dev/null
python3 admin_cli.py --dry-run access list >/dev/null
python3 admin_cli.py --dry-run testflight list-groups >/dev/null
python3 admin_cli.py --dry-run testflight list-builds >/dev/null

python3 admin_cli.py --dry-run access grant --email ci@wcs.test --tier pro --days 30 >/dev/null
ENTRIES=$(python3 admin_cli.py access list)
echo "$ENTRIES" | grep -q 'ci@wcs.test' || { echo "access grant failed"; exit 1; }
python3 admin_cli.py access revoke --email ci@wcs.test >/dev/null

# Revert registry entries from CI run
python3 - <<'PY'
import json
from pathlib import Path
p = Path("access_registry.json")
data = json.loads(p.read_text())
data["entries"] = [e for e in data.get("entries", []) if e.get("email") != "ci@wcs.test"]
p.write_text(json.dumps(data, indent=2) + "\n")
PY

echo "TestFlight script CI checks passed."
