---
type: Work Item
title: Design-Token Consistency & Empty/Loading State Pass
parent: ../spec.md
---

## What to build

Audit the 5 screens touched or rebuilt this iteration (`Today`, `Medications`, `Recovery`, `Assistant`, `Profile`) for consistent use of the `AppColors`/`AppTextStyles`/`AppTheme` design-system tokens established in the WI-01 Riverpod migration, and add proper empty and loading states wherever a screen currently shows blank space or a raw default spinner.

## Required context

- `docs/product/10-implementation-plan.md` Issue #15.
- `mobile/lib/features/medications/medications_screen.dart` (new, from Work Item 1), `mobile/lib/features/today/today_screen.dart`, `mobile/lib/features/recovery/recovery_screen.dart`, `mobile/lib/features/profile/profile_screen.dart`.
- `mobile/lib/core/widgets/` — shared shimmer/empty/error-state widgets established by WI-01; reuse rather than rebuild.
- `docs/ux/07-accessibility-spec.md` Standard M-02 (Dynamic Text Scaling 200%) — spot-check the 5 screens at scale, since this pass touches shared layout/token usage that could affect scaling.
- No dark-mode requirement exists in `docs/ux/07-accessibility-spec.md` — do not introduce one speculatively as part of this pass.

## Acceptance criteria

- [x] No screen among the 5 touched uses a raw/default `CircularProgressIndicator` where a shimmer/skeleton placeholder from `mobile/lib/core/widgets/` is feasible.
- [x] No screen shows blank space on an empty state — each has copy (sourced from `docs/ux/06-content-system.md`) plus an icon/illustration.
- [x] Spot-check across the 5 screens confirms no hardcoded colors or fonts outside `AppColors`/`AppTextStyles`.
- [x] Manual QA at 200% text scale (`flutter_screenutil`) confirms no clipped/overlapping content on the 5 screens.

## Covers

- User Stories: 8
- Interview Ledger: L2

## Blocked by

6, 7, 8 — lands last among mobile Work Items since it touches the widest file surface and should absorb the final shape of every other screen change rather than being rebased repeatedly against them.
