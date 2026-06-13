import os
from typing import Any


def log_model(model: Any, metrics: dict[str, float], model_name: str) -> None:
    """Log when MLflow is configured; local training remains usable without it."""
    if not os.getenv("MLFLOW_TRACKING_URI"):
        return
    import mlflow
    import mlflow.sklearn

    mlflow.set_tracking_uri(os.environ["MLFLOW_TRACKING_URI"])
    mlflow.set_experiment(os.getenv("MLFLOW_EXPERIMENT", "wcs-bim-materials"))
    with mlflow.start_run(run_name=model_name):
        mlflow.log_metrics(metrics)
        mlflow.sklearn.log_model(model, artifact_path="model", registered_model_name=model_name)
