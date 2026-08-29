---
type: Work Item
title: AUD-B03 Resend OTP Code 60-Second Cooldown Timer
parent: ../spec.md
---

## What to build
Add a 60-second countdown timer to the "Resend Code" button on Screen B03 (`VerifyCodeScreen`) with a live remaining seconds indicator to prevent rate-limit spamming and provide clear feedforward.

## Required context
- Target file: `mobile/lib/features/auth/presentation/screens/verify_code_screen.dart`
- Target file: `mobile/lib/features/auth/presentation/screens/otp_screen.dart`

## Acceptance criteria
- [x] After requesting a code, "Resend Code" button is disabled for 60 seconds.
- [x] Displays remaining seconds: "Resend Code in 58s".
- [x] Re-enables automatically when countdown reaches 0.

## Covers
- User Stories: US5
- Requirements: Requirement 26
- Interview Ledger: L26

## Blocked by
None - ready to start
