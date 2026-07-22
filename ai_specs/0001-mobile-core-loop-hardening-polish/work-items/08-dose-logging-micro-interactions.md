---
type: Work Item
title: Dose-Logging Micro-Interactions & Animation Polish
parent: ../spec.md
---

## What to build

Add the interaction polish that makes dose logging feel considered rather than merely functional, now that undo (Work Item 3) and dual-icon status pills (Work Item 2) exist: animated status-pill transitions instead of an instant swap, haptic feedback plus a brief success micro-animation on logging a dose, and a small, non-blocking, dismissible celebratory state when a patient completes all of a day's doses.

## Required context

- `docs/product/10-implementation-plan.md` Issue #14.
- `mobile/lib/features/today/today_screen.dart`.
- `docs/product/09-measurement-plan.md` §5 Experiment Guardrail Rule 2 — **no streak counters, gamification badges, or shame copy**, even in a "celebratory" state.
- This Work Item's polish has no meaningful automated test; per the Spec's Testing Strategy, verify via manual visual QA (e.g. the `act-flutter-screenshot` skill) and say so in the PR rather than writing a brittle animation-timing test.

## Acceptance criteria

- [x] Status pill transitions animate (not an instant color/icon swap).
- [x] Logging a dose triggers haptic feedback and a brief success micro-animation.
- [x] Completing all doses for the day shows a small, non-blocking, dismissible celebratory state on `Today` — no streaks, badges, or gamification elements.
- [x] Manual visual QA performed and documented in the PR description (screenshots or a short recording); no fabricated automated test for animation feel.

## Covers

- User Stories: 8
- Requirements: Dose Logging UX 8
- Interview Ledger: L2

## Blocked by

2, 3 — polishes the output of the status-pill and undo-toast Work Items, must land after both.
