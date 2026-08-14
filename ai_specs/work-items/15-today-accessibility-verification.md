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

- [x] Merged-semantics slot + live-region announcements verified by semantics widget tests
- [x] 200% text scale test: no overflow on slot, correction sheet, banners
- [x] All interactive targets ≥48dp (test or measured audit recorded)
- [x] Reduce Motion honored for celebration animation
- [x] `flutter analyze` clean; full `flutter test` suite green
- [x] Manual a11y checklist written and integration-vs-backend status recorded

## Implementation notes (2026-07-27)

- **M-01:** `DoseSlotCard`'s descriptive block (name/dose/scheduled time/status badge/both-times/previous-value) is wrapped in one `Semantics(container: true, excludeSemantics: true, label: <merged sentence>)` node — exact pattern *"{medName} {dose}, scheduled {time}, {state}. Actions: taken, skipped, missed."* (the "Actions:" clause is omitted for logged/terminal slots, which have no taken/skipped/missed buttons). Action rows are structural **siblings** of that Semantics node, not descendants — verified by `find.descendant(of: <merged node>, matching: find.byKey(<action key>))` returning nothing, so TalkBack/VoiceOver reach the card as one announcement, then the three actions as their own focusable stops (spec's reading order: card → actions). `today_screen.dart._logDose` sends a live-region announcement via `SemanticsService.sendAnnouncement` (the modern, non-deprecated, multi-window-safe API — `SemanticsService.announce` is deprecated as of Flutter 3.35) with the exact spec-example shape, `"Ibuprofen marked as taken"`; verified in a widget test by intercepting `SystemChannels.accessibility`.
- **M-02:** Removed every remaining fixed-height (`SizedBox(height: 48)`) interactive target in the Today surface — slot action rows, correction-sheet options, C8 Yes/No/emergency-CTA, the retry button, the PRN log button, and the group-collapse toggle — replacing each with `ConstrainedBox(constraints: BoxConstraints(minHeight: 48))` so 48dp is a floor, not a ceiling, letting content grow at large text scales instead of clipping. `CorrectionSheet`'s content is now wrapped in `SingleChildScrollView` — at 200% scale the title + three ≥48dp options can exceed the sheet's available height, and a bottom sheet has no other escape valve. Fixed one real overflow bug found by the new 200%-scale test: `DoseSlotCard`'s scheduled-time row (`Icon` + `Text`) had no `Flexible`, so a wide badge at 2x scale pushed it into overflow — wrapped the time `Text` in `Flexible` + `overflow: ellipsis`. Widget tests added at 200% (`TextScaler.linear(2.0)`, applied via `MaterialApp.builder` — wrapping `MaterialApp` itself in an ancestor `MediaQuery` doesn't work, since `MaterialApp` builds its own root `MediaQuery` from the test view) for the slot, correction sheet, C8 prompt, and the banner region — all assert `tester.takeException()` is null.
- **M-03:** New test enumerates all 6 `SlotState` values against `DoseSlotCard` and asserts the status badge's icon is pairwise-distinct across all of them (icon+text was already the existing pattern from WI 12; this test is the verification WI 15 owns). The pre-existing `dose_status_pill_test.dart`, which covered the same requirement against the now-deleted hardcoded-meds `today_screen.dart`, was already retired in WI 13.
- **M-04:** Full audit of Today's interactive targets found two real violations introduced by the WI 13 rewrite, both fixed: the top-bar avatar (visually 40dp, per the design) had only a 40dp hit area — wrapped in `InkWell` inside a 48×48 `SizedBox` so the visible size is unchanged but the hit area meets the floor; the C1/C6/C5 banner's text-only action link (e.g. "Open Settings") had no minimum height — wrapped in `ConstrainedBox(minHeight: 48)` + `GestureDetector(behavior: HitTestBehavior.opaque)` so the whole padded row is tappable, not just the glyph bounds. Also bumped `CheckInCard`'s mood-picker chips and its new error-retry row to the same floor (predates WI 13/15 but sits on Today, cheap to fix while in the file). Verified via existing + new `tester.getSize(...).height >= 48.0` assertions across `dose_slot_card_test.dart`, `correction_sheet_test.dart`, `side_effect_prompt_card_test.dart`.
- **M-05:** Haptic-on-log was already wired in WI 13 (`HapticFeedback.mediumImpact()` in `_logDose`, try/catch-guarded). Reduce Motion: Today's celebration card, banners, and slot cards use **no `AnimationController`/`AnimatedContainer`/implicit-animation widget anywhere** — there is nothing to disable in the first place, verified by a test asserting `find.byType(AnimatedContainer)` is empty even with `AccessibilityFeatures.disableAnimations`/`reduceMotion` forced true via `platformDispatcher.accessibilityFeaturesTestValue`. This is compliant by construction, not by a runtime branch — a deliberate simplification versus the pre-WI-13 screen, which had an `AnimatedContainer` on the status badge with no Reduce Motion guard at all (a real defect this rewrite also incidentally fixes).
- **M-06:** Automated proxy test confirms the pinned "DUE NOW" slot and its action row are found (built into the tree) **without any scroll gesture**, i.e. above the fold, in the same 1080×2400@2x viewport `today_screen_test.dart` already uses. The stricter "primary actions entirely within the bottom 60% of viewport" one-handed-reachability claim is inherently a physical/geometric audit against real device dimensions and thumb-reach templates — the parent a11y spec's own M-06 test procedure says exactly this ("perform a reachability audit using standard one-handed thumb reach templates"); it is not meaningfully unit-testable and is carried into the manual checklist below instead of being faked with a brittle pixel assertion.
- **M-07:** Manual qualitative Grade-8 readability sweep of the WI 11-14 copy matrix (`app_en.arb`'s `today*` keys): all patient-facing strings are short, plain-language sentences (e.g. *"We couldn't load your care plan. Check your connection and try again."*, *"Log saved on your device. We will update your care team once you are back online."*); no jargon or acronyms. The one clinically-worded string (`todaySkipPrompt`, "Are you experiencing severe or troubling symptoms?") is marked ⚕ in the spec's own copy matrix as pending clinical sign-off — not altered here, out of scope for an engineering pass to rewrite clinically-reviewed safety copy. No automated Flesch-Kincaid scanner was built for this (out of proportion to the remaining string count); this was a manual read-through.
- **M-08:** `formatDose` (`0.5 mg`, leading zero, single space) is exercised by the pre-existing `dose_format_test.dart` (4 tests, unchanged) and is the only path used to render doses on Today — confirmed via the WI 13 screen (slot cards and PRN cards both call `formatDose`, no other dose-rendering path exists on the screen).
- **Async/lifecycle audit** (per this WI's own "Required context" note): the 60s empty-state poll and 30s offline-queue-retry timers are cancelled via `TodayAgendaNotifier`'s `ref.onDispose` (unchanged from WI 11, already covered by its own unit tests). Discovered and fixed a real test-authoring gap while adding the WI 13/14 widget suite: `flutter_test`'s "no pending timers" invariant is checked **before** `addTearDown` callbacks run, so a `ProviderContainer` disposed only via `addTearDown` never satisfies it if the notifier has a live periodic timer at test end — `today_screen_test.dart`'s empty/offline-state tests now dispose the container explicitly at the end of the test body (in addition to keeping `addTearDown` as an exception-safety net), which is the actual fix, not new WI 15 code.
- **Verification pass:** `flutter analyze` clean (15 pre-existing issues remain, all in files this branch never touched — auth screens and their tests); full `flutter test` suite green (133 tests, up from 111 pre-WI-13).
- **Integration-vs-backend status:** backend WIs 07/08 (`agenda.py`, `adherence.py`) are present and registered in `backend/app/main.py`, so `integration_test/golden_loop_test.dart` is structurally unblocked. It was **not executed this session** — this sandbox has no booted iOS/Android simulator or emulator (`flutter devices` shows only macOS-desktop and Chrome; `xcrun simctl list devices booted` is empty), and standing one up plus a docker-compose Postgres stack plus seeding was judged out of proportion to attempt speculatively within this pass. Per this WI's own "Blocking decisions" allowance, the integration pass is recorded as a follow-up: run `docker-compose up`, `python app/scripts/seed_data.py`, boot a simulator, then `flutter test integration_test/golden_loop_test.dart` before release sign-off.

## Manual accessibility checklist (release-blocking sign-off record)

Per spec §11 "Manual a11y (release-blocking)" — **not yet executed against a physical device or simulator this session**; this is the checklist a release owner must complete and initial before shipping Today, mirroring the spec's own M-01–M-06 test procedures:

- [ ] **TalkBack (Android) / VoiceOver (iOS), eyes closed:** swipe linearly through Today; confirm each slot reads as one sentence *"{med} {dose}, scheduled {time}, {state}. Actions: taken, skipped, missed."* before advancing to the Taken/Skipped/Missed buttons; complete a full log (Taken) and hear the "{med} marked as taken" announcement; open a logged slot's correction sheet and complete a correction, purely by ear.
- [ ] **200% system text size**, all six screen states (loading, fresh, empty, error, stale, offline) plus the correction sheet and C8 prompt open: no visual clipping, no red/yellow `RenderFlex` overflow banners, all text remains legible.
- [ ] **Grayscale / color-filter simulation** (e.g. iOS Color Filters → Grayscale, or a colorblindness simulator): confirm `upcoming`/`due`/`overdue`/`missed`/`taken`/`skipped` badges remain distinguishable from icon + text alone.
- [ ] **Reduce Motion enabled** (OS-level): trigger the all-done celebration card; confirm nothing animates/shakes (expected — Today has no animated widgets to begin with, per the implementation notes above).
- [ ] **One-handed thumb-reach audit** (M-06): on a representative large-screen device, confirm the next-due pinned slot's Taken/Skipped/Missed row and the check-in mood picker fall within the bottom ~60% of the viewport without stretching.
- [ ] **Integration-vs-backend:** run the golden-loop integration test (see status note above) against a seeded local backend before this checklist is signed off as complete.

## Covers

- Spec: §7 Accessibility; §10 Use Case 11; §11 manual a11y + verification rows; §13 AC 7

## Blocked by

- `12-dose-slot-correction-c8.md`
- `13-today-screen-states-banners-purge.md`
- `14-notification-scheduling-server-times.md`

## Blocking decisions

- Live-backend integration verification is gated on backend WIs 07/08 (`ai_specs/2026-07-26-adherence-pipeline-backend-spec.md`) shipping; if they have not landed when this WI runs, the manual a11y + unit/widget verification completes here and the integration pass is recorded as a follow-up.
