# WCS-Bin Test Case Catalog

## Auth

- **Valid login** — Input: Known user credentials; Expected: Session created, home opens; Suite: UI/Integration.
- **Invalid login** — Input: Bad password; Expected: Error shown, no session; Suite: Unit/UI.
- **Session restore** — Input: Existing token; Expected: User returns to last state; Suite: Integration.

## Onboarding

- **First launch** — Input: Fresh install; Expected: Intro flow appears once; Suite: UI.
- **Skip onboarding** — Input: Skip action; Expected: Home loads immediately; Suite: UI.

## Core

- **Primary action success** — Input: Valid payload; Expected: Action completes and persists; Suite: Integration/UI.
- **Primary action failure** — Input: Server error; Expected: Graceful error and retry path; Suite: Unit/Integration.

## Sync

- **Offline save** — Input: No network; Expected: Local queue stores data; Suite: Unit/Integration.
- **Reconnect sync** — Input: Network restored; Expected: Queued data syncs; Suite: Integration.

## Settings

- **Change preference** — Input: Toggle setting; Expected: Setting persists after relaunch; Suite: Unit/Integration/UI.

## Notifications

- **Permission grant** — Input: Allow notifications; Expected: Token registered; Suite: Manual/UI.
- **Permission deny** — Input: Deny notifications; Expected: Fallback path works; Suite: Manual/UI.

## Performance

- **Cold launch** — Input: App starts from terminated state; Expected: Launch within target; Suite: Perf.
- **Scroll smoothness** — Input: Long feed; Expected: No visible jank; Suite: Perf/UI.
