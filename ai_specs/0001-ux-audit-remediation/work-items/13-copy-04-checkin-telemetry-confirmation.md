---
type: Work Item
title: COPY-04 Daily Check-in Clinician Visibility Confirmation
parent: ../spec.md
---

## What to build
Display an explicit status confirmation banner in `CheckInCard` (`A03`) after symptom submission: "Telemetry received • Dr. Miller's care team notified" to eliminate uncertainty regarding clinician oversight.

## Required context
- Target file: `mobile/lib/features/checkin/presentation/widgets/checkin_card.dart`
- L10n: `mobile/lib/core/l10n/`

## Acceptance criteria
- [ ] Successful check-in submission displays a confirmation card/banner with text "Telemetry received • Care team notified".
- [ ] Incorporates physician's name when available in patient profile/auth state.

## Covers
- User Stories: US2
- Requirements: Requirement 13
- Interview Ledger: L13

## Blocked by
None - ready to start
