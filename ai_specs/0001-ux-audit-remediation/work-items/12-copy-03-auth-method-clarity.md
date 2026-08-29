---
type: Work Item
title: COPY-03 Disambiguated Authentication Method Copy
parent: ../spec.md
---

## What to build
Re-label auth option buttons on Screen B01 (`WelcomeScreen`) to eliminate semantic confusion: "New Patient? Enter Clinic Invitation" vs "Sign in with One-Time Code" vs "Clinician Sign In".

## Required context
- Target file: `mobile/lib/features/auth/presentation/screens/welcome_screen.dart`
- Target file: `mobile/lib/features/auth/presentation/auth_strings.dart`

## Acceptance criteria
- [x] Primary button explicitly states "Sign in with One-Time Code" (or email).
- [x] Clinic invitation option clearly reads "New Patient? Enter Clinic Invitation".
- [x] Clinician option clearly labeled "Clinician Sign In".

## Covers
- User Stories: US5
- Requirements: Requirement 12
- Interview Ledger: L12

## Blocked by
None - ready to start
