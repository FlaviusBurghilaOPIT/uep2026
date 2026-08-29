---
type: Work Item
title: VIS-04 Welcome Illustration Viewport Constraint
parent: ../spec.md
---

## What to build
Wrap the welcome illustration in `WelcomeScreen` (`B01`) with flexible constraints clamping maximum height to 180.h on compact viewports (<600dp) so that auth CTA buttons are never pushed below the fold.

## Required context
- Target file: `mobile/lib/features/auth/presentation/screens/welcome_screen.dart`

## Acceptance criteria
- [ ] Welcome hero image/illustration height is constrained to `clamp(120.h, 25.vh, 180.h)`.
- [ ] Auth buttons and footer text remain fully visible above the fold on 568dp/600dp screen heights.

## Covers
- User Stories: US5
- Requirements: Requirement 17
- Interview Ledger: L17

## Blocked by
None - ready to start
