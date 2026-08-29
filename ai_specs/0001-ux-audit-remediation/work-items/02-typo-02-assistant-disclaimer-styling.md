---
type: Work Item
title: TYPO-02 Assistant Disclaimer Banner Styling Refactor
parent: ../spec.md
---

## What to build
Refactor the legal guardrail disclaimer banner in `AssistantScreen` (`A05`) from italic serif to clean system sans-serif 13.sp with weight 500, #334155 text on #F0FDF4 emerald background and 1.4 line-height to reduce cognitive strain.

## Required context
- Target file: `mobile/lib/features/assistant/presentation/screens/assistant_screen.dart`
- Widget: `GuardrailBanner`

## Acceptance criteria
- [ ] `GuardrailBanner` uses `TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500, color: Color(0xFF334155), height: 1.4)`.
- [ ] Background container uses `Color(0xFFF0FDF4)` with subtle border `#DCFCE7`.
- [ ] Meets WCAG 2.1 AA 4.5:1 contrast requirement.

## Covers
- User Stories: US3
- Requirements: Requirement 2
- Interview Ledger: L2

## Blocked by
None - ready to start
