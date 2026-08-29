---
type: Work Item
title: AUD-A01 Optimistic Riverpod State Mutation for Dose Logging
parent: ../spec.md
---

## What to build
Implement optimistic UI updates (<50ms) in `TodayAgendaNotifier` when logging doses on Screen A01 (`TodayScreen`), queuing background network/SQLite sync operations and displaying a rollback error notification only if all retries fail.

## Required context
- Target file: `mobile/lib/features/today/presentation/providers/today_agenda_notifier.dart`
- Target file: `mobile/lib/features/today/presentation/screens/today_screen.dart`

## Acceptance criteria
- [ ] Tapping "Mark as Taken" updates slot state in UI immediately (<50ms) without showing a blocking spinner.
- [ ] SQLite local cache is updated immediately in the background.
- [ ] Network synchronization executes asynchronously.
- [ ] Rollback occurs with error notification if offline retry queue fails.

## Covers
- User Stories: US1
- Requirements: Requirement 18
- Interview Ledger: L18

## Blocked by
None - ready to start
