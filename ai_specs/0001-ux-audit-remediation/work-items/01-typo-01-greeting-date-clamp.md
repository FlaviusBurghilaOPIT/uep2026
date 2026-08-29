---
type: Work Item
title: TYPO-01 Fluid Clamp and Single-Line Clamping on Greeting & Date Header
parent: ../spec.md
---

## What to build
Apply fluid typography scaling with `clamp()` and explicit `maxLines: 1` with `TextOverflow.ellipsis` to the date and greeting lines on Screen A01 (`TodayScreen`) so that date header text never wraps unpredictably or overflows on narrow viewports (<360dp).

## Required context
- Target file: `mobile/lib/features/today/presentation/screens/today_screen.dart`
- Header builder: `_buildGreetingCard`
- Design tokens in `mobile/lib/core/constants/app_text_styles.dart`

## Acceptance criteria
- [x] Date label (`dateLine.toUpperCase()`) is clamped with `maxLines: 1` and `overflow: TextOverflow.ellipsis`.
- [x] Greeting line (`greetingLine`) uses responsive font size sizing with ellipsis overflow on ultra-narrow viewports (<360dp).
- [x] Layout renders without RenderFlex overflow on 320dp width simulator tests.

## Covers
- User Stories: US1
- Requirements: Requirement 1
- Interview Ledger: L1

## Blocked by
None - ready to start
