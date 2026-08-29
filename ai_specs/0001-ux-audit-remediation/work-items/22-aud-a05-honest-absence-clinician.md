---
type: Work Item
title: AUD-A05 Honest Absence Care Team Display
parent: ../spec.md
---

## What to build
Display explicit honest absence copy in `RecoveryScreen` (`A04`) when a patient does not have a dedicated clinician name assigned: "No dedicated care team assigned — contact clinic main desk", preventing blank or confusing placeholder states.

## Required context
- Target file: `mobile/lib/features/recovery/presentation/screens/recovery_screen.dart`

## Acceptance criteria
- [ ] If `doctorName` is absent or empty, displays "No dedicated care team assigned — contact clinic main desk".
- [ ] Preserves clean card layout without awkward empty spacing or dummy strings.

## Covers
- User Stories: US4
- Requirements: Requirement 22
- Interview Ledger: L22

## Blocked by
None - ready to start
