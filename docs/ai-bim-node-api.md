# WCS-BIM Four-Pillar Node/Supabase API

The iOS `AI BIM Lab` can operate offline with deterministic rules and may be connected to these Express/TypeScript endpoints for shared organisational data and model-backed generation.

## Resource endpoints

| Method | Endpoint | Purpose |
| --- | --- | --- |
| `GET/POST` | `/projects`, `/api/projects` | List or create projects |
| `GET/PATCH` | `/projects/:id`, `/api/projects/:id` | Read or update project context |
| `GET/POST` | `/api/projects/:id/materials` | Project-scoped material catalog and specifications |
| `GET/POST` | `/api/projects/:id/tests` | Project-scoped material testing and prediction records |
| `GET/POST` | `/api/projects/:id/bim-elements` | Project-scoped IFC/BIM elements and metadata |
| `GET/POST` | `/projects/:id/design-alternatives` | BIM-linked design strategies |
| `GET/POST` | `/projects/:id/fabrication-modules` | DFMA process plans and as-built feedback |
| `GET` | `/api/materials?projectId=...` | Compatibility material list response with `items` |
| `GET/POST` | `/api/tests?projectId=...`, `/api/tests` | Compatibility material-test routes |
| `GET` | `/api/bim/elements?projectId=...` | Compatibility BIM element list response with `items` |
| `POST` | `/api/bim/link-test` | Link one project-scoped material test to a BIM element |
| `POST` | `/api/bim/fabrication-plan` | Create a fabrication plan with an explicit project ID |
| `GET/POST` | `/api/projects/:id/fabrication-plans` | Persist project-scoped fabrication plans |
| `GET` | `/api/projects/:id/reports` | List persisted AI-generated project reports |
| `POST` | `/api/reports/material-test` | Generate and persist a material-test report |
| `POST` | `/api/tests/report` | Compatibility alias for a persisted material-test report |
| `GET/POST` | `/api/model-registry` | List or register model versions, tasks, metrics, and active state |
| `GET/PATCH/DELETE` | `/api/model-registry/:id` | Read, update, activate, or delete one registered model |
| `POST` | `/api/uploads/file` | Upload one validated project file to an approved private bucket |
| `POST` | `/api/uploads/signed-url` | Create a short-lived URL for an authorised project file |
| `GET/POST` | `/api/retrain/status`, `/api/retrain/run` | Inspect or trigger the controlled background retraining job |
| `POST` | `/api/retrain/drift-check` | Run a KS distribution-drift check through the ML service |

## Codex-style prompt endpoints

### `POST /ai/mix-optimizer`

Accepts target properties, cost/CO2 constraints, and available components. Returns three mixes and a rationale. Production implementations can route to MFA-ANN, RF, SVM-RBF, GA, MFA, or BAS services.

The Node gateway includes a deterministic Python heuristic engine at `backend/python/optimizer.py`. `/ai/mix-optimizer` uses it directly, while `/api/materials/optimize` falls back to it when the trained-model ML service is unavailable. Configure `PYTHON_PATH` and `OPTIMIZER_TIMEOUT_MS` when needed.

### `POST /ai/qc-report`

Accepts project metadata, material-test records, specimen image-analysis output, and linked BIM element IDs. Returns a markdown QA report with non-conformances and recommendations.

### `POST /ai/design-copilot`

Accepts room schedules, climate summary, material catalog, and BIM element IDs. Returns three performance-aware strategies plus BIM view-filter JSON.

### `POST /ai/fabrication-planner`

Accepts BIM assemblies and fabrication capabilities. Returns manufacturable modules, assigned processes, time/waste estimates, QA checkpoints, and risks.

### `POST /ai/material-predict`

Proxies a registered materials-property model prediction. Use `target`, `model`, and numeric `inputFeatures`.

### `POST /ai/defect-qc`

Performs automated image screening and returns edge-density, confidence, and review status. It is deliberately labelled as screening and always requires qualified human review.

## Operations

- `/health` supports service health checks.
- `/metrics` reports request count and uptime.
- Configure `SUPABASE_URL` and `SUPABASE_ANON_KEY` to validate Supabase Auth bearer tokens.
- Use `backend/src/supabaseAuth.ts` for TypeScript email/password sign-in and sign-out helpers.
- Set `JWT_SECRET` only when the local signed-JWT fallback is required.
- Keep `SUPABASE_SERVICE_ROLE_KEY` only in private backend services; never expose it through `NEXT_PUBLIC_*` variables or the iOS app.
- Apply `docs/migrations/20260612_supabase_rls_storage.sql` in Supabase for membership-based RLS and private buckets.
- Set `TRAINING_DATA_CSV` for the ML service before triggering retraining.
- Set `RETRAIN_INTERVAL_MS` on the Node gateway to enable interval scheduling; `0` disables it.
- Retraining triggers require an authenticated `admin` or `model_maintainer` membership when auth is configured.
- `docker compose up --build` starts PostgreSQL, the ML service, and the Node gateway.
- MLflow logging activates when `MLFLOW_TRACKING_URI` is configured.

## Safety and governance

- Keep a human responsible for accepting designs, test dispositions, and fabrication plans.
- Label model outputs as estimates and retain model/version metadata.
- Validate jurisdiction-specific standards outside the generation layer.
- Use Supabase Row Level Security for every project-linked table.
- Store drawings, lab photos, and site imagery in private storage buckets with signed URLs.
