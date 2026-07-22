# Remote CarePro — Privacy-Aware Product Measurement Plan

**Document ID:** `docs/product/09-measurement-plan.md`  
**Generated Date:** 2026-07-22  
**Role:** Lead Product, UX, and Technical-Design Agent  
**Status:** Approved Measurement & Telemetry Specification

---

## 1. Executive Summary & Privacy Governance

This measurement plan defines how Remote CarePro evaluates product success, patient safety, clinician utility, and UX efficiency. 

### 1.1 Non-Optimization Principle
Remote CarePro **NEVER** optimizes for vanity engagement metrics such as time-in-app, total screen views, app session length, or AI chatbot message volume. For a recovering post-surgery patient, **less time spent in the app represents superior UX**. Success is defined by rapid 1-tap task completion, clinical safety, and transparent recovery signals.

### 1.2 HIPAA & Privacy Boundary Rule
Telemetry events **MUST NEVER** transmit Protected Health Information (PHI) or Personally Identifiable Information (PII).
* ❌ **STRICTLY FORBIDDEN IN TELEMETRY**: Patient real names, email addresses, exact drug names (e.g., *"Oxycodone"*), exact dosage strings (e.g., *"10mg"*), raw patient chat text, or clinician notes.
* ✅ **APPROVED IN TELEMETRY**: Hashed IDs (`patient_hash`), status enums (`taken`/`skipped`/`missed`), time-deltas in seconds, medication category enums (`analgesic`/`antibiotic`), and system state codes.

---

## 2. Core Metrics Architecture

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│                                NORTH-STAR METRIC                                 │
│                   30-DAY POST-SURGERY SAFE ADHERENCE RATE                        │
│   (% of scheduled doses logged on-time without unhandled severe escalations)    │
└──────────────────────────────────────────────────────────────────────────────────┘
         │                                                        │
         ▼                                                        ▼
┌─────────────────────────────────┐      ┌─────────────────────────────────────────┐
│     PATIENT INPUT METRICS       │      │        CLINICIAN VALUE METRICS          │
│ • On-Time Log Rate (±2 hrs)     │      │ • Time-to-Triage High Risk (<60s)       │
│ • 1-Tap Completion Velocity (<3s)│     │ • 7-Day Exception Resolution Rate       │
│ • Daily Feeling Check-In Rate   │      │ • Active Roster Triage Coverage         │
└─────────────────────────────────┘      └─────────────────────────────────────────┘
         │                                                        │
         ▼                                                        ▼
┌─────────────────────────────────┐      ┌─────────────────────────────────────────┐
│     SAFETY COUNTER-METRICS      │      │       AI & NOTIFICATION METRICS         │
│ • Unhandled Side-Effect Rate    │      │ • AI Guardrail Refusal Rate             │
│ • Accidental Log Undo Frequency │      │ • Emergency Contact Call CTA Tap Rate   │
│ • Un-Synced Offline Queue (>24h)│      │ • Notification Permission Turn-Off Rate │
└─────────────────────────────────┘      └─────────────────────────────────────────┘
```

---

### 2.1 North-Star Metric

* **Metric Name**: **30-Day Post-Surgery Safe Adherence Rate**
* **Definition**: The percentage of total prescribed medication doses across all active post-surgery cases that are logged as `Taken` or `Skipped` (with valid clinician-visible reason) within a $\pm 2$-hour window of the scheduled wall-clock time, without unhandled severe escalation events.
* **Target Threshold**: $\ge 85\%$ across all active patient cohorts.
* **Patient Benefit**: Demonstrates that patients are receiving their prescribed therapy on schedule while maintaining a safe feedback loop with their care team.

---

### 2.2 Patient Adherence Input Metrics

| Metric Name | Calculation / Formula | Target Threshold | Patient Benefit |
|---|---|---|---|
| **On-Time Dose Log Rate** | $\frac{\text{Doses Logged within } \pm 2 \text{ Hours}}{\text{Total Scheduled Doses}} \times 100$ | $\ge 80\%$ | Minimizes therapeutic window gaps during post-surgery recovery. |
| **1-Tap Log Velocity** | Median time (seconds) from app launch to tapping `Taken` | $< 3.0 \text{ seconds}$ | Reduces cognitive burden and physical effort for fatigued patients. |
| **Daily Check-In Rate** | $\frac{\text{Days with Submitted Feeling Check-In}}{\text{Total Active Recovery Days}} \times 100$ | $\ge 75\%$ | Provides clinician with continuous recovery status. |

---

### 2.3 Clinician Value Metrics

| Metric Name | Calculation / Formula | Target Threshold | Clinician Value |
|---|---|---|---|
| **Time-to-Triage High-Risk Exception** | Median time (seconds) from Red triage alert creation to clinician view | $< 60 \text{ seconds}$ | Ensures rapid clinical follow-up for non-adherent or symptomatic patients. |
| **Exception Resolution Rate** | $\frac{\text{Triage Alerts Resolved within 24 Hours}}{\text{Total Generated Triage Alerts}} \times 100$ | $\ge 90\%$ | Prevents patient alert fatigue and ensures complete case follow-through. |
| **Active Roster Coverage** | % of active cases with updated treatment plans & emergency contacts | $100\%$ | Eliminates unmonitored post-surgery cases. |

---

### 2.4 Safety Counter-Metrics

| Counter-Metric Name | Trigger Condition | Safety Alarm Threshold | Remediation Action |
|---|---|---|---|
| **Unhandled Severe Side-Effect Rate** | Patient selects `Skipped (Side Effects)` but does not tap Emergency CTA within 60s | $> 5\%$ of skipped logs | Automatically generate Red Triage Alert on clinician dashboard. |
| **Un-Synced Offline Log Stagnation** | Un-synced logs remain in local SQLite queue for $> 24$ hours | $> 1\%$ of offline logs | Display persistent sync warning banner and attempt push on network resume. |
| **Accidental Log Undo Frequency** | Patient taps `Undo` snackbar within 5 seconds of logging dose | $> 10\%$ of total logs | Redesign dose card hitboxes and visual confirmation affordances. |

---

### 2.5 Notification Fatigue & AI Safety Metrics

| Metric Domain | Metric Name | Formula / Definition | Target |
|---|---|---|---|
| **Notifications** | **Permission Turn-Off Rate** | % of onboarded patients who disable OS notifications | $< 5\%$ |
| **Notifications** | **Late Notification Tap Rate** | % of doses logged via late notification prompts ($>1$ hour late) | $< 15\%$ |
| **AI Safety** | **Guardrail Refusal Rate** | % of total AI chat messages triggering out-of-scope refusal box | Tracked |
| **AI Safety** | **Emergency Call CTA Tap-Through** | $\frac{\text{Taps on Call Emergency Contact Button}}{\text{Total Guardrail Refusal Boxes Rendered}} \times 100$ | $\ge 50\%$ |

---

### 2.6 Usability Funnel & Data-Quality Metrics

* **3-Step Onboarding Funnel Completion**: $\frac{\text{Completed Step 3 Profile}}{\text{Entered 6-Digit Code (Step 1)}} \times 100 \ge 90\%$.
* **Offline-to-Online Queue Sync Success**: % of SQLite `PendingQueueTable` records successfully posted to `POST /adherence/log` upon reconnect $= 100\%$.
* **Duplicate Log Conflict Handling**: % of duplicate `scheduled_reminder_id` POSTs returning `HTTP 409 Conflict` without 500 server error $= 100\%$.
* **openFDA Live Availability**: % of openFDA API requests succeeding without falling back to fixture cache $\ge 98\%$.

---

## 3. Event Taxonomy & Property Schema

All telemetry events follow the standard naming convention: `<platform>.<domain>.<action_verb>`.

### 3.1 Event Taxonomy Catalog

```
mobile.auth.invite_verified
mobile.auth.onboarding_completed
mobile.today.dose_logged
mobile.today.dose_log_undone
mobile.today.checkin_submitted
mobile.recovery.emergency_call_tapped
mobile.assistant.query_sent
mobile.assistant.guardrail_triggered
mobile.assistant.emergency_cta_tapped
mobile.fda.viewed
web.auth.login_succeeded
web.patient.invited
web.case.created
web.medication.prescribed
web.recommendation.saved
web.triage.exception_viewed
web.triage.patient_called
backend.adherence.log_created
backend.adherence.duplicate_conflict_returned
backend.ai.guardrail_intercepted
backend.fda.fallback_to_fixture_triggered
```

---

### 3.2 Detailed Telemetry Event Properties

```json
{
  "event_name": "mobile.today.dose_logged",
  "timestamp": "2026-07-22T11:37:00Z",
  "platform": "mobile",
  "app_version": "1.2.0",
  "properties": {
    "patient_hash": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
    "case_hash": "f2d81a260dea8a100dd517984e53c56a7523d96942a834b9cdc249bd4e6c7092",
    "status_enum": "taken",
    "time_delta_seconds": 120,
    "is_offline": false,
    "medication_category_enum": "analgesic"
  }
}
```

```json
{
  "event_name": "mobile.assistant.guardrail_triggered",
  "timestamp": "2026-07-22T11:37:05Z",
  "platform": "mobile",
  "app_version": "1.2.0",
  "properties": {
    "patient_hash": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
    "guardrail_rule_matched": "dosage_change_request",
    "escalate_flag_set": true
  }
}
```

---

### 3.3 Strict PHI / PII Exclusion Matrix

| Data Attribute | Included in Telemetry? | Handling / Anonymization Rule |
|---|---|---|
| **Patient Real Name** | ❌ **NEVER** | Replace with SHA-256 `patient_hash`. |
| **Drug Name** (e.g. *"Oxycodone"*) | ❌ **NEVER** | Replace with high-level category enum (`analgesic`, `antibiotic`). |
| **Exact Dose Text** (e.g. *"10mg"*) | ❌ **NEVER** | Omit entirely. |
| **Raw AI Chat Query String** | ❌ **NEVER** | Replace with matching guardrail rule name (`out_of_scope_dosage`). |
| **Clinician Notes Text** | ❌ **NEVER** | Omit entirely. |
| **Device IP Address** | ❌ **NEVER** | Anonymize/truncate last octet before storage. |

---

## 4. Analytics Dashboard Requirements

### 4.1 Clinician Operational Triage Board (Real-Time)
* **Widget 1 (Critical Red Counter)**: Live count of unreviewed patients with $\ge 2$ missed doses, "Bad" check-ins, or AI emergency flags.
* **Widget 2 (Warning Amber Counter)**: Live count of patients with skipped doses due to side effects or adherence $<80\%$.
* **Widget 3 (Response Time Gauge)**: Median seconds taken to view Red triage alerts today (Target: $<60$ seconds).

### 4.2 Product & UX Health Board (Weekly Aggregate)
* **Widget 1 (North-Star Gauge)**: 30-Day Safe Adherence Rate trend graph (Target: $\ge 85\%$).
* **Widget 2 (Onboarding Funnel)**: Step 1 code entry $\rightarrow$ Step 3 completion percentage (Target: $\ge 90\%$).
* **Widget 3 (AI Guardrail & Emergency Call Rate)**: Total guardrail triggers vs. Emergency phone CTA taps.

---

## 5. Experimentation Guardrails

When running A/B tests on UI features, the following non-negotiable experiment guardrails MUST be enforced:

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│                           EXPERIMENT GUARDRAIL RULES                             │
├──────────────────────────────────────────────────────────────────────────────────┤
│ 1. NO variant may obscure, delay, or remove the Clinician Emergency Contact card. │
│ 2. NO variant may introduce streak counters, gamification badges, or shame copy. │
│ 3. If a variant reduces On-Time Dose Log Rate by >2%, the test must auto-stop.   │
│ 4. If a variant increases Unhandled Side-Effect Rate by >1%, the test auto-stops.│
└──────────────────────────────────────────────────────────────────────────────────┘
```
