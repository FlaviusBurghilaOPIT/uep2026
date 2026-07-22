# Remote CarePro — Comprehensive UX Audit & Prioritized Backlog

**Document ID:** `docs/ux/08-prioritized-ux-backlog.md`  
**Generated Date:** 2026-07-22  
**Role:** Lead Product, UX, and Technical-Design Agent  
**Status:** Approved Audit & Backlog Specification

---

## 1. Executive Summary & Audit Overview

This document presents a factual, code-grounded UX audit of Remote CarePro across the **Flutter Patient Mobile App**, the **React Clinician Web Dashboard**, and the **FastAPI Backend Services**.

### 1.1 Composite UX Health Score
* **Overall Composite UX Health Score**: **64 / 100**
  * *Clarity of Next Action*: 70/100 (1-tap dose logging present, but missing 5-sec undo and offline indicators).
  * *Clinician Authored-Source Clarity*: 60/100 (Missing visual lock badges to distinguish clinician orders vs. AI vs. FDA data).
  * *Clinician Exception Handling*: 50/100 (Default landing is a passive roster; missing dedicated "Needs Attention" triage dashboard).
  * *Accessibility Compliance*: 55/100 (Missing dynamic text wrap on mobile; missing visible focus rings and ARIA form labels on web).
  * *Patient Safety & Guardrails*: 75/100 (AI guardrails present in backend, but missing direct phone dialer CTA on mobile refusal box and `escalate=True` triage flags).

---

## 2. Detailed UX Audit Findings

---

### Finding FIND-M01: Mobile Navigation Shell Lacks Dedicated Medications & Profile Tabs

* **App**: `mobile`
* **Screen / Route / Component**: `MainShellPage` (`mobile/lib/features/main/main_shell_page.dart`)
* **Evidence in Current Code**: `MainShellPage` currently configures 4 tabs: `TodayScreen`, `CheckInScreen`, `AssistantScreen`, `RecoveryScreen`. `Profile` is pushed to an external route (`/profile`), and `Medications` is buried inside `TodayScreen`.
* **Problem**: A 1-tap daily check-in consumes a top-level tab, while full prescription lists and user profile/settings are fragmented, violating `docs/ux/05-information-architecture.md`.
* **Severity**: `3` (Major Usability Issue)
* **Safety Impact**: Patients struggle to find their full clinician-authored medication instructions.
* **Recommended Change**: Restructure `MainShellPage` to a 5-tab bottom navigation bar (`Today`, `Medications`, `Recovery`, `Assistant`, `Profile`) and embed `CheckInScreen` as a top action card on `TodayScreen`.
* **Dependencies**: `docs/ux/05-information-architecture.md`
* **Acceptance Criteria**: Bottom navigation renders 5 tabs; tapping Medications displays full active prescription list; Today feed contains the daily feeling check-in card.
* **Effort**: `M`

---

### Finding FIND-M02: Accidental Dose Log Lacks Immediate 5-Second Undo Toast

* **App**: `mobile`
* **Screen / Route / Component**: `TodayScreen` (`mobile/lib/features/today/today_screen.dart`)
* **Evidence in Current Code**: Tapping "Taken" immediately updates the timecard without rendering an undo snackbar or toast window.
* **Problem**: Patients with motor tremors who accidentally tap "Taken" instead of "Skipped" cannot easily undo their action within the flow.
* **Severity**: `3` (Major Usability Issue)
* **Safety Impact**: Inaccurate dose logs reach clinician dashboard without immediate correction option.
* **Recommended Change**: Display a 5-second snackbar toast (*"Logged as Taken. [Undo]"*) upon tapping any status button, reverting card state on tap.
* **Dependencies**: SQLite `PendingQueueTable`
* **Acceptance Criteria**: Tapping Taken shows 5-second undo toast; tapping Undo within 5 seconds reverts card to pending state locally and on API.
* **Effort**: `S`

---

### Finding FIND-M03: Dose Status Pills Rely on Color Alone Without Dual Icon Cues

* **App**: `mobile`
* **Screen / Route / Component**: `TodayScreen` & `MedicationCardWidget` (`mobile/lib/features/today/today_screen.dart`)
* **Evidence in Current Code**: Status pills use solid green/amber background fills with plain text, lacking distinct geometric icon indicators.
* **Problem**: Colorblind patients cannot distinguish green (Taken), amber (Skipped), and red (Missed) pills, violating WCAG 1.4.1.
* **Severity**: `4` (Critical Usability & Accessibility Issue)
* **Safety Impact**: Patient misinterprets dose status on timecards.
* **Recommended Change**: Pair every status color with a distinct icon (Checkmark for Taken, Warning Triangle for Skipped, Cross for Missed) and high-contrast text.
* **Dependencies**: `docs/ux/07-accessibility-spec.md`
* **Acceptance Criteria**: Statuses render with dual color + icon + text indicators and remain 100% distinguishable in monochrome display mode.
* **Effort**: `S`

---

### Finding FIND-M04: AI Guardrail Refusal Box Lacks Direct Emergency Call CTA

* **App**: `mobile`
* **Screen / Route / Component**: `AssistantScreen` (`mobile/lib/features/assistant/assistant_screen.dart`)
* **Evidence in Current Code**: Out-of-scope regex intercept renders text refusal banner (*"I cannot assist with dose changes..."*), but does not display a direct emergency phone button.
* **Problem**: A patient experiencing urgent symptoms or asking about dosage changes is refused help by AI without an immediate 1-tap dialer option.
* **Severity**: `4` (Critical Patient Safety Risk)
* **Safety Impact**: Delayed emergency care seeking during post-surgery complications.
* **Recommended Change**: Render a prominent red-bordered guardrail box containing a bold **Call Emergency Contact ({phone})** button linking to `tel:`.
* **Dependencies**: `GET /cases/{id}/emergency-contact`
* **Acceptance Criteria**: Submitting out-of-scope query displays red refusal box with clickable **Call Emergency Contact** dialer button.
* **Effort**: `S`

---

### Finding FIND-M05: FDA Safety Content Missing Source Badge & Freshness Timestamp

* **App**: `mobile`
* **Screen / Route / Component**: `RecoveryScreen` & `FDAPage` (`mobile/lib/features/recovery/recovery_screen.dart`)
* **Evidence in Current Code**: FDA drug warnings render plain text bullets without displaying regulatory source metadata (`openFDA` vs `Fixture`) or retrieval timestamp.
* **Problem**: Violates Constraint 3 & 6 (FDA Transparency & Provenance). Patient cannot verify data freshness.
* **Severity**: `3` (Major Trust & Provenance Issue)
* **Safety Impact**: Patient relies on potentially outdated cached drug warnings without knowing data age.
* **Recommended Change**: Display explicit source pill badge (`📋 Source: openFDA Live` / `Regulatory Cache`) and retrieval timestamp (`Retrieved: 2026-07-22`).
* **Dependencies**: `docs/product/03-safety-and-edge-cases.md`
* **Acceptance Criteria**: FDA safety cards display source badge and timestamp header above warnings.
* **Effort**: `S`

---

### Finding FIND-M06: Local Notification Service Missing Startup Time-Zone Reconciliation

* **App**: `mobile`
* **Screen / Route / Component**: `NotificationService` (`mobile/lib/core/services/notification_service.dart`)
* **Evidence in Current Code**: `NotificationService` schedules notifications once on login, but does not listen to OS time zone shift events or re-anchor triggers on boot.
* **Problem**: Traveling across time zones or DST shifts causes local notifications to fire at wrong wall-clock hours.
* **Severity**: `3` (Major Usability Issue)
* **Safety Impact**: Reminders arrive hours early or late relative to local medication time.
* **Recommended Change**: Call `NotificationService.instance.reinitialize()` upon app launch and OS time zone change events.
* **Dependencies**: `flutter_local_notifications`
* **Acceptance Criteria**: Changing device time zone reschedules pending notification intents to local wall-clock hours.
* **Effort**: `M`

---

### Finding FIND-M07: Offline Dose Logging Lacks Persistent Top Banner Feedback

* **App**: `mobile`
* **Screen / Route / Component**: `TodayScreen` (`mobile/lib/features/today/today_screen.dart`)
* **Evidence in Current Code**: Logging a dose offline updates local Riverpod state, but does not surface a top sync banner indicating un-synced queue items.
* **Problem**: Patient is unsure whether their offline dose log will reach their clinician once connectivity returns.
* **Severity**: `3` (Major Usability Issue)
* **Safety Impact**: Patient re-logs doses unnecessarily thinking offline logs were lost.
* **Recommended Change**: Render a top bar banner: *"Saved offline. Will sync when connected."* whenever SQLite pending queue contains un-flushed logs.
* **Dependencies**: SQLite `PendingQueueTable`
* **Acceptance Criteria**: Logging offline displays persistent top sync banner; banner clears automatically upon successful background API flush.
* **Effort**: `M`

---

### Finding FIND-W01: Web Dashboard Defaults to Passive Roster Instead of Triage View

* **App**: `web`
* **Screen / Route / Component**: `App.tsx` & `PatientsPage.tsx` (`web/src/App.tsx`)
* **Evidence in Current Code**: Router default route (`/`) redirects directly to `/patients`, rendering an un-sorted list of patient cards without exception filtering.
* **Problem**: Clinicians managing 30+ patients must manually inspect individual cards to find non-compliant or symptomatic patients.
* **Severity**: `4` (Critical Clinical Speed & Safety Issue)
* **Safety Impact**: Delayed clinical intervention for patients missing multiple doses or reporting severe symptoms.
* **Recommended Change**: Implement `TriageDashboardPage` as home (`/`), displaying **"Needs Attention"** Red/Amber exception alerts ahead of passive roster.
* **Dependencies**: `GET /adherence/patients/{id}`, `GET /symptoms/patients/{id}/symptoms/trend`
* **Acceptance Criteria**: Landing on `/` presents Red/Amber exception alerts (Missed 2+ doses, Bad check-in, AI emergency flag) before roster table.
* **Effort**: `L`

---

### Finding FIND-W02: Pending Invite Patient Cards Do Not Display 6-Digit Code

* **App**: `web`
* **Screen / Route / Component**: `PatientsPage.tsx` (`web/src/pages/PatientsPage.tsx`)
* **Evidence in Current Code**: Patient cards with `status="invited"` display pending status text, but do not show the 6-digit invitation code generated during creation.
* **Problem**: Clinician who forgets to write down the code must re-create the patient or check database logs.
* **Severity**: `3` (Major Clinician Efficiency Issue)
* **Safety Impact**: Delayed patient onboarding to mobile app.
* **Recommended Change**: Render the active 6-digit invite code in bold 24px text on pending patient cards with a 1-click **Copy Code** button.
* **Dependencies**: `GET /patients`
* **Acceptance Criteria**: Cards for pending onboarding patients clearly display 6-digit code and Copy button.
* **Effort**: `S`

---

### Finding FIND-W03: Web Form Inputs Lack `<label htmlFor>` Associations and ARIA Attributes

* **App**: `web`
* **Screen / Route / Component**: `CreatePatientPage.tsx` & `MedicationsPage.tsx` (`web/src/pages/`)
* **Evidence in Current Code**: Form inputs use floating text labels without explicit `htmlFor` bindings or `aria-invalid` error attributes.
* **Problem**: Screen readers do not announce input field names or field validation errors on focus/submit.
* **Severity**: `3` (High Accessibility Issue)
* **Safety Impact**: Inaccessible to vision-impaired clinicians using screen readers.
* **Recommended Change**: Bind all `<label htmlFor="id">` elements to inputs and add `aria-invalid` / `aria-describedby` error spans.
* **Dependencies**: `docs/ux/07-accessibility-spec.md`
* **Acceptance Criteria**: Forms pass axe-core accessibility scanner with zero label/error binding violations.
* **Effort**: `S`

---

### Finding FIND-W04: Web Sidebar Controls Lack Visible Focus Rings (`:focus-visible`)

* **App**: `web`
* **Screen / Route / Component**: `NavBar.tsx` (`web/src/components/NavBar.tsx`)
* **Evidence in Current Code**: CSS styles strip default outline without supplying a custom `:focus-visible` ring.
* **Problem**: Keyboard-only clinicians tabbing through sidebar links cannot see focused element location.
* **Severity**: `3` (High Accessibility Issue)
* **Safety Impact**: Keyboard navigation failure.
* **Recommended Change**: Add `:focus-visible { outline: 2px solid #4338ca; outline-offset: 2px; }` across all web components.
* **Dependencies**: `docs/ux/07-accessibility-spec.md`
* **Acceptance Criteria**: Tabbing through web interface highlights focused elements with prominent 2px indigo ring.
* **Effort**: `S`

---

### Finding FIND-B01: Duplicate `scheduled_reminder_id` POST Throws 500 Error

* **App**: `backend`
* **Screen / Route / Component**: `adherence.py` (`backend/app/routers/adherence.py`)
* **Evidence in Current Code**: `POST /adherence/log` does not catch database unique constraint violations on `scheduled_reminder_id`, resulting in an unhandled HTTP 500 Server Error.
* **Problem**: Duplicate local notifications firing on mobile cause server errors instead of a clean conflict response.
* **Severity**: `3` (Backend Data Resilience Issue)
* **Safety Impact**: Mobile app receives 500 error and re-queues log repeatedly.
* **Recommended Change**: Catch `IntegrityError` in SQLAlchemy session and return `HTTP 409 Conflict` with existing `DoseLog` payload.
* **Dependencies**: `models.py` `DoseLog`
* **Acceptance Criteria**: Duplicate POST returns HTTP 409 Conflict with existing log details without throwing 500 error.
* **Effort**: `S`

---

### Finding FIND-B02: AI Out-of-Scope Guardrail Intercept Fails to Persist Triage Flag

* **App**: `backend`
* **Screen / Route / Component**: `ai.py` (`backend/app/routers/ai.py`)
* **Evidence in Current Code**: `POST /ai/chat` intercepts out-of-scope queries and returns refusal text, but sets `escalate=False` in saved `ChatMessage` DB record.
* **Problem**: Emergencies or dosage-change requests asked to AI are hidden from clinician triage dashboard.
* **Severity**: `4` (Critical Patient Safety Risk)
* **Safety Impact**: Clinician is unaware that patient asked AI for emergency or dosage advice.
* **Recommended Change**: Set `in_scope=False`, `escalate=True` on `ChatMessage` DB record when guardrail triggers, surfacing alert in clinician triage API.
* **Dependencies**: `backend/app/routers/ai.py`
* **Acceptance Criteria**: Out-of-scope AI queries persist `escalate=True` and trigger Red alert on clinician triage API endpoint.
* **Effort**: `S`

---

## 3. Top 10 Changes for First Build Iteration

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│                      TOP 10 FIRST BUILD ITERATION CHANGES                        │
├──────────────────────────────────────────────────────────────────────────────────┤
│ 1. FIND-W01: Implement Triage & Exceptions Dashboard ("Needs Attention") Home    │
│ 2. FIND-M04: Add Direct Emergency Call CTA to Mobile AI Guardrail Refusal Box    │
│ 3. FIND-B02: Set escalate=True on AI Guardrail Intercepts for Clinician Alert     │
│ 4. FIND-M03: Add Dual Icon + Text Indicators to Mobile Dose Status Pills         │
│ 5. FIND-M01: Restructure Mobile Shell to 5-Tab Layout & Embed Check-In in Today   │
│ 6. FIND-M02: Add 5-Second Undo Toast Snackbar for Accidental Dose Taps           │
│ 7. FIND-W02: Display 6-Digit Invitation Code on Pending Clinician Patient Cards   │
│ 8. FIND-M05: Add openFDA / Fixture Source Badges & Retrieval Timestamps          │
│ 9. FIND-B01: Return HTTP 409 Conflict on Duplicate Dose Log Submissions          │
│ 10. FIND-W04: Add 2px Indigo Visible Focus Rings (:focus-visible) Across Web     │
└──────────────────────────────────────────────────────────────────────────────────┘
```

---

## 4. "Do Not Touch Yet" List (Excluded from MVP)

To maintain focus on core adherence, safety, and triage, the following complex or out-of-scope features are explicitly designated as **Do Not Touch Yet**:

1. **Patient Self-Prescription or Schedule Editing**: Strictly prohibited by safety constraint 1.
2. **Direct In-App Clinician-Patient Video Calls / Telehealth**: Out of scope for post-surgery adherence MVP.
3. **Multi-Clinician Real-Time Chat System**: Requires complex WebSockets infrastructure; rely on phone/email follow-up.
4. **Automated ML Diagnostic / Symptom Triage Models**: Bedrock AI must remain strictly informational (Constraint 2).
5. **Billing, Insurance Claims, & EHR HL7/FHIR Integration**: Deferred to post-MVP phase.
6. **Social Sharing or Patient Community Forums**: Excluded to prevent patient privacy exposure and unvalidated advice sharing.

---

## 5. Recommended Implementation Sequence

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│                           RECOMMENDED IMPLEMENTATION SEQUENCE                    │
├──────────────────────────────────────────────────────────────────────────────────┤
│ PHASE 1: BACKEND SAFETY & DATA RULES (Sprint 1)                                  │
│ • Fix FIND-B01: Return HTTP 409 Conflict on duplicate dose logs                  │
│ • Fix FIND-B02: Set escalate=True on AI guardrail intercept records              │
│                                                                                  │
│ PHASE 2: MOBILE SAFETY, ACCESSIBILITY & 5-TAB IA (Sprint 2)                       │
│ • Fix FIND-M01: Implement 5-Tab Shell & embed Check-In in TodayScreen            │
│ • Fix FIND-M02: Add 5-second undo toast snackbar                                 │
│ • Fix FIND-M03: Add dual icon + text status indicators                           │
│ • Fix FIND-M04: Add emergency call button to AI refusal box                     │
│ • Fix FIND-M05: Add openFDA source badge & freshness timestamp                   │
│                                                                                  │
│ PHASE 3: CLINICIAN WEB TRIAGE & ACCESSIBILITY (Sprint 3)                         │
│ • Fix FIND-W01: Implement Triage & Exceptions Dashboard ("Needs Attention")      │
│ • Fix FIND-W02: Display 6-digit invite code on pending patient cards             │
│ • Fix FIND-W03 & W04: Form accessibility labels & 2px focus rings                │
│                                                                                  │
│ PHASE 4: VERIFICATION & E2E DEMO VALIDATION (Sprint 4)                           │
│ • Execute automated accessibility scans (axe-core / Flutter Inspector)           │
│ • Conduct 8-Step Golden Loop E2E Demo Walkthrough                                │
└──────────────────────────────────────────────────────────────────────────────────┘
```

---

## 6. GitHub Issue-Ready Backlog

---

### Issue #1: [Web] Implement Triage & Exceptions Dashboard ("Needs Attention") Default Home
* **Labels**: `web`, `p0-critical`, `ux`, `triage`
* **Description**:  
  Currently, the clinician web app defaults to `/patients` rendering an un-sorted roster. Clinicians must manually click through profiles to spot non-compliant patients.  
  *Task*: Implement `TriageDashboardPage` as default home (`/`), surfacing Red (Missed 2+ doses, Bad check-in, AI emergency flag) and Amber (Skipped for side effects, Low adherence) alerts ahead of passive roster.
* **Acceptance Criteria**:
  - Landing on `/` presents high-risk exception alerts first.
  - Clicking patient card on triage dashboard navigates to detail view.
* **Effort**: `L`

---

### Issue #2: [Mobile] Add Emergency Phone Call Button to AI Guardrail Refusal Box
* **Labels**: `mobile`, `p0-critical`, `safety`, `ai`
* **Description**:  
  Out-of-scope AI queries trigger a text refusal banner, but lack a direct emergency dialer button.  
  *Task*: Render a prominent red-bordered box containing a **Call Emergency Contact ({phone})** button linking to `tel:`.
* **Acceptance Criteria**:
  - Asking diagnostic or dose-change prompt displays red refusal box.
  - Tapping Emergency button launches device phone dialer.
* **Effort**: `S`

---

### Issue #3: [Backend] Persist `escalate=True` on Out-of-Scope AI Queries
* **Labels**: `backend`, `p0-critical`, `safety`, `ai`
* **Description**:  
  `POST /ai/chat` intercepts dangerous queries but sets `escalate=False` in saved `ChatMessage` records.  
  *Task*: Set `in_scope=False`, `escalate=True` on `ChatMessage` DB record when guardrail matches, exposing alert to clinician triage API.
* **Acceptance Criteria**:
  - Out-of-scope chat query sets `escalate=True` in DB.
  - Endpoint `GET /adherence/patients/{id}` surfaces flagged AI query.
* **Effort**: `S`

---

### Issue #4: [Mobile] Add Dual Icon + Text Cues to Medication Status Pills
* **Labels**: `mobile`, `p1-major`, `accessibility`, `a11y`
* **Description**:  
  Status pills rely on color alone (green/amber/red), violating WCAG 1.4.1.  
  *Task*: Pair every status color with a distinct icon (Checkmark for Taken, Warning for Skipped, Cross for Missed) and explicit text label.
* **Acceptance Criteria**:
  - Status pills render icon + text label.
  - 100% distinguishable in monochrome/grayscale mode.
* **Effort**: `S`

---

### Issue #5: [Mobile] Restructure Mobile Shell to 5-Tab IA & Embed Check-In in Today
* **Labels**: `mobile`, `p1-major`, `ia`, `navigation`
* **Description**:  
  Mobile app currently uses 4 tabs, burying Profile and Medications while assigning an entire tab to Check-In.  
  *Task*: Update `MainShellPage` to 5 tabs (`Today`, `Medications`, `Recovery`, `Assistant`, `Profile`) and embed `CheckIn` card on `TodayScreen`.
* **Acceptance Criteria**:
  - Bottom navigation bar displays 5 tabs.
  - Today feed embeds daily symptom check-in card.
* **Effort**: `M`

---

### Issue #6: [Mobile] Add 5-Second Undo Toast Snackbar for Accidental Dose Taps
* **Labels**: `mobile`, `p1-major`, `ux`, `safety`
* **Description**:  
  Tapping "Taken" immediately commits without an immediate undo window.  
  *Task*: Render a 5-second snackbar toast (*"Logged as Taken. [Undo]"*) upon tapping status buttons, reverting state if Undo is tapped.
* **Acceptance Criteria**:
  - Tapping status button displays 5-second undo toast.
  - Tapping Undo within 5 seconds reverts dose status locally and on API.
* **Effort**: `S`

---

### Issue #7: [Web] Display 6-Digit Invite Code on Pending Clinician Patient Cards
* **Labels**: `web`, `p1-major`, `ux`, `clinician-speed`
* **Description**:  
  Pending onboarding patient cards do not show the generated 6-digit code.  
  *Task*: Surface 6-digit invite code in 24px bold text on pending patient cards with a 1-click Copy button.
* **Acceptance Criteria**:
  - Pending patient cards display 6-digit code.
  - Clicking Copy copies code to clipboard.
* **Effort**: `S`

---

### Issue #8: [Mobile] Add openFDA / Fixture Source Badges & Retrieval Timestamps
* **Labels**: `mobile`, `p1-major`, `fda`, `transparency`
* **Description**:  
  FDA warnings lack regulatory source pills and data freshness timestamps.  
  *Task*: Render explicit source badge (`openFDA Live` / `Regulatory Cache`) and timestamp (`Retrieved: YYYY-MM-DD`).
* **Acceptance Criteria**:
  - FDA cards render source badge and timestamp header.
* **Effort**: `S`

---

### Issue #9: [Backend] Return HTTP 409 Conflict on Duplicate Dose Log POSTs
* **Labels**: `backend`, `p1-major`, `resilience`, `api`
* **Description**:  
  Duplicate `scheduled_reminder_id` POST throws 500 error due to unique constraint.  
  *Task*: Catch `IntegrityError` in `adherence.py` and return HTTP 409 Conflict with existing log payload.
* **Acceptance Criteria**:
  - Duplicate POST returns HTTP 409 Conflict without server error.
* **Effort**: `S`

---

### Issue #10: [Web] Apply 2px Indigo Visible Focus Rings (:focus-visible) Across Web
* **Labels**: `web`, `p1-major`, `accessibility`, `a11y`
* **Description**:  
  Web interactive elements lack prominent visible focus rings for keyboard navigation.  
  *Task*: Apply `:focus-visible { outline: 2px solid #4338ca; outline-offset: 2px; }` across all web controls.
* **Acceptance Criteria**:
  - Tabbing through controls highlights focused element with 2px indigo outline.
* **Effort**: `S`
