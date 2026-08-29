---
type: Work Item
title: FORM-03 Dose Skip Slip-Prevention Non-Blocking Undo SnackBar
parent: ../spec.md
---

## What to build
Replace disruptive modal confirmation dialogs when skipping a dose in `DoseSlotCard` / `TodayScreen` (`A02`) with an immediate optimistic state update and a 5-second non-blocking `SnackBar` featuring an instant `[Undo]` button to prevent slip anxiety and maintain patient momentum.

## Required context
- Target file: `mobile/lib/features/today/presentation/screens/today_screen.dart`
- Target file: `mobile/lib/features/today/presentation/widgets/dose_slot_card.dart`
- Notifier: `TodayAgendaNotifier` (`undoDoseLog`)

## Acceptance criteria
- [x] Tapping "Skip Dose" updates slot state optimistically without opening a blocking modal alert.
- [x] Displays a 5-second non-blocking SnackBar with text "Dose marked as Skipped" and an "Undo" action.
- [x] Tapping "Undo" within 5 seconds reverts the slot back to its previous state immediately.

## Covers
- User Stories: US1
- Requirements: Requirement 7
- Interview Ledger: L7

## Blocked by
None - ready to start
