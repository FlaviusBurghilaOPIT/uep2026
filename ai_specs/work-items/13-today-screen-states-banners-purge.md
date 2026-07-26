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

- [ ] Zero fabricated data on Today: no fallback meds rendered when API returns empty; no forced times/statuses; no hardcoded dates/names (grep-verifiable)
- [ ] All six states render per spec with widget tests: skeleton, empty, error+retry, stale, offline, all-done
- [ ] Banners stack max one per kind; C1 deep-links to settings
- [ ] FDA card renders only for on-plan meds with data; silent omission otherwise; no "coming soon" snackbars remain
- [ ] Orphan checkin screen deleted; CheckInCard error state renders with retry
- [ ] All Today strings from ARB in 5 locales; dead `AppStrings` entries removed
- [ ] `flutter analyze` clean; `flutter test` green

## Covers

- Spec: §7 Screen (layout/states); §8 copy rows (screen/banner/checkin); §9 Deletions; §10 Use Cases 1, 2, 3, 5, 10; §11 widget rows (states, grouping, skeleton, no-fallback, ARB); §13 AC 1, AC 4 (state half), AC 6

## Blocked by

- `11-agenda-notifier-offline-queue.md` (notifier states/intents)
- `12-dose-slot-correction-c8.md` (slot component)

## Blocking decisions

None.
