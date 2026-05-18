# Branch protection (GitHub Settings)

Enforce these rules on `main` so CI/CD blocks broken builds:

1. **Require status checks**
   - `build-and-test` (workflow: **CI Main**)
   - `pr-gate` (workflow: **CI Pull Request**)
   - `validate-scripts` (workflow: **CI TestFlight Admin**)

2. **Require branches to be up to date** before merge.

3. **Require pull request reviews** (1 reviewer) for production repos.

4. **Tags / releases** — run **CI Release Candidate** on `v*` tags before App Store submission.

Local parity:

```bash
./scripts/test-fast.sh      # pre-commit
./scripts/test-pr-gate.sh   # PR gate
./scripts/test-ui-all.sh    # full UI (nightly)
```
