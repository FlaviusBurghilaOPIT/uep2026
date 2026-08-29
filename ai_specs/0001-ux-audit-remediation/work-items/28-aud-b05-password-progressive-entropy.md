---
type: Work Item
title: AUD-B05 Progressive Password Strength and Entropy Meter
parent: ../spec.md
---

## What to build
Render an inline progressive entropy meter that evaluates password strength dynamically as the user types in `CreatePasswordScreen` (`B05`), providing visual progress feedback before prompting for confirmation.

## Required context
- Target file: `mobile/lib/features/auth/presentation/screens/create_password_screen.dart`

## Acceptance criteria
- [ ] Renders a segmented strength bar (Weak, Medium, Strong) beneath the password field.
- [ ] Updates bar color and fill level dynamically on each keystroke.
- [ ] Confirmation password field is enabled only when strength reaches acceptable threshold.

## Covers
- User Stories: US5
- Requirements: Requirement 28
- Interview Ledger: L28

## Blocked by
None - ready to start
