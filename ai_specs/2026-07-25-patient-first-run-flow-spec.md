---
type: Spec
title: Patient First-Run Flow — Clinic Invitation to Today (Auth Unification & Accessibility Hardening)
status: Ready for Engineering
created: 2026-07-25
sources:
  - Intent /journey design (2026-07-25, conversation)
  - Intent /include accessibility audit (2026-07-25, conversation) — P0–P3 amendments folded in
  - Intent extract-mode mobile UX inventory (2026-07-25)
  - backend/app/routers/auth.py (live API contract)
  - docs/ux/07-accessibility-spec.md (M-01–M-08), docs/product/03-safety-and-edge-cases.md (C1, C7–C11, C14) — via git HEAD
---

## 1. Ownership & Context

- **Owner:** Flavius (product/engineering)
- **Status:** Ready for Engineering — pending ⚕ clinical copy sign-off (§11) and clinic-identity product decision (§14, non-blocking)
- **Scope:** `mobile/` only. No backend changes required for the base flow; one optional backend enhancement flagged (§14-E1).

**Traceability:** This spec resolves Critical findings C1 (mock auth shipped, real auth unrouted) and H2 (notification permission never requested) from the 2026-07-25 extract-mode audit, and implements safety cases C1, C7 (partial), C10 from `03-safety-and-edge-cases.md`.

## 2. Problem & User Need

Post-surgery patients are **invited by their clinic** — they never chose this app and arrive with trust already granted. Today the shipped first-run flow breaks that trust: the routed auth flow (`InvitationScreen → ProfileSetupScreen → EmailLoginScreen → OtpScreen`) makes **zero network calls**, accepts any invitation code and any 6-digit OTP, and discards collected profile data. The real passwordless flow (`login_screen.dart`, backed by `POST /auth/patient/request-code` + `verify-code`) exists and is widget-tested but **is not wired to any route**. Boot routing uses demo SharedPreferences flags instead of the JWT, so sign-out silently fails. Notification permission — the trigger for the entire adherence loop — is only requested inside a dead screen.

**Success metric:** ≥90% of invited patients reach `Today` within 24h of invitation, with zero support contacts to the clinic. Activation, not engagement: less time in app is better (docs/product/09-measurement-plan.md §1.1).

## 3. Design Approach

- **One screen, two stages** (email → code) built on the existing `login_screen.dart` pattern; progressive disclosure instead of four single-purpose screens.
- **Clinic-forward framing** throughout: "Your care team invited you." No marketing carousel, no "Create account" — the patient is enrolled, not acquired.
- **Accessibility specified at widget level** (Semantics, live regions, focus order) per `07-accessibility-spec.md` M-01–M-08; the flow's acceptance test includes an eyes-closed TalkBack completion.

**What we did NOT do, and why:**

| Rejected alternative | Reason |
|---|---|
| Separate invitation-code screen before email | Inverts the mental model; the emailed code *is* the invitation. One flow, email-first. |
| 6 separate `TextField`s for the code | Fragments screen-reader interaction into 6 unlabeled fields; per-digit focus theft violates WCAG 3.2.1. **Single semantic field, visually segmented** (include-audit P0-1). |
| Masked email (`m•••@…`) on code screen | Defeats recognition-over-recall on the patient's own device; reads badly aloud. Show full email (P1-1). |
| Countdown timer on code validity | Never Rule 3 (no manufactured urgency). The 15-min expiry is stated as information; resend is the honest recovery. |
| Persistent step counter for all users | Screen 3 is conditional (first-run only); a persistent counter would lie. Stage dots shown during first-run only (P1-5). |
| Auto-advancing past denied notification prompt | Permission Harassment (Category 5). One primer, one OS ask, then the C1 calm banner owns recovery forever. |
| Marketing onboarding carousel | Consumer-acquisition pattern in a clinic-enrollment context; its job is done by one line of copy. |

## 4. Scope

### In scope

- New route graph and boot logic (real JWT check)
- `WelcomeScreen` (two-stage: email → code) — extends existing `login_screen.dart`
- `FirstRunProfileScreen` (phone + DOB, first sign-in only)
- `ReminderPrimerScreen` (notification permission primer)
- ARB string keys × 5 locales (en, es, it, fr, de)
- Telemetry events (§12)
- Tests (§13)

### Deletions (part of this work — the shadow flows cannot coexist with the real one)

| File | Disposition |
|---|---|
| `lib/features/auth/invitation_screen.dart` | Delete |
| `lib/features/auth/email_login_screen.dart` | Delete |
| `lib/features/auth/otp_screen.dart` | Delete |
| `lib/features/auth/profile_setup_screen.dart` | Delete |
| `lib/features/auth/onboarding_screen.dart` | Delete (marketing carousel) |
| `lib/features/auth/signup_step2_screen.dart`, `signup_step3_screen.dart` | Delete (password-era flow) |
| `lib/features/auth/demo_auth_state.dart` + all `demoAuthProvider` references | Delete; boot uses real JWT |
| `lib/features/auth/login_screen.dart` | **Keep and extend** — becomes `WelcomeScreen` |

### Out of scope (flagged, not forgotten)

- Clinic identity/white-labeling (§14-D1) — the flow works without it
- Invite email template (backend/SES) — §14-E2
- Auto-lock / task-switcher privacy (C14) — separate work item
- Universal deep links from email → app — v2

## 5. UX Questions Answered

- **How does the patient know this is their clinic's app?** Clinic-forward copy on every auth screen; personal "Welcome, {firstName}" after code verification (`verify-code` returns `full_name`).
- **What if the code never arrives?** Anti-enumeration means the request always "succeeds"; the failure surfaces as a missing email. Recovery: resend (30s cooldown) + "No code from your clinic?" sheet on Screen 1.
- **What if the patient takes >15 min on the profile step?** `complete-onboarding` 400s (code is the credential and has expired). Recovery in place: one tap re-requests a code, returns to the code stage with **phone/DOB preserved**.
- **What does a returning patient experience?** Boot → Today. Nothing else. Expired session → Welcome with email prefilled → code → Today.
- **What happens on sign-out?** Confirmation dialog, JWT cleared, boot routes to Welcome. (Fixes the broken demo-path sign-out.)

## 6. Ethical Review

Checked against the Intent anti-pattern catalog:

- **Resend 30s countdown** — a rate limit, not a countdown timer (Category 3). Disclosed as such; validity window is stated factually, never as pressure. **Clear.**
- **"Not now" on the reminder primer** — must be same size/contrast as any secondary action; suppressing it would be Low-Contrast Opt-Out (Category 6). Spec requires ≥3:1 contrast, ≥48dp target. **Clear by design constraint.**
- **Notification permission** — asked once, in context, after value is explained; denied → never re-asked by the app (Permission Harassment, Category 5). **Clear.**
- **Stage dots (first-run only)** — orientation aid, not a completeness score (Artificial Incompleteness, Category 4). **Clear.**
- **Data collection (phone, DOB)** — minimum required by the backend; the *reason* is stated on-screen before the fields. No marketing consent, no prechecked anything. **Clear.**
- **No dark patterns introduced.** Explicit clearance: this design employs no deceptive, coercive, or manipulative patterns.

## 7. Measurement

Per `09-measurement-plan.md`: activation and safety metrics only; **no PHI/PII in telemetry** (hashed IDs, enums, time deltas only). The app already posts to `/telemetry/events` via `TelemetryService`.

| Event | Fires when | Properties (no PHI) |
|---|---|---|
| `mobile.auth.code_requested` | request-code succeeds | — |
| `mobile.auth.code_request_failed` | network/5xx on request-code | error_class |
| `mobile.auth.code_verified` | verify-code 200 | result (`onboarding`\|`authenticated`) |
| `mobile.auth.code_failed` | verify-code 400 | — |
| `mobile.auth.code_resent` | resend tapped | — |
| `mobile.auth.onboarding_completed` | complete-onboarding 200 | — |
| `mobile.auth.onboarding_expired_recovery` | expiry recovery path entered | — |
| `mobile.notifications.primer_shown` | primer displayed | — |
| `mobile.notifications.permission_result` | OS prompt returns | result (`granted`\|`denied`) |

**Primary metric:** activation rate (invited → `code_verified` within 24h). **Counter-metrics:** `code_failed` rate (delivery/UX problem, never patient blame), support contacts per 100 invitations, notification opt-in rate. **Learning plan:** check at day 1 (smoke), week 1 (drop-off by stage), month 1 (resend-rate decision on the 15-min window — feeds §14-E3).

## 8. Routes & Architecture Changes

### Route graph (`lib/core/navigation/app_routes.dart`)

| Route | Screen | Notes |
|---|---|---|
| `/boot` | `BootScreen` | rewritten routing logic (below) |
| `/welcome` | `WelcomeScreen` (was `login_screen.dart`) | two-stage |
| `/setup-profile` | `FirstRunProfileScreen` (new) | first sign-in only |
| `/reminders` | `ReminderPrimerScreen` (new) | pushed after S3, or after S2 for returning users whose permission is undetermined |
| `/main` | `MainShellPage` | unchanged |
| `/profile` | `ProfileScreen` | unchanged |

Delete legacy aliases `onboarding`, `login`, `signupStep2`, `signupStep3`.

### Boot logic (replaces `demoAuthProvider` flags)

```
read JWT from secure storage
  ├─ present → GET /auth/me
  │    ├─ 200 → /main
  │    └─ 401/network-fail → /welcome (email prefilled if stored; offline notice if network)
  └─ absent → /welcome
```

Sign-out (`ProfileScreen`) clears JWT + in-memory flow state, routes to `/boot`, and gains a confirmation dialog (string `authSignOutConfirm`, §11).

### State

- `AuthNotifier` (`lib/core/providers/app_providers.dart`) is the single auth source. `demo_auth_state.dart` is deleted; `hasActiveSession`/`isFirstTime` prefs flags are deleted with it.
- First-run flow state (`email`, `invite_code`, `phone`, `dob`) lives in memory only (a `FirstRunFlowState` inside the flow's notifier) — **never written to SharedPreferences**.

## 9. Screen Specifications

### S0 — BootScreen

**Intent:** route correctly in <1s; never show sign-in to a signed-in patient. If removed: every launch re-authenticates (anxiety) or dead-ends on a spinner.

**Behavior:** branded splash (app mark + "Remote CarePro", centered) over `CircularProgressIndicator` while the JWT check runs.

**Accessibility:** spinner carries `Semantics(label: 'Signing you in')`. No interactive elements.

**States:** default (checking) → routes; network error → `/welcome` with `authOfflineNotice` banner.

---

### S1 — WelcomeScreen, stage 1 (email)

**Intent:** answer in <5s: *Is this the app my clinic meant? What do I do? Is this safe?* If removed: the patient has no legitimate entry.

**Layout:** single column, content bottom-weighted (M-06 thumb zone). Clinic-forward eyebrow + headline + sub-copy; one email field (`keyboardType: emailAddress`, autofocus, autofill hints); primary CTA (full width, ≥56dp); quiet secondary text button "No code from your clinic?"; small reassurance line.

**API:** CTA → `POST /auth/patient/request-code` `{email}`. Response is always 200 (anti-enumeration) → advance to stage 2. Network failure → inline error, input preserved, retry in place.

**Interaction logic:**
- Validate format on submit (not on every keystroke — M-07 error prevention without nagging). Invalid → inline error `authEmailInvalid` below field.
- "No code from your clinic?" → modal bottom sheet (`authNoCodeSheetBody` ⚕); focus moves into sheet, dismiss control present, focus returns to trigger on close.

**Accessibility (widget-level):**
- Semantics order: header("Welcome") → body(invitation explanation) → email field (`Semantics(textField: true, label: l10n.authEmailFieldLabel)`) → button(CTA) → button(secondary).
- Errors: ⚠ icon + text, `Semantics(liveRegion: true)`, focus moves to the error.
- Email field semantic label announces the format expectation.

**States:** default / invalid-format inline error / request-in-flight (CTA spinner-inline, field locked) / request-failed inline error.

---

### S2 — WelcomeScreen, stage 2 (code)

**Intent:** verify identity with minimum keystrokes and zero ambiguity about where the code comes from. The gate to everything.

**Layout:** same screen, stage 2 slides in (250ms; instant crossfade under Reduce Motion). Header `authCodeTitle`; sub-copy with **full email** (not masked — include-audit P1-1) + 15-min validity stated factually. **Single `TextField` with segmented 6-box visual decoration** (include-audit P0-1): numeric keyboard, `autofillHints: [AutofillHints.oneTimeCode]`, paste supported. Visible **Verify** button (explicit path alongside auto-submit). Resend + "use a different email" below.

**API:**
- `POST /auth/patient/verify-code` `{email, code}` →
  - `{"result": "authenticated", access_token}` → store JWT → `/main`
  - `{"result": "onboarding", full_name}` → keep `{email, code, full_name}` in flow state → S3
  - 400 → inline error `authCodeInvalid` (covers wrong + expired — the API intentionally doesn't distinguish; neither do we, per C10)

**Interaction logic:**
- **Auto-submit on 6th digit** (include-audit P0-2): before the transition, live region announces "Verifying your code" (`authVerifyingAnnouncement`). On 400: digits clear, focus returns to the code field, error announced. Recovery is one continuous action.
- **Resend**: 30s cooldown. The countdown is **not** a live region while counting (P0-3); at zero, one polite announcement `authResendAvailableAnnouncement`. On resend success: `authCodeResentNote` ("New code sent. Your previous code no longer works.") — resend resets the 15-min validity server-side.
- **Expiry honesty:** validity stated as information; no countdown timer, no urgency styling.

**Accessibility:**
- Code field: one `Semantics(textField: true, label: l10n.authCodeFieldLabel)` ("Sign-in code, 6 digits"). Progress announced sparsely — at most "3 of 6 digits entered", not per-digit.
- Stage change focus rule (P1-4): focus moves to stage header (`Semantics(header: true)`), announced, then input focus to the field.
- 200% text scaling (M-02): single-field pattern reflows; segmented boxes are decoration, sized by text scale. No fixed container heights.

**States:** default / verifying (field locked, spinner-inline on Verify) / error (icon+text+shake — shake decorative only, disabled under Reduce Motion) / resent confirmation / cooldown.

---

### S3 — FirstRunProfileScreen (first sign-in only)

**Intent:** collect the two fields the backend requires while making the patient feel *recognized*, not interrogated. This is the arc's turning point: the app proves it knows who the clinic invited.

**Layout:** header `authProfileWelcome` with `{firstName}` (from `verify-code`); why-we-ask line (`authProfileWhyAsk` ⚕) above the fields; phone field (numeric keyboard); DOB field (date picker, **never free text**); CTA `authFinishSetupButton` (≥56dp). Stage indicator: 3 dots + announced `authStageOfThree` — **first-run only**.

**API:** CTA → `POST /auth/complete-onboarding` `{email, invite_code, date_of_birth, phone}` → `TokenResponse` → store JWT → S4.

**Interaction logic:**
- Inline validation on blur; both fields required (backend requires them; the why-line makes the requirement legible).
- **DOB picker: `initialDatePickerMode: DatePickerMode.year`** (include-audit P1-3 — a 67-year-old must not scroll ~800 months). Selected date echoed in locale format with `Semantics` label.
- **Expiry recovery (code >15 min old):** on 400, show `authCodeExpiredRecovery` with a single action → re-request code, navigate to S2 with **phone/DOB preserved** (journey state management: re-entry shows prior context, never restarts).

**Accessibility:** semantics order header → why-line → phone → DOB (announces selected date) → CTA → stage indicator. Errors are the standard icon+text+liveRegion component.

**States:** default / field errors / submit-in-flight / expired-code recovery.

---

### S4 — ReminderPrimerScreen

**Intent:** earn the notification permission before the OS asks — a denied OS prompt is nearly unrecoverable for this population, and reminders are the trigger of the entire adherence loop.

**Layout:** headline `reminderPrimerTitle`; body `reminderPrimerBody` (patient benefit: lock-screen reminders + one-tap dose logging from the reminder); primary `reminderPrimerEnable` → triggers the **real OS prompt**; secondary `reminderPrimerNotNow` → `/main`. Shown: after S3 (first-run), or after S2 for returning users whose permission status is undetermined. Never shown again once determined.

**Interaction logic:**
- OS `granted` → schedule reminders (existing `NotificationService` path) → `/main`.
- OS `denied` or "Not now" → `/main`; the C1 calm banner on Today (`remindersOffBanner`, from 03-safety C1) owns recovery with a deep link to OS settings. **The app never asks again.**

**Accessibility:** both buttons ≥48dp, secondary ≥3:1 contrast (no suppressed opt-out). Semantics order: header → body → enable → not-now.

**States:** default / (OS prompt is system UI, accessible by platform).

---

### S5 — Today (handoff guarantees)

Not owned by this spec, but this flow must guarantee the landing conditions:

1. Regimen renders from real API data only — **no fallback medications, no hardcoded dose times** (finding C2; separate work item, tracked as blocking for a honest first-run).
2. Empty plan → C9 state `emptyPlanMessage` ("Your care team is preparing your care plan. No action is needed from you right now.").
3. Notifications denied → C1 banner present with settings deep link.
4. M-01 reading order on Today: Next Medication → Dose → Due Time → Actions.

## 10. Use Cases & Variants

| # | Scenario | Expected behavior |
|---|---|---|
| 1 | First-time invited patient, happy path | S1 → S2 → S3 → S4 → Today. ≤6 taps + 2 fields beyond code |
| 2 | Returning patient, valid JWT | S0 → Today. No auth UI at all |
| 3 | Returning patient, expired JWT | S1 (email prefilled) → S2 → Today (S3 skipped; S4 only if permission undetermined) |
| 4 | Wrong code, then correct | Inline error, digits clear, focus refocused; unlimited retries (C10); succeeds |
| 5 | Code expired (>15 min) | Same error string as wrong code (API doesn't distinguish); resend issues new code + note |
| 6 | Email with no patient account | request-code returns 200, no email ever arrives; recovery = resend + "No code from your clinic?" sheet. **No enumeration leak** |
| 7 | Offline at S1/S2 | Inline `authOfflineNotice`; input preserved; retry in place. No dead spinner |
| 8 | Interrupted mid-S3, returns next day | JWT absent (never issued) → S1 fresh; phone/DOB not persisted (memory-only) |
| 9 | >15 min spent on S3 | complete-onboarding 400 → expiry recovery → code re-request → S2 with phone/DOB preserved → completes |
| 10 | Denies notifications | S4 → Today with C1 banner; never asked again by the app |
| 11 | 200% system text size | All screens reflow, no fixed heights, CTA labels wrap, code field reflows (M-02) |
| 12 | TalkBack, eyes closed | Full first-run completable using §9 announcement script — **release-blocking acceptance test** |
| 13 | Switch Control / external keyboard | Tab order per §9 nav maps; all actions reachable and labeled |

## 11. Copy Matrix (ARB keys — EN source shown; es/it/fr/de required before merge)

All strings `[LOCALIZATION_READY]`, named `{params}` only, Grade 8 (M-07). ⚕ = `[CLINICAL_VALIDATION_NEEDED]` sign-off required before release. Several keys exist already in `app_en.arb` (reuse); **NEW** = add to all 5 ARB files.

| Key | EN source | Notes |
|---|---|---|
| `authClinicEyebrow` **NEW** | "Your clinic's recovery app" | replaces "RemoteCare Pro" self-branding on auth screens |
| `authWelcomeTitle` (exists) | "Welcome." | period, not exclamation — calm |
| `authWelcomeSubtitle` **NEW** | "Your care team invited you. Sign in with the email they have on file for you." | |
| `authEmailFieldLabel` **NEW** | "Email" | semantic label includes format expectation |
| `authSendCodeButton` **NEW** | "Send my sign-in code" | |
| `authNoCodeLink` **NEW** | "No code from your clinic?" | |
| `authNoCodeSheetBody` **NEW** ⚕ | "This app works by invitation from your clinic. Your sign-in code arrives by email. If you can't find it, contact your clinic and ask them to resend your invitation." | |
| `authPasswordlessNote` **NEW** | "No password needed — we email you a code you use once." | `/articulate` to review "code you use once" per locale |
| `authEmailInvalid` **NEW** | "Enter the email your clinic has on file for you." | |
| `authCodeTitle` **NEW** | "Check your email" | |
| `authCodeSubtitle` **NEW** | "We sent a 6-digit code to {email}. It's valid for 15 minutes." | full email, not masked |
| `authCodeFieldLabel` **NEW** | "Sign-in code, 6 digits" | semantic label |
| `authVerifyButton` **NEW** | "Verify" | |
| `authVerifyingAnnouncement` **NEW** | "Verifying your code" | live-region only |
| `authCodeInvalid` **NEW** | "That code didn't work. Check the 6 digits and try again — or resend a new code." | covers wrong + expired |
| `authResendButton` (exists) | "Resend code" | cooldown suffix `({seconds}s)` not announced |
| `authResendAvailableAnnouncement` **NEW** | "You can resend the code now." | live-region only, fires once |
| `authCodeResentNote` **NEW** | "New code sent. Your previous code no longer works." | |
| `authDifferentEmailLink` **NEW** | "Use a different email" | |
| `authProfileWelcome` **NEW** | "Welcome, {firstName}." | recognition moment |
| `authProfileSubtitle` **NEW** | "Just two details to finish setting up your record." | |
| `authProfileWhyAsk` **NEW** ⚕ | "Your care team uses these to match your records and reach you in an emergency." | |
| `authPhoneFieldLabel` **NEW** | "Phone" | |
| `authDobFieldLabel` **NEW** | "Date of birth" | |
| `authFinishSetupButton` **NEW** | "Finish setup" | |
| `authStageOfThree` **NEW** | "Set up your account — step {step} of 3" | first-run only; announced |
| `authCodeExpiredRecovery` **NEW** | "Your code expired while we were setting up. Send a new one?" | single action |
| `authOfflineNotice` **NEW** | "No connection. Check your network and try again." | |
| `authSignOutConfirm` **NEW** | "Sign out? You'll need a new code from your email to sign back in." | |
| `reminderPrimerTitle` **NEW** | "Never wonder when to take your medication." | |
| `reminderPrimerBody` **NEW** | "Your care team set times for your doses. Reminders appear on your lock screen — and you can log a dose right from the reminder." | |
| `reminderPrimerEnable` **NEW** | "Turn on reminders" | |
| `reminderPrimerNotNow` **NEW** | "Not now" | ≥3:1 contrast, ≥48dp |
| `remindersOffBanner` (C1, may exist) | "Reminders are turned off. You can log doses manually — or turn reminders on in Settings." | on Today |
| `emptyPlanMessage` (C9, may exist) | "Your care team is preparing your care plan. No action is needed from you right now." | on Today |
| `bootSigningInLabel` **NEW** | "Signing you in" | semantic label on S0 spinner |

## 12. Telemetry

Events as tabled in §7. Implementation: extend `TelemetryService` calls in `AuthNotifier`/flow notifiers. **No PHI**: never send email, name, code, phone, DOB — only enum results and error classes. Verify each event payload against `09-measurement-plan.md` §1.2 before merge.

## 13. Test Plan

### Unit / widget (no backend — `FakeApiService` seam)

| Test | Asserts |
|---|---|
| `welcome_screen_test.dart` (extend `login_screen_test.dart`) | stage 1→2 transition on request-code success; inline error on invalid email; error preserved on network failure |
| code stage | auto-submit fires exactly once at 6 digits; 400 → digits cleared + error shown; resend cooldown disables button 30s; `onboarding` result routes to S3 with full_name |
| `first_run_profile_screen_test.dart` | validation blocks empty submit; success stores token + routes to S4; 400 → expiry recovery card → re-request returns to S2 with phone/DOB preserved |
| `reminder_primer_screen_test.dart` | granted → `/main`; denied → `/main` (no re-prompt); "Not now" → `/main` |
| `boot_screen_test.dart` | valid JWT → `/main`; absent → `/welcome`; 401 → `/welcome` |
| deletion guard | no references to `demoAuthProvider`, deleted routes, or deleted screens compile |
| i18n | every new key exists in all 5 ARB files (CI check, per 10-plan convention) |

### Integration (backend + seeded DB + simulator — extends `integration_test/golden_loop_test.dart`)

- Fresh patient (seeded `pending_onboarding`): full arc S1→Today using the seeded code; lands on real regimen.
- Returning seeded patient (`patient@example.com` / `424242`): S1→S2→Today, S3 skipped.

### Manual accessibility (release-blocking)

1. **Eyes-closed TalkBack (Android) and VoiceOver (iOS):** complete use case #1 using only the §9 announcement script.
2. **200% text scale:** all screens, zero overflow/clipping (M-02).
3. **Grayscale:** all status/error communication distinguishable without color (M-03).
4. **Reduce Motion:** stage transitions crossfade; error shake absent; announcements carry state.
5. **One-handed:** every primary action reachable in bottom 60% of a 375×812 viewport (M-06).

### Success criteria

- Widget + integration suites green; `flutter analyze` clean.
- All 5 manual a11y checks pass.
- Telemetry events observed in `/telemetry/events` during integration run with zero PHI.

## 14. Pending Questions

### Design (non-blocking)

- **D1 — Clinic identity:** the API has no clinic entity; `request-code` returns nothing. The flow ships with "Your care team" framing. Enhancement: backend returns clinic display name → "Your care team at {clinicName}" on S1/S2. Owner: product (`/strategize` white-label decision).
- **D2 — ⚕ copy sign-off:** `authNoCodeSheetBody`, `authProfileWhyAsk` need `[CLINICAL_VALIDATION_NEEDED]` review before release (not before implementation).

### Engineering (non-blocking)

- **E1 — Invite email template:** must name the app, the clinic, and the 15-min validity, or S2 inherits confusion it can't fix. Owner: backend (SES template).
- **E2 — Resend rate limiting:** UX promises "resend freely"; server-side throttle policy on `request-code` (per email/IP) must be decided so the promise stays honest. Owner: backend.
- **E3 — 15-min validity window:** may be short for elderly patients who check email slowly. Revisit with resend-rate data at month 1 (§7 learning plan).

## 15. Acceptance Criteria (summary)

1. Real passwordless flow is the only routed auth path; `demoAuthProvider` and 7 dead screens deleted; app compiles with no references to them.
2. Boot routes on JWT via `GET /auth/me`; sign-out (with confirmation) reliably returns to S1.
3. First-run arc (S1→S2→S3→S4→Today) works end-to-end against the live backend with the seeded patient.
4. Code input is a single semantic field with segmented visuals; auto-submit announced; resend cooldown silent-until-available.
5. Notification permission requested exactly once via primer; denial handled by C1 banner only.
6. All §11 strings in all 5 locales; ⚕ strings flagged for clinical sign-off.
7. All §13 tests pass, including eyes-closed TalkBack first-run completion.
8. Telemetry events fire with zero PHI.
