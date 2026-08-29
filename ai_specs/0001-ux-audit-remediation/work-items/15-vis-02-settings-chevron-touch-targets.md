---
type: Work Item
title: VIS-02 Settings Row 48x48dp Touch Target Expansion
parent: ../spec.md
---

## What to build
Expand touch target areas for interactive row chevrons and settings action triggers in `ProfileScreen` (`A06`) to meet the minimum 48x48dp touch boundary required by mobile ergonomic standards (Fitts's Law).

## Required context
- Target file: `mobile/lib/features/profile/presentation/screens/profile_screen.dart`

## Acceptance criteria
- [ ] Settings rows and chevrons wrap interactive triggers with `HitTestBehavior.opaque` container measuring at least 48x48dp.
- [ ] No interactive tap targets measure below 48x48dp.

## Covers
- User Stories: US4
- Requirements: Requirement 15
- Interview Ledger: L15

## Blocked by
None - ready to start
