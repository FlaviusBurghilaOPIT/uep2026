# Remote CarePro — Shared Content-Design System

**Document ID:** `docs/ux/06-content-system.md`  
**Generated Date:** 2026-07-22  
**Role:** Lead Product, UX, and Technical-Design Agent  
**Status:** Approved Shared Content System

---

## 1. Voice & Ethical Copy Framework

Remote CarePro bridges clinical care and home recovery. The words used across mobile and web interfaces directly impact patient trust, adherence, and emotional safety.

### 1.1 Voice Attributes

* **Calm**: Reassuring and unhurried. Reduces anxiety for fatigued post-surgery patients.
* **Direct**: Clear, objective, and operational. Says what needs to be done without fluff.
* **Respectful**: Honors patient autonomy. Treats compliance as a partnership, not an obligation.
* **Non-Judgmental**: Objective reporting of dose events (`Skipped`/`Missed`) without guilt or shame.
* **Plain Language**: 8th-grade reading level. Replaces medical jargon with accessible everyday words.
* **Clinically Bounded**: Strictly informational. Never oversteps clinical authority or simulates medical diagnosis.

### 1.2 The Six Mandatory "Never" Rules

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│                               THE SIX "NEVER" RULES                              │
├──────────────────────────────────────────────────────────────────────────────────┤
│ 1. NEVER imply diagnosis or offer diagnostic interpretations of symptoms.         │
│ 2. NEVER instruct a patient to change, double, or stop a medication dose.       │
│ 3. NEVER create false urgency, countdown timers, or pressure-driven copy.        │
│ 4. NEVER blame, shame, or scold a patient for a missed or skipped dose.          │
│ 5. NEVER present AI-generated replies as clinician-authored content.            │
│ 6. NEVER hide data uncertainty, regulatory sources, or freshness timestamps.     │
└──────────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Production Copy Dictionary

Every user-facing string in Remote CarePro is documented below with strict keying, platform targeting, UI context, exact production copy, dynamic parameters, max-length limits, and governance flags.

---

### Category 1: Clinician Invite (Web & Mobile)

| String Key | Platform | UI Context | Production Copy | Dynamic Parameters | Max-Length | Review Flag |
|---|---|---|---|---|---|---|
| `auth.invite.title` | Web | Invite Patient Page Header | `Invite New Patient` | None | 30 chars | `[LOCALIZATION_READY]` |
| `auth.invite.success_title` | Web | Invite Confirmation Title | `Patient Invitation Sent ✓` | None | 35 chars | `[LOCALIZATION_READY]` |
| `auth.invite.code_label` | Web / Mobile | 6-Digit Code Label | `6-Digit Invitation Code:` | None | 30 chars | `[LOCALIZATION_READY]` |
| `auth.invite.code_subtext` | Web | Instructions below code | `Provide this code to {patientName} to complete onboarding in the mobile app.` | `{patientName}` | 100 chars | `[LOCALIZATION_READY]` |
| `auth.invite.error_exists` | Web | Form submission error | `An account with the email {email} already exists. Check the patient directory.` | `{email}` | 100 chars | `[LOCALIZATION_READY]` |

---

### Category 2: Patient Onboarding (Mobile)

| String Key | Platform | UI Context | Production Copy | Dynamic Parameters | Max-Length | Review Flag |
|---|---|---|---|---|---|---|
| `mobile.onboard.verify_title` | Mobile | Signup Step 1 Header | `Welcome to Remote CarePro` | None | 30 chars | `[LOCALIZATION_READY]` |
| `mobile.onboard.code_placeholder` | Mobile | Invite code input field | `Enter 6-digit code` | None | 25 chars | `[LOCALIZATION_READY]` |
| `mobile.onboard.password_title` | Mobile | Signup Step 2 Header | `Create Your Password` | None | 30 chars | `[LOCALIZATION_READY]` |
| `mobile.onboard.profile_title` | Mobile | Signup Step 3 Header | `Complete Your Profile` | None | 30 chars | `[LOCALIZATION_READY]` |
| `mobile.onboard.invalid_code` | Mobile | Step 1 error alert | `Invalid or expired invitation code. Please check your code or contact your clinic.` | None | 100 chars | `[LOCALIZATION_READY]` |

---

### Category 3: Today Page (Mobile)

| String Key | Platform | UI Context | Production Copy | Dynamic Parameters | Max-Length | Review Flag |
|---|---|---|---|---|---|---|
| `mobile.today.header_greeting` | Mobile | Today Screen Top Header | `Hello, {firstName}` | `{firstName}` | 30 chars | `[LOCALIZATION_READY]` |
| `mobile.today.adherence_summary` | Mobile | Progress Pill Badge | `{percent}% Scheduled Doses Logged` | `{percent}` | 35 chars | `[LOCALIZATION_READY]` |
| `mobile.today.next_dose_header` | Mobile | Next Due Card Title | `Next Medication Due` | None | 30 chars | `[LOCALIZATION_READY]` |
| `mobile.today.checkin_prompt` | Mobile | Check-In Feed Card | `How are you feeling today?` | None | 35 chars | `[LOCALIZATION_READY]` |

---

### Category 4: Medication Cards & Detail (Mobile & Web)

| String Key | Platform | UI Context | Production Copy | Dynamic Parameters | Max-Length | Review Flag |
|---|---|---|---|---|---|---|
| `med.card.dose_label` | Shared | Dose information label | `Dose: {dose}` | `{dose}` | 30 chars | `[LOCALIZATION_READY]` |
| `med.card.schedule_label` | Shared | Schedule text label | `Schedule: {schedule}` | `{schedule}` | 40 chars | `[LOCALIZATION_READY]` |
| `med.card.duration_label` | Shared | Prescription duration | `Duration: {duration}` | `{duration}` | 30 chars | `[LOCALIZATION_READY]` |
| `med.card.notes_header` | Shared | Clinician notes title | `Clinician Instructions:` | None | 30 chars | `[LOCALIZATION_READY]` |
| `med.card.read_only_badge` | Mobile | Prescription lock pill | `🔒 Prescribed by Care Team — Read Only` | None | 45 chars | `[CLINICAL_VALIDATION_NEEDED]` |

---

### Category 5: Reminder Notifications (Mobile OS)

| String Key | Platform | UI Context | Production Copy | Dynamic Parameters | Max-Length | Review Flag |
|---|---|---|---|---|---|---|
| `notif.reminder.title` | Mobile | Local Notification Title | `Medication Reminder` | None | 25 chars | `[LOCALIZATION_READY]` |
| `notif.reminder.body` | Mobile | Local Notification Body | `Time to take {drugName} ({dose}). Open app to log.` | `{drugName}`, `{dose}` | 80 chars | `[LOCALIZATION_READY]` |
| `notif.reminder.late_body` | Mobile | Delayed Notification | `Scheduled for {scheduledTime} — Tap to log your dose.` | `{scheduledTime}` | 80 chars | `[LOCALIZATION_READY]` |
| `notif.disabled.banner` | Mobile | Today Screen Alert | `Reminders are turned off in settings. Tap to enable notifications.` | None | 80 chars | `[LOCALIZATION_READY]` |

---

### Category 6: Dose Logging Actions & Recovery (Mobile)

| String Key | Platform | UI Context | Production Copy | Dynamic Parameters | Max-Length | Review Flag |
|---|---|---|---|---|---|---|
| `mobile.action.taken_btn` | Mobile | Primary Action Pill | `Taken` | None | 15 chars | `[LOCALIZATION_READY]` |
| `mobile.action.taken_status` | Mobile | Logged Badge Text | `Logged as Taken at {time}` | `{time}` | 35 chars | `[LOCALIZATION_READY]` |
| `mobile.action.skipped_btn` | Mobile | Secondary Action Pill | `Skipped` | None | 15 chars | `[LOCALIZATION_READY]` |
| `mobile.action.skipped_status` | Mobile | Logged Badge Text | `Logged as Skipped` | None | 25 chars | `[LOCALIZATION_READY]` |
| `mobile.action.missed_btn` | Mobile | Secondary Action Pill | `Missed` | None | 15 chars | `[LOCALIZATION_READY]` |
| `mobile.action.missed_status` | Mobile | Logged Badge Text | `Logged as Missed` | None | 25 chars | `[LOCALIZATION_READY]` |
| `mobile.action.undo_toast` | Mobile | 5-Second Snackbar | `Logged as {status}.` | `{status}` | 30 chars | `[LOCALIZATION_READY]` |
| `mobile.action.undo_btn` | Mobile | Snackbar Action Link | `Undo` | None | 10 chars | `[LOCALIZATION_READY]` |

---

### Category 7: Symptom Check-In (Mobile)

| String Key | Platform | UI Context | Production Copy | Dynamic Parameters | Max-Length | Review Flag |
|---|---|---|---|---|---|---|
| `checkin.title` | Mobile | Check-In Screen Title | `Daily Recovery Check-In` | None | 30 chars | `[LOCALIZATION_READY]` |
| `checkin.great_option` | Mobile | Feeling Option 1 Card | `Feeling Great 🙂` | None | 20 chars | `[LOCALIZATION_READY]` |
| `checkin.ok_option` | Mobile | Feeling Option 2 Card | `Feeling Ok 😐` | None | 20 chars | `[LOCALIZATION_READY]` |
| `checkin.not_great_option` | Mobile | Feeling Option 3 Card | `Not Feeling Great 😟` | None | 25 chars | `[LOCALIZATION_READY]` |
| `checkin.bad_option` | Mobile | Feeling Option 4 Card | `Feeling Unwell 😣` | None | 20 chars | `[LOCALIZATION_READY]` |
| `checkin.success_banner` | Mobile | Post-Submit Feedback | `Daily check-in logged. Thank you for updating your care team.` | None | 80 chars | `[LOCALIZATION_READY]` |

---

### Category 8: Recovery Guidance & Emergency Contact (Mobile & Web)

| String Key | Platform | UI Context | Production Copy | Dynamic Parameters | Max-Length | Review Flag |
|---|---|---|---|---|---|---|
| `recovery.contact_title` | Shared | Emergency Card Header | `Clinician Emergency Contact` | None | 35 chars | `[LOCALIZATION_READY]` |
| `recovery.emergency_btn` | Mobile | Direct Call Button | `Call Emergency Contact ({phone})` | `{phone}` | 45 chars | `[CLINICAL_VALIDATION_NEEDED]` |
| `recovery.recs_header` | Shared | Recommendations List Title| `Post-Surgery Care Instructions` | None | 35 chars | `[CLINICAL_VALIDATION_NEEDED]` |

---

### Category 9: Offline, Syncing, & Network States (Mobile)

| String Key | Platform | UI Context | Production Copy | Dynamic Parameters | Max-Length | Review Flag |
|---|---|---|---|---|---|---|
| `sync.saving_offline` | Mobile | Bottom Toast | `Saved on your device. Will update care team when online.` | None | 70 chars | `[LOCALIZATION_READY]` |
| `sync.syncing_banner` | Mobile | Top Bar Pill | `Syncing latest care plan...` | None | 35 chars | `[LOCALIZATION_READY]` |
| `sync.failed_toast` | Mobile | Error Toast | `Sync delayed. Your data is safe on this device and will retry.` | None | 75 chars | `[LOCALIZATION_READY]` |
| `sync.synced_success` | Mobile | Transient Toast | `Care plan synced with care team ✓` | None | 40 chars | `[LOCALIZATION_READY]` |

---

### Category 10: No Active Treatment Plan (Mobile)

| String Key | Platform | UI Context | Production Copy | Dynamic Parameters | Max-Length | Review Flag |
|---|---|---|---|---|---|---|
| `plan.empty_title` | Mobile | Empty State Card Title | `Care Plan Pending` | None | 30 chars | `[LOCALIZATION_READY]` |
| `plan.empty_body` | Mobile | Empty State Body Text | `Your care team is preparing your recovery plan. Check back soon or call your clinic if you have questions.` | None | 120 chars | `[LOCALIZATION_READY]` |

---

### Category 11: Medication Plan Updated (Mobile)

| String Key | Platform | UI Context | Production Copy | Dynamic Parameters | Max-Length | Review Flag |
|---|---|---|---|---|---|---|
| `plan.updated_banner` | Mobile | Banner Alert | `Your care team updated your prescribed medications. Review your list below.` | None | 90 chars | `[CLINICAL_VALIDATION_NEEDED]` |

---

### Category 12: FDA Safety Content & Metadata Badges (Mobile & Web)

| String Key | Platform | UI Context | Production Copy | Dynamic Parameters | Max-Length | Review Flag |
|---|---|---|---|---|---|---|
| `fda.summary.disclaimer` | Shared | Card Footer Disclaimer | `Informational only. Sourced from openFDA. Consult your clinician before changing medications.` | None | 110 chars | `[LEGAL_REVIEW_REQUIRED]` |
| `fda.source.live_badge` | Shared | Source Badge Tag | `📋 Source: openFDA Live` | None | 25 chars | `[LOCALIZATION_READY]` |
| `fda.source.fixture_badge`| Shared | Source Badge Tag | `📋 Source: Regulatory Cache` | None | 25 chars | `[LOCALIZATION_READY]` |
| `fda.source.freshness` | Shared | Timestamp Label | `Retrieved: {timestamp}` | `{timestamp}` | 35 chars | `[LOCALIZATION_READY]` |
| `fda.external_link_btn` | Shared | Action Button | `View on Official FDA Website` | None | 30 chars | `[LEGAL_REVIEW_REQUIRED]` |

---

### Category 13: AI Assistant Welcome, Refusal, & Handoff (Mobile & Web)

| String Key | Platform | UI Context | Production Copy | Dynamic Parameters | Max-Length | Review Flag |
|---|---|---|---|---|---|---|
| `ai.chat.disclaimer` | Shared | Chat Header Disclaimer | `AI Assistant — Informational only. Never diagnostic.` | None | 55 chars | `[LEGAL_REVIEW_REQUIRED]` |
| `ai.chat.welcome_msg` | Shared | Initial Assistant Chat Bubble| `Hello! I can answer questions about your prescribed medications and recovery instructions.` | None | 110 chars | `[CLINICAL_VALIDATION_NEEDED]` |
| `ai.chat.refusal_banner` | Shared | Red Refusal Box Title | `I Cannot Advise on Dose Changes or Urgent Symptoms` | None | 55 chars | `[LEGAL_REVIEW_REQUIRED]` |
| `ai.chat.refusal_body` | Shared | Guardrail Refusal Text | `I cannot assist with changing medication doses or diagnosing urgent symptoms — that requires clinical judgment. If you feel unwell or have urgent questions, contact your clinic or emergency contact immediately. [NEEDS CLINICAL VALIDATION]` | None | 240 chars | `[CLINICAL_VALIDATION_NEEDED]` |
| `ai.chat.emergency_btn` | Mobile / Web | Guardrail Action CTA | `Call Emergency Contact ({phone})` | `{phone}` | 45 chars | `[CLINICAL_VALIDATION_NEEDED]` |

---

### Category 14: Clinician Empty State (Web)

| String Key | Platform | UI Context | Production Copy | Dynamic Parameters | Max-Length | Review Flag |
|---|---|---|---|---|---|---|
| `web.roster.empty_title` | Web | Patients Directory Empty Title| `No Active Patients Found` | None | 30 chars | `[LOCALIZATION_READY]` |
| `web.roster.empty_body` | Web | Directory Empty Body | `Click "+ New Patient" to invite a post-surgery patient and generate their mobile invitation code.` | None | 110 chars | `[LOCALIZATION_READY]` |

---

### Category 15: Clinician Needs-Attention & Triage Badges (Web)

| String Key | Platform | UI Context | Production Copy | Dynamic Parameters | Max-Length | Review Flag |
|---|---|---|---|---|---|---|
| `web.triage.critical_missed`| Web | Red Triage Badge | `🔴 High Risk: Missed {count} Doses` | `{count}` | 35 chars | `[CLINICAL_VALIDATION_NEEDED]` |
| `web.triage.amber_skipped` | Web | Amber Triage Badge | `🟡 Warning: Skipped ({reason})` | `{reason}` | 35 chars | `[CLINICAL_VALIDATION_NEEDED]` |
| `web.triage.bad_checkin` | Web | Red Check-In Badge | `🔴 Feeling Unwell Reported` | None | 30 chars | `[CLINICAL_VALIDATION_NEEDED]` |
| `web.triage.ai_flag` | Web | AI Emergency Query Badge | `🚨 Emergency Query Flagged` | None | 30 chars | `[CLINICAL_VALIDATION_NEEDED]` |

---

### Category 16: Clinician Patient-Plan Form Validation (Web)

| String Key | Platform | UI Context | Production Copy | Dynamic Parameters | Max-Length | Review Flag |
|---|---|---|---|---|---|---|
| `web.form.required` | Web | Field Validation Error | `Please complete this required field.` | None | 40 chars | `[LOCALIZATION_READY]` |
| `web.form.invalid_email` | Web | Email Validation Error | `Enter a valid email address (e.g. patient@example.com).` | None | 55 chars | `[LOCALIZATION_READY]` |
| `web.form.med_required` | Web | Prescribing Validation | `Drug name, dose, frequency, and duration days are required.` | None | 65 chars | `[LOCALIZATION_READY]` |
| `web.form.save_success` | Web | Toast Notification | `Treatment plan saved successfully ✓` | None | 40 chars | `[LOCALIZATION_READY]` |

---

## 3. Microcopy & Pattern Guidelines

### 3.1 Button & Action Verbs
* **Primary Action Verbs**: Use explicit, user-centered verbs.  
  * *Good*: `Invite Patient`, `Add Medication`, `Save Recommendations`, `Submit Check-In`, `Taken`.  
  * *Avoid*: `Submit`, `OK`, `Continue`, `Process`.
* **Destructive Action Verbs**: Explicitly state consequences.  
  * *Good*: `Delete Medication`, `Archive Case`.  
  * *Avoid*: `Remove`, `Delete`.

### 3.2 Error & Recovery Copy Principles
* **Never Blame**: Use neutral description of system state.  
  * *Good*: *"Invalid or expired invitation code."*  
  * *Avoid*: *"You typed the wrong code."*
* **Provide Actionable Step**: Always give the user an immediate recovery action.  
  * *Good*: *"Check your code or contact your clinic for a new invite."*

---

## 4. Localization & Plain Language Audit

1. **Reading Level Compliance**: All patient-facing copy is audited to satisfy Flesch-Kincaid Grade 8 reading level (short sentences, simple active verbs).
2. **String Concatenation Prohibition**: No sentences are constructed via string concatenation (e.g. `title + count`). All dynamic strings use named curly-brace parameters (`{patientName}`, `{count}`).
3. **Legal & Clinical Governance**: Strings tagged with `[LEGAL_REVIEW_REQUIRED]` or `[CLINICAL_VALIDATION_NEEDED]` must pass formal compliance sign-off prior to production deployment.
