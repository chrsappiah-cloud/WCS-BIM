# Branch protection (GitHub Settings)

Enforce these rules on `main` so CI/CD blocks broken builds:

1. **Require status checks**
   - `pr-gate` (workflow: **CI Pull Request**)
   - `validate-scripts` (workflow: **CI TestFlight Admin**)
   - `backend` (workflow: **ML and Backend CI**)
   - `ml-service` (workflow: **ML and Backend CI**)
   - `containers` (workflow: **ML and Backend CI**)

   `validate-integrations` stays path-scoped and should remain non-required unless the
   workflow is changed to run on every pull request; otherwise it can block unrelated
   PRs by never reporting a status.

2. **Require branches to be up to date** before merge.

3. **Require pull request reviews** (1 reviewer) for production repos.

4. **Tags / releases** — run **CI Release Candidate** and **CI TestFlight Upload** on `v*` tags before App Store submission.

Local parity:

```bash
./scripts/test-fast.sh      # pre-commit
./scripts/test-pr-gate.sh   # PR gate (unit + smoke UI + UI registry)
./scripts/test-ui-all.sh    # full UI tiers 1–4 + matrix (nightly)
./scripts/test-all.sh       # unit + full UI (release candidate)
```
