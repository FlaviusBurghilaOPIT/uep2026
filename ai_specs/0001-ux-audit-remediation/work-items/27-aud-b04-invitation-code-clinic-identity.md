---
type: Work Item
title: AUD-B04 Clinic Identity Recognition and Verification
parent: ../spec.md
---

## What to build
Display verified clinic name and inviting physician name immediately upon valid invitation code recognition on Screen B04 (`InvitationCodeScreen` / `ProfileSetupScreen`) before proceeding with profile setup (Pre-suasion).

## Required context
- Target file: `mobile/lib/features/auth/presentation/screens/invitation_code_screen.dart`
- Target file: `mobile/lib/features/auth/presentation/screens/profile_setup_screen.dart`

## Acceptance criteria
- [ ] Validating an invitation code retrieves and displays the clinic name (e.g. "St. Jude Recovery Clinic") and physician name.
- [ ] Confirms trust before prompting for password or personal profile details.

## Covers
- User Stories: US5
- Requirements: Requirement 27
- Interview Ledger: L27

## Blocked by
None - ready to start
