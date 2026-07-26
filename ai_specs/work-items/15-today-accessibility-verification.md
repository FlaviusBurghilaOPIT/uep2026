---
type: Work Item
title: Today accessibility hardening + verification pass
parent: ../2026-07-26-today-screen-hardening-spec.md
---

## What to build

Final accessibility hardening of the rebuilt Today screen (spec §7 "Accessibility" M-01–M-08) plus the verification pass that closes the parent spec:

1. **M-01:** each slot is one merged `Semantics` unit — *"{medName} {dose}, scheduled {time}, {stateDescription}. Actions: taken, skipped, missed."*; reading order Next-due → groups in time order → actions within slot; state changes announced via live region ("Ibuprofen marked as taken").
2. **M-02:** 200% text scale — slot actions wrap below med name; no fixed card heights. Add a widget test at 200% scale for the slot + correction sheet.
3. **M-03:** verify all statuses distinguishable in grayscale (icon+text, never color-only) — golden or semantics assertion per badge.
4. **M-04:** audit all interactive targets ≥48dp with ≥8dp spacing (slot actions, correction sheet, C8 prompt, banners).
5. **M-05:** haptic on log + persistent visual confirmation; Reduce Motion disables celebration animation and any shake.
6. **M-06:** primary log actions in bottom 60%; next-due slot pinned above the fold (layout test).
7. **M-07/08:** Grade-8 copy sweep of new strings; dose formatting rule (`0.5 mg`) verified everywhere doses render on Today.
8. **Verification pass:** `flutter analyze` + full `flutter test` green; extend/verify the golden-loop integration path notes (integration against live backend is gated on backend WIs 07/08 shipping — record status in the PR); write the manual a11y checklist (TalkBack eyes-closed log+correct, 200% all states, grayscale, Reduce Motion) as the release-blocking sign-off record.

## Required context

- Parent spec: `ai_specs/2026-07-26-today-screen-hardening-spec.md` §7 Accessibility, §10 use case 11, §11 (manual a11y rows), §13 AC 7.
- `docs/ux/07-accessibility-spec.md` via git HEAD — M-01–M-08 canonical wording.
- Before finishing (per Flutter guidance): audit async flows, controller/subscription/timer disposal (60s empty-state poll!), state derivation, widget rebuild behavior, entry-point parity, and untested widget paths introduced by WIs 11–14.

## Acceptance criteria

- [ ] Merged-semantics slot + live-region announcements verified by semantics widget tests
- [ ] 200% text scale test: no overflow on slot, correction sheet, banners
- [ ] All interactive targets ≥48dp (test or measured audit recorded)
- [ ] Reduce Motion honored for celebration animation
- [ ] `flutter analyze` clean; full `flutter test` suite green
- [ ] Manual a11y checklist written and integration-vs-backend status recorded

## Covers

- Spec: §7 Accessibility; §10 Use Case 11; §11 manual a11y + verification rows; §13 AC 7

## Blocked by

- `12-dose-slot-correction-c8.md`
- `13-today-screen-states-banners-purge.md`
- `14-notification-scheduling-server-times.md`

## Blocking decisions

- Live-backend integration verification is gated on backend WIs 07/08 (`ai_specs/2026-07-26-adherence-pipeline-backend-spec.md`) shipping; if they have not landed when this WI runs, the manual a11y + unit/widget verification completes here and the integration pass is recorded as a follow-up.
