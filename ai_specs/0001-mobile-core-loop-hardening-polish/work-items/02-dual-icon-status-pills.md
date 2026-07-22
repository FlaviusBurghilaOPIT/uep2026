---
type: Work Item
title: Dual Icon + Text Status Indicators on Dose Pills
parent: ../spec.md
---

## What to build

Pair every dose status pill's color with a distinct icon and explicit text label so status is never conveyed by color alone: a checkmark for `Taken`, a warning triangle for `Skipped`, and a cross for `Missed`, per WCAG 1.4.1 and `docs/ux/07-accessibility-spec.md` Standard M-03.

## Required context

- `docs/product/10-implementation-plan.md` Issue #8.
- `mobile/lib/features/today/today_screen.dart` — the medication card / status pill widget (confirm exact widget name while implementing; the originating backlog finding references `MedicationCardWidget`).
- `docs/ux/07-accessibility-spec.md` Standard M-03 (Contrast & Non-Colour Status Cues).

## Acceptance criteria

- [ ] Each of the 3 dose statuses (`Taken`, `Skipped`, `Missed`) renders its existing color fill plus a distinct icon plus an explicit text label.
- [ ] All 3 states remain 100% distinguishable from each other in a grayscale/monochrome rendering (verify via screenshot comparison, not just visual inspection).
- [ ] No regression to existing dose-status widget tests; pill tap targets remain ≥48×48dp per Standard M-04.

## Covers

- User Stories: 3
- Requirements: Dose Logging UX 7
- Interview Ledger: L3

## Blocked by

1 — lands after the shell restructure to avoid double-touching `today_screen.dart` mid-flight.
