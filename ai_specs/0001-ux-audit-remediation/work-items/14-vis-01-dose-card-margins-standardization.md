---
type: Work Item
title: VIS-01 Card Layout 8-Point Grid Spacing Standardization
parent: ../spec.md
---

## What to build
Standardize all arbitrary margins (6px, 10px, 14px, 15px) across card layouts in `TodayScreen` (`A01`) to the strict 8-point grid scale using `AppSpacing.md` (16dp), `AppSpacing.sm` (8dp), and `AppSpacing.lg` (24dp).

## Required context
- Target file: `mobile/lib/features/today/presentation/screens/today_screen.dart`
- Target file: `mobile/lib/features/today/presentation/widgets/dose_slot_card.dart`
- Tokens: `mobile/lib/core/constants/app_spacing.dart`

## Acceptance criteria
- [x] Dose slot cards and section containers use standardized `AppSpacing.md` vertical and horizontal spacing.
- [x] No arbitrary non-token integer margins remain in card wrappers.

## Covers
- User Stories: US1
- Requirements: Requirement 14
- Interview Ledger: L14

## Blocked by
None - ready to start
