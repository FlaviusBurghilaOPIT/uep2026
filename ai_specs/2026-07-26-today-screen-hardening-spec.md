---
type: Spec
title: Today Screen Hardening — Server-Truth Agenda, Single Write Path, Correction Sheet, Safety States
status: Ready for Engineering
created: 2026-07-26
sources:
  - Intent /fortify: Today screen & adherence pipeline (2026-07-25, conversation) — state inventory, slot state machine, edge catalog
  - ai_specs/2026-07-26-adherence-pipeline-backend-spec.md (E1/E2 contracts this consumes) — BLOCKER dependency
  - Intent extract-mode mobile inventory (2026-07-25) — current today_screen.dart behaviors
  - docs/product/03-safety-and-edge-cases.md C1–C9, C11 via git HEAD; docs/ux/07-accessibility-spec.md M-01–M-08
related:
  - ai_specs/2026-07-25-patient-first-run-flow-spec.md (lands patients on this screen; owns the reminder primer + C1 banner strings)
---

## 1. Ownership & Context

- **Owner:** Flavius (engineering)
- **Status:** Ready for Engineering — **blocked on** `2026-07-26-adherence-pipeline-backend-spec.md` (E2 agenda endpoint, E1 write API). Server constants `DUE_WINDOW_BEFORE/AFTER` shared with backend (⚕ clinical validation pending there).
- **Scope:** `mobile/lib/features/today/`, `mobile/lib/features/checkin/`, notification scheduling in `today_agenda_notifier.dart`, `FakeApiService` test seam. Recovery/Profile fabricated-data fixes are **out of scope** (separate work).

**Traceability:** resolves audit findings C2 (fabricated meds, discarded real times/statuses) and C3 (double POST, swallowed errors, no correction path) on the mobile side, plus safety cases C1, C3, C4, C5, C6, C7, C8, C9, C11 and fortify P0s 1–5.

## 2. Problem & User Need

Today is where the product promise is kept or broken: *"Patient comprehends their next due dose in <3 seconds without scrolling."* The current screen renders hardcoded fallback medications as real prescriptions, discards the server's real dose times and statuses (forcing `'08:00'`/`pending`), double-posts every log through two divergent write paths, swallows all errors in empty catch blocks, allows unlabeled silent reverts of logged doses, and has no empty, error, stale, or plan-changed states. For a clinic's app, showing a patient a drug they were never prescribed — or a real prescription at the wrong time — is a safety defect, not a UI bug.

**Success metric:** 100% of rendered dose data is server truth; every log reaches the server exactly once (or is visibly queued); every mistap is correctable.

## 3. Design Approach

- **The notifier is the only writer.** `TodayAgendaNotifier` owns all adherence writes; the screen emits intents. This removes the double POST by construction (fortify P0-2).
- **Server computes, client renders.** Slot states (`upcoming/due/overdue/missed/taken/skipped`) arrive computed from E2; no client-side time windows, no `schedule_text` parsing, no client-created reminders.
- **Optimistic but honest:** instant UI feedback on tap, single write in flight per slot, 409-reconcile to server truth, explicit rollback with explanation on final failure.

**What we did NOT do, and why:**

| Rejected | Reason |
|---|---|
| Keep fallback meds for demo/dev | Fabricated clinical data under the clinic's name — the C2 defect itself. Demos seed the backend instead |
| Silent tap-to-revert on logged slots | Unlabeled correction that stages a confusing second write (C3) — replaced by an explicit correction sheet |
| Client-side due/overdue computation | Two sources of truth for "late"; backend owns the ⚕-validated constants |
| Client-side `schedule_text` parsing for notifications | Server slot times drive local notifications; parser code deleted |
| Blocking modal for C8 side-effect prompt | Must never hold a patient in pain hostage to a dialog — one-tap, dismissible, non-blocking |

## 4. Ethical Review

- **Correction sheet copy is factual, never shaming** (Never Rule 4): "Logged as Taken at 8:42 AM. Change what happened?" — no guilt, no warning styling beyond neutral emphasis.
- **Auto-missed rendering** is factual ("Scheduled for 8:00 AM"), never punitive color-blocking or streak language. Reviewed against Streak Manipulation (Category 4): no streaks, no counts of consecutive days, no loss framing. **Clear.**
- **C8 prompt** offers help without surveillance framing; "No, I'm okay" is equal-weight to "Yes" (no Visual Misdirection toward the clinic-preferred answer). **Clear.**
- **Offline banner** discloses data state honestly (Never Rule 6). **Clear.**
- **No dark patterns introduced.** Clearance: this spec removes deceptive structures (fabricated data presented as authoritative) and adds none.

## 5. Measurement

No PHI — enums, timestamps-as-deltas, booleans only (`09-measurement-plan.md` §1.2).

| Event | Fires when | Properties |
|---|---|---|
| `mobile.today.agenda_viewed` | agenda load succeeds | slot_count, has_prn, stale (bool) |
| `mobile.today.agenda_failed` | agenda load fails with no cache | error_class |
| `mobile.today.dose_log_tapped` | slot action tapped | slot_state_before, action |
| `mobile.today.dose_log_committed` | write confirmed by server | status, was_offline (bool) |
| `mobile.today.dose_log_undone` | undo within 5s | — |
| `mobile.today.dose_log_rolled_back` | final write failure after retry | error_class |
| `mobile.today.correction_opened` | logged slot tapped | slot_age_hours_bucket |
| `mobile.today.dose_log_corrected` | PATCH succeeds | — |
| `mobile.today.skip_sideeffect_yes` / `_no` | C8 prompt answer | — |
| `mobile.today.emergency_cta_tapped` | emergency call tapped from C8 | — |
| `mobile.today.sync_flushed` | offline queue flush completes | entries_count, duration_ms_bucket |
| `mobile.today.banner_cta` | C1/C6/C11 banner action tapped | banner_kind |

**Primary metric:** dose-log write success rate (committed ÷ tapped). **Counter-metrics:** rollback rate, correction rate (high rates → slot-time defaults wrong — feeds backend §5 learning plan), C8-yes rate (safety signal for clinician triage).

## 6. Data Layer Specification (`TodayAgendaNotifier` — rewrite)

### Read

- `loadAgenda()` → `GET /patients/me/agenda?date=<today local>`. Cache last-good response (in-memory + persisted JSON for cold start). Exposes: `slots`, `prn`, `sourceState: loading|fresh|stale|error|empty`, `lastSyncedAt`.
- **State mapping:** `fresh` = fetch OK; `stale` = fetch failed but cache exists (render cache + freshness line); `error` = fetch failed, no cache; `empty` = fetch OK, zero slots and zero PRN (C9 state).
- Pull-to-refresh retriggers; 60s background poll while screen is visible **only when `empty`** (C9: plan may arrive mid-session). No polling otherwise (battery + attention respect).

### Write — single path, per-slot lock

```
logDose(slot, status):
  if slot.writeInFlight: ignore (haptic only)          # double-tap guard
  slot.writeInFlight = true
  previousState = slot.state
  apply optimistic state + status                       # instant UI
  show Undo snackbar (5s, ARB-localized)
  if undone within 5s: revert local, writeInFlight = false, return
  try:
    POST /adherence/log?scheduled_reminder_id=slot.slot_id&status=status
    on 201: commit; sync logged_at from response
    on 409: reconcile slot to response detail (status + logged_at)  # server truth wins
  on network failure:
    enqueue OfflineEntry(idempotency_key=uuid4(), kind=create, slot_id, status)
    slot.syncPending = true                             # "saved on device" icon + C3 banner
  on final failure after retry:
    rollback to previousState + error snackbar (ARB: todayLogRollbackError)
  slot.writeInFlight = false
```

- **Correction:** `correctLog(slot, newStatus)` → `PATCH /adherence/logs/{slot.dose_log_id}`; on success update + show `previous_status` factually; offline → queued as `kind=correct` entry; queue flush order: **creates before corrections**.
- **PRN ad-hoc:** `logPrn(medication, status)` → `POST /adherence/log-adhoc` with `idempotency_key=uuid4()` generated per user action (retries reuse the same key).
- **Boot flush (C4):** on app start and on connectivity restore, flush queue in order; per-entry 409 → reconcile, not error. On complete: `sync_flushed` event + banner clears.

### Notifications (rebuilt on server truth)

- Schedule local notifications **from E2 slot times** (UTC → device-local). Delete the `'3x'/'2x'` parsing scheduler.
- **Re-anchor (C5):** recompute on every app start and on OS timezone-change event; if rendered times shift, show `todayTimezoneAdjusted` banner once.
- Permission: never requested here — the first-run primer owns asking. If denied → C1 banner state only.

## 7. Screen Specification — TodayScreen

**Intent:** the clinical home screen. Answers in <3s: *what do I take next, and what have I already done?* If removed: the product has no daily surface.

### Layout (top → bottom)

1. **Top bar:** "RemoteCare" + `{fullName}` (real auth data; ellipsize long names — never clip the greeting); avatar → `/profile`. **Delete** the notification-bell "coming soon" snackbar — the bell is removed until a real notification center exists (dead controls erode clinical trust).
2. **Greeting card:** time-of-day greeting + first name (or nameless "Good morning." if unavailable); progress `{taken}/{total} doses` from **real slot states**; **delete** "Day 19 post-surgery" and hardcoded `'TODAY · JUL …'` (format real date via locale).
3. **Banners region** (stacking, max one per kind): C1 reminders-off (+ settings deep link) · C6 plan-changed · C11 stale freshness line · C3 offline · C5 timezone-adjusted.
4. **CheckInCard** (unchanged behavior; §9 covers its copy/localization; error state added — currently unrendered).
5. **FdaWarningCard** — only rendered when the API returns data for **a medication on the patient's plan** (query per-plan med, not hardcoded "Amoxicillin"); silent omission on failure, never a fabricated warning. **Delete** the "FDA detail — coming soon" snackbar — tap opens the detail sheet or the card doesn't render as tappable.
6. **Next-due pinned slot** (if any `due`/`overdue` slot exists).
7. **Dose slots grouped by time-of-day** (Morning / Midday / Evening / Bedtime buckets by local scheduled hour; collapsible when >3 slots per group).
8. **PRN section** ("As needed") — cards with log action (ad-hoc write).
9. **Celebration card** when all non-PRN slots are terminal (taken/skipped/missed): existing copy, ARB-localized, dismissible. No streaks, no counts of consecutive days.

### Dose slot (the core component)

- **Content:** med name (Tall Man mixed-case preserved, wraps 2 lines), dose formatted per M-08 (`0.5 mg` — leading zero, space before unit), scheduled time (device-local), state badge.
- **Badges:** icon + text + color (M-03): `upcoming` neutral-clock · `due` teal-dot "Due now" · `overdue` amber "Scheduled 8:00 AM" · `missed` grey factual "Scheduled 8:00 AM" · `taken` green-check · `skipped` amber · `syncPending` cloud icon "Saved on device".
- **Logged slots always show both times:** "Scheduled for 8:00 AM — Logged at 8:42 AM."
- **Actions by state:** `upcoming`/`due`/`overdue` → three action rows ≥48dp: Taken / Skipped / Missed (localized — currently hardcoded via AppStrings). Early logging allowed; slot keeps scheduled-time label. `taken`/`skipped`/logged → tapping opens the **correction sheet**. `writeInFlight` → actions replaced by inline spinner.
- **Correction sheet (C7):** bottom sheet — "Logged as {status} at {loggedAt}. Change what happened?" + the two *other* statuses as options + "Keep as is" (equal visual weight). Success → factual confirmation; previous value visible in slot detail.
- **C8 side-effect prompt:** on `skipped` commit → one-tap prompt: "Are you experiencing severe or troubling symptoms?" → **"Yes"** → Call Emergency Contact CTA (tel:). **If no emergency contact on file:** no CTA — render "No emergency contact on file — contact your clinic." (fixes the silent-dead-button finding). **"No, I'm okay"** → completes silently. Dismissible, non-blocking.

### States (visual spec per fortify inventory)

| State | Rendering |
|---|---|
| loading (initial) | skeleton greeting + 3 skeleton slot cards (`AppSkeletonLoader`) |
| empty (C9) | calm empty state, `emptyPlanMessage`; pull-to-refresh hint |
| error (no cache) | error card + retry button (`todayAgendaError`) |
| stale (C11) | cached agenda + "Updated {relativeTime} — syncing latest plan…" |
| offline (C3) | persistent banner `todayOfflineBanner`; slots fully loggable |
| all-done | celebration card + "Next dose: {weekday} at {time}" from first future slot |

### Accessibility (widget-level, M-01–M-08)

- **M-01:** each slot is one merged `Semantics` unit: *"{medName} {dose}, scheduled {time}, {stateDescription}. Actions: taken, skipped, missed."* Reading order: Next-due → groups in time order → actions within slot. State changes announced via live region ("Ibuprofen marked as taken").
- **M-02:** 200% text scale — slot actions wrap below med name; no fixed card heights.
- **M-03:** all statuses distinguishable in grayscale (icon+text, never color-only).
- **M-04:** all targets ≥48dp, ≥8dp spacing (current `_MedAction` ~34dp must grow).
- **M-05:** haptic on log + persistent visual confirmation; Reduce Motion disables celebration animation and shake.
- **M-06:** primary log actions in bottom 60%; next-due slot pinned above the fold.
- **M-07/08:** Grade-8 copy; dose formatting rules above.

## 8. Copy Matrix (new ARB keys ×5 locales; ⚕ = clinical sign-off)

| Key | EN source |
|---|---|
| `todayAgendaError` | "We couldn't load your care plan. Check your connection and try again." |
| `todayStaleBanner` | "Updated {relativeTime} — syncing latest plan…" |
| `todayOfflineBanner` | "Log saved on your device. We will update your care team once you are back online." |
| `todayPlanUpdatedBanner` | "Your care team updated your prescribed medications." |
| `todayTimezoneAdjusted` | "Your reminder times have adjusted to your current time zone." |
| `todayLogUndo` | "Undo" |
| `todayLoggedAs` | "Logged as {status}." |
| `todayLogRollbackError` | "We couldn't save that log. Your dose shows as unlogged — tap to try again." |
| `todayCorrectionTitle` | "Logged as {status} at {time}. Change what happened?" |
| `todayCorrectionKeep` | "Keep as is" |
| `todaySkipPrompt` ⚕ | "Are you experiencing severe or troubling symptoms?" |
| `todaySkipPromptYes` | "Yes" |
| `todaySkipPromptNo` | "No, I'm okay" |
| `todayNoEmergencyContact` ⚕ | "No emergency contact on file — contact your clinic." |
| `todayGroupMorning` / `Midday` / `Evening` / `Bedtime` | "Morning" / "Midday" / "Evening" / "Bedtime" |
| `todayPrnSection` | "As needed" |
| `todayDueNow` / `todayScheduledFor` | "Due now" / "Scheduled {time}" |
| `todaySyncPending` | "Saved on device" |
| `todayCelebrationNext` | "Next dose: {weekday} at {time}" |
| `checkinErrorRetry` | "We couldn't save your check-in. Tap to try again." |

Existing C1/C9 keys (`remindersOffBanner`, `emptyPlanMessage`) are reused from the first-run spec. All `AppStrings` usages on Today are replaced by ARB keys; `AppStrings` entries used only here are deleted.

## 9. Deletions & Standardizations

| Item | Disposition |
|---|---|
| 3 hardcoded fallback meds (`today_screen.dart:34-59`) | Delete |
| `'time': '08:00'` / `'status': 'pending'` forcing on API meds (`:188-189`) | Delete — render server values |
| Screen-side write path (5s timer → GET /reminders → create → POST, `:294-327`) | Delete — notifier owns writes |
| `'3x'/'2x'` notification scheduler (`today_agenda_notifier.dart:288-308`) | Delete — schedule from E2 slot times |
| "Day 19 post-surgery", `'TODAY · JUL …'`, "How Mitchell"-style derivations | Delete — real data or honest absence |
| Notification bell "coming soon" + FDA "coming soon" snackbars | Delete (bell removed; FDA card untappable unless detail exists) |
| `lib/features/checkin/checkin_screen.dart` (orphan) | Delete — CheckInCard is the one check-in; posts to `/checkins` (standardize; the orphan's `/symptoms/checkin` path dies with it) |
| Empty `catch (_) {}` blocks on Today | Replaced by the state machine in §6 |

## 10. Use Cases

| # | Scenario | Expected |
|---|---|---|
| 1 | Happy path | Real slots, real times; next-due pinned; log in 1 tap → optimistic → 201 commit |
| 2 | No plan yet (C9) | Calm empty state; 60s poll; plan appears without restart |
| 3 | Offline logging (C3/C4) | Log → queued + banner + cloud badge; kill app → reopen → queue flushed, banner clears |
| 4 | Double-tap Taken | One write; second tap haptic-only |
| 5 | Two devices log same slot | Second device 409-reconciles to server truth; both show identical state after refresh |
| 6 | Mistap, 5s window | Undo reverts; nothing reaches server |
| 7 | Mistap discovered after 3h | Tap slot → correction sheet → new status; previous value preserved |
| 8 | Skip due to nausea | C8 prompt → "Yes" → emergency CTA (or no-contact note); "No" → silent |
| 9 | Timezone travel (C5) | Times re-render device-local; banner once; reminders re-anchored |
| 10 | Clinician stops a med (C6) | Banner; med's future slots gone, history intact (backend E4) |
| 11 | 200% text, TalkBack | Slots reflow; full log + correction completable eyes-closed |
| 12 | PRN pain med | "As needed" section → log → ad-hoc write; retry-safe |

## 11. Test Plan

**Unit (notifier, `FakeApiService` extended with agenda/log-adhoc/PATCH fakes):** optimistic apply; per-slot write lock; 409 reconcile to server detail; rollback on final failure; undo within window cancels write; correction path; queue ordering (creates→corrections); ad-hoc idempotency-key reuse; boot flush; empty/stale/error source-state mapping.

**Widget:** slot rendering per state (badges icon+text); both-times rendering on logged slots; correction sheet options; C8 prompt branches (yes → CTA / yes → no-contact note / no → silent); C9 empty; error retry; offline banner; time-of-day grouping; skeleton on load; no fallback meds rendered when API returns empty; all new ARB keys present in 5 locales.

**Integration (backend + seeded DB):** golden loop extension — seeded patient logs a dose on real slot; visible on clinician web; correction reflected; offline airplane-mode log → online → appears without duplicate.

**Manual a11y (release-blocking):** TalkBack eyes-closed log + correct; 200% text all states; grayscale status check; Reduce Motion.

## 12. Pending Questions

- **D1 — Emergency contact endpoint** (`GET /cases/{caseId}/emergency-contact`) already exists and is used by Assistant; reuse. Confirm it 404s (not 500s) when unset — drives the no-contact note branch.
- **D2 — Check-in endpoint standardization:** CheckInCard posts `/checkins`; confirm backend `checkins.py` is the canonical route (orphan's `/symptoms/checkin` dies with its screen).
- **E1 — FDA card data source:** per-plan-med query needs a case-medication list the notifier already has — confirm `GET /cases/{id}/medications` remains the source, or fold into agenda response later (non-blocking; card is omissible).

## 13. Acceptance Criteria

1. Zero fabricated data: no fallback meds, no forced times/statuses, no hardcoded dates/names on Today.
2. Exactly one write per log intent; 409-reconcile verified; offline queue survives app kill and flushes in order.
3. Correction sheet works post-window with previous value preserved; no silent reverts.
4. C8 prompt + honest emergency-CTA/no-contact branches; C1/C3/C5/C6/C9/C11 states all render per spec.
5. Notifications scheduled from server times; re-anchored on boot/timezone change.
6. All new strings in 5 ARB locales; `AppStrings` Today usages eliminated.
7. All §11 tests pass, including eyes-closed TalkBack log+correct.
