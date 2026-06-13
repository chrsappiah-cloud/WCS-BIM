import argparse
import json
from pathlib import Path

import joblib
import pandas as pd
from sklearn.compose import ColumnTransformer
from sklearn.ensemble import GradientBoostingRegressor, RandomForestRegressor
from sklearn.impute import SimpleImputer
from sklearn.metrics import mean_absolute_error, r2_score, root_mean_squared_error
from sklearn.model_selection import train_test_split
from sklearn.neural_network import MLPRegressor
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder, StandardScaler
from sklearn.svm import SVR
from mlflow_utils import log_model

NUMERIC_FEATURES = [
    "cement_kg", "fly_ash_kg", "ggbss_kg", "silica_fume_kg", "water_kg",
    "superplasticizer_kg", "fine_aggregate_kg", "coarse_aggregate_kg",
    "w_b_ratio", "scm_ratio", "sp_ratio", "age_days", "log_age_days",
    "naoh_molarity", "curing_temperature_c", "alkali_content_kg",
]
CATEGORICAL_FEATURES = ["binder_type"]
DEFAULT_TARGETS = [
    "compressive_strength_mpa", "tensile_strength_mpa", "slump_mm",
    "permeability", "soil_cbr", "rcpt_coulombs", "water_absorption_pct",
]


def engineer(frame: pd.DataFrame) -> pd.DataFrame:
    frame = frame.copy()
    derived = {"w_b_ratio", "scm_ratio", "sp_ratio", "log_age_days"}
    for column in (feature for feature in NUMERIC_FEATURES if feature not in derived):
        if column not in frame:
            frame[column] = 0.0
    for column in derived:
        if column not in frame:
            frame[column] = float("nan")
    if "binder_type" not in frame:
        frame["binder_type"] = "OPC"

    binder = (
        frame["cement_kg"] + frame["fly_ash_kg"] + frame["ggbss_kg"]
        + frame["silica_fume_kg"] + frame["alkali_content_kg"]
    ).replace(0, float("nan"))
    scm = frame["fly_ash_kg"] + frame["ggbss_kg"] + frame["silica_fume_kg"]
    frame["w_b_ratio"] = frame["w_b_ratio"].fillna(frame["water_kg"] / binder)
    frame["scm_ratio"] = frame["scm_ratio"].fillna(scm / binder)
    frame["sp_ratio"] = frame["sp_ratio"].fillna(frame["superplasticizer_kg"] / binder)
    frame["log_age_days"] = frame["age_days"].clip(lower=1).map(__import__("math").log)
    return frame


def preprocessor() -> ColumnTransformer:
    numeric = Pipeline([
        ("impute", SimpleImputer(strategy="median")),
        ("scale", StandardScaler()),
    ])
    categorical = Pipeline([
        ("impute", SimpleImputer(strategy="most_frequent")),
        ("one_hot", OneHotEncoder(handle_unknown="ignore")),
    ])
    return ColumnTransformer([
        ("numeric", numeric, NUMERIC_FEATURES),
        ("categorical", categorical, CATEGORICAL_FEATURES),
    ])


def estimators() -> dict[str, object]:
    models: dict[str, object] = {
        "bpnn": MLPRegressor(
            hidden_layer_sizes=(12,), activation="logistic", solver="lbfgs",
            max_iter=2000, random_state=42,
        ),
        "svm_rbf": SVR(kernel="rbf", C=100, gamma="scale", epsilon=0.1),
        "random_forest": RandomForestRegressor(
            n_estimators=500, min_samples_leaf=2, n_jobs=-1, random_state=42,
        ),
        "gradient_boosting": GradientBoostingRegressor(
            n_estimators=400, learning_rate=0.035, max_depth=3,
            loss="huber", random_state=42,
        ),
    }
    try:
        from xgboost import XGBRegressor
        models["xgboost"] = XGBRegressor(
            n_estimators=500, learning_rate=0.035, max_depth=4,
            subsample=0.85, colsample_bytree=0.85, objective="reg:squarederror",
            n_jobs=-1, random_state=42,
        )
    except ImportError:
        pass
    try:
        from catboost import CatBoostRegressor
        models["catboost"] = CatBoostRegressor(
            iterations=500, depth=6, learning_rate=0.05, verbose=False,
            random_seed=42, allow_writing_files=False,
        )
    except ImportError:
        pass
    return models


def train(csv_path: Path, output_dir: Path, requested_targets: list[str]) -> None:
    frame = engineer(pd.read_csv(csv_path))
    targets = [target for target in requested_targets if target in frame and frame[target].notna().sum() >= 10]
    if not targets:
        raise ValueError("No requested target has at least 10 non-null rows.")

    output_dir.mkdir(parents=True, exist_ok=True)
    registry: dict[str, object] = {"features": NUMERIC_FEATURES + CATEGORICAL_FEATURES, "targets": {}}
    for target in targets:
        target_frame = frame.dropna(subset=[target])
        x_train, x_test, y_train, y_test = train_test_split(
            target_frame[NUMERIC_FEATURES + CATEGORICAL_FEATURES],
            target_frame[target], test_size=0.2, random_state=42,
        )
        target_metrics: dict[str, dict[str, float]] = {}
        target_dir = output_dir / target
        target_dir.mkdir(exist_ok=True)
        for name, estimator in estimators().items():
            model = Pipeline([("features", preprocessor()), ("model", estimator)])
            model.fit(x_train, y_train)
            predicted = model.predict(x_test)
            target_metrics[name] = {
                "mae": float(mean_absolute_error(y_test, predicted)),
                "rmse": float(root_mean_squared_error(y_test, predicted)),
                "r2": float(r2_score(y_test, predicted)),
            }
            joblib.dump(model, target_dir / f"{name}.joblib")

        best = max(target_metrics, key=lambda name: target_metrics[name]["r2"])
        registry["targets"][target] = {"best_model": best, "models": target_metrics}
        log_model(joblib.load(target_dir / f"{best}.joblib"), target_metrics[best], f"{target}-{best}")

    (output_dir / "registry.json").write_text(json.dumps(registry, indent=2))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Train reproducible materials-property regressors.")
    parser.add_argument("csv", type=Path)
    parser.add_argument("--output", type=Path, default=Path("artifacts"))
    parser.add_argument("--targets", nargs="+", default=DEFAULT_TARGETS)
    args = parser.parse_args()
    train(args.csv, args.output, args.targets)
