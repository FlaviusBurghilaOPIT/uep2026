---
type: Work Item
title: AUD-A03 Forgiving All-Day Dose Logging with Retroactive Marking
parent: ../spec.md
---

## What to build
Allow patients to log doses anytime during the active day in `DoseSlotCard` / `TodayScreen` (`A02`) without blocking actions outside a strict 15-minute window, clearly recording and displaying retroactive timestamps when logged late or early (Postel's Law).

## Required context
- Target file: `mobile/lib/features/today/presentation/widgets/dose_slot_card.dart`
- Target file: `mobile/lib/features/today/presentation/providers/today_agenda_notifier.dart`

## Acceptance criteria
- [ ] Due, overdue, and upcoming doses for the current day can be logged at any time.
- [ ] If logged outside scheduled slot time, displays clear subtle timestamp (e.g. "Logged at 10:14 AM").
- [ ] No restrictive window blocking dialogs or errors occur.

## Covers
- User Stories: US1
- Requirements: Requirement 20
- Interview Ledger: L20

## Blocked by
None - ready to start
