# Product

## Vision
RemoteCare Pro bridges the critical blind post-discharge window by providing surgical patients with a frictionless, 1-tap mobile recovery companion and clinical care teams with automated closed-loop adherence triage, Clinical AI guardrails, and real-time openFDA safety surveillance.

---

## MVP Definition
- **Included Scope**:
  - Flutter Mobile Patient Companion (Today Agenda, 1-Tap Dose Logging with 5s Undo, AI Assistant with Clinical Guardrails, Recovery Timeline, and Emergency Red Flag Escalation).
  - React/Vite Clinician Web Portal (Patient Roster, Case & Medication Authoring, Live Triage Exception Dashboard, openFDA FAERS Adverse Event Surveillance, and Sandbox Demo).
  - FastAPI + PostgreSQL backend with pgvector RAG, SSE chat streaming, and adherence write APIs.
- **Deliberately Excluded (Out of Scope)**:
  - Commercial tier gating / in-app paywalls (100% of capabilities are included for licensed clinics).
  - Direct diagnostic medical advice from AI (strictly guarded as non-diagnostic informational support).
  - Complex multi-step manual onboarding questionnaires for post-op patients (streamlined to 3-step discharge code auth).

---

## Outcome Roadmap (Steve Jobs Review Cut & Fix List)

| Outcome / Problem | Job Served | Priority | Status |
|---|---|---|---|
| **Cut 1: Remove artificial paywalls / tier modals** | Clean institutional deployment; 100% all-inclusive clinical license | P0 (Critical Cut) | Done |
| **Cut 2: Strip repetitive chat bubble disclaimers** | Eliminate chat clutter; replace with persistent top clinical safety seal | P0 (Critical Cut) | Done |
| **Cut 3: Eliminate blocking confirmation dialogs on dose logging** | Frictionless 1-tap daily habit loop with 5s non-blocking Undo snackbar | P0 (Critical Cut) | Done |
| **Cut 4: Deprecate raw decimal metric displays** | Instant clinician glanceability with high-contrast triage status pills | P1 (Visual Cut) | Done |
| **Fix 1: Emergency Red Flag Direct Dial Banner** | Patient safety; direct 1-tap call (911 / Clinic Direct) on acute symptoms | P0 (Safety Gate) | Done |
| **Fix 2: Sub-100ms Optimistic Dose Logging & Haptics** | Instant patient feedback; zero perceived network latency | P0 (Daily Loop) | Done |
| **Fix 3: "Day Complete" Ring Closure Signature Moment** | Emotional validation & closure for recovering post-op patients | P1 (Polish) | Done |
| **Fix 4: Empathetic Back-of-the-Fence Empty & Error States** | Reassuring human copy during offline mode or empty schedules | P1 (Polish) | Done |
| **Fix 5: Constrained Medication Authoring Controls** | Prevent clinician schedule slips via standardized clinical time slots | P1 (Clinical Safety) | Done |

---

## Opportunity Solution Tree Notes
- **Desired Outcome**: Post-op medication adherence >92% with sub-60s clinician intervention on missed antibiotic/anticoagulant doses.
  - **Opportunity 1 (Patient Activation)**: Patients forget to log doses when groggy.
    - *Solution*: 1-tap notification response + instant optimistic checkmark pop + SMS magic access code.
  - **Opportunity 2 (Patient Reassurance)**: Patients panic over mild surgical aches or side effects.
    - *Solution*: 24/7 Clinical guardrailed assistant with explicit clinical protocol grounding and red-flag 911 escalation.
  - **Opportunity 3 (Clinician Triage Efficiency)**: Clinicians overwhelmed by checking patient profiles one-by-one.
    - *Solution*: Unified high-density Triage Dashboard matrix with 1-click quick-outreach phone/SMS modal.

---

## Hook Model
- **Trigger**:
  - *External*: Scheduled push notification at 08:00 AM ("Morning Dose Due: Amoxicillin 500mg").
  - *Internal*: Post-discharge anxiety and desire to heal safely without complications.
- **Action**: Open app → 1 tap on `[Log Taken]` (<2 seconds total friction).
- **Variable Reward**: Satisfying sub-100ms checkmark bounce + daily progress ring closure + calming reassurance message.
- **Investment**: Building unbroken 14-day adherence streak and logging symptoms for the surgeon's review.

---

## Activation & Retention Plan

| Friction / Moment | Fix | Owner | Status |
|---|---|---|---|
| Day-1 Hospital Discharge Sign-In | 6-digit access key auto-paste with auto-submit on 6th digit | Mobile Eng | Done |
| Accidental Skip Slip | 5-second non-blocking Undo snackbar on dose slot | Mobile Eng | Done |
| Poor Connectivity / Wi-Fi Drops | Offline SQLite queue with persistent sync badge | Mobile / Backend | Done |
| Clinical Triage Bottleneck | 1-Click resolve dialog with pre-populated outreach templates | Web Eng | Done |
| Acute Symptom Emergency | Red Flag 1-tap direct dial banner | Product / Design | Done |

---

## Discovery Cadence
- **Weekly Clinical Cohort Review**: Review real-time adherence telemetries and triage response logs every Monday with clinical leads.
- **Bi-Weekly Patient Usability Walkthroughs**: Test onboarding and dose logging with recently discharged post-op patients to verify 0-friction execution.
