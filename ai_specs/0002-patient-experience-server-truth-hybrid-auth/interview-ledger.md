---
type: Interview Ledger
parent: spec.md
---

## Records

### L1

Status: current

Question: How should a patient authenticate — passwordless (the existing approved design) or password-based?

Recommended Answer:
- Hybrid: the patient sets a password at onboarding after the emailed code verifies their email; returning login offers email+password (default) or an emailed one-time code (fallback).
- This reverses the passwordless decision in `ai_specs/2026-07-25-patient-first-run-flow-spec.md` and `docs/superpowers/specs/2026-07-23-dev-stack-and-patient-auth-cleanup-design.md`.

Answer: hybrid

Decision: Patient authentication is hybrid — a password set at onboarding plus a code fallback; both methods land on Today.

Reason: The owner chose a persistent credential for convenience while keeping the code path as a safety net for an elderly post-surgery population.

Negative Requirements:
- Not password-only; the code path must remain available.

### L2

Status: current

Question: Which patient details should the clinician capture at case creation so the patient sees them pre-filled and editable?

Recommended Answer:
- The clinician form gains date_of_birth (required); patient onboarding shows name + DOB pre-filled and editable; phone stays patient-provided.

Answer: i agree with dob prefilled editable, and dob is required of course

Decision: The clinician captures a required DOB at case creation; the patient sees name + DOB pre-filled and editable; phone is patient-provided (pre-filled only if captured).

Reason: The core requirements make the clinician the source of truth ("the patient receives everything automatically"); the dashboard already renders DOB as "N/A" because nothing populated it.

### L3

Status: current

Question: With hybrid auth, build a standalone "Forgot password" reset flow now or defer it?

Recommended Answer:
- Defer standalone forgot-password; the email-code login path is account recovery; add a "Change password" action in the Profile for authenticated users.

Answer: agree, defer it and add change password in profile

Decision: No standalone forgot-password flow; the code-login path is recovery; the Profile gains a "Change password" action.

Reason: In hybrid auth the patient always has a passwordless way in, so a forgotten password is not a lockout; this also avoids resurrecting the route the 2026-07-23 design deliberately deleted.

Negative Requirements:
- Do not build a separate password-reset screen or endpoint in this effort.

### L4

Status: current

Question: For Recovery content with no backend source (milestones, "Day N", warning-signs box), build new backend endpoints now or remove until supported?

Recommended Answer:
- Apply server-truth / real-data-or-honest-absence: care instructions ← `/cases/{id}/recommendations`, chart ← real adherence, header ← real case/auth, Day N + surgery date ← surgery_date captured at intake [L7]; remove the fabricated milestones timeline and warning-signs box; extend `AppSkeletonLoader` + empty/error states; defer a structured Milestone model and authored warning signs.

Answer: proceed with recommended answers

Decision: Recovery renders only server truth. Care instructions/chart/header/Day N are wired to real data; the fabricated milestones timeline and warning-signs box are removed (honest absence); loading uses `AppSkeletonLoader` with empty/error states.

Reason: Matches the today-screen-hardening "no fabricated clinical data under the clinic's name" safety bar.

Negative Requirements:
- No fabricated milestones, hardcoded "Day 19", or hardcoded warning signs.

### L5

Status: current

Question: Confirm item 6 — does "the cat" mean the AI chat/Assistant, and what do "improve" and "add banner" mean?

Recommended Answer:
- "the cat" = the chat = the Assistant; canonicalize the term "Assistant"; add an informational-only disclaimer banner; improve loading/error/streaming polish.

Answer: cat refers to the chat, back-forth communication to assist the user

Decision: "The cat" is the Assistant (AI chat). The term "Assistant" is canonical. Add an informational-only disclaimer banner and improve loading/error/streaming states.

Reason: Resolves competing names (chatbot / AI Recovery Assistant / chat / "the cat"); the guardrail banner serves the "never diagnostic, always informational" requirement.

Constraints:
- The informational-only guardrail banner is already specified in `ai_specs/0001-mobile-core-loop-hardening-polish/spec.md` (Req 14); this Spec confirms it and adds streaming/error/loading behavior rather than re-defining the banner.

### L6

Status: current

Question: How should the Profile screen be cleaned up so the backend and frontend make sense?

Recommended Answer:
- Remove the "Two-factor authentication" and "Connected devices" rows (dead, no backend) and the dead notification bell; wire "Change password" [L3]; replace hardcoded fallbacks with real auth/Case data or honest absence; make personal info editable; drop the "Invite code" row; persist Med-reminders + Daily-check-in toggles to shared_preferences and remove the "FDA safety alerts" toggle.

Answer: proceed with recommended answers

Decision: The Profile removes 2FA, Connected devices, and the dead bell; wires Change password; de-hardcodes all fallbacks to real data or honest absence; persists notification toggles locally; and drops the FDA-alerts toggle and the Invite-code row.

Reason: The owner asked to "remove useless things... if missing on backend" and "make sure backend and frontend make sense"; this extends 0001's "reuse profile_screen.dart" with a cleanup pass.

Negative Requirements:
- No 2FA UI, no Connected-devices UI, no fake notification badge.

### L7

Status: current

Question: What is in scope for improving the clinician's new-patient flow (web CreatePatientPage)?

Recommended Answer:
- Add surgery_date (required) to case creation (powers a real Day N [L4] and the Profile surgery date); DOB added [L2]; invite-flow polish (loading/success/error states; keep showing the invite code as the documented fallback channel); no full redesign.

Answer: yes, i agree

Decision: The clinician new-patient flow adds a required DOB [L2] and a required surgery_date, plus invite-flow loading/success/error polish; surgery_date enables a real server-computed "Day N". No broader redesign.

Reason: The clinic knows the surgery date; capturing it makes the Recovery day-count and the Profile surgery date truthful rather than absent.
