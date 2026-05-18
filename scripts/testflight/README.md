# TestFlight & subscription admin (App Store Connect)

App: **ArchFusion BIM** (`6770373495`)  
[TestFlight console](https://appstoreconnect.apple.com/teams/70c46c69-5d6d-438d-b300-31df2b93163a/apps/6770373495/testflight)

## Setup

1. Create an App Store Connect API key (Admin or App Manager).
2. Copy `config.example.env` to `.env` and fill in values (never commit `.env` or `.p8` keys).
3. Install Python deps:

```bash
cd scripts/testflight
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
```

## Admin commands

```bash
# Subscription access ledger (local JSON — sync to app via commit or manual export)
python admin_cli.py access grant --email user@company.com --tier pro --days 365 --payment-ref INV-1001
python admin_cli.py access grant --email user@company.com --tier team --days 90 --invite-testflight
python admin_cli.py access list
python admin_cli.py access revoke --email user@company.com

# TestFlight (live API — requires .env)
python admin_cli.py testflight list-builds
python admin_cli.py testflight list-groups
python admin_cli.py testflight invite --email user@company.com --group "WCS External Testers"

# Dry run (CI / local without keys)
python admin_cli.py --dry-run testflight list-groups
```

## GitHub Actions secrets

| Secret | Purpose |
|--------|---------|
| `ASC_KEY_ID` | API key ID |
| `ASC_ISSUER_ID` | Issuer UUID |
| `ASC_PRIVATE_KEY` | Contents of `.p8` file |
| `ASC_APP_ID` | `6770373495` |
| `WCS_ADMIN_PIN` | In-app admin panel PIN |

Workflow `ci-testflight.yml` runs script validation on every PR. Optional job `testflight-invite` uses secrets when triggered manually.

## In-app panels

- **Settings → Subscription** — user purchases / restore (StoreKit 2).
- **Settings → Admin Access** — PIN-gated tester & tier overrides (matches registry).

Product IDs are defined in `subscription_catalog.json` and `Products.storekit`.
