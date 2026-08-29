---
type: Work Item
title: AUD-B02 Email Input TextCapitalization and Autocorrect Disabling
parent: ../spec.md
---

## What to build
Set `textCapitalization: TextCapitalization.none`, `autocorrect: false`, and `keyboardType: TextInputType.emailAddress` on email input fields in `EmailLoginScreen` / `LoginScreen` (`B02`) to prevent unintended capitalized letters from causing authentication errors.

## Required context
- Target file: `mobile/lib/features/auth/presentation/screens/email_login_screen.dart`
- Target file: `mobile/lib/features/auth/presentation/screens/login_screen.dart`
- Target file: `mobile/lib/core/widgets/app_text_field.dart`

## Acceptance criteria
- [ ] Email input fields explicitly disable autocapitalization and autocorrection.
- [ ] Keyboard opens in email-optimized format (`TextInputType.emailAddress`).
- [ ] Entering an email begins with lowercase by default.

## Covers
- User Stories: US5
- Requirements: Requirement 25
- Interview Ledger: L25

## Blocked by
None - ready to start
