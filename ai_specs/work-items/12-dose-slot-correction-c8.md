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

- [ ] Slot renders every state with icon+text badge (grayscale-distinguishable); logged slots show both times
- [ ] Correction sheet offers exactly the two other statuses + Keep as is at equal weight; success path preserves previous value in slot detail
- [ ] C8 branches covered by widget tests: yes → CTA / yes → no-contact note (404 fake) / no → silent; prompt is dismissible and non-blocking
- [ ] All new copy via ARB in 5 locales; no `AppStrings` introduced
- [ ] Widget tests per spec §11 (slot per state, both-times, correction options, C8 branches) green; `flutter analyze` clean

## Covers

- Spec: §7 Dose slot / Correction sheet / C8 prompt; §8 copy rows (slot/correction/C8); §10 Use Cases 7, 8; §11 widget rows (slot, correction, C8); §13 AC 3, AC 4 (C8 half)

## Blocked by

- `11-agenda-notifier-offline-queue.md` (notifier intents + slot model)

## Blocking decisions

None.
