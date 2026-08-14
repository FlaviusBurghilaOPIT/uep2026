---
type: Work Item
title: 5-Tab Shell Restructure & New Medications Screen
parent: ../spec.md
---

## What to build

Restructure `MainShellPage`/`MainBottomNav` from the current 4 tabs (`Today`, `Check-In`, `Assistant`, `Recovery`) to 5 tabs (`Today`, `Medications`, `Recovery`, `Assistant`, `Profile`). Embed the daily feeling check-in as a top action card on `Today` instead of a standalone tab. Build a new `Medications` feature/screen from scratch — no such screen exists today; prescriptions are currently only visible embedded inside `TodayScreen`. Wire `Profile` into the tab bar, reusing the existing `profile_screen.dart` content instead of a pushed route. Delete the stale duplicate `mobile/lib/core/services/api_service.dart` (superseded by `mobile/lib/core/network/api_service.dart` from the WI-01 Riverpod migration).

## Required context

- `docs/product/10-implementation-plan.md` Issue #6 for the full grounding (files, rationale, effort note that this is bigger than the originating backlog finding implied because the Medications screen must be built, not relocated).
- `mobile/lib/features/main/main_shell_page.dart`, `mobile/lib/core/shared_widgets/main_bottom_nav.dart`, `mobile/lib/core/providers/navigation_provider.dart` — current 4-tab implementation using `IndexedStack` + `navigationProvider`.
- `mobile/lib/features/today/today_screen.dart` — where check-in is currently a separate screen (`checkin_screen.dart`) reached via its own tab; this must become an embedded card instead.
- `GET /cases/{id}/medications` (`backend/app/routers/cases.py:86`) — existing endpoint to fetch the prescription list for the new Medications screen. No new backend endpoint is needed.
- Copy source: `docs/ux/06-content-system.md` Category 4 (Medication Cards & Detail).
- All 5 locale ARB-backed files under `mobile/lib/core/l10n/` need any new strings (tab labels, Medications screen copy) added — no hardcoded text.

## Acceptance criteria

- [x] Bottom navigation renders exactly 5 tabs in order: `Today`, `Medications`, `Recovery`, `Assistant`, `Profile`.
- [x] `IndexedStack` (or equivalent) preserves each tab's state/scroll position across switches.
- [x] New `mobile/lib/features/medications/medications_screen.dart` (+ a Riverpod notifier under `mobile/lib/features/medications/providers/`) fetches and renders the full active prescription list via `GET /cases/{id}/medications`: medication name, dose, schedule, and a clinician-authored-source indicator.
- [x] `Today` feed contains the daily feeling check-in as a top action card; the standalone Check-In tab is removed from the bottom nav (the underlying `checkin_screen.dart`/`symptom_checkin_notifier.dart` logic is reused, not rewritten).
- [x] `Profile` is reachable as a tab; content is the existing `profile_screen.dart` (any old pushed-route entry point either still resolves or is removed cleanly — no dangling route).
- [x] `mobile/lib/core/services/api_service.dart` is deleted; every import resolves to `mobile/lib/core/network/api_service.dart`.
- [x] All new/changed user-facing strings are added to all 5 ARB files (`en`, `it`, `es`, `fr`, `de`) and sourced via `AppLocalizations.of(context)`.
- [x] `flutter analyze` reports zero errors, including zero unused-import warnings from the deleted duplicate file.

## Covers

- User Stories: 1
- Requirements: Navigation & Medications Screen 1-5
- Interview Ledger: L3

## Blocked by

None — ready to start.
