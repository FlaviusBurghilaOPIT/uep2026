# Remote CarePro — Implementation Plan: Core Loop Hardening & Mobile Polish Iteration

**Document ID:** `docs/product/10-implementation-plan.md`
**Generated Date:** 2026-07-22
**Role:** Lead Product, UX, and Technical-Design Agent
**Status:** Approved Delivery Plan
**Inputs:** `docs/ux/08-prioritized-ux-backlog.md`, `docs/product/09-measurement-plan.md`, `docs/product/00-04`, `docs/ux/05-07`, `ai_specs/2026-07-22-flutter-mobile-enhancements-{spec,ledger}.md`, `ai_specs/work-items/01-05`, current repository state.

---

## 1. Executive Summary & Iteration Goal

This iteration closes the loop that defines the product: **a clinician authors a plan → a patient acts on it day-to-day → the clinician sees the result and can intervene.** Every issue in this plan is chosen because it sits on that loop, fixes something that currently breaks it, or removes friction from it. Nothing in this iteration expands the product surface into documents, caregiver accounts, advanced charts, deep reporting, or clinical-guideline integrations.

Two forces shaped the ordering:

1. **The loop, not the layer.** The prioritized backlog (`08-prioritized-ux-backlog.md`) sequences work by technical layer (backend → mobile → web → verify). This plan instead sequences by where each fix sits on the clinician → patient → clinician loop, so that by the end of the **Core flow** milestone the full loop already works end-to-end, even before every safety and polish item lands.
2. **Two mobile work items are already scoped but unbuilt.** `ai_specs/work-items/04-interactive-notifications-dose-logging.md` (interactive lock-screen notification actions) and `05-ai-assistant-chat-guardrail-notifier.md` (AI assistant guardrail UX) are fully specified with 0 of 9 and 0 of 11 acceptance criteria respectively met. They overlap directly with backlog findings FIND-M02, FIND-M04, FIND-M06, and FIND-M07. This plan folds their remaining scope into the relevant issues below rather than tracking them as a separate parallel effort.

### 1.1 Current State Snapshot (verified against code, 2026-07-22)

| Area | State |
|---|---|
| Mobile Riverpod migration (WI-01) | ✅ Done — `flutter_riverpod` wired, `ProviderScope` in `main.dart`, feature-first folders in place. |
| Mobile notifiers (WI-02) | ✅ Done — `auth_notifier`, `today_agenda_notifier`, `symptom_checkin_notifier`, `chat_assistant_notifier` all present. |
| Mobile i10n (WI-03) | ✅ Done — 5 locales (`en`, `it`, `es`, `fr`, `de`) with generated `AppLocalizations`. |
| Mobile interactive notifications (WI-04) | ❌ Not started — 0/9 AC. `notification_service.dart` schedules once at login; no interactive actions, no timezone re-anchoring. |
| Mobile AI guardrail UX (WI-05) | ❌ Not started — 0/11 AC. Guardrail logic exists server-side only; no refusal box, banner, or emergency CTA in `assistant_screen.dart`. |
| Mobile shell | 4 tabs (`Today`, `Check-In`, `Assistant`, `Recovery`) — no `Medications` or `Profile` tab; `Profile` is a pushed route; no dedicated Medications screen exists yet. |
| Web routing | No triage/exceptions view; `/` redirects to `/login`, and the roster (`/patients`) is the only patient-list view. |
| Backend `POST /adherence/log` | No `IntegrityError` handling — duplicate `scheduled_reminder_id` throws an unhandled 500. |
| Backend `ChatMessage` model | Has no `in_scope` / `escalate` columns at all — the guardrail flag is computed and returned in the API response but never persisted. **This requires an Alembic migration**, not just a code change. |
| Web test tooling | **None.** `web/package.json` has no test runner, no RTL/vitest. Verification for web issues is manual QA + `npm run lint`/`npm run build` + a one-off `axe-core` scan, not an automated suite. |

Two additional pieces of housekeeping surfaced during grounding and are folded into the issues below rather than spawned as separate tickets:
- `mobile/lib/core/services/api_service.dart` is a stale duplicate of `mobile/lib/core/network/api_service.dart` (the WI-01 move left the old file behind). Delete it as part of Issue #6.
- `mobile/lib/features/assistant/assistant_screen.dart` and `mobile/lib/features/assistant/screens/assistant_screen.dart` are duplicates; `main_shell_page.dart` imports the former. Consolidate and delete the orphan as part of Issue #11.

---

## 2. Workstreams

### 2.1 Mobile (Flutter) — the larger of the two product workstreams this iteration
Carries the 5-tab IA restructure (which also requires building the Medications screen from scratch), the completion of WI-04 and WI-05, four accessibility/trust fixes from the backlog (status pill icons, offline banner, FDA badge, undo toast), and two net-new polish issues addressing the constraint that mobile should read as more visually and interactively finished than web this iteration. Every mobile issue must source its copy from `docs/ux/06-content-system.md` rather than inventing new strings, and every new/changed string must be added to all 5 ARB-backed locale files.

### 2.2 Web (React) — kept to "complete enough to demonstrate," not expanded
Three small, independent accessibility/efficiency fixes (invite code, form labels, focus rings) plus the one substantial addition: the Triage & Exceptions Dashboard, which is the concrete, demoable proof that the clinician side of the loop closes. No new backend aggregation endpoint is introduced for it — the dashboard composes from existing endpoints (`GET /patients`, `GET /adherence/patients/{id}`, `GET /checkins/patients/{id}/symptoms/trend`, `GET /cases/{id}/emergency-contact`) client-side. This is a deliberate, noted tradeoff (see §7).

### 2.3 Backend / Shared
Two focused correctness fixes (duplicate dose-log conflict handling, guardrail escalation persistence) that other workstreams depend on to be meaningful — an emergency CTA is pointless if the triage dashboard can never actually see that it fired. Telemetry event emission from `09-measurement-plan.md`'s taxonomy (e.g. `mobile.today.dose_logged`, `backend.ai.guardrail_intercepted`, `web.triage.exception_viewed`) is **not** a standalone issue; it is a Definition-of-Done line item on each issue that touches a relevant user action, so instrumentation lands with the feature instead of as a follow-up nobody prioritizes.

---

## 3. Milestones

| Milestone | Goal | Issues | Exit Criteria |
|---|---|---|---|
| **M1 — Foundation** | Fix the two data-integrity gaps that everything else builds on; give mobile its full navigable IA; give web its cheap accessibility baseline. | #1–#6 | Duplicate dose logs return 409, not 500. Guardrail escalation persists in the DB. Mobile has 5 working tabs including a real Medications screen. Web forms and nav are keyboard/screen-reader navigable. |
| **M2 — Core flow** | Make the clinician→patient→clinician loop work end-to-end for the first time. | #7–#10 | A clinician can invite a patient, the patient can log a dose (including via lock-screen notification action) with instant undo and unambiguous status, and the clinician sees it reflected on a Triage & Exceptions home screen — without needing to open individual patient profiles. |
| **M3 — Safety/resilience** | Cover the edge cases and safety-critical UI defined in `03-safety-and-edge-cases.md` that sit outside the happy path. | #11–#13 | AI guardrail refusals show a 1-tap emergency call CTA and are visible to clinicians. Offline logging is never silent. FDA content always shows its provenance and freshness. |
| **M4 — Polish/demo** | Give mobile the visual/interaction finish the constraint calls for, and verify the whole iteration end-to-end before demo. | #14–#16 | Dose-logging interactions feel considered, not just functional. Design tokens are applied consistently. Accessibility scans pass. The golden-loop QA script (§6) passes clean. |

---

## 4. Ordered GitHub Issues

Each issue lists its backlog/work-item origin for traceability. Effort estimates are carried from `08-prioritized-ux-backlog.md` where the issue maps 1:1 to a finding; new/expanded issues are estimated fresh.

### Milestone 1 — Foundation

---

**Issue #1 — [Backend] Return HTTP 409 Conflict on Duplicate Dose Log POSTs**
*Origin: FIND-B01. Labels: `backend`, `p0-critical`, `resilience`, `api`.*

**Description:** `POST /adherence/log` (`backend/app/routers/adherence.py:15`) inserts a `DoseLog` with a `unique=True` FK on `scheduled_reminder_id` and does not catch the resulting `IntegrityError`. A duplicate submission (e.g. a retried offline-queue flush, or a double-tap on a lock-screen notification action once WI-04 ships) currently 500s instead of resolving cleanly.

**Files likely affected:** `backend/app/routers/adherence.py`, `backend/tests/test_adherence_router.py` (new file — no adherence-specific test file currently exists).

**Dependencies:** None. Should land first — Issue #9 (interactive notification actions) depends on this returning a clean, parseable conflict response rather than a 500.

**Definition of Done:**
- [ ] Catch `sqlalchemy.exc.IntegrityError` on the `db.commit()` in `log_dose`, roll back, and return `HTTPException(409, ...)` with the existing `DoseLog` payload for that `scheduled_reminder_id`.
- [ ] Response body matches the shape a client can use to reconcile local state (same shape as a successful log).
- [ ] `backend.adherence.duplicate_conflict_returned` telemetry event emitted per `09-measurement-plan.md` §3.1.

**Test Plan:** New `pytest` cases in `backend/tests/test_adherence_router.py`: (1) first POST for a `scheduled_reminder_id` succeeds; (2) second POST for the same ID returns 409 with the original log's data, not a 500; (3) two different `scheduled_reminder_id`s both succeed. Run via `pytest backend/tests`.

---

**Issue #2 — [Backend] Persist `in_scope`/`escalate` on AI Guardrail Intercepts**
*Origin: FIND-B02. Labels: `backend`, `p0-critical`, `safety`, `ai`, `migration`.*

**Description:** `POST /ai/chat` (`backend/app/routers/ai.py:52`) computes `in_scope`/`escalate` via `_check_guardrail` and returns them in `ChatResponse`, but `models.ChatMessage` (`backend/app/models.py:196`) has **no `in_scope` or `escalate` columns at all** — the flag is never written to the database. A clinician has no way to know a patient asked the AI something out-of-scope or urgent.

**Files likely affected:** `backend/app/models.py` (add `in_scope: Mapped[bool]`, `escalate: Mapped[bool]` to `ChatMessage`), `backend/alembic/versions/` (new migration), `backend/app/routers/ai.py` (set the columns on both the user-message insert), `backend/app/schemas.py` if `ChatMessage` gets a response schema exposed to the triage endpoint, `backend/app/routers/adherence.py` or `patients.py` (surface flagged messages — see Issue #10's dependency below), `backend/tests/test_ai_router.py` (existing — extend it).

**Dependencies:** None to start. Issue #10 (Triage Dashboard) depends on this — the Red/Amber alert criteria in `09-measurement-plan.md` §4.1 explicitly include "AI emergency flags," which cannot exist without this fix.

**Definition of Done:**
- [ ] Alembic migration adds `in_scope` (bool, default `true`) and `escalate` (bool, default `false`) to `chat_messages`.
- [ ] The user-turn `ChatMessage` insert in `chat()` sets both columns from `_check_guardrail`'s result.
- [ ] A way exists for the web client to query escalated messages per patient/case (either exposed via an existing endpoint or a minimal addition — do not build a new dashboard-shaped endpoint here, keep this backend-only and data-shaped).
- [ ] `backend.ai.guardrail_intercepted` telemetry event emitted with `escalate_flag_set` per the existing example in `09-measurement-plan.md` §3.2.

**Test Plan:** Extend `backend/tests/test_ai_router.py`: assert an out-of-scope message (e.g. containing "increase your dose") persists `in_scope=False, escalate=True` on the stored `ChatMessage`, and an in-scope message persists `in_scope=True, escalate=False`. Run `alembic upgrade head` against a scratch DB as part of CI/test setup to confirm the migration applies cleanly.

---

**Issue #3 — [Web] Display 6-Digit Invite Code on Pending Patient Cards**
*Origin: FIND-W02. Labels: `web`, `p1-major`, `ux`, `clinician-speed`.*

**Description:** `PatientsPage.tsx` shows a pending-status label for `status="invited"` patients but never surfaces the 6-digit code generated by `POST /patients/invite`. This is the literal first step of the E2E loop — a clinician cannot onboard a patient without it.

**Files likely affected:** `web/src/pages/PatientsPage.tsx`, `web/src/api/client.ts` (if the invite code isn't already in the `GET /patients` payload, confirm/add it — do not add a new endpoint).

**Dependencies:** None.

**Definition of Done:**
- [ ] Pending patient cards render the 6-digit code in bold 24px text, per `docs/ux/06-content-system.md` Category 1.
- [ ] A "Copy Code" button copies it to the clipboard with a brief confirmation state.
- [ ] `web.patient.invited` telemetry event fires on successful invite creation (if not already firing).

**Test Plan:** Manual QA (no web test runner exists): create a patient, confirm the code renders and Copy works via `document.execCommand`/`navigator.clipboard`, confirm it disappears once the patient completes onboarding (status flips away from `invited`).

---

**Issue #4 — [Web] Bind Form Labels & ARIA Error Attributes**
*Origin: FIND-W03. Labels: `web`, `p1-major`, `accessibility`, `a11y`.*

**Description:** Inputs in `CreatePatientPage.tsx` and `MedicationsPage.tsx` use floating labels with no `htmlFor`/`id` binding and no `aria-invalid`/`aria-describedby` on validation errors, per `docs/ux/07-accessibility-spec.md` Standard W-02.

**Files likely affected:** `web/src/pages/CreatePatientPage.tsx`, `web/src/pages/MedicationsPage.tsx`, `web/src/pages/CreateCasePage.tsx` (same pattern likely present — confirm during implementation).

**Dependencies:** None. Independent of #3 (different files), can run in parallel.

**Definition of Done:**
- [ ] Every input has an explicit `<label htmlFor="...">` bound to a matching `id`.
- [ ] Validation errors set `aria-invalid="true"` and `aria-describedby` pointing to a visible error `<span>`.
- [ ] Zero label/error-binding violations on a manual `axe-core` scan (see Issue #16).

**Test Plan:** Manual QA with a screen reader (VoiceOver/NVDA) tabbing through both forms, confirming field names and error announcements. One-off `npx @axe-core/cli http://localhost:5173/patients/new` (and `/cases/:id/medications`) as an automated spot-check.

---

**Issue #5 — [Web] Add Visible `:focus-visible` Rings Across Web**
*Origin: FIND-W04. Labels: `web`, `p1-major`, `accessibility`, `a11y`.*

**Description:** CSS strips the default outline in `NavBar.tsx` (and likely other interactive elements) without a replacement, per `docs/ux/07-accessibility-spec.md` Standard W-01. Keyboard-only clinicians cannot see focus location.

**Files likely affected:** `web/src/components/NavBar.tsx`, a shared stylesheet (create `web/src/index.css` global rule if one doesn't already cover this, or extend the existing global stylesheet — confirm current CSS approach during implementation since no `.css` files were enumerated in the source scan; component styling may be inline).

**Dependencies:** None. Independent of #3/#4.

**Definition of Done:**
- [ ] `:focus-visible { outline: 2px solid #4338ca; outline-offset: 2px; }` (or the styling mechanism's equivalent) applied globally to interactive elements — links, buttons, inputs, cards.
- [ ] Tabbing through `NavBar` and both list pages shows a clear, consistent focus indicator.

**Test Plan:** Manual keyboard-only pass (Tab/Shift+Tab) through NavBar, PatientsPage, and CreatePatientPage confirming every focusable element shows the ring.

---

**Issue #6 — [Mobile] Restructure Shell to 5-Tab IA & Build Medications Screen**
*Origin: FIND-M01. Labels: `mobile`, `p1-major`, `ia`, `navigation`.*

**Description:** `MainShellPage`/`MainBottomNav` currently render 4 tabs (`Today`, `Check-In`, `Assistant`, `Recovery`); `Profile` is a pushed route and there is **no dedicated Medications screen at all** — prescriptions are only visible embedded inside `TodayScreen`. This issue restructures to the 5-tab IA from `docs/ux/05-information-architecture.md`: `Today`, `Medications`, `Recovery`, `Assistant`, `Profile`, and embeds the daily Check-In as a card on `Today` rather than a standalone tab. Because `Medications` has no existing screen to repoint to, this issue includes building it — larger than the backlog's original `M` estimate implied.

**Files likely affected:** `mobile/lib/features/main/main_shell_page.dart`, `mobile/lib/core/shared_widgets/main_bottom_nav.dart`, `mobile/lib/core/providers/navigation_provider.dart`, `mobile/lib/features/today/today_screen.dart` (embed check-in card, remove standalone check-in tab wiring), new `mobile/lib/features/medications/medications_screen.dart` + `mobile/lib/features/medications/providers/medications_notifier.dart` (fetch via `GET /cases/{id}/medications`), `mobile/lib/features/profile/profile_screen.dart` (wire into tab instead of pushed route — content likely unchanged). Delete stale `mobile/lib/core/services/api_service.dart` (superseded duplicate of `core/network/api_service.dart`).

**Dependencies:** None, but should land **before** Issues #7, #8, #9, #12, #13 since they all touch `today_screen.dart`/`today_agenda_notifier.dart`, which this issue restructures first.

**Definition of Done:**
- [ ] Bottom nav renders 5 tabs in the specified order; `IndexedStack` preserves each tab's scroll/state.
- [ ] Tapping `Medications` shows the full active prescription list (name, dose, schedule, clinician-authored badge per FIND-W-adjacent provenance rules).
- [ ] `Today` feed contains the daily feeling check-in as a top action card, not a separate screen reachable only via tab.
- [ ] `Profile` is reachable as a tab; the old pushed-route entry point (if referenced elsewhere) still resolves or is removed cleanly.
- [ ] Stale `core/services/api_service.dart` deleted; all imports point to `core/network/api_service.dart`.
- [ ] `flutter analyze` reports zero errors.

**Test Plan:** New/updated widget test in `mobile/test/widget/` asserting all 5 tabs render and switch `IndexedStack` index correctly; update `mobile/test/unit/today_agenda_test.dart` if check-in embedding changes its provider surface. `flutter test`.

---

### Milestone 2 — Core Flow

---

**Issue #7 — [Mobile] Add 5-Second Undo Toast for Dose Logging**
*Origin: FIND-M02. Labels: `mobile`, `p1-major`, `ux`, `safety`.*

**Description:** Tapping `Taken`/`Skipped`/`Missed` on `TodayScreen` commits immediately with no undo window, per `docs/ux/03-safety-and-edge-cases.md` Case 7. Patients with motor tremors who mis-tap cannot correct it without contacting support.

**Files likely affected:** `mobile/lib/features/today/today_screen.dart`, `mobile/lib/features/today/providers/today_agenda_notifier.dart`.

**Dependencies:** Depends on Issue #6 (shell restructure lands first to avoid double-touching `today_screen.dart`/`today_agenda_notifier.dart` in flight).

**Definition of Done:**
- [ ] Tapping any status button shows a 5-second snackbar ("Logged as Taken. Undo") per `docs/ux/06-content-system.md` Category 6.
- [ ] Tapping Undo within the window reverts the card to pending locally and issues the corresponding API call to revert (or simply does not commit the log until the window elapses — implementation choice, document which in the PR).
- [ ] `mobile.today.dose_log_undone` telemetry event fires on undo, per `09-measurement-plan.md` §2.4 (`Accidental Log Undo Frequency` counter-metric).

**Test Plan:** New case in `mobile/test/unit/today_agenda_test.dart` covering log → undo → state reverts to pending. Widget test simulating tap-then-undo-within-window vs. tap-then-wait (commits).

---

**Issue #8 — [Mobile] Dual Icon + Text Status Indicators on Dose Pills**
*Origin: FIND-M03. Labels: `mobile`, `p1-major`, `accessibility`, `a11y`.*

**Description:** Status pills use color alone (green/amber/red) to distinguish Taken/Skipped/Missed, violating WCAG 1.4.1 per `docs/ux/07-accessibility-spec.md` Standard M-03. Colorblind patients cannot distinguish states.

**Files likely affected:** `mobile/lib/features/today/today_screen.dart` (medication card / status pill widget — confirm exact widget name during implementation; backlog references `MedicationCardWidget`).

**Dependencies:** Should land before #7 within the same PR sequence slot is unnecessary — independent enough to land in either order, but land before #9 (notification actions) since both touch the card's visual state representation.

**Definition of Done:**
- [ ] Each status pairs its color with a distinct icon (check for Taken, warning triangle for Skipped, cross for Missed) and explicit text label.
- [ ] Verified legible/distinguishable with color simulation (grayscale screenshot comparison) per acceptance criteria in FIND-M03.

**Test Plan:** Widget golden test or manual screenshot comparison in grayscale mode (`act-flutter-screenshot` skill) confirming all three states remain distinguishable without color.

---

**Issue #9 — [Mobile] Complete Interactive Lock-Screen Notification Actions (WI-04 completion, folds FIND-M06)**
*Origin: `ai_specs/work-items/04-interactive-notifications-dose-logging.md` (0/9 AC) + FIND-M06. Labels: `mobile`, `p1-major`, `notifications`, `resilience`.*

**Description:** `NotificationService` currently schedules reminders once at login with no interactive actions and no timezone/DST re-anchoring (WI-04's full scope, plus FIND-M06). This issue completes WI-04: `[Take Dose]`/`[Snooze 15m]` actions directly on the notification/lock screen, background logging via `POST /adherence/log` (now returning clean 409s thanks to Issue #1), and re-scheduling on app launch and OS timezone-change events so reminders don't drift after travel or DST.

**Files likely affected:** `mobile/lib/core/notifications/notification_service.dart`, `mobile/lib/features/today/providers/today_agenda_notifier.dart` (background log integration), platform channel config if required for iOS/Android interactive notification categories (`mobile/ios/Runner/`, `mobile/android/app/src/main/`).

**Dependencies:** Depends on Issue #1 (409 handling) for background-logged duplicates to resolve cleanly, and Issue #6 (shell restructure) to avoid conflicting with the agenda notifier's in-flight shape.

**Definition of Done:** (WI-04's 9 AC, consolidated)
- [ ] Notifications reschedule on app launch and on OS timezone-change events (`NotificationService.instance.reinitialize()`).
- [ ] `[Take Dose]` logs `taken` in the background with haptic feedback; `[Snooze 15m]` reschedules +15 minutes.
- [ ] Tapping the notification body (not an action button) opens the app and highlights the target medication card.
- [ ] Notification permission requested during onboarding (if not already present from earlier work — confirm).
- [ ] Duplicate background-log attempts (e.g. a delayed retry) resolve via the Issue #1 409 path without user-visible error.
- [ ] `mobile.today.dose_logged` telemetry event fires with `is_offline` correctly set for background-originated logs.

**Test Plan:** Extend `mobile/test/unit/notification_service_test.dart` (already exists) with timezone-change and reschedule-on-launch cases. Manual device QA on both iOS and Android simulators/devices per `act-flutter-screenshot`/`act-flutter-driver-mcp` skills, since interactive notification actions cannot be fully exercised in a widget test harness.

---

**Issue #10 — [Web] Implement Triage & Exceptions Dashboard as Default Home**
*Origin: FIND-W01. Labels: `web`, `p0-critical`, `ux`, `triage`.*

**Description:** The router's `/` currently only redirects to `/login`; there is no post-login triage view — clinicians land on an unsorted `/patients` roster and must inspect each card manually. This is the payoff screen of the entire iteration: it's where the clinician side of the loop actually closes. Per `09-measurement-plan.md` §4.1, it composes Red (≥2 missed doses, bad check-in, AI emergency flag — now possible thanks to Issue #2) and Amber (skipped-for-side-effects, adherence <80%) exception alerts ahead of the passive roster.

**Files likely affected:** New `web/src/pages/TriageDashboardPage.tsx`, `web/src/App.tsx` (route `/` to it post-login instead of/in addition to redirecting to `/patients`), `web/src/api/client.ts` (compose from existing `GET /patients`, `GET /adherence/patients/{id}`, `GET /checkins/patients/{id}/symptoms/trend`, `GET /cases/{id}/emergency-contact` — no new backend endpoint).

**Dependencies:** Depends on Issue #2 (escalate persistence) for the AI-emergency-flag alert criterion to have real data behind it. Independent of all mobile issues — can run on a fully parallel track.

**Definition of Done:**
- [ ] Landing on `/` (post-login) shows Red/Amber exception alerts ahead of the passive roster, per FIND-W01 acceptance criteria.
- [ ] Clicking an alert card navigates to that patient's detail/case view.
- [ ] Widget 3 (Response Time Gauge — median seconds to view a Red alert) is out of scope for this issue (requires event-time tracking infra beyond a first pass); note explicitly in the PR description as deferred, do not silently drop it.
- [ ] `web.triage.exception_viewed` telemetry event fires on dashboard load.

**Test Plan:** Manual QA (no web test runner): seed 2–3 patients with missed doses / bad check-ins / an escalated AI message via the backend seed script, confirm they surface as Red/Amber ahead of compliant patients, confirm click-through navigation.

---

### Milestone 3 — Safety/Resilience

---

**Issue #11 — [Mobile] AI Assistant Guardrail UX + Emergency Call CTA (WI-05 completion, folds FIND-M04)**
*Origin: `ai_specs/work-items/05-ai-assistant-chat-guardrail-notifier.md` (0/11 AC) + FIND-M04. Labels: `mobile`, `p0-critical`, `safety`, `ai`.*

**Description:** The backend already refuses out-of-scope queries (`_check_guardrail` in `ai.py`), but `AssistantScreen` renders no refusal box, no guardrail banner, no typing indicator, no suggestion chips, and critically **no emergency call CTA** — a patient asking about a dosage change or in genuine distress gets refused with plain text and no path to help. This completes WI-05 in full and folds in FIND-M04's safety-critical addition.

**Files likely affected:** Consolidate the duplicate `mobile/lib/features/assistant/assistant_screen.dart` and `mobile/lib/features/assistant/screens/assistant_screen.dart` into the one actually wired in `main_shell_page.dart` (delete the orphan), `mobile/lib/features/assistant/providers/chat_assistant_notifier.dart`.

**Dependencies:** Depends on `GET /cases/{id}/emergency-contact` (already exists, verified in `cases.py:131`). Independent of mobile Today/notification track (#7–#9) — different screen, can run in parallel.

**Definition of Done:**
- [ ] Top guardrail banner ("Informational only, never diagnostic") always visible on the assistant screen.
- [ ] 3-dot typing indicator while awaiting a response.
- [ ] Quick suggestion chips per `docs/ux/06-content-system.md` Category 13.
- [ ] Out-of-scope responses render a prominent red-bordered refusal box with a bold **Call Emergency Contact ({phone})** button linking to `tel:`.
- [ ] Tapping the emergency CTA launches the device dialer.
- [ ] `mobile.assistant.guardrail_triggered` and `mobile.assistant.emergency_cta_tapped` telemetry events fire correctly.
- [ ] Duplicate `assistant_screen.dart` file removed; single source of truth confirmed via `flutter analyze` (no unused-file warnings/orphan imports).

**Test Plan:** Existing `mobile/test/widget/assistant_screen_test.dart` — extend with a case sending an out-of-scope message and asserting the refusal box + emergency CTA render, and a case asserting the CTA's `tel:` link matches the case's emergency contact. `mobile/test/unit/chat_provider_test.dart` — extend for guardrail state transitions.

---

**Issue #12 — [Mobile] Persistent Offline Sync Banner for Pending Dose Queue**
*Origin: FIND-M07. Labels: `mobile`, `p1-major`, `ux`, `resilience`.*

**Description:** Offline dose logs update local Riverpod state but surface no indication that they're queued rather than synced, per `docs/product/03-safety-and-edge-cases.md` Case 3/4. Patients re-log unnecessarily, thinking the first attempt was lost.

**Files likely affected:** `mobile/lib/features/today/today_screen.dart`, `mobile/lib/features/today/providers/today_agenda_notifier.dart` (or wherever the SQLite pending-queue table is read from — confirm exact persistence layer during implementation, referenced as `PendingQueueTable` in the backlog but not yet located in the current file scan).

**Dependencies:** Depends on Issue #9 (notification/background-logging path) landing first, since both touch the same offline-log write path.

**Definition of Done:**
- [ ] Top banner ("Saved offline. Will sync when connected.") renders whenever the pending queue has un-flushed logs, per `docs/ux/06-content-system.md` Category 9.
- [ ] Banner clears automatically on successful background flush.
- [ ] Un-synced-log-stagnation safety counter-metric (`>24h`, per `09-measurement-plan.md` §2.4) has the data it needs to be computed (timestamp on queued entries).

**Test Plan:** Unit test simulating offline log → banner state true → simulated reconnect/flush → banner state false, in the relevant notifier's test file.

---

**Issue #13 — [Mobile] openFDA / Fixture Source Badge & Retrieval Timestamp**
*Origin: FIND-M05. Labels: `mobile`, `p1-major`, `fda`, `transparency`.*

**Description:** FDA safety content renders as plain text bullets with no indication of provenance (`openFDA` live vs. fixture fallback) or freshness, violating the transparency/provenance constraints in `docs/product/03-safety-and-edge-cases.md` Case 12.

**Files likely affected:** `mobile/lib/features/recovery/recovery_screen.dart` (FDA content section).

**Dependencies:** Independent — can run in parallel with any other Milestone 3 issue.

**Definition of Done:**
- [ ] Source badge (`📋 Source: openFDA Live` / `Regulatory Cache`) and `Retrieved: YYYY-MM-DD` timestamp render above FDA warning content, per `docs/ux/06-content-system.md` Category 12.
- [ ] Badge correctly reflects fixture-fallback state when `backend.fda.fallback_to_fixture_triggered` has fired for that request.

**Test Plan:** Widget test asserting badge text switches between "Live" and "Regulatory Cache" states based on mocked API response metadata.

---

### Milestone 4 — Polish/Demo

---

**Issue #14 — [Mobile] Dose-Logging Micro-Interactions & Animation Polish** *(new, additive)*
*Origin: iteration constraint — mobile should read as more visually/interaction-finished than web this cycle. Labels: `mobile`, `p2-polish`, `ux`.*

**Description:** Once undo (#7) and dual-icon status pills (#8) exist functionally, add the interaction polish that makes dose logging feel considered: a brief success animation/haptic on log, a smooth pill-state transition rather than an instant swap, and a subtle celebratory moment on completing all of a day's doses (already referenced conceptually in WI-04's notification tap-through spec — extend it to the in-app path too).

**Files likely affected:** `mobile/lib/features/today/today_screen.dart`.

**Dependencies:** Depends on #7 and #8 (polishes their output — must land after both).

**Definition of Done:**
- [ ] Status transitions animate (not an instant color/icon swap).
- [ ] Logging a dose triggers haptic feedback and a brief success micro-animation.
- [ ] Completing all doses for the day shows a small celebratory state on `TodayScreen` (non-blocking, dismissible, no gamification streaks/badges per `09-measurement-plan.md` §5 experiment guardrail #2).

**Test Plan:** Manual visual QA via `act-flutter-screenshot`; no meaningful automated assertion for animation feel — note this in the PR description rather than fabricating a brittle test.

---

**Issue #15 — [Mobile] Design-Token Consistency & Empty/Loading State Pass** *(new, additive)*
*Origin: iteration constraint — mobile visual polish. Labels: `mobile`, `p2-polish`, `design-system`.*

**Description:** Audit the 5 rebuilt/touched screens (Today, Medications, Recovery, Assistant, Profile) for consistent use of `AppColors`/`AppTextStyles`/`AppTheme` tokens from the WI-01 design system, and add proper empty and loading states (shimmer/skeleton per `mobile/lib/core/widgets/` shared placeholders, if present, or build minimal ones) where screens currently show blank space or raw spinners.

**Files likely affected:** `mobile/lib/features/medications/medications_screen.dart`, `mobile/lib/features/today/today_screen.dart`, `mobile/lib/features/recovery/recovery_screen.dart`, `mobile/lib/features/profile/profile_screen.dart`, `mobile/lib/core/widgets/` (shared empty/shimmer widgets).

**Dependencies:** Must land last among mobile issues — touches the widest file surface, so it should absorb whatever visual shape the prior issues left rather than being rebased repeatedly against them.

**Definition of Done:**
- [ ] No screen uses a raw/default `CircularProgressIndicator` where a shimmer/skeleton placeholder is feasible.
- [ ] No screen shows blank space on empty state — each has copy + illustration/icon per `docs/ux/06-content-system.md`.
- [ ] Spot-check confirms no hardcoded colors/fonts outside `AppColors`/`AppTextStyles` on the 5 touched screens.

**Test Plan:** Manual visual QA across all 5 screens in both light conditions (no dark-mode requirement stated in `07-accessibility-spec.md` — confirm before adding one) and with `flutter_screenutil` scaling at 200% text per Standard M-02.

---

**Issue #16 — [Verification] Accessibility Scans + Golden Loop E2E Validation**
*Origin: FIND-W01/W03/W04 acceptance criteria + `08-prioritized-ux-backlog.md` §5 Phase 4. Labels: `verification`, `accessibility`, `qa`.*

**Description:** Closing gate for the iteration. Runs the automated accessibility spot-checks referenced in Issues #4/#5 and executes the manual QA script in §6 of this document end-to-end against a freshly seeded environment.

**Files likely affected:** None (verification-only); may add a short `docs/product/qa/` note or checklist artifact if the team wants a durable record — do not build CI infrastructure as part of this issue, that's out of scope.

**Dependencies:** Depends on all prior issues (#1–#15) being merged.

**Definition of Done:**
- [ ] `npx @axe-core/cli` scan against `/patients/new`, `/cases/:id/medications`, and the new `/` triage dashboard returns zero critical violations.
- [ ] `flutter analyze` and `flutter test` pass with zero errors on mobile.
- [ ] `pytest backend/tests` passes with zero failures.
- [ ] The golden loop QA script (§6) completes with no unhandled errors, no silent failures, and all safety affordances (emergency CTA, undo, offline banner) verified live on-device/in-browser.

**Test Plan:** This issue *is* the test plan — see §6.

---

## 5. PR Sequence (Minimizing Merge Conflicts)

Backend, web, and mobile run as three largely independent tracks. Within mobile, ordering is strict because #6, #7, #8, #9, #12 all touch `today_screen.dart` and/or `today_agenda_notifier.dart` — landing them out of order guarantees rebase pain.

```
Backend track (independent, parallel-safe):
  PR-B1: Issue #1  (409 handling)
  PR-B2: Issue #2  (escalate persistence + migration)

Web track (independent, parallel-safe with backend and mobile):
  PR-W1: Issue #3  (invite code)
  PR-W2: Issue #4  (form labels/ARIA)
  PR-W3: Issue #5  (focus rings)
  PR-W4: Issue #10 (triage dashboard) — merge after PR-B2 lands (needs escalate data to be meaningful)

Mobile track (strict order — shared-file dependency chain):
  PR-M1: Issue #6  (5-tab shell + Medications screen)         [after: none]
  PR-M2: Issue #8  (status pill icons)                         [after: PR-M1]
  PR-M3: Issue #7  (undo toast)                                [after: PR-M2]
  PR-M4: Issue #9  (interactive notifications, folds M06)      [after: PR-M3, PR-B1]
  PR-M5: Issue #12 (offline sync banner)                       [after: PR-M4]
  PR-M6: Issue #11 (AI assistant guardrail + emergency CTA)    [after: PR-M1 — independent screen, can run parallel to PR-M2..M5]
  PR-M7: Issue #13 (FDA badge)                                 [after: PR-M1 — independent, parallel-safe]
  PR-M8: Issue #14 (micro-interactions)                        [after: PR-M3, PR-M2]
  PR-M9: Issue #15 (design-token/empty-state pass)             [after: PR-M6, PR-M7, PR-M8 — lands last, widest surface]

Closing gate:
  PR-V1: Issue #16 (verification) — no code change; merge only after every above PR is in.
```

Practical parallelization: with two mobile engineers, one can run `PR-M1 → M2 → M3 → M4 → M5` (the Today/notifications spine) while the other runs `PR-M6 → M7` (Assistant/FDA, independent screens) concurrently, converging on `PR-M8 → M9`. Backend and web can proceed entirely independently of mobile throughout.

---

## 6. Manual End-to-End QA Script (Golden Loop)

Run against a freshly seeded backend (`python -m app.scripts.seed_data` or equivalent) after all Milestone 1–4 issues are merged. This extends the journeys in `docs/product/02-service-blueprint.md` §3 with the new surfaces this iteration adds.

1. **Clinician login** (web) → land on **Triage & Exceptions Dashboard** at `/` (not the raw roster). Confirm no Red/Amber alerts yet for a fresh seed.
2. **Create patient + invite** (web, `CreatePatientPage`) → return to `/patients` → confirm the 6-digit code is visible in bold with a working Copy button.
3. **Clinician creates a treatment plan** (web, `CreateCasePage` → `MedicationsPage`) → add 2+ medications with schedules. Confirm form labels/errors are screen-reader-announced (Tab through with VoiceOver/NVDA) and focus rings are visible throughout.
4. **Patient accepts invite** (mobile) using the 6-digit code → completes onboarding → lands on **Today**, now showing 5 tabs (`Today`, `Medications`, `Recovery`, `Assistant`, `Profile`).
5. **Patient reviews Medications tab** → confirm the full prescription list renders (this screen did not exist before this iteration).
6. **Patient logs a dose** on `Today`: tap `Taken` → confirm the 5-second undo toast appears → tap `Undo` → confirm the card reverts to pending → tap `Taken` again and let the toast expire → confirm it commits. Confirm the status pill shows icon + color + text.
7. **Patient triggers a duplicate log** (e.g. background-tap a lock-screen notification action twice, or resubmit the same `scheduled_reminder_id` via a second tap in a race) → confirm no crash/error surfaces to the patient; the app resolves it silently using the 409 path.
8. **Patient goes offline** (airplane mode) → logs a dose → confirm the persistent "Saved offline. Will sync when connected." banner appears → reconnect → confirm the banner clears automatically.
9. **Patient completes daily check-in** from the `Today` card (not a separate tab) → confirm it submits successfully.
10. **Patient views FDA content** on `Recovery` → confirm a source badge (`openFDA Live` or `Regulatory Cache`) and retrieval timestamp render above the warnings.
11. **Patient asks the AI assistant an out-of-scope question** (e.g. "can I double my dose?") on `Assistant` → confirm the guardrail banner, refusal box, and **Call Emergency Contact** button all render → tap the button → confirm it attempts to launch the device dialer with the correct number.
12. **Clinician returns to the Triage & Exceptions Dashboard** (web) → confirm the AI escalation from step 11 now shows as a Red alert, and (if steps 6–9 included a missed/skipped-for-side-effects dose) the corresponding Amber/Red exception is visible ahead of the passive roster.
13. **Clinician clicks the alert** → confirms it navigates to the correct patient's detail view with the underlying data (adherence history, check-in trend) intact.
14. **Run automated spot-checks**: `npx @axe-core/cli` against the three key web pages; `flutter analyze && flutter test` on mobile; `pytest backend/tests` on backend. All must pass clean before sign-off.

---

## 7. Deferred / Explicitly Out of Scope

Carried forward from `08-prioritized-ux-backlog.md` §4 ("Do Not Touch Yet"), plus items surfaced during this plan's grounding pass:

1. **Patient self-prescription or schedule editing** — prohibited by safety constraint 1.
2. **In-app clinician-patient video calls / telehealth** — out of scope for the adherence MVP.
3. **Multi-clinician real-time chat** — requires WebSocket infrastructure not justified by this iteration.
4. **Automated ML diagnostic/symptom-triage models** — the AI assistant must remain strictly informational (constraint 2).
5. **Billing, insurance claims, EHR HL7/FHIR integration** — deferred to post-MVP.
6. **Social sharing / patient community forums** — excluded on privacy grounds.
7. **Documents, caregiver accounts, advanced charts, deep reporting, clinical-guideline integrations** — explicitly excluded by this iteration's constraints; not touched even though the backlog/measurement plan reference adjacent concepts (e.g., dashboard "widgets").
8. **Backend triage-aggregation endpoint** — the Triage Dashboard (Issue #10) composes client-side from existing endpoints instead. If roster size in a future iteration makes N+1 client calls a real performance problem, revisit as a dedicated backend endpoint then — not preemptively now.
9. **Response Time Gauge widget** (median seconds to Red-alert view, `09-measurement-plan.md` §4.1 Widget 3) — requires event-timestamp infrastructure beyond what Issue #10 builds; explicitly noted as deferred within that issue rather than silently dropped.
10. **Web automated test framework** (vitest/RTL or similar) — web currently has zero test tooling. This plan does not introduce one; all web verification in this iteration is manual QA + `axe-core` spot-checks + `npm run build`/`lint`. Worth a dedicated follow-up if web's surface keeps growing.
11. **Broader duplicate-file cleanup** beyond what's touched inline in Issues #6 and #11 (stale `api_service.dart`, duplicate `assistant_screen.dart`) — if further dead code turns up during implementation, log it rather than expanding these issues' scope to a general cleanup pass.
12. **Dark mode** — not called for by `docs/ux/07-accessibility-spec.md`; not introduced speculatively in Issue #15's polish pass.

---

## 8. Traceability Matrix

| Origin | Issue(s) | Milestone |
|---|---|---|
| FIND-B01 | #1 | Foundation |
| FIND-B02 | #2 | Foundation |
| FIND-W02 | #3 | Foundation |
| FIND-W03 | #4 | Foundation |
| FIND-W04 | #5 | Foundation |
| FIND-M01 | #6 | Foundation |
| FIND-M02 | #7 | Core flow |
| FIND-M03 | #8 | Core flow |
| WI-04 (interactive notifications) | #9 | Core flow |
| FIND-M06 | #9 (folded) | Core flow |
| FIND-W01 | #10 | Core flow |
| WI-05 (AI guardrail notifier) | #11 | Safety/resilience |
| FIND-M04 | #11 (folded) | Safety/resilience |
| FIND-M07 | #12 | Safety/resilience |
| FIND-M05 | #13 | Safety/resilience |
| *(new)* | #14, #15 | Polish/demo |
| *(verification gate)* | #16 | Polish/demo |
