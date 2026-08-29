---
type: Work Item
title: AUD-B01 Auth Welcome Screen Visual Dominance Hierarchy
parent: ../spec.md
---

## What to build
Establish a single dominant primary CTA button (Email Sign In) on Screen B01 (`WelcomeScreen`), demoting secondary sign-in actions (Clinic Invitation code, Demo Mode) to outlined or subtle text buttons to prevent decision paralysis (Hick's Law).

## Required context
- Target file: `mobile/lib/features/auth/presentation/screens/welcome_screen.dart`

## Acceptance criteria
- [ ] Primary button is styled with solid fill and prominent contrast.
- [ ] Secondary actions use clear outlined/text link styling.
- [ ] Clear visual hierarchy directs patients smoothly toward their intended sign-in path.

## Covers
- User Stories: US5
- Requirements: Requirement 24
- Interview Ledger: L24

## Blocked by
None - ready to start
