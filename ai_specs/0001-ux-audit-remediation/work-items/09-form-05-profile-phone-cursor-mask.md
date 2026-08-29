---
type: Work Item
title: FORM-05 Profile Phone Input Cursor Positioning and E.164 Mask
parent: ../spec.md
---

## What to build
Preserve cursor position at the end of text upon re-focus and enforce standard E.164 telecommunication formatting in the phone number edit sheet on Screen A06 (`ProfileScreen`).

## Required context
- Target file: `mobile/lib/features/profile/presentation/screens/profile_screen.dart`

## Acceptance criteria
- [x] Focusing the phone number input places the cursor at the end of the existing text string.
- [x] Formats telephone input according to standard telecommunication masks.
- [x] Prevents cursor jumping to index 0 on tap/focus.

## Covers
- User Stories: US4
- Requirements: Requirement 9
- Interview Ledger: L9

## Blocked by
None - ready to start
