# WCS-BIM Materials ML Service

Use Python 3.12 for the pinned production dependency set.

Train BPNN, SVM-RBF, random-forest, gradient-boosting, and XGBoost models for every available requested target:

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python train.py data/concrete.csv --output artifacts \
  --targets compressive_strength_mpa tensile_strength_mpa slump_mm rcpt_coulombs water_absorption_pct
uvicorn app:app --reload --port 8000
```

CSV columns must include:

`binder_type,cement_kg,fly_ash_kg,ggbss_kg,silica_fume_kg,water_kg,superplasticizer_kg,fine_aggregate_kg,coarse_aggregate_kg,age_days`

Optional geopolymer inputs are `naoh_molarity`, `curing_temperature_c`, and `alkali_content_kg`. Derived water/binder, SCM, superplasticizer, and log-age features are calculated automatically.

The service exposes `/models`, `/predict`, `/predict/strength`, `/predict/slump`, `/optimize`, `/qc/image`, `/metrics`, and `/health`. Training uses a fixed seed, saves each target/model pipeline, records MAE/RMSE/R2, and registers the best model by R2. CatBoost and XGBoost are compared alongside the baseline portfolio. MLflow logging activates when `MLFLOW_TRACKING_URI` is set. The optimizer returns three strength-compliant cost/carbon trade-offs.

See `MODEL_PORTFOLIO.md` for soil, asphalt, FRP, image-QC, design-copilot, and DFMA deployment guidance.
