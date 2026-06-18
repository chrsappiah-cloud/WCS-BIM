import json
import os
import subprocess
import sys
import threading
from datetime import datetime, timezone
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
from fastapi import FastAPI, HTTPException, Request
from pydantic import BaseModel, Field
from scipy.optimize import differential_evolution
from PIL import Image
from io import BytesIO
import base64

ARTIFACTS = Path("artifacts")
app = FastAPI(title="WCS-BIM Materials ML Service", version="2.0.0")
request_count = 0
retraining_lock = threading.Lock()
retraining_status = {
    "state": "idle",
    "startedAt": None,
    "finishedAt": None,
    "exitCode": None,
    "message": "No retraining job has run.",
}


def utc_now():
    return datetime.now(timezone.utc).isoformat()


class PredictionRequest(BaseModel):
    target: str = "compressive_strength_mpa"
    model: str = "best"
    inputFeatures: dict[str, float | str]


class MaterialsPredictionRequest(BaseModel):
    targets: list[str] = Field(default_factory=lambda: ["compressive_strength_mpa", "tensile_strength_mpa", "permeability"])
    inputFeatures: dict[str, float | str]


class OptimizeRequest(BaseModel):
    targetProperties: dict[str, float] = Field(default_factory=dict)
    constraints: dict[str, float] = Field(default_factory=dict)
    availableComponents: list[str] = Field(default_factory=list)


class ImageQCRequest(BaseModel):
    imageBase64: str
    bimElementId: str | None = None


def registry() -> dict:
    path = ARTIFACTS / "registry.json"
    if not path.exists():
        raise HTTPException(503, "Model registry not found. Run train.py first.")
    return json.loads(path.read_text())


def model_for(target: str, name: str):
    registered = registry().get("targets", {}).get(target)
    if not registered:
        raise HTTPException(404, f"No trained models registered for {target}.")
    selected = registered["best_model"] if name == "best" else name
    path = ARTIFACTS / target / f"{selected}.joblib"
    if not path.exists():
        raise HTTPException(404, f"Model artifact not found: {target}/{selected}.")
    return selected, joblib.load(path)


def feature_frame(features: dict[str, float | str]) -> pd.DataFrame:
    row = dict(features)
    for key in [
        "cement_kg", "fly_ash_kg", "ggbss_kg", "silica_fume_kg", "water_kg",
        "superplasticizer_kg", "fine_aggregate_kg", "coarse_aggregate_kg",
        "naoh_molarity", "curing_temperature_c", "alkali_content_kg",
    ]:
        row.setdefault(key, 0.0)
    row.setdefault("binder_type", "OPC")
    row.setdefault("age_days", 28.0)
    binder = max(1.0, sum(float(row[key]) for key in ["cement_kg", "fly_ash_kg", "ggbss_kg", "silica_fume_kg", "alkali_content_kg"]))
    row.setdefault("w_b_ratio", float(row["water_kg"]) / binder)
    row.setdefault("scm_ratio", sum(float(row[key]) for key in ["fly_ash_kg", "ggbss_kg", "silica_fume_kg"]) / binder)
    row.setdefault("sp_ratio", float(row["superplasticizer_kg"]) / binder)
    row.setdefault("log_age_days", float(np.log(max(1.0, float(row["age_days"])))))
    return pd.DataFrame([row])


@app.get("/health")
def health():
    return {"status": "ok", "registry": registry() if (ARTIFACTS / "registry.json").exists() else None}


@app.middleware("http")
async def count_requests(request: Request, call_next):
    global request_count
    request_count += 1
    return await call_next(request)


@app.get("/metrics")
def metrics():
    return {"requests": request_count, "registeredTargets": len(registry().get("targets", {})) if (ARTIFACTS / "registry.json").exists() else 0}


@app.get("/models")
def models():
    return registry()


def run_retraining():
    retraining_status.update(state="running", startedAt=utc_now(), finishedAt=None, exitCode=None, message="Training models.")
    try:
        completed = subprocess.run(
            [sys.executable, "train_models.py"],
            capture_output=True,
            text=True,
            timeout=int(os.getenv("RETRAIN_TIMEOUT_SECONDS", "7200")),
            check=False,
        )
        message = completed.stdout.strip() or completed.stderr.strip()
        retraining_status.update(
            state="completed" if completed.returncode == 0 else "failed",
            finishedAt=utc_now(),
            exitCode=completed.returncode,
            message=message[-4000:],
        )
    except Exception as error:
        retraining_status.update(state="failed", finishedAt=utc_now(), exitCode=None, message=str(error))
    finally:
        retraining_lock.release()


@app.get("/retrain/status")
def retrain_status():
    return retraining_status


@app.post("/retrain/run", status_code=202)
def retrain_run():
    if not retraining_lock.acquire(blocking=False):
        raise HTTPException(409, "A retraining job is already running.")
    threading.Thread(target=run_retraining, daemon=True).start()
    return {"accepted": True, "state": "running"}


@app.post("/drift/check")
def drift_check(payload: dict):
    from drift_check import drift
    if not payload.get("currentPath") or not payload.get("baselinePath"):
        raise HTTPException(400, "currentPath and baselinePath are required.")
    return drift(payload["currentPath"], payload["baselinePath"])


@app.post("/predict")
def predict(payload: PredictionRequest):
    selected, model = model_for(payload.target, payload.model)
    prediction = float(model.predict(feature_frame(payload.inputFeatures))[0])
    return {"target": payload.target, "value": prediction, "model": selected}


@app.post("/predict/materials")
def predict_materials(payload: MaterialsPredictionRequest):
    registered_targets = registry().get("targets", {})
    requested = [target for target in payload.targets if target in registered_targets]
    if not requested:
        raise HTTPException(404, "None of the requested material properties has a registered model.")

    predictions: dict[str, float] = {}
    models: dict[str, str] = {}
    confidences: list[float] = []
    frame = feature_frame(payload.inputFeatures)
    for target in requested:
        selected, model = model_for(target, "best")
        predictions[target] = float(model.predict(frame)[0])
        models[target] = selected
        metrics = registered_targets[target].get("models", {}).get(selected, {})
        confidences.append(float(np.clip(metrics.get("r2", 0.5), 0.0, 1.0)))

    return {
        "predictions": predictions,
        "models": models,
        "confidence": float(np.mean(confidences)),
        "unavailableTargets": [target for target in payload.targets if target not in registered_targets],
    }


@app.post("/predict/strength")
def predict_strength(payload: PredictionRequest):
    payload.target = "compressive_strength_mpa"
    result = predict(payload)
    return {"prediction_mpa": result["value"], "model_version": result["model"]}


@app.post("/predict/slump")
def predict_slump(payload: PredictionRequest):
    payload.target = "slump_mm"
    result = predict(payload)
    return {"prediction_mm": result["value"], "model_version": result["model"]}


@app.post("/qc/image")
def image_qc(payload: ImageQCRequest):
    try:
        raw = base64.b64decode(payload.imageBase64, validate=True)
        image = Image.open(BytesIO(raw)).convert("L").resize((256, 256))
    except Exception as error:
        raise HTTPException(400, f"Invalid inspection image: {error}") from error
    pixels = np.asarray(image, dtype=float)
    gradient = np.hypot(*np.gradient(pixels))
    edge_density = float(np.mean(gradient > 28))
    return {
        "bimElementId": payload.bimElementId,
        "screening": "review_recommended" if edge_density > 0.16 else "no_obvious_surface_anomaly",
        "edgeDensity": edge_density,
        "confidence": min(0.95, 0.55 + abs(edge_density - 0.16)),
        "disclaimer": "Automated visual screening only; requires qualified human review.",
    }


@app.post("/optimize")
def optimize(payload: OptimizeRequest):
    selected, model = model_for("compressive_strength_mpa", "best")
    target = payload.targetProperties.get("compressive_strength_mpa", 45.0)
    maximum_co2 = payload.constraints.get("max_co2_kg_per_m3", 300.0)
    maximum_cost = payload.constraints.get("max_cost_per_m3", 200.0)
    keys = ["cement_kg", "fly_ash_kg", "ggbss_kg", "silica_fume_kg", "water_kg",
            "superplasticizer_kg", "fine_aggregate_kg", "coarse_aggregate_kg"]
    bounds = [(120, 500), (0, 300), (0, 300), (0, 80), (100, 260), (0, 25), (450, 1100), (550, 1300)]

    def values(x):
        binder = max(1.0, sum(x[:4]))
        features = dict(zip(keys, map(float, x)))
        features.update({
            "binder_type": "blended", "w_b_ratio": float(x[4] / binder),
            "scm_ratio": float(sum(x[1:4]) / binder), "sp_ratio": float(x[5] / binder),
            "age_days": 28.0, "log_age_days": float(np.log(28)),
            "naoh_molarity": 0.0, "curing_temperature_c": 20.0, "alkali_content_kg": 0.0,
        })
        strength = float(model.predict(feature_frame(features))[0])
        co2 = x[0] * 0.82 + x[1] * 0.04 + x[2] * 0.07 + x[3] * 0.18
        cost = x[0] * 0.16 + x[1] * 0.08 + x[2] * 0.09 + x[3] * 0.35 + (x[6] + x[7]) * 0.025 + x[5] * 2.5
        return features, strength, co2, cost

    mixes = []
    for seed, tradeoff in enumerate((0.25, 0.5, 0.75), start=41):
        def objective(x):
            _, strength, co2, cost = values(x)
            penalty = max(0, target - strength) * 1000 + max(0, co2 - maximum_co2) * 1000 + max(0, cost - maximum_cost) * 1000
            return tradeoff * cost + (1 - tradeoff) * co2 + abs(strength - target) * 20 + penalty

        result = differential_evolution(objective, bounds, seed=seed, maxiter=100, polish=True)
        features, strength, co2, cost = values(result.x)
        mixes.append({
            "components": {key: features[key] for key in keys},
            "compressiveStrengthMPa": strength, "slumpMM": 100.0, "permeability": None,
            "co2KgPerM3": float(co2), "costPerM3": float(cost),
        })
    return {
        "mixes": mixes,
        "rationale": f"Three cost-carbon trade-offs optimized against the best registered strength surrogate ({selected}).",
    }
