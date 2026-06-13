# Deployment

## Supabase

1. Apply `supabase/schema.sql` file order.
2. Apply `supabase/rls.sql` file order.
3. Seed an organization and admin using `supabase/seeds.sql`.
4. Verify all storage buckets remain private.

## Backend

1. Configure `.env.example` values in the hosting secret manager.
2. Build and deploy `backend/Dockerfile`.
3. Restrict inbound traffic and configure trusted client origins at the edge.
4. Monitor `/health`, `/metrics`, upload errors, and retraining status.

## ML Service

1. Build and deploy `ml-service/Dockerfile`.
2. Mount or download the versioned training dataset and model artifacts.
3. Run the first baseline training.
4. Configure `RETRAIN_INTERVAL_MS` or an external weekly scheduler.
5. Review drift flags and validation metrics before model promotion.

## iOS

1. Configure the API URL per build environment.
2. Store the authenticated access token securely.
3. Test role visibility, uploads, prediction, optimization, dashboard, and reports.
4. Archive and validate the release build in Xcode.

## Production Gates

- Service-role credentials are absent from client builds.
- Organization RLS is applied and tested with every role.
- Model artifacts and training data are versioned together.
- Active-model promotion and retraining are auditable.
