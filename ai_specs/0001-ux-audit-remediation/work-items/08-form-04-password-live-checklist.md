---
type: Work Item
title: FORM-04 Real-Time Interactive Password Requirement Checklist
parent: ../spec.md
---

## What to build
Add a live interactive requirement checklist (8+ characters, uppercase letter, lowercase letter, number, special character) in `CreatePasswordScreen` (`B05`) that evaluates and updates each requirement dynamically on keypress instead of failing on submit.

## Required context
- Target file: `mobile/lib/features/auth/presentation/screens/create_password_screen.dart`

## Acceptance criteria
- [ ] Checklist displays all password requirements beneath the password field.
- [ ] Each requirement dynamically turns green with a checkmark when satisfied as the user types.
- [ ] Submit button is enabled only when all criteria are satisfied.

## Covers
- User Stories: US5
- Requirements: Requirement 8
- Interview Ledger: L8

## Blocked by
None - ready to start
