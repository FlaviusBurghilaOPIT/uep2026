---
type: Work Item
title: AUD-A04 Simplified 4-Option Feeling Check-In Model
parent: ../spec.md
---

## What to build
Simplify the symptom check-in feeling choices in `CheckInCard` (`A03`) to 4 distinct, intuitive options: Great, OK, Not Great, Unwell (applying Hick's Law to reduce decision fatigue).

## Required context
- Target file: `mobile/lib/features/checkin/presentation/widgets/checkin_card.dart`
- Notifier: `mobile/lib/features/checkin/presentation/providers/symptom_checkin_notifier.dart`

## Acceptance criteria
- [ ] Renders exactly 4 mood chips: Great (green), OK (blue/teal), Not Great (amber), Unwell (rose/red).
- [ ] Selecting "Unwell" triggers the emergency red flag banner (FORM-01).
- [ ] Submissions map accurately to backend feeling telemetry values (`great`, `ok`, `poor`, `bad`).

## Covers
- User Stories: US2
- Requirements: Requirement 21
- Interview Ledger: L21

## Blocked by
None - ready to start
