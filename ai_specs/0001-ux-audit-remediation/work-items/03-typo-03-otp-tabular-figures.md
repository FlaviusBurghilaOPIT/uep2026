---
type: Work Item
title: TYPO-03 Monospaced Tabular Figures for OTP Entry Cells
parent: ../spec.md
---

## What to build
Configure 6-digit OTP entry cells and countdown timers on Screen B03 (`VerifyCodeScreen` / `RequestCodeScreen`) to use `fontFeatures: [FontFeature.tabularFigures()]` and explicit monospaced numeric styling to eliminate character jitter during typing and countdowns.

## Required context
- Target files:
  - `mobile/lib/features/auth/presentation/screens/verify_code_screen.dart`
  - `mobile/lib/features/auth/presentation/screens/request_code_screen.dart`
  - `mobile/lib/features/auth/presentation/screens/otp_screen.dart`

## Acceptance criteria
- [ ] OTP digit text fields use `TextStyle(fontFeatures: [FontFeature.tabularFigures()])`.
- [ ] Countdown timer display preserves fixed character width without jitter.

## Covers
- User Stories: US5
- Requirements: Requirement 3
- Interview Ledger: L3

## Blocked by
None - ready to start
