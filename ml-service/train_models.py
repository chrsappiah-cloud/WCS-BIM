import json
import os
from datetime import datetime, timezone
from pathlib import Path
from urllib.error import HTTPError
from urllib.request import Request, urlopen

from train import DEFAULT_TARGETS, train

DATASET = Path(os.getenv("TRAINING_DATA_CSV", "data/materials_training.csv"))
OUTPUT = Path(os.getenv("TRAINING_OUTPUT_DIR", "artifacts"))
VERSION = os.getenv("TRAINING_VERSION") or datetime.now(timezone.utc).strftime("%Y.%m.%d.%H%M%S")


def supabase_request(path: str, method: str, payload):
    url = os.getenv("SUPABASE_URL")
    key = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
    if not url or not key:
        return None
    request = Request(
        f"{url.rstrip('/')}/rest/v1/{path}",
        data=json.dumps(payload).encode(),
        method=method,
        headers={
            "apikey": key,
            "Authorization": f"Bearer {key}",
            "Content-Type": "application/json",
            "Prefer": "return=representation",
        },
    )
    try:
        with urlopen(request, timeout=30) as response:
            raw = response.read()
            return json.loads(raw) if raw else None
    except HTTPError as error:
        raise RuntimeError(f"Supabase registry request failed: {error.read().decode()}") from error


def sync_registry(registry: dict):
    registered = []
    features = registry["features"]
    for task, details in registry["targets"].items():
        best_name = details["best_model"]
        metrics = details["models"][best_name]
        supabase_request(f"model_registry?task=eq.{task}", "PATCH", {"active": False})
        payload = {
            "model_name": best_name,
            "version": VERSION,
            "task": task,
            "feature_set": features,
            "metrics": metrics,
            "artifact_path": f"{OUTPUT}/{task}/{best_name}.joblib",
            "active": True,
            "notes": f"Scheduled retraining from {DATASET}",
        }
        response = supabase_request("model_registry", "POST", payload)
        registered.append(response[0] if isinstance(response, list) and response else payload)
    return registered


def main():
    if not DATASET.exists():
        raise FileNotFoundError(f"Training dataset not found: {DATASET}")
    train(DATASET, OUTPUT, DEFAULT_TARGETS)
    registry = json.loads((OUTPUT / "registry.json").read_text())
    print(json.dumps({
        "ok": True,
        "dataset": str(DATASET),
        "version": VERSION,
        "targets": list(registry["targets"]),
        "registeredModels": sync_registry(registry),
    }))


if __name__ == "__main__":
    main()
