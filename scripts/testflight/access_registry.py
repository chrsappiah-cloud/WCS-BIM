"""Local admin registry for subscription / TestFlight access (source of truth for scripts)."""

from __future__ import annotations

import json
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any

REGISTRY_PATH = Path(__file__).resolve().parent / "access_registry.json"


def load_registry() -> dict[str, Any]:
    if not REGISTRY_PATH.exists():
        return {"version": 1, "updated_at": None, "entries": []}
    return json.loads(REGISTRY_PATH.read_text(encoding="utf-8"))


def save_registry(data: dict[str, Any]) -> None:
    data["updated_at"] = datetime.now(timezone.utc).isoformat()
    REGISTRY_PATH.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")


def grant_access(email: str, tier: str, days: int, payment_ref: str = "") -> dict[str, Any]:
    data = load_registry()
    expires = (datetime.now(timezone.utc) + timedelta(days=days)).isoformat()
    entry = {
        "email": email.lower().strip(),
        "tier": tier,
        "expires_at": expires,
        "payment_ref": payment_ref,
        "testflight": True,
    }
    entries = [e for e in data.get("entries", []) if e.get("email") != entry["email"]]
    entries.append(entry)
    data["entries"] = entries
    save_registry(data)
    return entry


def revoke_access(email: str) -> bool:
    data = load_registry()
    before = len(data.get("entries", []))
    data["entries"] = [
        e for e in data.get("entries", []) if e.get("email") != email.lower().strip()
    ]
    save_registry(data)
    return len(data["entries"]) < before


def list_entries() -> list[dict[str, Any]]:
    return load_registry().get("entries", [])
