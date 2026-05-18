#!/usr/bin/env python3
"""
WCS-BIM TestFlight + subscription access admin CLI.

Examples:
  python admin_cli.py --dry-run testflight list-builds
  python admin_cli.py access grant --email user@wcs.com --tier pro --days 90
  python admin_cli.py access list
  python admin_cli.py testflight invite --email user@wcs.com --group "WCS External Testers"
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

from access_registry import grant_access, list_entries, revoke_access

try:
    from asc_client import ASCError, AppStoreConnectClient
except ImportError as exc:
    raise SystemExit("Install deps: pip install -r scripts/testflight/requirements.txt") from exc

ROOT = Path(__file__).resolve().parent
CATALOG = ROOT / "subscription_catalog.json"


def load_catalog() -> dict:
    return json.loads(CATALOG.read_text(encoding="utf-8"))


def load_env_file() -> None:
    env_path = ROOT / ".env"
    if not env_path.exists():
        return
    for line in env_path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        os.environ.setdefault(key.strip(), value.strip())


def client_or_exit(dry_run: bool) -> AppStoreConnectClient | None:
    if dry_run:
        print("[dry-run] Skipping App Store Connect API calls.")
        return None
    try:
        return AppStoreConnectClient.from_env()
    except ASCError as exc:
        print(f"ASC config error: {exc}", file=sys.stderr)
        sys.exit(2)


def cmd_access_grant(args: argparse.Namespace) -> None:
    entry = grant_access(args.email, args.tier, args.days, args.payment_ref or "")
    print(json.dumps(entry, indent=2))
    if args.invite_testflight and not args.dry_run:
        cmd_testflight_invite(
            argparse.Namespace(
                email=args.email,
                group=args.group,
                dry_run=False,
                first_name=args.first_name,
                last_name=args.last_name,
            )
        )


def cmd_access_revoke(args: argparse.Namespace) -> None:
    removed = revoke_access(args.email)
    print("revoked" if removed else "not found")


def cmd_access_list(_: argparse.Namespace) -> None:
    print(json.dumps(list_entries(), indent=2))


def cmd_testflight_list_builds(args: argparse.Namespace) -> None:
    client = client_or_exit(args.dry_run)
    if not client:
        print(json.dumps(load_catalog().get("products", []), indent=2))
        return
    builds = client.list_builds()
    for b in builds:
        attrs = b.get("attributes", {})
        print(f"{b['id']}\t{attrs.get('version')}\t{attrs.get('processingState')}")


def cmd_testflight_list_groups(args: argparse.Namespace) -> None:
    client = client_or_exit(args.dry_run)
    if not client:
        for name in load_catalog().get("testflight_groups", []):
            print(name)
        return
    for g in client.list_beta_groups():
        attrs = g.get("attributes", {})
        print(f"{g['id']}\t{attrs.get('name')}\tinternal={attrs.get('isInternalGroup')}")


def cmd_testflight_invite(args: argparse.Namespace) -> None:
    if args.dry_run:
        print(f"[dry-run] Would invite {args.email} to group {args.group}")
        return
    client = client_or_exit(False)
    assert client is not None
    group_id = client.find_beta_group_id(args.group)
    if not group_id:
        print(f"Creating beta group: {args.group}")
        group_id = client.create_beta_group(args.group, is_internal=False)
    client.add_tester_to_group(
        args.email,
        group_id,
        first_name=args.first_name,
        last_name=args.last_name,
    )
    print(f"Invited {args.email} to {args.group} ({group_id})")


def cmd_catalog(_: argparse.Namespace) -> None:
    print(json.dumps(load_catalog(), indent=2))


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="WCS-BIM TestFlight & subscription admin")
    parser.add_argument("--dry-run", action="store_true", help="Skip live API calls")
    sub = parser.add_subparsers(dest="command", required=True)

    access = sub.add_parser("access", help="Subscription access registry")
    access_sub = access.add_subparsers(dest="access_cmd", required=True)

    grant = access_sub.add_parser("grant", help="Grant tier access")
    grant.add_argument("--email", required=True)
    grant.add_argument("--tier", choices=["pro", "team", "enterprise"], required=True)
    grant.add_argument("--days", type=int, default=365)
    grant.add_argument("--payment-ref", default="")
    grant.add_argument("--invite-testflight", action="store_true")
    grant.add_argument("--group", default=os.environ.get("ASC_DEFAULT_BETA_GROUP", "WCS External Testers"))
    grant.add_argument("--first-name", default="WCS")
    grant.add_argument("--last-name", default="Tester")
    grant.set_defaults(func=cmd_access_grant)

    revoke = access_sub.add_parser("revoke", help="Revoke access")
    revoke.add_argument("--email", required=True)
    revoke.set_defaults(func=cmd_access_revoke)

    listing = access_sub.add_parser("list", help="List registry entries")
    listing.set_defaults(func=cmd_access_list)

    tf = sub.add_parser("testflight", help="TestFlight operations")
    tf_sub = tf.add_subparsers(dest="tf_cmd", required=True)

    lb = tf_sub.add_parser("list-builds")
    lb.set_defaults(func=cmd_testflight_list_builds)

    lg = tf_sub.add_parser("list-groups")
    lg.set_defaults(func=cmd_testflight_list_groups)

    inv = tf_sub.add_parser("invite", help="Invite tester to beta group")
    inv.add_argument("--email", required=True)
    inv.add_argument("--group", default=os.environ.get("ASC_DEFAULT_BETA_GROUP", "WCS External Testers"))
    inv.add_argument("--first-name", default="WCS")
    inv.add_argument("--last-name", default="Tester")
    inv.set_defaults(func=cmd_testflight_invite)

    cat = sub.add_parser("catalog", help="Print subscription catalog JSON")
    cat.set_defaults(func=cmd_catalog)

    return parser


def main() -> None:
    load_env_file()
    parser = build_parser()
    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
