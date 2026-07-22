# Remote CarePro — Interaction-Safety & Edge Case Specification

**Document ID:** `docs/product/03-safety-and-edge-cases.md`  
**Generated Date:** 2026-07-22  
**Role:** Lead Product, UX, and Technical-Design Agent  
**Status:** Approved Resilience Specification

---

## 1. Governance & Core Safety Constraints

This specification defines the interaction safety, resilience rules, failure recovery paths, and copy standards for Remote CarePro. Every design and engineering implementation MUST strictly enforce the following five non-negotiable constraints:

1. **Patient Immutability Constraint**: The patient companion app NEVER allows self-prescribing, adding, editing, or deleting prescribed medications, doses, or schedules.
2. **AI Boundary Constraint**: The AI Assistant NEVER diagnoses symptoms, triages urgency, prescribes treatment, or recommends changing medication doses/schedules.
3. **FDA Transparency Constraint**: All FDA drug safety content is strictly informational and MUST explicitly state its regulatory source (`live openFDA` vs `cached fixture`) and retrieval timestamp.
4. **Ethical Engagement Constraint**: The system NEVER uses shame copy, streak counters, false urgency, or guilt-inducing mechanics to coerce medication adherence.
5. **Clinical Validation Marker**: Any copy, clinical threshold, or emergency escalation text intended for urgent care situations MUST be explicitly tagged with `[NEEDS CLINICAL VALIDATION]`.

---

## 2. Detailed Edge Case Specifications

---

### Case 1: Notification Permission Denied

* **Trigger**: Patient denies notification permission during initial OS prompt or disables notifications in OS settings.
* **Patient-Visible State & UX**: A calm, persistent, non-intrusive top banner appears on `TodayScreen`: *"Reminders are turned off in system settings."* Tapping the banner opens the device's OS settings page. All medication timecards remain fully visible and operational for manual checking.
* **Clinician-Visible State**: Patient roster on web dashboard displays a neutral status indicator: *"Local reminders disabled on patient device"*.
* **Backend Data-State Rule**: No backend error. App syncs device metadata (`notifications_enabled: false`) during periodic `/me` profile updates.
* **Retry / Undo Rule**: Patient can tap the banner at any time to re-open OS settings and grant permissions.
* **Safe Copy Requirements**:  
  > *"To receive medication reminders on time, enable notifications in your phone settings."*  
  *(Strictly informational — zero guilt or pressure).*
* **Telemetry Event**: `notification_permission_denied`, `notification_settings_opened`.
* **Testable Acceptance Criteria**: Given a patient who denies notification permissions, when they land on `TodayScreen`, then an informational banner renders, tapping it triggers OS settings, and dosage cards remain loggable.

---

### Case 2: Notification Delayed, Duplicated, or Missing

* **Trigger**: OS background throttling delays local notification delivery, system schedules duplicate notification IDs, or device reboot clears pending intents.
* **Patient-Visible State & UX**: On app resume, the app reconciles scheduled times with wall-clock time. Dosage timecard displays actual scheduled time alongside current context. Tapping a duplicate notification opens the app directly to the active `TodayScreen` without double-triggering or crashing.
* **Clinician-Visible State**: Clinician views actual logged timestamp (`logged_at`) alongside prescribed `scheduled_time` in adherence timeline.
* **Backend Data-State Rule**: `DoseLog` table enforces a `UNIQUE` constraint on `scheduled_reminder_id`. Second log attempt for the same reminder ID returns `HTTP 409 Conflict` / existing log record.
* **Retry / Undo Rule**: `NotificationService.instance.initialize()` cancels and reschedules pending notification IDs upon every app startup.
* **Safe Copy Requirements**:  
  > *"Scheduled for 8:00 AM — Logged at 8:42 AM."*  
  *(Objective, factual timestamping).*
* **Telemetry Event**: `notification_delivered_late`, `notification_duplicate_ignored`.
* **Testable Acceptance Criteria**: Given a duplicate notification tap, when the app opens, then it displays `TodayScreen` once without creating duplicate `DoseLog` rows in database.

---

### Case 3: Offline Use When a Dose Is Logged

* **Trigger**: Patient logs a dose (`Taken`, `Skipped`, `Missed`) while device has no cellular or Wi-Fi connectivity.
* **Patient-Visible State & UX**: Immediate optimistic UI update (timecard transitions to green/amber/red badge with checkmark). A subtle sync indicator appears at bottom: *"Saved offline. Will sync when connected."*
* **Clinician-Visible State**: Unchanged until client sync completes. Once synced, timeline updates with the original `logged_at` timestamp.
* **Backend Data-State Rule**: Client writes log entry to local SQLite `PendingQueueTable` with local UUID and client timestamp. Background worker pushes queue to `POST /adherence/log` when online.
* **Retry / Undo Rule**: Exponential backoff retry loop (1s, 5s, 15s, 60s) on network reconnection. 5-second local undo toast remains fully functional offline.
* **Safe Copy Requirements**:  
  > *"Log saved on your device. We will update your care team once you are back online."*
* **Telemetry Event**: `dose_logged_offline`, `offline_queue_synced`.
* **Testable Acceptance Criteria**: Given offline device state, when patient taps "Taken", then UI updates immediately, record is queued in SQLite, and auto-posts to `POST /adherence/log` upon network restore.

---

### Case 4: App Restarted Before Sync

* **Trigger**: Patient logs a dose offline, and the app process is force-killed or device restarts before background sync executes.
* **Patient-Visible State & UX**: On app relaunch, Flutter app loads local SQLite state. Dosage card correctly displays the logged state (`Taken`/`Skipped`/`Missed`). A background sync runner detects pending queue items and pushes them to API.
* **Clinician-Visible State**: Dashboard updates as soon as API receives queued logs.
* **Backend Data-State Rule**: `DoseLog` API accepts original `logged_at` client timestamp in payload, preserving true adherence history.
* **Retry / Undo Rule**: On app startup (`main.dart`), pending queue manager checks SQLite and flushes un-synced entries to `POST /adherence/log`.
* **Safe Copy Requirements**:  
  > *"Syncing offline logs..."*  
  *(Brief toast if sync duration exceeds 2 seconds).*
* **Telemetry Event**: `un_synced_logs_recovered_on_boot`, `pending_queue_flushed`.
* **Testable Acceptance Criteria**: Given an un-synced log in SQLite, when app is force-killed and re-launched, then local state displays the logged status and auto-flushes to backend.

---

### Case 5: Time-Zone / Daylight-Saving Change

* **Trigger**: Patient travels across time zones or daylight saving time (DST) shifts the clock $\pm 1$ hour.
* **Patient-Visible State & UX**: Medication schedule times remain fixed relative to local wall-clock time (e.g. 8:00 AM local time). App detects time zone change and re-anchors local notification triggers to local wall-clock hours.
* **Clinician-Visible State**: Adherence timestamps stored in UTC and rendered in clinician's local time zone with explicit time zone indicator (e.g., *"8:00 AM EDT"*).
* **Backend Data-State Rule**: All DB timestamps (`scheduled_time`, `logged_at`, `created_at`) are stored in UTC (`DateTime` in SQLAlchemy).
* **Retry / Undo Rule**: App listens to OS time zone change broadcasts and reschedules `flutter_local_notifications`.
* **Safe Copy Requirements**:  
  > *"Your reminder times have adjusted to your current time zone (8:00 AM local time)."*
* **Telemetry Event**: `timezone_change_detected`, `reminders_rescheduled_tz`.
* **Testable Acceptance Criteria**: Given a time zone shift from EST to PST, when local time hits 8:00 AM PST, then local notification fires at 8:00 AM PST.

---

### Case 6: Clinician Changes or Stops Medication

* **Trigger**: Clinician deletes or updates a medication prescription on React Web (`/cases/:id/medications`).
* **Patient-Visible State & UX**: On next sync, discontinued medication disappears from `TodayScreen` active list or reflects updated dose. A quiet notification banner appears: *"Your care team updated your treatment plan."*
* **Clinician-Visible State**: Web dashboard shows updated medication list. Historical dose logs for discontinued medications are preserved for clinical audit.
* **Backend Data-State Rule**: Deleting a medication sets `Medication.status="discontinued"` or soft-deletes record. Existing `DoseLog` records linked to past `ScheduledReminder`s remain immutably stored in DB.
* **Retry / Undo Rule**: Mobile client auto-pulls latest treatment plan on resume (`GET /cases/{id}/medications`).
* **Safe Copy Requirements**:  
  > *"Your care team updated your prescribed medications. Review your updated list below."*
* **Telemetry Event**: `treatment_plan_updated_by_clinician`, `patient_regimen_refreshed`.
* **Testable Acceptance Criteria**: Given a clinician deletes a medication, when patient app syncs, then discontinued medication no longer shows pending reminders, and past dose history remains archived.

---

### Case 7: Patient Logs a Dose Accidentally

* **Trigger**: Patient accidentally taps "Taken" instead of "Skipped", or selects the wrong dosage card.
* **Patient-Visible State & UX**: Upon tap, a 5-second snackbar toast appears at bottom: *"Logged as Taken. [Undo / Change]"*. Tapping **Undo** immediately reverts card state to pending. Tapping card after 5 seconds opens a status selection modal with confirmation.
* **Clinician-Visible State**: Dashboard reflects the corrected status once updated.
* **Backend Data-State Rule**: `PATCH /reminders/{id}` or `POST /adherence/log` with existing `scheduled_reminder_id` updates `DoseLog.status` and updates `logged_at`.
* **Retry / Undo Rule**: 5-second immediate undo toast; subsequent corrections supported via manual card tap.
* **Safe Copy Requirements**:  
  > *"Dose status updated. Your care team will see the updated log."*
* **Telemetry Event**: `dose_log_undone`, `dose_log_status_corrected`.
* **Testable Acceptance Criteria**: Given an accidental tap on "Taken", when patient taps "Undo" within 5 seconds, then status reverts to pending locally and on backend.

---

### Case 8: Patient Selects "Skipped" Due to Side Effects

* **Trigger**: Patient taps "Skipped" on a medication card and selects "Experiencing side effects" or adds an optional note.
* **Patient-Visible State & UX**: Card marks as "Skipped". An optional prompt asks: *"Are you experiencing severe or troubling symptoms?"* Displays a direct button to **Call Emergency Contact** or **Contact Clinic**.
* **Clinician-Visible State**: Clinician web dashboard flags patient profile card with an Amber badge: *"Dose Skipped — Side Effects Reported"*.
* **Backend Data-State Rule**: `DoseLog` records `status="skipped"`, `notes="Side effects"`. Triggers alert flag in `GET /adherence/patients/{id}` payload.
* **Retry / Undo Rule**: Patient can update status or notes within app session.
* **Safe Copy Requirements**:  
  > *"Skipped logged. If you are experiencing severe or troubling symptoms, contact your doctor or emergency contact immediately. [NEEDS CLINICAL VALIDATION]"*
* **Telemetry Event**: `dose_skipped_side_effects`, `emergency_contact_prompted`.
* **Testable Acceptance Criteria**: Given a patient selects "Skipped due to side effects", when submitted, then clinician dashboard displays an Amber alert badge and emergency contact options are presented to patient.

---

### Case 9: Patient Has No Active Treatment Plan

* **Trigger**: Patient completes onboarding before clinician has authored medications/recommendations, or clinician archives case.
* **Patient-Visible State & UX**: `TodayScreen` renders a calm, supportive empty state illustration: *"Your recovery care plan is being prepared by your care team. Check back soon or call your clinic if you have questions."*
* **Clinician-Visible State**: Web dashboard flags patient profile as *"Invited — Pending Treatment Plan Creation"*.
* **Backend Data-State Rule**: `GET /cases/{id}/medications` returns empty JSON list `[]` with `HTTP 200 OK`.
* **Retry / Undo Rule**: Pull-to-refresh or automatic 60-second polling.
* **Safe Copy Requirements**:  
  > *"Your care team is preparing your care plan. No action is needed from you right now."*
* **Telemetry Event**: `empty_treatment_plan_viewed`.
* **Testable Acceptance Criteria**: Given a patient with 0 medications, when viewing `TodayScreen`, then a calm empty state renders without error alerts or crash loops.

---

### Case 10: Invite Expired or Account Cannot Be Accessed

* **Trigger**: Patient enters an invalid 6-digit code, expired invite, or locked credentials during signup/login.
* **Patient-Visible State & UX**: `SignupStep1Screen` displays an explicit error alert banner: *"Invalid or expired invitation code. Please check your code or contact your clinic for a new invite."*
* **Clinician-Visible State**: Clinician can view pending invite on web dashboard (`/patients`) and click **Resend / Regenerate Invite Code**.
* **Backend Data-State Rule**: `POST /auth/verify-invite` returns `HTTP 400 Bad Request` with `{ "detail": "Invalid email or invite code" }`.
* **Retry / Undo Rule**: Unlimited code re-entry attempts permitted; provides "Request New Code" button instructing patient to call clinic.
* **Safe Copy Requirements**:  
  > *"We couldn't verify that code. Double-check your code or ask your care team to resend your invite."*
* **Telemetry Event**: `invite_verification_failed`, `invite_code_regenerated`.
* **Testable Acceptance Criteria**: Given an invalid invite code, when submitted on Step 1, then error alert renders without locking screen, allowing code re-entry.

---

### Case 11: API Returns Stale or Inconsistent Data

* **Trigger**: Local mobile cache contains outdated prescription while API returns updated case, or network drops mid-payload transport.
* **Patient-Visible State & UX**: App displays cached data with a subtle freshness timestamp: *"Updated today at 08:00 AM"*. A top bar indicator shows: *"Syncing latest plan..."*. Server state takes precedence on conflict reconciliation.
* **Clinician-Visible State**: Dashboard shows last synced telemetry timestamp per patient.
* **Backend Data-State Rule**: Models enforce `updated_at` timestamps. Client compares version/timestamps during sync reconciliation.
* **Retry / Undo Rule**: Silent background retry with exponential backoff.
* **Safe Copy Requirements**:  
  > *"Showing cached care plan. Updating..."*
* **Telemetry Event**: `stale_data_detected`, `data_reconciled_with_server`.
* **Testable Acceptance Criteria**: Given a data mismatch between local SQLite and server DB, when sync completes, server state replaces local cache deterministically.

---

### Case 12: FDA Source Is Unavailable

* **Trigger**: openFDA public API returns HTTP 503 Service Unavailable or network blocks external API requests.
* **Patient-Visible State & UX**: `RecoveryScreen` / `FDAPage` displays cached FDA summary or fallback card: *"FDA safety information currently unavailable. Sourced from fixture/cached records."* Displays drug name and generic advice to consult clinician.
* **Clinician-Visible State**: Web FDA view displays `source="fixture"` or *"Cached"*.
* **Backend Data-State Rule**: `get_fda_provider()` catches `httpx.HTTPError` and falls back to `FixtureFDAProvider` or returns cached DB records.
* **Retry / Undo Rule**: Background retry on openFDA endpoint after 30 seconds.
* **Safe Copy Requirements**:  
  > *"FDA live safety updates are temporarily unavailable. Sourced from cached regulatory database. Sourced: 2026-07-22."*
* **Telemetry Event**: `fda_api_fallback_triggered`, `fda_fixture_served`.
* **Testable Acceptance Criteria**: Given openFDA API timeout, when patient requests FDA info, then app renders cached/fixture warnings with explicit source labeling without throwing an unhandled exception.

---

### Case 13: AI Request Seeks Diagnosis, Dosage Changes, or Emergency Advice

* **Trigger**: Patient submits chat query containing keywords like *"I have chest pain"*, *"Can I double my dose?"*, or *"Should I stop taking ibuprofen?"*.
* **Patient-Visible State & UX**: Assistant immediately blocks LLM processing. Renders a prominent red-bordered guardrail box: *"I cannot help with changing medication doses, diagnosing symptoms, or emergency advice."* Displays a bold **Call Emergency Contact** button (linking to `emergency_contact_phone`) and clinic number.
* **Clinician-Visible State**: Web dashboard flags patient profile with a Red alert indicator: *"Out-of-Scope / Potential Emergency Query Flagged"*.
* **Backend Data-State Rule**: `_check_guardrail()` matches `OUT_OF_SCOPE_MARKERS`. Sets `in_scope=False`, `escalate=True`. Saves `ChatMessage` in DB without querying LLM provider.
* **Retry / Undo Rule**: LLM call blocked. Chat input cleared.
* **Safe Copy Requirements**:  
  > *"I cannot advise on changing medication doses or diagnosing urgent symptoms — that requires clinical judgment. If you are experiencing an emergency, call your local emergency services or contact your clinic immediately. [NEEDS CLINICAL VALIDATION]"*
* **Telemetry Event**: `ai_guardrail_triggered`, `emergency_cta_tapped`.
* **Testable Acceptance Criteria**: Given a chat prompt containing "double dose" or "chest pain", when submitted, LLM is NOT queried, refusal banner renders immediately, and emergency contact button displays.

---

### Case 14: Shared Device & Privacy Exposure

* **Trigger**: Patient shares phone with family member or leaves app unattended in a public location.
* **Patient-Visible State & UX**: App auto-locks after 5 minutes of inactivity or when backgrounded (if PIN/biometrics enabled). Displays a secure lock screen requiring PIN or TouchID/FaceID to resume. Health details (medication names, surgery type) hidden on OS task switcher previews.
* **Clinician-Visible State**: N/A (mobile client security).
* **Backend Data-State Rule**: JWT access token stored securely in `flutter_secure_storage` (iOS Keychain / Android Keystore). Session invalidated on explicit logout.
* **Retry / Undo Rule**: PIN/biometric prompt permits 3 attempts before requiring password re-authentication.
* **Safe Copy Requirements**:  
  > *"Remote CarePro Locked. Authenticate to view your care plan."*
* **Telemetry Event**: `app_autolocked_inactivity`, `biometric_auth_failed`.
* **Testable Acceptance Criteria**: Given 5 minutes of inactivity, when user re-opens app, then a lock screen prompts for authentication before revealing health data.

---

### Case 15: Patient Has Vision, Motor, Cognitive, or Low-Literacy Limitations

* **Trigger**: Patient has low vision (requires 200% system font scaling), motor tremors (difficulty tapping small targets), cognitive fatigue, or low health literacy.
* **Patient-Visible State & UX**: Full support for OS dynamic text scaling without visual clipping; minimum 48×48dp touch targets for all action buttons; high-contrast text ratios ($\ge 4.5:1$); plain-language copy (8th-grade reading level); color + icon dual indicators; screen reader (`Semantics` in Flutter) labels on all dose buttons.
* **Clinician-Visible State**: Standard high-density clinical dashboard.
* **Backend Data-State Rule**: API schemas support plain-language `schedule_text` (e.g., *"Take 1 pill in the morning with food"* rather than *"1 tab PO TID PC"*).
* **Retry / Undo Rule**: Large 1-tap target buttons with generous touch hitboxes.
* **Safe Copy Requirements**:  
  > *"Take 1 pill in the morning with food."*  
  *(Plain language, active voice, short sentences. No medical jargon or acronyms).*
* **Telemetry Event**: `accessibility_text_scale_detected`, `screen_reader_active`.
* **Testable Acceptance Criteria**: Given 200% system font scaling enabled, when viewing `TodayScreen`, then all text wraps cleanly without visual clipping or overflow errors.

---

## 3. Resilience Matrix Summary

| Case ID | Feature / System Area | Primary Threat / Edge Scenario | Safe Recovery Strategy | Telemetry Event |
|---|---|---|---|---|
| **1** | Notifications | Permission Denied | Persistent non-intrusive banner + settings link | `notification_permission_denied` |
| **2** | Notifications | Late / Duplicate Intent | DB `UNIQUE` constraint + startup re-initialization | `notification_duplicate_ignored` |
| **3** | Offline Sync | Logging offline | Local SQLite queue + background HTTP retry | `dose_logged_offline` |
| **4** | Offline Sync | App force-killed mid-sync | Boot-time SQLite queue flush | `un_synced_logs_recovered_on_boot`|
| **5** | Schedule / Time | Time-zone / DST shift | Re-anchor local notifications to wall clock | `timezone_change_detected` |
| **6** | Prescription | Med deleted by doctor | Soft-delete + archive past logs for audit | `treatment_plan_updated_by_clinician`|
| **7** | Dose Logging | Accidental tap | 5-second snackbar undo toast + edit modal | `dose_log_undone` |
| **8** | Dose Logging | Skipped for side effects | Amber clinician alert badge + emergency CTA | `dose_skipped_side_effects` |
| **9** | Regimen | Empty treatment plan | Calm supportive empty state + polling | `empty_treatment_plan_viewed` |
| **10**| Auth | Expired invite code | Clear error alert + clinician code resend | `invite_verification_failed` |
| **11**| Data Sync | Stale cache vs server | Server state precedence + timestamp check | `data_reconciled_with_server` |
| **12**| openFDA | API 503 / network drop | Fallback to fixture / DB cache + source label| `fda_api_fallback_triggered` |
| **13**| AI Guardrail | Diagnostic / dose prompt | Regex intercept + emergency contact CTA | `ai_guardrail_triggered` |
| **14**| Mobile Security| Shared device exposure | 5-min auto-lock + OS task switcher blur | `app_autolocked_inactivity` |
| **15**| Accessibility | Low vision / motor tremor | 200% font scale + 48dp targets + plain text | `accessibility_text_scale_detected` |
