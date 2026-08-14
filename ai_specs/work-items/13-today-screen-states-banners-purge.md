---
type: Work Item
title: Today screen states, banners + fabricated-data purge
parent: ../2026-07-26-today-screen-hardening-spec.md
---

## What to build

Rewire `TodayScreen` onto the WI 11 notifier and the WI 12 slot component, and purge all fabricated data (spec §7 layout/states, §9 deletions):

1. **Layout (top → bottom)** per spec §7: top bar (real `{fullName}`, ellipsized, avatar → `/profile`; **delete** notification bell + "coming soon" snackbar) · greeting card (time-of-day greeting, real `{taken}/{total} doses` from slot states; **delete** "Day 19 post-surgery" and hardcoded `'TODAY · JUL …'` — format real date via locale) · banners region (stacking, max one per kind: C1 reminders-off, C6 plan-changed, C11 stale freshness line, C3 offline, C5 timezone-adjusted) · CheckInCard (unchanged behavior + added error state with `checkinErrorRetry`) · FdaWarningCard (only when API returns data for a med on the patient's plan — query per-plan med, not hardcoded "Amoxicillin"; silent omission on failure; **delete** "coming soon" snackbar — card untappable unless detail exists) · next-due pinned slot · dose slots grouped Morning/Midday/Evening/Bedtime by local scheduled hour (collapsible when >3 per group) · PRN "As needed" section · celebration card when all non-PRN slots terminal (ARB-localized, dismissible, no streaks).
2. **States** per spec §7 table: loading skeleton (greeting + 3 slot cards), empty (C9 `emptyPlanMessage` + pull-to-refresh hint), error (error card + retry `todayAgendaError`), stale (cache + `todayStaleBanner`), offline (persistent `todayOfflineBanner`, slots fully loggable), all-done (celebration + `todayCelebrationNext` from first future slot).
3. **Deletions per spec §9:** 3 hardcoded fallback meds (`today_screen.dart:34-59`); `'time': '08:00'`/`'status': 'pending'` forcing (`:188-189`); screen-side write path (5s timer → GET /reminders → create → POST, `:294-327`); "Day 19"/hardcoded dates; orphan `lib/features/checkin/checkin_screen.dart` (its `/symptoms/checkin` path dies with it; CheckInCard posts `/checkins` — verify D2 against backend `checkins.py`); empty `catch (_) {}` blocks on Today.
4. **Strings:** all Today `AppStrings` usages → ARB keys (5 locales per spec §8); delete `AppStrings` entries used only on Today.

## Required context

- Parent spec: `ai_specs/2026-07-26-today-screen-hardening-spec.md` §7 (layout + states), §8 copy matrix, §9 deletions, §10 use cases 1, 2, 3, 5, 10; pending questions D2, E1.
- Supersedes pre-audit slices: `ai_specs/0001-mobile-core-loop-hardening-polish/work-items/02-dual-icon-status-pills.md`.
- C5 timezone banner trigger logic lands in WI 14; this WI renders the banner region slot for it.
- Do not touch Recovery/Profile fabricated data — out of scope (separate work).

## Acceptance criteria

- [x] Zero fabricated data on Today: no fallback meds rendered when API returns empty; no forced times/statuses; no hardcoded dates/names (grep-verifiable)
- [x] All six states render per spec with widget tests: skeleton, empty, error+retry, stale, offline, all-done
- [x] Banners stack max one per kind; C1 deep-links to settings
- [x] FDA card renders only for on-plan meds with data; silent omission otherwise; no "coming soon" snackbars remain
- [x] Orphan checkin screen deleted; CheckInCard error state renders with retry
- [x] All Today strings from ARB in 5 locales; dead `AppStrings` entries removed
- [x] `flutter analyze` clean; `flutter test` green

## Implementation notes (2026-07-27)

- `today_screen.dart` fully rewritten (886 → ~950 lines, but zero fabricated data) onto `TodayAgendaNotifier` (WI 11) + `DoseSlotCard`/`CorrectionSheet`/`SideEffectPromptCard` (WI 12). No screen code calls `ApiService` directly for adherence data; the only remaining `api`-adjacent read is `fdaWarningProvider` (read-only, per-plan-med FDA lookup).
- **D2 resolved against real backend evidence, correcting the spec's own assumption:** `backend/app/routers/checkins.py` mounts at prefix `/symptoms` (`POST /symptoms/checkin`, query params `case_id`/`feeling`, no JSON body) — there is no `/checkins` route. `/checkins` was the orphan `SymptomCheckinNotifier`'s bug, not the canonical route as the spec assumed; the orphan `CheckInScreen`'s `/symptoms/checkin` path was actually correct. Fixed `SymptomCheckinNotifier.submit()` to call `POST /symptoms/checkin?case_id=&feeling=` (renamed the `severity` param to `feeling` to match `CheckInFeeling` enum values already used by `CheckInCard`'s mood picker); updated `test/unit/symptom_checkin_test.dart` accordingly. This was necessary for the new `checkinErrorRetry` state to be meaningful — building it atop the previously-broken write path would have made every check-in fail against a real backend.
- **E1 confirmed:** FDA card data source is `GET /cases/{id}/medications` names surfaced through the agenda's slots/PRN (`fdaWarningProvider` queries `GET /fda/drug/{medicationName}` for each on-plan med, first non-empty summary wins; silent omission — logged via `debugPrint`, never surfaced — on 404/error/no data). New `fda_warning_provider.dart` + `test/unit/fda_warning_provider_test.dart` (3 tests: real data, no on-plan match, query throws).
- New supporting files: `dose_group.dart` (Morning/Midday/Evening/Bedtime bucketing by local hour), `core/settings/settings_opener.dart` (C1 banner's OS-settings deep link, via the `app_settings` package).
- Celebration card's spec-listed "Next dose: {weekday} at {time}" sub-line is **not rendered**: E2's agenda endpoint is single-day, so there is no real "next dose" data once every non-PRN slot for today is terminal — showing one would mean fabricating it, which the spec's own §3 rejects ("Keep fallback meds for demo/dev — Fabricated clinical data"). The celebration text itself (`todayCelebration`) renders; the `todayCelebrationNext` ARB key exists (pinned by `today_l10n_test.dart`) but is currently unused pending a real multi-day/next-occurrence data source.
- Time-of-day group collapse (`>3 slots`) uses an icon + bare count toggle (no prose "show more" string) — the spec's copy matrix (§8) doesn't define copy for this control, so no unvetted English string was invented; the toggle's `Semantics` label composes only already-localized parts (group name + count).
- **Deviation — notification-scheduling wiring intentionally deferred to WI 14's commit:** `today_screen.dart` renders the C1 (`remindersOff`) and C5 (`timezoneAdjusted`) banner slots against `TodayAgendaNotifier` state, but nothing sets those flags yet in this commit — matches the parent WI's own "Required context" note ("C5 timezone banner trigger logic lands in WI 14; this WI renders the banner region slot for it"); WI 14 additionally owns C1's trigger (permission-check → `setRemindersOff`) per its own spec. `TodayAgendaNotifier` gained `setTimezoneAdjusted`/`dismissTimezoneAdjusted` methods in this commit since the banner's dismiss action needs a home; `setTimezoneAdjusted` sits unused until WI 14 wires the reanchor pass to call it.
- Two pre-existing tests exercised the fabricated data this WI deletes and were retired: `test/widget/dose_status_pill_test.dart` (deleted — its icon+text/48dp/grayscale coverage is superseded by `test/widget/dose_slot_card_test.dart`, landed with WI 12) and the "TodayScreen FDA Source Badge Integration Tests" group in `test/widget/fda_source_badge_test.dart` (removed — it asserted the hardcoded-Amoxicillin fallback the spec explicitly deletes; the `FdaWarningCard` presentational-component coverage in the same file is untouched and still passes).
- `test/widget/main_shell_page_test.dart` and `integration_test/golden_loop_test.dart` needed small fixes unrelated to their own scope, both required to keep `flutter analyze`/`flutter test` green now that `TodayScreen.initState` synchronously touches `TodayAgendaNotifier` (which needs `sharedPreferencesProvider`): added `sharedPreferencesProvider`/`apiServiceProvider` overrides to the shell test, and replaced `AppStrings.taken` (deleted) with the literal `'Taken'` string (the English `doseStatusTaken` ARB value the WI 12 `DoseSlotCard` renders) in the golden-loop integration test.
- Added a testable `DateTime Function()? clock` constructor seam to `TodayScreen` (defaults to `DateTime.now`) so the time-of-day greeting is deterministic in tests, avoiding flakiness from the previous implicit real-clock dependency.

## Covers

- Spec: §7 Screen (layout/states); §8 copy rows (screen/banner/checkin); §9 Deletions; §10 Use Cases 1, 2, 3, 5, 10; §11 widget rows (states, grouping, skeleton, no-fallback, ARB); §13 AC 1, AC 4 (state half), AC 6

## Blocked by

- `11-agenda-notifier-offline-queue.md` (notifier states/intents)
- `12-dose-slot-correction-c8.md` (slot component)

## Blocking decisions

None.
