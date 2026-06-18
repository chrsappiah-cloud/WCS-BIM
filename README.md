# WCS-BIM Materials AI

A SwiftUI, Node.js, Python ML, and Supabase platform for AI-assisted construction materials, BIM workflows, fabrication planning, model governance, and retraining.

## Stack

- iOS: SwiftUI, SwiftData
- Backend: Node.js, Express, TypeScript
- ML: Python, FastAPI, scikit-learn, joblib
- Data/Auth/Storage: Supabase Postgres, Auth, Storage

## Repository

- `WCS-BIM/`: production iOS application
- `backend/`: authenticated API, orchestration, uploads, dashboard, registry, retraining gateway
- `ml-service/`: prediction, optimization, training, drift detection
- `supabase/`: schema, RLS application order, and seed template
- `docs/`: architecture, API, deployment, and detailed migrations
- `docker-compose.yml`: local production-like stack

The repository intentionally preserves the established iOS feature structure rather than duplicating it under a second `ios/` directory.

## Start

1. Copy `.env.example` to `.env` and configure secrets.
2. Apply the SQL files listed in `supabase/schema.sql` and `supabase/rls.sql`.
3. Run `docker compose up --build`.
4. Open `WCS-BIM.xcodeproj` in Xcode.
5. Configure the BIM API URL and bearer token in app Settings.

## Local Verification

```bash
cd backend && npm ci && npm run typecheck
cd ../ml-service && python3 -m py_compile app.py train.py train_models.py drift_check.py
cd .. && xcodebuild build-for-testing -project WCS-BIM.xcodeproj -scheme WCS-BIM \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## Security

- Keep `SUPABASE_SERVICE_ROLE_KEY` only in private backend services.
- Use the Supabase anon key and authenticated user token on clients.
- Apply organization RLS before enabling production users.
- Restrict model registry and retraining operations to `admin` and `model_maintainer`.
