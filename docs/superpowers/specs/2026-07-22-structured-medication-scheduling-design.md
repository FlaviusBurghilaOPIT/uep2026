# Structured Medication Scheduling & Language-Agnostic Guardrails

**Date:** 2026-07-22  
**Status:** Approved  
**Scope:** Backend schedule parser, API schema, web clinician UI, mobile patient app, AI guardrails  

---

## Problem Statement

The current system has three tightly coupled problems:

1. **`schedule_parser.py`** uses hardcoded English regex to parse free-text schedule strings. Breaks under i18n.
2. **`llm.py` and `ai.py`** use English-only keyword lists as safety guardrails. Non-English patients bypass them.
3. **`MedicationsPage.tsx`** presents a free-text input for frequency, producing arbitrary strings the backend tries to parse.

**Root cause:** The backend is doing natural language processing on input that should never be natural language.

---

## Design Decision: Approach A — Structured Schedule Contract

Replace all natural-language schedule handling with a typed, language-agnostic contract. Frontend sends structured data; backend does pure math. No regex. No English parsing.

---

## Section 1: Data Contract

### Frequency Codes (canonical)

| Code | Meaning            | Default reminder times        |
|------|--------------------|-------------------------------|
| QD   | Once daily         | 08:00                         |
| BID  | Twice daily        | 08:00, 20:00                  |
| TID  | Three times daily  | 08:00, 13:00, 20:00           |
| QID  | Four times daily   | 08:00, 12:00, 16:00, 20:00    |
| PRN  | As needed          | *(no reminders generated)*    |

### Schema Changes

**`FrequencyCode` enum** added to `backend/app/schemas.py`.

**`MedicationCreate`** — `schedule_text: str` removed, `frequency: FrequencyCode` added.

**`MedicationResponse`** — `schedule_text: str` replaced with `frequency` and computed `schedule_times: list[str]`.

### DB Model Strategy

`Medication.schedule_text` column kept (no migration). Router writes canonical code (e.g., `"TID"`) into it.

---

## Section 2: Backend Parser Replacement

### `schedule_parser.py` — full rewrite

Remove all regex. Replace with a pure lookup table:

```python
FREQUENCY_TIMES: Final[dict[str, list[time]]] = {
    "QD":  [time(8, 0)],
    "BID": [time(8, 0), time(20, 0)],
    "TID": [time(8, 0), time(13, 0), time(20, 0)],
    "QID": [time(8, 0), time(12, 0), time(16, 0), time(20, 0)],
    "PRN": [],
}

def times_for_frequency(frequency: str) -> list[time]:
    return FREQUENCY_TIMES.get(frequency.upper(), [time(8, 0)])
```

`parse_schedule_text` deleted. `parse_duration_days` kept (still parses duration string).

### AI Guardrail Redesign

**`ChatRequest` gains `intent_category: IntentCategory` field.**

**`IntentCategory` enum:**
- `general_question`
- `medication_query`
- `dose_change_request`  ← blocked server-side
- `diagnosis_request`    ← blocked server-side

`OUT_OF_SCOPE_MARKERS`, `OUT_OF_SCOPE_REGEX`, and `_check_local_regex_guardrail` are **deleted**.

Backend blocks `dose_change_request` and `diagnosis_request` by enum check — language-agnostic.

Bedrock native guardrails handle semantic filtering for any language.

---

## Section 3: Web Clinician UI

### `MedicationsPage.tsx`

Replace `<input type="text" placeholder="e.g. 3x daily">` with `<select>` dropdown:

| Value | Label (EN)              |
|-------|-------------------------|
| QD    | Once daily (QD)         |
| BID   | Twice daily (BID)       |
| TID   | Three times daily (TID) |
| QID   | Four times daily (QID)  |
| PRN   | As needed (PRN)         |

Add reminder time preview below dropdown: `⏰ Reminders at: 08:00, 13:00, 20:00` (reactive, no API call).

Add frequency label keys to all locale translation files.

---

## Section 4: Mobile Patient App

### `medications_notifier.dart`

Replace `scheduleText: String` with `frequency: String` + `scheduleTimes: List<String>`.

### ARB files — 5 locales (EN, ES, IT, DE, FR)

Add `frequencyQD`, `frequencyBID`, `frequencyTID`, `frequencyQID`, `frequencyPRN` keys.

### `today_screen.dart`

Replace raw `schedule_text` display with `_localizedFrequency(context, medication.frequency)` lookup.

### `assistant_screen.dart`

Add `_classifyIntent(String message)` → sends `intent_category` in `ChatRequest` payload.

---

## Files Changed

| File | Change |
|------|--------|
| `backend/app/schemas.py` | Add `FrequencyCode`, `IntentCategory` enums; update `MedicationCreate`, `MedicationResponse`, `ChatRequest` |
| `backend/app/services/schedule_parser.py` | Full rewrite — delete regex, add `FREQUENCY_TIMES` lookup |
| `backend/app/routers/cases.py` | Write `frequency.value` to `schedule_text`; use updated parser |
| `backend/app/routers/ai.py` | Delete `OUT_OF_SCOPE_MARKERS`; add `BLOCKED_INTENTS` enum check |
| `backend/app/providers/llm.py` | Delete `OUT_OF_SCOPE_REGEX` and `_check_local_regex_guardrail` |
| `web/src/pages/MedicationsPage.tsx` | Replace `<input>` with `<select>` + reminder preview |
| `web/src/i18n/translations/*.ts` | Add frequency label and reminder preview keys |
| `mobile/lib/features/medications/providers/medications_notifier.dart` | Replace `scheduleText` with `frequency` + `scheduleTimes` |
| `mobile/lib/features/today/today_screen.dart` | Replace `schedule_text` display with localized lookup |
| `mobile/lib/core/l10n/app_*.arb` | Add `frequencyQD/BID/TID/QID/PRN` in EN, ES, IT, DE, FR |
| `mobile/lib/features/assistant/assistant_screen.dart` | Add `_classifyIntent()` + send `intent_category` |

---

## Non-Goals

- No custom reminder time overrides (future feature)
- No tapered schedules (future feature)
- No DB column rename/migration
- PRN generates zero `ScheduledReminder` rows by design

---

## Testing

| Layer | Test |
|-------|------|
| Backend unit | `times_for_frequency("TID")` returns 3 times; `PRN` returns `[]` |
| Backend unit | POST with `frequency: "BID"` creates exactly 2 × `duration_days` reminder rows |
| Backend unit | POST `/ai/chat` with `intent_category: "dose_change_request"` returns `in_scope=false, escalate=true` |
| Web | `npm run build` + `npm run lint` passes |
| Mobile | `flutter analyze` 0 issues; `flutter test` passes |
