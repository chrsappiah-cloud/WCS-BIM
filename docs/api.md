# API

The detailed endpoint catalog and operations notes live in [ai-bim-node-api.md](ai-bim-node-api.md).

## Core Groups

- `/api/session/permissions`, `/api/dashboard`
- `/api/projects`, `/api/materials`, `/api/tests`, `/api/bim`
- `/api/uploads/file`, `/api/uploads/signed-url`
- `/api/models`, `/api/model-registry`
- `/api/retrain/run`, `/api/retrain/status`, `/api/retrain/drift-check`
- `/ai/material-predict`, `/ai/materials/predict`, `/ai/materials/optimize`
- `/ai/qc-report`, `/ai/design-copilot`, `/ai/fabrication-planner`

All production requests except health endpoints should include an authenticated bearer token.
