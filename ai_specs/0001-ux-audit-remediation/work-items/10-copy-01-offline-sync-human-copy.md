---
type: Work Item
title: COPY-01 Human-Centered Offline and Sync Recovery Copy
parent: ../spec.md
---

## What to build
Replace raw technical network exception strings (`SocketException`, `HTTP 422`, `Failed to fetch`) across `TodayScreen` (`A01`), `RecoveryScreen` (`A04`), and global snackbars with reassuring plain language: "Saved locally. Will sync automatically once reconnected."

## Required context
- Target files:
  - `mobile/lib/core/l10n/app_localizations*.dart`
  - `mobile/lib/features/today/presentation/screens/today_screen.dart`
  - `mobile/lib/features/recovery/presentation/screens/recovery_screen.dart`

## Acceptance criteria
- [ ] Network failures during background dose logging or recovery refresh display human-centered localized text: "Saved locally. Will sync automatically once reconnected."
- [ ] No raw exception names or HTTP status codes are displayed to patients.

## Covers
- User Stories: US1, US4
- Requirements: Requirement 10
- Interview Ledger: L10

## Blocked by
None - ready to start
