---
type: Work Item
title: AUD-A02 Day Complete Celebration Ring Closure Animation and Haptics
parent: ../spec.md
---

## What to build
Trigger a "Day Complete" Ring Closure animation with an emerald glow sweep and medium haptic impact (`HapticFeedback.mediumImpact()`) in `CelebrationRingCard` (`A01`) when the patient completes 100% of their daily doses.

## Required context
- Target file: `mobile/lib/features/today/presentation/widgets/celebration_ring_card.dart`
- Target file: `mobile/lib/features/today/presentation/screens/today_screen.dart`
- Haptics: `package:flutter/services.dart`

## Acceptance criteria
- [ ] Transitioning from <100% to 100% completed doses animates the progress ring with an emerald glow sweep.
- [ ] Triggers `HapticFeedback.mediumImpact()` when 100% is reached.
- [ ] Shows positive reinforcement message ("All doses completed for today!").

## Covers
- User Stories: US1
- Requirements: Requirement 19
- Interview Ledger: L19

## Blocked by
None - ready to start
