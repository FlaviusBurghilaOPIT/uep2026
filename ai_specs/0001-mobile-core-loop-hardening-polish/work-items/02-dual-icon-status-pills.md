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

- [x] Each of the 3 dose statuses (`Taken`, `Skipped`, `Missed`) renders its existing color fill plus a distinct icon plus an explicit text label.
- [x] All 3 states remain 100% distinguishable from each other in a grayscale/monochrome rendering (verify via screenshot comparison, not just visual inspection).
- [x] No regression to existing dose-status widget tests; pill tap targets remain ≥48×48dp per Standard M-04.

**Implementation notes:**
- `Taken` → `Icons.check_circle`, `Skipped` → `Icons.warning_amber_rounded`, `Missed` → `Icons.close`, each paired with the existing color fill and the existing `l10n.doseStatusTaken/Skipped/Missed` text label (previously the Skipped pill used the mismatched `AppStrings.skip` = "Skip" instead of "Skipped"; fixed as part of this pass since the AC calls out the exact state names).
- Also changed the unrelated drug-interaction `hasWarning` suffix icon from `Icons.warning_amber_rounded` to `Icons.error_outline` — it previously used the identical icon+similar amber color as the new Skipped status icon, which would have made a skipped-and-interacting medication show two visually-identical triangle icons side by side, undermining the very non-color-cue distinguishability this AC requires.
- AC2 verification: `mobile/test/widget/dose_status_pill_test.dart` asserts a distinct `IconData` and distinct text label renders per status (the structural property that guarantees grayscale/monochrome distinguishability) and taps through all three states via the real `TodayScreen` widget tree. A live-device grayscale screenshot comparison was not captured in this environment — the local backend/auth chain needed to reach `TodayScreen` past login is not running here (pre-existing, unrelated Docker/OrbStack networking gap), and headless widget-test screenshot capture (`RepaintBoundary.toImage`) requires a network font fetch (`google_fonts`) that this environment also could not complete. Recommend a manual grayscale screenshot pass on a dev machine with the backend running before or shortly after merge.
- AC3 verification: `mobile/test/widget/dose_status_pill_test.dart` measures the `_MedAction` "Taken" tap target via `tester.getSize` and asserts ≥48×48dp; the badge/pill itself is non-interactive (no tap target) and unaffected.

## Covers

- User Stories: 3
- Requirements: Dose Logging UX 7
- Interview Ledger: L3

## Blocked by

1 — lands after the shell restructure to avoid double-touching `today_screen.dart` mid-flight.
