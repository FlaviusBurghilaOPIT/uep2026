# Remote CarePro — Cross-Product User Journeys

**Document ID:** `docs/product/04-cross-product-journeys.md`  
**Generated Date:** 2026-07-22  
**Role:** Lead Product, UX, and Technical-Design Agent  
**Status:** Approved User Journeys Specification

---

## 1. Overview & Navigation System

This document specifies the complete, linked user journeys across both the **Flutter Patient Mobile App** and the **React Clinician Web Dashboard**. Every journey maps entry points, emotional states, sequential screens, actions, information requirements above the fold, API dependencies, state variations, accessibility constraints, completion criteria, and acceptance test rules.

---

## 2. Patient Mobile Journeys (Flutter)

---

### Journey M-01: Invite Acceptance and First Login

* **Entry Point**: Patient receives a 6-digit invite code (e.g. `849201`) from their clinician, downloads/opens the Flutter app, landing on `OnboardingScreen` (`/onboarding`).
* **User Goal & Emotional State**:  
  * *Goal*: Activate account effortlessly and view prescribed post-surgery plan.  
  * *Emotional State*: Anxious, post-surgery fatigue, cautious, seeking reassurance.
* **Screens in Order**:  
  1. `OnboardingScreen` (`/onboarding`) $\rightarrow$ Tap **Sign Up**
  2. `SignupStep1Screen` (`/signup/step1`) $\rightarrow$ Enter Email & 6-Digit Invite Code
  3. `SignupStep2Screen` (`/signup/step2`) $\rightarrow$ Create Password
  4. `SignupStep3Screen` (`/signup/step3`) $\rightarrow$ Enter Date of Birth & Phone
  5. `MainShellPage` (`/main` $\rightarrow$ `TodayScreen`)
* **Primary Action**: Submit invite verification $\rightarrow$ Submit password $\rightarrow$ Complete profile.
* **Secondary Actions**: Tap "Log In" (if account exists), view Privacy Statement.
* **Information Required Above the Fold**: Clean app title, single invitation code card, auto-focused 6-digit text input with visual character spacing.
* **Data / API Dependencies**:  
  * `POST /auth/verify-invite` with `{ email, invite_code }`.
  * `POST /auth/complete-onboarding` with `{ email, invite_code, password, date_of_birth, phone }`.
* **States**:  
  * *Empty*: Initial blank form fields.  
  * *Loading*: Submit button changes to spinner (*"Verifying..."*).  
  * *Offline*: Banner: *"No connection. Connect to internet to activate account."*  
  * *Error*: Alert banner: *"Invalid or expired invitation code."*  
  * *Success*: Transitions to `/main` with saved JWT.  
  * *Stale*: N/A.
* **Accessibility Constraints**: Minimum 48×48dp touch targets; `Semantics` tags on step indicators; dynamic font scale (up to 200%); high contrast ($\ge 4.5:1$).
* **Completion Definition**: Patient account status becomes `active`, Bearer JWT is saved in `flutter_secure_storage`, and app lands on `TodayScreen`.
* **Acceptance Criteria**: Entering valid email + 6-digit code completes 3-step signup and displays `TodayScreen` without errors.

---

### Journey M-02: Today: Understand Next Action in Under 3 Seconds

* **Entry Point**: Patient launches app or selects **Today** tab (Tab 0).
* **User Goal & Emotional State**:  
  * *Goal*: Instantly identify the next medication dose due right now without reading dense text.  
  * *Emotional State*: Fatigued, seeking immediate clarity, low cognitive energy.
* **Screens in Order**: `MainShellPage` (`TodayScreen` - Tab 0).
* **Primary Action**: View top active dosage timecard due next.
* **Secondary Actions**: Tap "Taken", "Missed", or "Skipped" buttons on timecard; switch tabs.
* **Information Required Above the Fold**: Patient greeting ("Hello Maria"), overall daily adherence progress pill (e.g. `100%`), next due medication timecard featuring bold drug name, dose, schedule, due time, and prominent 1-tap **Taken** button.
* **Data / API Dependencies**: `GET /patients/{id}/case`, `GET /cases/{case_id}/medications`, `GET /adherence/patients/{id}`.
* **States**:  
  * *Empty*: Calm card: *"Your care plan is being prepared by your clinic."*  
  * *Loading*: Skeleton shimmer cards.  
  * *Offline*: Top pill: *"Showing cached plan."*  
  * *Error*: Banner: *"Could not load regimen. Tap to retry."*  
  * *Success*: Rendered timecards.  
  * *Stale*: Subtitle: *"Updated today at 08:00 AM"*.
* **Accessibility Constraints**: Screen reader reading order: Next Medication $\rightarrow$ Dose $\rightarrow$ Due Time $\rightarrow$ Action Buttons. High color contrast.
* **Completion Definition**: Patient comprehends their next due dose in $<3$ seconds without scrolling.
* **Acceptance Criteria**: Top card displays earliest pending medication with bold name, due time, and 1-tap action buttons.

---

### Journey M-03: Reminder -> Taken

* **Entry Point**: Local notification arrives on device screen (*"Time for Ibuprofen 400mg"*).
* **User Goal & Emotional State**:  
  * *Goal*: Confirm dose taken in 1 tap and return to resting.  
  * *Emotional State*: Passive, wants minimal friction.
* **Screens in Order**: OS Notification $\rightarrow$ `TodayScreen`.
* **Primary Action**: Tap **Taken** pill button on medication card.
* **Secondary Actions**: Tap "Undo" (within 5 seconds).
* **Information Required Above the Fold**: Medication name, dose, frequency, immediate **Taken** green action button.
* **Data / API Dependencies**: `POST /adherence/log` with `{ scheduled_reminder_id, status: "taken" }`.
* **States**:  
  * *Loading*: Optimistic UI update ($<100$ms).  
  * *Offline*: Queued in local SQLite `PendingQueueTable` + sync toast.  
  * *Success*: Card transitions to solid green checkmark (*"Taken at 08:30 AM"*).  
  * *Error*: Background retry runner attempts re-send.
* **Accessibility Constraints**: 48dp touch target, haptic vibration feedback on tap, screen reader announcement: *"Ibuprofen marked as taken"*.
* **Completion Definition**: `DoseLog` record created; adherence percentage increments immediately.
* **Acceptance Criteria**: Tapping "Taken" updates card state in $<100$ms optimistically and posts to `/adherence/log`.

---

### Journey M-04: Reminder -> Skipped / Missed / I Need Help

* **Entry Point**: Patient receives local reminder or opens `TodayScreen` for a problematic dose.
* **User Goal & Emotional State**:  
  * *Goal*: Accurately report non-adherence or seek help without feeling judged or shamed.  
  * *Emotional State*: Discomfort, side effects, or confusion.
* **Screens in Order**: `TodayScreen` $\rightarrow$ Reason Selection Modal $\rightarrow$ Emergency Contact Sheet (if help requested).
* **Primary Action**: Tap **Skipped** or **Missed** button.
* **Secondary Actions**: Select reason ("Side effects", "Ran out"), tap **Call Emergency Contact**.
* **Information Required Above the Fold**: Non-judgmental status buttons, prominent **Call Emergency Contact** button.
* **Data / API Dependencies**: `POST /adherence/log` (`status: "skipped"` | `"missed"`), `GET /cases/{id}/emergency-contact`.
* **States**:  
  * *Success*: Card transitions to Amber (*"Skipped"*) or Red (*"Missed"*) badge without shame copy.  
  * *Error*: Queued offline.
* **Accessibility Constraints**: Dual text + icon indicators (cross icon alongside color), clear focus indicators.
* **Completion Definition**: Non-adherence log stored; if severe side effects selected, direct phone dialer opens.
* **Acceptance Criteria**: Selecting "Skipped" logs reason without shame copy; selecting severe side effects surfaces emergency phone CTA.

---

### Journey M-05: Medication Detail and Clinician-Authored Instructions

* **Entry Point**: Patient taps any medication card on `TodayScreen` or `RecoveryScreen`.
* **User Goal & Emotional State**:  
  * *Goal*: Read exact clinician instructions for a specific prescribed medication.  
  * *Emotional State*: Seeking reassurance, verifying instructions (*"take with food"*).
* **Screens in Order**: `TodayScreen` $\rightarrow$ Medication Detail Sheet.
* **Primary Action**: Read clinician notes and schedule details.
* **Secondary Actions**: Tap **FDA Safety Info** link, view duration.
* **Information Required Above the Fold**: Drug name header, prescribed dose, schedule text, duration, clinician notes, read-only lock badge (*"Prescribed by Clinician — Read Only"*).
* **Data / API Dependencies**: `GET /cases/{case_id}/medications`.
* **States**:  
  * *Loading*: Card skeleton.  
  * *Offline*: Rendered from cached SQLite store.  
  * *Success*: Detail sheet displayed.
* **Accessibility Constraints**: Readable font contrast, explicit screen reader announcement of clinician notes.
* **Completion Definition**: Patient reads full prescription notes.
* **Acceptance Criteria**: Screen clearly indicates "Prescribed by Dr. [Name] — Read Only" with exact dosage instructions.

---

### Journey M-06: Daily Symptom Check-In

* **Entry Point**: Patient taps **Check-In** tab (Tab 1) on `MainShellPage`.
* **User Goal & Emotional State**:  
  * *Goal*: Record daily recovery feeling in 1 tap to inform care team.  
  * *Emotional State*: Reflective, sore, or hopeful.
* **Screens in Order**: `MainShellPage` (`CheckInScreen` - Tab 1).
* **Primary Action**: Select 1 of 4 feeling options (`Great`, `Ok`, `Not Great`, `Bad`) $\rightarrow$ Tap **Submit Check-In**.
* **Secondary Actions**: View recent check-in history summary.
* **Information Required Above the Fold**: Prompt: *"How do you feel today?"*, 4 large option cards with emojis/icons, **Submit Check-In** primary button.
* **Data / API Dependencies**: `POST /symptoms/checkin` with `{ case_id, feeling }`.
* **States**:  
  * *Empty*: Unsubmitted state for today.  
  * *Success*: Card updates: *"Check-in logged for today ✓"*.  
  * *Disabled*: Form disabled if already submitted today.  
  * *Offline*: Log queued in local SQLite.
* **Accessibility Constraints**: High contrast, dual text + icon labels, screen reader announces: *"Option Great selected, 1 of 4"*.
* **Completion Definition**: `CheckIn` row saved; submission disabled until next calendar day.
* **Acceptance Criteria**: Selecting a feeling option and tapping Submit records check-in and updates UI to "Logged for Today".

---

### Journey M-07: Recovery Recommendations and Task Progress

* **Entry Point**: Patient taps **Recovery** tab (Tab 3) on `MainShellPage`.
* **User Goal & Emotional State**:  
  * *Goal*: Review non-medication care instructions (wound care, ice, activity limits) and clinic contact info.  
  * *Emotional State*: Seeking structured recovery guidance.
* **Screens in Order**: `MainShellPage` (`RecoveryScreen` - Tab 3).
* **Primary Action**: Read recovery recommendations and emergency contact card.
* **Secondary Actions**: Tap **Call Emergency Contact** button, view FDA summaries.
* **Information Required Above the Fold**: Clinician Emergency Contact Card (Name, Phone, Direct Call Button), structured Recovery Recommendations list.
* **Data / API Dependencies**: `GET /cases/{case_id}/recommendations`, `GET /cases/{case_id}/emergency-contact`.
* **States**:  
  * *Empty*: Card: *"No additional instructions added yet."*  
  * *Loading*: Skeleton shimmer.  
  * *Offline*: Rendered from local cache.
* **Accessibility Constraints**: Clear section headings, accessible tap-to-call phone link.
* **Completion Definition**: Patient views complete recovery instructions and emergency phone card.
* **Acceptance Criteria**: Screen presents emergency contact info at top and bulleted clinician recommendations below.

---

### Journey M-08: AI Assistant, Refusal, and Safe Handoff

* **Entry Point**: Patient taps **Assistant** tab (Tab 2) on `MainShellPage`.
* **User Goal & Emotional State**:  
  * *Goal*: Ask a natural-language question about medications or recovery.  
  * *Emotional State*: Uncertain, seeking quick answer.
* **Screens in Order**: `MainShellPage` (`AssistantScreen` - Tab 2).
* **Primary Action**: Type query in input field and tap **Send**.
* **Secondary Actions**: Tap pre-set suggested questions, tap **Call Emergency Contact** when guardrail triggers.
* **Information Required Above the Fold**: Chat conversation list, disclaimer header: *"Informational only — never diagnostic"*, text input field.
* **Data / API Dependencies**: `POST /ai/chat` with `{ case_id, message }`.
* **States**:  
  * *Loading*: Typing bubble (*"Thinking..."*).  
  * *Guardrail Refusal*: Red-bordered refusal box + **Call Emergency Contact** button.  
  * *Success*: Contextual answer bubble rendered.
* **Accessibility Constraints**: Screen reader announces incoming messages; high-contrast refusal callout box.
* **Completion Definition**: Query answered or guardrail triggered with safe emergency handoff.
* **Acceptance Criteria**: Safe questions get contextual answers; dosage-change/diagnostic questions trigger guardrail refusal and emergency phone CTA.

---

### Journey M-09: FDA Safety Information

* **Entry Point**: Patient taps **FDA Info** from `RecoveryScreen` or Medication Detail.
* **User Goal & Emotional State**:  
  * *Goal*: Review official regulatory safety warnings for prescribed drugs.  
  * *Emotional State*: Cautious, wanting regulatory context.
* **Screens in Order**: `RecoveryScreen` / `FDAPage`.
* **Primary Action**: Read bulleted plain-language safety summary and warnings.
* **Secondary Actions**: Tap **View on Official FDA Site** external link.
* **Information Required Above the Fold**: Drug name header, Source Badge (`openFDA` / `Fixture`), Freshness Timestamp, Bulleted Warnings, Disclaimer text.
* **Data / API Dependencies**: `GET /fda/drug/{name}`.
* **States**:  
  * *Loading*: Card: *"Fetching FDA data..."*  
  * *Fallback*: *"FDA live updates unavailable — showing cached warnings."*  
  * *Success*: FDA safety card rendered.
* **Accessibility Constraints**: High-contrast warning callout box, clear external link label.
* **Completion Definition**: Patient views FDA safety summary and regulatory source metadata.
* **Acceptance Criteria**: Renders plain-language warnings with explicit source badge and timestamp.

---

## 3. Clinician Web Journeys (React + TypeScript)

---

### Journey W-01: Create Patient and Invite

* **Entry Point**: Clinician clicks **+ New Patient** on `/patients` header.
* **User Goal & Emotional State**:  
  * *Goal*: Register a post-surgery patient and generate a 6-digit invite code.  
  * *Emotional State*: Efficient, clinical focus.
* **Screens in Order**: `/patients` $\rightarrow$ `/patients/new` (`CreatePatientPage.tsx`).
* **Primary Action**: Enter Name, Email, Surgery Type, Emergency Phone $\rightarrow$ Click **Invite Patient**.
* **Secondary Actions**: Click **Cancel** (returns to `/patients`).
* **Information Required Above the Fold**: Page title *"Invite New Patient"*, required fields marked with asterisks, **Invite Patient** primary button.
* **Data / API Dependencies**: `POST /patients/invite`.
* **States**:  
  * *Loading*: Button updates to *"Inviting..."*.  
  * *Error*: Alert text: *"User with this email already exists"*.  
  * *Success*: **Patient Invited ✓** card showing 6-digit code in 32px text.
* **Accessibility Constraints**: ARIA labels on form inputs, keyboard tab navigation order, high contrast.
* **Completion Definition**: Patient and Case created in DB with 6-digit code displayed.
* **Acceptance Criteria**: Submitting valid form creates `User` & `Case` and displays 6-digit code.

---

### Journey W-02: Create/Edit Medication and Recovery Plan

* **Entry Point**: Clinician clicks **+ New Case** or **Medications** / **Recommendations** on a patient card in `/patients`.
* **User Goal & Emotional State**:  
  * *Goal*: Prescribe medications and write recovery instructions for a case.  
  * *Emotional State*: Precise, authoritative.
* **Screens in Order**: `/patients` $\rightarrow$ `/cases/new` $\rightarrow$ `/cases/:caseId/medications` $\rightarrow$ `/cases/:caseId/recommendations`.
* **Primary Action**: Enter drug name, dose, frequency, duration $\rightarrow$ Click **Add Medication**; type instructions $\rightarrow$ Click **Save Recommendations**.
* **Secondary Actions**: Click **FDA Check**, toggle AI assistant drawer in recommendations page.
* **Information Required Above the Fold**: Surgery type header, medication form inputs, prescribing action buttons.
* **Data / API Dependencies**: `POST /cases/{case_id}/medications`, `POST /cases/{case_id}/recommendations`, `POST /ai/chat`.
* **States**:  
  * *Loading*: Button shows *"Adding..."* / *"Saving..."*.  
  * *Success*: Confirmation card (*"Medication Added ✓"*).  
  * *Error*: Red alert: *"Please fill in required fields"*.
* **Accessibility Constraints**: Explicit `htmlFor` form labels, visible focus outline.
* **Completion Definition**: Medication and recommendation records saved in DB for target case.
* **Acceptance Criteria**: Prescribed meds and recs persist in backend and link to case ID.

---

### Journey W-03: View Patient List

* **Entry Point**: Clinician navigates to `/patients` after login.
* **User Goal & Emotional State**:  
  * *Goal*: View all managed post-surgery patients and active cases.  
  * *Emotional State*: Scanning, organizing.
* **Screens in Order**: `/patients` (`PatientsPage.tsx`).
* **Primary Action**: Scan patient cards and nested case details.
* **Secondary Actions**: Click **+ New Patient**, **+ New Case**, **Medications**, **Recommendations**.
* **Information Required Above the Fold**: Header title *"Patients"*, **+ New Patient** CTA, list of patient cards with Name, DOB, Allergies, Case Status.
* **Data / API Dependencies**: `GET /patients`, `GET /cases`.
* **States**:  
  * *Empty*: Text: *"No patients found"*.  
  * *Loading*: Text: *"Loading..."*  
  * *Error*: Alert: *"Failed to fetch data"*.
* **Accessibility Constraints**: Accessible card/table layout, distinct action button labels.
* **Completion Definition**: Clinician views complete patient roster.
* **Acceptance Criteria**: Displays all patients and associated active cases fetched from API.

---

### Journey W-04: Identify "Needs Attention" Patients

* **Entry Point**: Clinician views `/patients` roster or dashboard triage view.
* **User Goal & Emotional State**:  
  * *Goal*: Identify non-adherent patients or troubling symptom check-ins at a glance.  
  * *Emotional State*: Alert, triage mindset.
* **Screens in Order**: `/patients` (Triage Filtered View).
* **Primary Action**: Scan for Red/Amber status badges (*"Low Adherence"*, *"Skipped — Side Effects"*, *"Bad Check-In"*).
* **Secondary Actions**: Click patient card to view detailed logs or call phone.
* **Information Required Above the Fold**: Color-coded triage indicators (Red = Missed 2+ doses / Bad check-in; Amber = Skipped / Low adherence; Green = Compliant).
* **Data / API Dependencies**: `GET /adherence/patients/{id}`, `GET /symptoms/patients/{id}/symptoms/trend`.
* **States**:  
  * *Loading*: Status skeletons.  
  * *Success*: Triage badges rendered.
* **Accessibility Constraints**: Dual Color + Text indicators (*"Red — Missed 2 Doses"*, never color alone).
* **Completion Definition**: Clinician isolates high-risk patients needing intervention.
* **Acceptance Criteria**: Triage status badges render accurately based on dose logs and check-ins.

---

### Journey W-05: Review Patient Detail and Adherence History

* **Entry Point**: Clinician clicks **Medications**, **Recommendations**, or adherence status on a patient card in `/patients`.
* **User Goal & Emotional State**:  
  * *Goal*: Inspect complete dose history, check-in trends, and active treatment plan.  
  * *Emotional State*: Evaluative, thorough.
* **Screens in Order**: `/patients` $\rightarrow$ `/cases/:caseId/medications/list` / `/cases/:caseId/recommendations/list`.
* **Primary Action**: Review timeline of taken, missed, and skipped doses alongside daily check-in ratings.
* **Secondary Actions**: Add new medication, update recovery recommendations, review FDA warnings.
* **Information Required Above the Fold**: Patient Name, Case Surgery Type, Adherence Percentage, Detailed Log List with timestamps.
* **Data / API Dependencies**: `GET /cases/{case_id}/medications`, `GET /adherence/patients/{id}`, `GET /symptoms/patients/{id}/symptoms`.
* **States**:  
  * *Loading*: Log skeleton.  
  * *Empty*: *"No dose logs recorded yet."*  
  * *Success*: History rendered.
* **Accessibility Constraints**: Accessible timeline table, clean typography contrast.
* **Completion Definition**: Clinician evaluates adherence pattern.
* **Acceptance Criteria**: Displays accurate historical log records and check-in trends for patient.

---

### Journey W-06: Record or Initiate Follow-Up

* **Entry Point**: Patient detail view or triage alert card on `/patients`.
* **User Goal & Emotional State**:  
  * *Goal*: Contact non-compliant or symptomatic patient via phone/email and adjust care plan if necessary.  
  * *Emotional State*: Proactive, care-oriented.
* **Screens in Order**: `/patients` $\rightarrow$ Phone Dialer / Edit Treatment Plan (`/cases/:caseId/medications`).
* **Primary Action**: Click patient emergency phone link or modify prescription.
* **Secondary Actions**: Adjust recovery recs, add clinician note.
* **Information Required Above the Fold**: Patient Phone Number, Emergency Contact Phone, **Call Patient** quick action button.
* **Data / API Dependencies**: `GET /cases/{case_id}/emergency-contact`, `POST /cases/{case_id}/medications`.
* **States**:  
  * *Success*: System dialer opened / Medication updated.
* **Accessibility Constraints**: Clickable `tel:` links, explicit action button labels.
* **Completion Definition**: Clinician contacts patient or modifies treatment plan to resolve exception.
* **Acceptance Criteria**: Tapping phone link opens system dialer with correct phone number.

---

## 4. Complete Screen Catalog

### 4.1 Mobile Screens (Flutter)

```
mobile/lib/
├── features/
│   ├── auth/
│   │   ├── onboarding_screen.dart       # Screen M-01: Welcome carousel & entry portal (/onboarding)
│   │   ├── login_screen.dart            # Screen M-02: Direct credentials login (/login)
│   │   ├── signup_step1_screen.dart     # Screen M-03: Invite code & email verification (/signup/step1)
│   │   ├── signup_step2_screen.dart     # Screen M-04: Password creation (/signup/step2)
│   │   ├── signup_step3_screen.dart     # Screen M-05: DOB & phone profile completion (/signup/step3)
│   │   └── forgot_password_screen.dart # Screen M-06: Password recovery request (/forgot-password)
│   │
│   ├── main/
│   │   └── main_shell_page.dart         # Screen M-07: IndexedStack container with bottom navigation (/main)
│   │
│   ├── today/
│   │   └── today_screen.dart            # Screen M-08: Daily agenda, medication cards, 1-tap dose logging (Tab 0)
│   │
│   ├── checkin/
│   │   └── checkin_screen.dart          # Screen M-09: Daily feeling 4-option check-in form (Tab 1)
│   │
│   ├── assistant/
│   │   └── assistant_screen.dart        # Screen M-10: AI RAG chat interface with guardrails & emergency CTA (Tab 2)
│   │
│   ├── recovery/
│   │   └── recovery_screen.dart         # Screen M-11: Clinician recs, emergency contact card, FDA info (Tab 3)
│   │
│   └── profile/
│       └── profile_screen.dart          # Screen M-12: User profile settings, language selector, logout (/profile)
```

### 4.2 Web Screens (React + TypeScript)

```
web/src/pages/
├── LoginPage.tsx                        # Screen W-01: Clinician portal login page (/login)
├── PatientsPage.tsx                     # Screen W-02: Patient overview roster & triage indicators (/patients)
├── CreatePatientPage.tsx                # Screen W-03: Patient invitation & 6-digit invite code generator (/patients/new)
├── CreateCasePage.tsx                   # Screen W-04: New case surgery type selection (/cases/new)
├── MedicationsPage.tsx                  # Screen W-05: Medication prescribing form with FDA link (/cases/:caseId/medications)
├── MedicationsListPage.tsx              # Screen W-06: Case medications roster (/cases/:caseId/medications/list)
├── RecommendationsPage.tsx              # Screen W-07: Recovery instruction editor + AI drawer (/cases/:caseId/recommendations)
├── RecommendationsListPage.tsx          # Screen W-08: Case recommendations roster (/cases/:caseId/recommendations/list)
└── FDAPage.tsx                          # Screen W-09: Standalone openFDA drug safety search & AI summary tool (/fda)
```
