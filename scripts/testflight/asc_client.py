"""Minimal App Store Connect API client for TestFlight administration."""

from __future__ import annotations

import json
import os
import time
from pathlib import Path
from typing import Any

import jwt
import requests

API_BASE = "https://api.appstoreconnect.apple.com/v1"


class ASCError(RuntimeError):
    pass


class AppStoreConnectClient:
    def __init__(
        self,
        key_id: str,
        issuer_id: str,
        private_key_path: Path,
        app_id: str,
    ) -> None:
        self.key_id = key_id
        self.issuer_id = issuer_id
        self.private_key = private_key_path.read_text(encoding="utf-8")
        self.app_id = app_id
        self._token: str | None = None
        self._token_expires = 0.0

    @classmethod
    def from_env(cls) -> "AppStoreConnectClient":
        key_id = os.environ.get("ASC_KEY_ID", "")
        issuer_id = os.environ.get("ASC_ISSUER_ID", "")
        key_path = os.environ.get("ASC_PRIVATE_KEY_PATH", "")
        app_id = os.environ.get("ASC_APP_ID", "6770373495")
        missing = [n for n, v in [
            ("ASC_KEY_ID", key_id),
            ("ASC_ISSUER_ID", issuer_id),
            ("ASC_PRIVATE_KEY_PATH", key_path),
        ] if not v]
        if missing:
            raise ASCError(f"Missing env: {', '.join(missing)}")
        return cls(key_id, issuer_id, Path(key_path), app_id)

    def _bearer_token(self) -> str:
        now = time.time()
        if self._token and now < self._token_expires - 60:
            return self._token
        headers = {"alg": "ES256", "kid": self.key_id, "typ": "JWT"}
        payload = {
            "iss": self.issuer_id,
            "iat": int(now),
            "exp": int(now) + 1200,
            "aud": "appstoreconnect-v1",
        }
        self._token = jwt.encode(payload, self.private_key, algorithm="ES256", headers=headers)
        self._token_expires = now + 1200
        return self._token

    def request(
        self,
        method: str,
        path: str,
        *,
        params: dict[str, Any] | None = None,
        json_body: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        url = f"{API_BASE}{path}"
        headers = {
            "Authorization": f"Bearer {self._bearer_token()}",
            "Content-Type": "application/json",
        }
        response = requests.request(
            method,
            url,
            headers=headers,
            params=params,
            json=json_body,
            timeout=60,
        )
        if response.status_code >= 400:
            raise ASCError(f"{method} {path} failed ({response.status_code}): {response.text}")
        if not response.text:
            return {}
        return response.json()

    def list_beta_groups(self) -> list[dict[str, Any]]:
        data = self.request("GET", f"/apps/{self.app_id}/betaGroups", params={"limit": 200})
        return data.get("data", [])

    def list_beta_testers(self, limit: int = 200) -> list[dict[str, Any]]:
        data = self.request("GET", "/betaTesters", params={"limit": limit})
        return data.get("data", [])

    def list_builds(self, limit: int = 25) -> list[dict[str, Any]]:
        data = self.request(
            "GET",
            f"/apps/{self.app_id}/builds",
            params={"limit": limit, "sort": "-uploadedDate"},
        )
        return data.get("data", [])

    def find_beta_group_id(self, name: str) -> str | None:
        for group in self.list_beta_groups():
            attrs = group.get("attributes", {})
            if attrs.get("name") == name:
                return group["id"]
        return None

    def create_beta_group(self, name: str, is_internal: bool = False) -> str:
        body = {
            "data": {
                "type": "betaGroups",
                "attributes": {
                    "name": name,
                    "isInternalGroup": is_internal,
                },
                "relationships": {
                    "app": {"data": {"type": "apps", "id": self.app_id}}
                },
            }
        }
        data = self.request("POST", "/betaGroups", json_body=body)
        return data["data"]["id"]

    def add_tester_to_group(self, email: str, group_id: str, first_name: str = "WCS", last_name: str = "Tester") -> None:
        body = {
            "data": {
                "type": "betaTesters",
                "attributes": {
                    "email": email,
                    "firstName": first_name,
                    "lastName": last_name,
                },
                "relationships": {
                    "betaGroups": {
                        "data": [{"type": "betaGroups", "id": group_id}]
                    }
                },
            }
        }
        self.request("POST", "/betaTesters", json_body=body)
