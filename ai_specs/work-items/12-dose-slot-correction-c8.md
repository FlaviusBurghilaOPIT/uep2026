---
type: Work Item
title: Dose slot component + correction sheet + C8 side-effect prompt
parent: ../2026-07-26-today-screen-hardening-spec.md
---

## What to build

The core Today-screen dose slot component and its two interaction sheets (spec §7 "Dose slot", "Correction sheet", "C8 side-effect prompt"):

1. **Dose slot component:**
   - Content: med name (Tall Man mixed-case preserved, wraps 2 lines), dose formatted per M-08 (`0.5 mg` — leading zero, space before unit), scheduled time device-local, state badge.
   - Badges icon + text + color (M-03) for `upcoming` / `due` ("Due now") / `overdue` / `missed` (grey factual "Scheduled {time}") / `taken` / `skipped` / `syncPending` (cloud icon "Saved on device").
   - Logged slots always show both times: "Scheduled for 8:00 AM — Logged at 8:42 AM."
   - Actions by state: `upcoming`/`due`/`overdue` → three action rows (Taken / Skipped / Missed, localized, ≥48dp); early logging allowed, scheduled-time label kept. Logged slots → tapping opens the correction sheet. `writeInFlight` → inline spinner replaces actions.
2. **Correction sheet (C7):** bottom sheet — `todayCorrectionTitle` ("Logged as {status} at {time}. Change what happened?") + the two *other* statuses + `todayCorrectionKeep` ("Keep as is") at equal visual weight. Success → factual confirmation; previous value visible in slot detail. Factual, never shaming (Never Rule 4).
3. **C8 side-effect prompt:** on `skipped` commit → one-tap, dismissible, non-blocking prompt `todaySkipPrompt` → **Yes** → Call Emergency Contact CTA (`tel:`) via `GET /cases/{caseId}/emergency-contact`; **if 404/unset** → no CTA, render `todayNoEmergencyContact` instead; **No, I'm okay** → completes silently.
4. ARB keys for all new copy ×5 locales per spec §8 (slot/correction/C8 rows).

## Required context

- Parent spec: `ai_specs/2026-07-26-today-screen-hardening-spec.md` §7 (slot, correction sheet, C8 prompt), §8 copy matrix, §4 ethical constraints, §10 use cases 7, 8; accessibility M-03/M-04/M-08 rows.
- Pending question D1: confirm the emergency-contact endpoint 404s (not 500s) when unset — drives the no-contact branch; verify against `backend/app/routers/cases.py`.
- Writes go through the WI 11 notifier intents (`logDose`, `correctLog`); the component emits intents, it never calls `ApiService` directly.
- Existing `_MedAction` (~34dp targets) is replaced, not extended.

## Acceptance criteria

- [x] Slot renders every state with icon+text badge (grayscale-distinguishable); logged slots show both times
- [x] Correction sheet offers exactly the two other statuses + Keep as is at equal weight; success path preserves previous value in slot detail
- [x] C8 branches covered by widget tests: yes → CTA / yes → no-contact note (404 fake) / no → silent; prompt is dismissible and non-blocking
- [x] All new copy via ARB in 5 locales; no `AppStrings` introduced
- [x] Widget tests per spec §11 (slot per state, both-times, correction options, C8 branches) green; `flutter analyze` clean

## Implementation notes (2026-07-27)

- New components: `dose_slot_card.dart` (all 6 server states + syncPending + writeInFlight spinner, 48dp action rows, both-times line, previous-value line, M-08 dose formatting via `dose_format.dart`), `correction_sheet.dart` (C7), `side_effect_prompt_card.dart` (C8, inline non-blocking card — a modal dialog was rejected by spec §3).
- **D1 verified:** `GET /cases/{caseId}/emergency-contact` returns 200 with `{"name": null, "phone": null}` when unset (404 only for unknown case) — the no-contact branch keys off null/empty phone, not 404 (`backend/app/routers/cases.py:193-207`).
- C8 telemetry (`skip_sideeffect_yes/no`, `emergency_cta_tapped`, `correction_opened`) fires from the notifier; phone fetch reuses the auth case with the `/patients/{id}/case` fallback.
- All spec §8 ARB keys + reused C1/C9 keys (`remindersOffBanner`, `emptyPlanMessage`) added in en/de/es/fr/it and pinned by `test/unit/today_l10n_test.dart`.

## Covers

- Spec: §7 Dose slot / Correction sheet / C8 prompt; §8 copy rows (slot/correction/C8); §10 Use Cases 7, 8; §11 widget rows (slot, correction, C8); §13 AC 3, AC 4 (C8 half)

## Blocked by

- `11-agenda-notifier-offline-queue.md` (notifier intents + slot model)

## Blocking decisions

None.
