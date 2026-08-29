---
type: Work Item
title: FORM-02 OTP Auto-Paste, Auto-Advance, and Auto-Submit
parent: ../spec.md
---

## What to build
Implement automatic clipboard paste detection, segmented digit focus auto-advance, and automatic form submission upon entering the 6th digit in `VerifyCodeScreen` (`B03`) to eliminate manual tap fatigue.

## Required context
- Target file: `mobile/lib/features/auth/presentation/screens/verify_code_screen.dart`
- Target file: `mobile/lib/features/auth/presentation/screens/otp_screen.dart`
- Services: `Clipboard.getData(Clipboard.kTextPlain)` and `FocusScope`

## Acceptance criteria
- [x] Pasting a 6-digit code into any OTP cell automatically populates all 6 cells.
- [x] Typing a digit automatically shifts focus to the next cell.
- [x] Backspace on an empty cell automatically shifts focus back to the preceding cell.
- [x] Populating the 6th digit automatically triggers code verification submit without requiring an extra tap.

## Covers
- User Stories: US5
- Requirements: Requirement 6
- Interview Ledger: L6

## Blocked by
None - ready to start
