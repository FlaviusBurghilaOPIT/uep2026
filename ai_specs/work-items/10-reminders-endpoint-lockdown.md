---
type: Work Item
title: Reminders endpoint lockdown — scope now, delete later
parent: ../2026-07-26-adherence-pipeline-backend-spec.md
---

## What to build

Close the unscoped-read privacy gap on `/reminders` **without breaking the current mobile app** (which still calls these endpoints until the Today-screen migration ships):

1. `GET /reminders` — replace `.all()` with role-scoped queries: patient → reminders whose medication's case has `patient_id == current_user.id`; clinician → own cases' reminders.
2. `POST /reminders` — clinician role only (403 for patients); validate the target medication belongs to one of the clinician's cases.
3. `PATCH /reminders/{id}` — clinician role only, same case-ownership validation.
4. Final grep precheck of `web/` for fetch calls to all three endpoints; record findings in the PR. If the web app calls one, keep it clinician-scoped (do not delete) and record the deviation.
5. Add a `# DEPRECATED — delete after mobile Today-screen migration` comment on all three handlers.

Do NOT delete the endpoints in this Work Item — deletion is gated (see Blocking decisions).

## Required context

- Parent spec: `ai_specs/2026-07-26-adherence-pipeline-backend-spec.md` §6 E3, §8 Use Case 7.
- The privacy gap: `scheduled_reminders` has no RLS policy today (WI 06 adds it) and `GET /reminders` currently returns every patient's reminders to any authenticated user.
- Mobile callers to preserve temporarily: `today_screen.dart` (~lines 294-327) GET-then-create flow; notification scheduling in `today_agenda_notifier.dart`.
- Use `get_db_for_user`, not plain `get_db`.

## Acceptance criteria

- [x] Patient A receives zero of patient B's reminders from `GET /reminders` (two-patient fixture test)
- [x] Patients get 403 on POST/PATCH; clinicians restricted to own cases
- [~] Current mobile flows against these endpoints still function — existing backend suite fully green (88 passed, 1 skipped, 2026-07-26); golden-loop integration test NOT run (requires booted simulator + live backend). Note: patient `POST /reminders` now returns 403 by design — the `today_screen.dart` fallback create path fails silently (try/catch) until the Today-screen migration ships.
- [x] `web/` grep results recorded; deviations documented (see note below — no deviation needed)
- [x] Deprecation comments present on all three handlers

### Web grep findings (2026-07-26, `grep -rn "reminders" web/src/`)

No fetch/axios calls to any of the three `/reminders` endpoints exist in `web/src/` — only i18n display strings. Verbatim results:

```
web/src/i18n/types.ts:156:  remindersAt:      string
web/src/i18n/translations/it.ts:308:    remindersAt: '⏰ Promemoria alle:',
web/src/i18n/translations/es.ts:308:    remindersAt: '⏰ Recordatorios a las:',
web/src/i18n/translations/en.ts:310:    remindersAt:    '⏰ Reminders at:',
web/src/i18n/translations/en.ts:311:    noReminders:    '⏰ No scheduled reminders (as needed)',
web/src/pages/MedicationsPage.tsx:163:                ? `${t('medication.remindersAt')} ${reminderTimes.join(', ')}`
```

Deviation: none — endpoints kept (deprecated, not deleted) solely because the mobile app still calls them, per this WI's gating decision.

## Covers

- Spec: §6 E3; §8 Use Case 7 (scoping half); §13 AC 3 (query-logic half)

## Blocked by

None - ready to start

## Blocking decisions

- Full **deletion** of the three endpoints is gated on the mobile Today-screen migration (`ai_specs/2026-07-26-today-screen-hardening-spec.md`) shipping — the current mobile app depends on them. After that ships, a small follow-up removes the handlers and this decision.
