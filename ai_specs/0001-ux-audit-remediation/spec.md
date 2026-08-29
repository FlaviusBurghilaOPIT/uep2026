---
type: Spec
title: RemoteCare Pro UX Audit Remediation & Clinical Flow Hardening
---

## Problem

The UX Audit across the 23 behavioral, ergonomic, cognitive, and visual design disciplines in RemoteCare Pro identified 32 critical usability, accessibility, cognitive load, and visual polish defects across the mobile patient companion (Screens A01–A06, B01–B05) and the web clinician portal (Screens C01–C03).

Key issues include:
1. Saccadic regression from unconstrained header typography and low contrast disclaimers under cognitive fatigue.
2. Inefficient input mechanics (manual OTP entry without auto-paste, disruptive blocking modals for dose skips, unguided password creation).
3. Technical system errors displayed during offline sync drops instead of reassuring plain language.
4. Spacing inconsistencies and undersized interactive touch targets below 48x48dp.
5. Incomplete feedback loops (static completion states without closure payoff, unconfirmed check-in transmissions).
6. Web clinician triage inefficiencies requiring multi-step navigation for routine alert resolutions.

## Proposed Outcome

Remediate all 32 UX audit defects across mobile and web platforms to achieve:
- WCAG 2.1 AA compliance with high-contrast text tokens and minimum 48x48dp touch boundaries.
- Forgiving, slip-resistant medication logging with optimistic Riverpod state mutations (<50ms) and 5-second non-blocking undo SnackBars.
- Streamlined, accessible authentication flows (auto-paste OTP, live password strength meter, cooldown timers, clinic identity verification).
- Sticky 1-tap emergency direct-dial escalation for acute patient symptoms.
- Clinical web portal optimizations for rapid inline triage resolutions and constrained error-free medication scheduling.

## User Stories

1. **US1 (Patient - Daily Medication & Today Screen)**: As a post-op patient, I want to view my daily schedule clearly on any device size and log or correct medication doses instantly without disruptive popups or lag, so that tracking my recovery feels effortless and reliable. [L1, L7, L14, L16, L18, L19, L20]
2. **US2 (Patient - Daily Symptom Check-In & Safety)**: As a recovering patient, I want simple, clear options to report how I feel, immediate 1-tap access to emergency care if I feel unwell, and confirmation that my doctor received my report. [L5, L13, L21]
3. **US3 (Patient - AI Clinical Assistant)**: As a patient with questions, I want a clean chat assistant with legible guidance, persistent safety guardrails, and quick suggestion prompts to help me ask relevant questions without seeing repeated disclaimers on every message. [L2, L11, L23]
4. **US4 (Patient - Recovery & Profile)**: As a patient, I want to track my recovery adherence clearly, understand if a care team is assigned, and edit my profile contact information smoothly without input glitches. [L4, L9, L10, L15, L22]
5. **US5 (Patient - Seamless Onboarding & Authentication)**: As a new or returning patient, I want unambiguous sign-in options, smart email inputs, automatic OTP paste and verification, and clear password strength feedback when setting up my account. [L3, L6, L8, L12, L17, L24, L25, L26, L27, L28]
6. **US6 (Clinician - Triage & Web Management)**: As a clinician managing multiple post-op cases, I want high-priority patients visually highlighted on my triage dashboard, the ability to resolve routine alerts inline with a note, and constrained prescription scheduling tools to prevent dosage syntax errors. [L29, L30, L31, L32]

## Requirements

### Typography & Readability (TYPO-01 .. TYPO-04)
1. **TYPO-01 (Date & Greeting Header)**: Apply responsive fluid clamping to greeting and date headers in `TodayScreen` (`A01`) with `maxLines: 1` and `TextOverflow.ellipsis` to prevent wrapping on narrow viewports (<360dp). [L1]
2. **TYPO-02 (Assistant Guardrail Banner)**: Refactor `GuardrailBanner` in `assistant_screen.dart` (`A05`) to use system sans-serif 13.sp, weight 500, #334155 on #F0FDF4 background with 1.4 line height. [L2]
3. **TYPO-03 (Tabular Digits)**: Configure OTP entry fields in `VerifyCodeScreen` / `RequestCodeScreen` (`B03`) and countdown timers to use `FontFeature.tabularFigures()` and monospaced font features to prevent character width jitter. [L3]
4. **TYPO-04 (Recovery Adherence Stat)**: Emphasize the recovery percentage metric in `RecoveryScreen` (`A04`) with bold display weight (FontWeight.w700) and primary emerald hue (`AppColors.primaryGreen` / #10B981). [L4]

### Form Usability & Safety (FORM-01 .. FORM-05)
5. **FORM-01 (Emergency Red Flag Banner)**: In `CheckInCard` (`A03`), display a pinned sticky Emergency Red Flag banner with a 1-tap direct phone dialer (`tel:911` / clinic hotline) immediately upon selecting "Unwell" / 'bad'. [L5]
6. **FORM-02 (OTP Auto-Paste & Auto-Submit)**: In `VerifyCodeScreen` (`B03`), implement automatic clipboard detection/paste listener, segmented digit auto-advance, and automatic submit trigger upon entering the 6th digit. [L6]
7. **FORM-03 (Dose Skip Undo SnackBar)**: In `DoseSlotCard` (`A02`), replace blocking modal dialogs for skipping doses with an immediate optimistic skip mutation and a 5-second non-blocking `SnackBar` containing an `[Undo]` action. [L7]
8. **FORM-04 (Interactive Password Checklist)**: In `CreatePasswordScreen` (`B05`), display a dynamic real-time checklist (8+ chars, uppercase, lowercase, number, symbol) that updates interactively on keypress. [L8]
9. **FORM-05 (Profile Phone Cursor & Formatting)**: In `ProfileScreen` edit sheet (`A06`), preserve cursor position at the end of text upon re-focus and enforce E.164 telecommunication formatting. [L9]

### Flow Consistency & Copy (COPY-01 .. COPY-04)
10. **COPY-01 (Human-Centered Offline Copy)**: Replace raw technical network exceptions across `TodayScreen` (`A01`) and `RecoveryScreen` (`A04`) with friendly copy: "Saved locally. Will sync automatically once reconnected." [L10]
11. **COPY-02 (Consolidated Assistant Disclaimers)**: Keep AI chat bubbles natural and concise in `AssistantScreen` (`A05`), removing repetitive disclaimer prefixes in favor of the pinned top guardrail banner. [L11]
12. **COPY-03 (Auth Method Clarity)**: Re-label welcome options in `WelcomeScreen` (`B01`): "New Patient? Enter Clinic Invitation" vs "Sign in with One-Time Code" vs "Clinician Sign In". [L12]
13. **COPY-04 (Check-In Telemetry Confirmation)**: In `CheckInCard` (`A03`), show an explicit post-submission status banner: "Telemetry received • Dr. Miller's care team notified". [L13]

### Visual Polish & Spacing (VIS-01 .. VIS-04)
14. **VIS-01 (8-Point Grid Spacing)**: Standardize all card vertical and horizontal margins in `TodayScreen` (`A01`) and throughout the app to `AppSpacing.md` (16dp) on the strict 8-point grid. [L14]
15. **VIS-02 (48x48dp Touch Targets)**: Expand interactive row chevrons and action icons in `ProfileScreen` (`A06`) to a minimum 48x48dp hit test area using `HitTestBehavior.opaque` / `IconButton`. [L15]
16. **VIS-03 (Medication Form Glyphs)**: Add dedicated SVG/Icon glyphs for Capsule, Tablet, and Liquid dosages beside text dosage badges in `DoseSlotCard` / `DoseFormat` (`A02`). [L16]
17. **VIS-04 (Welcome Asset Constraint)**: Constrain illustration height in `WelcomeScreen` (`B01`) to a maximum of 180.h on compact viewports (<600dp). [L17]

### Batch 1 — Core Patient Surfaces (AUD-A01 .. AUD-A06)
18. **AUD-A01 (Optimistic Riverpod State)**: Execute instant dose logging state updates in `TodayAgendaNotifier` (<50ms) with background SQLite sync and rollback notification on final error. [L18]
19. **AUD-A02 (Day Complete Ring Animation)**: Enhance `CelebrationRingCard` (`A01`) with an animated emerald glow sweep and medium haptic feedback pulse (`HapticFeedback.mediumImpact()`) upon reaching 100% daily adherence. [L19]
20. **AUD-A03 (Forgiving Dose Time Logging)**: Allow logging doses anytime during the active day in `DoseSlotCard` (`A02`) with clear retroactive timestamp recording instead of rejecting actions outside strict windows. [L20]
21. **AUD-A04 (Simplified 4-Choice Mood Picker)**: Consolidate daily feeling options in `CheckInCard` (`A03`) to 4 distinct intuitive choices: Great, OK, Not Great, Unwell. [L21]
22. **AUD-A05 (Honest Absence Care Team)**: Display explicit honest absence copy in `RecoveryScreen` (`A04`) when no clinician is assigned: "No dedicated care team assigned — contact clinic main desk". [L22]
23. **AUD-A06 (Assistant Quick Prompts)**: Provide 3 pre-seeded clinical prompt chips in empty `AssistantScreen` (`A05`): "Is mild swelling normal?", "When can I shower?", "Medication instructions". [L23]

### Batch 2 — Onboarding & Auth (AUD-B01 .. AUD-B05)
24. **AUD-B01 (Dominant Primary Auth CTA)**: Establish a clear visual hierarchy in `WelcomeScreen` (`B01`) with a single dominant primary button and secondary outlined/text links. [L24]
25. **AUD-B02 (Email Field Configuration)**: In `EmailLoginScreen` / `LoginScreen` (`B02`), configure email text fields with `textCapitalization: TextCapitalization.none`, `autocorrect: false`, and `keyboardType: TextInputType.emailAddress`. [L25]
26. **AUD-B03 (Resend Code 60s Timer)**: In `VerifyCodeScreen` (`B03`), add a 60-second cooldown timer to the "Resend Code" button with live remaining seconds display. [L26]
27. **AUD-B04 (Clinic Identity Preview)**: In `InvitationCodeScreen` (`B04`), show verified clinic name and inviting physician details upon entering a valid invitation code before account creation. [L27]
28. **AUD-B05 (Progressive Password Entropy)**: In `CreatePasswordScreen` (`B05`), render an inline progressive entropy meter evaluating password strength dynamically as the user types. [L28]

### Batch 3 — Clinician Portal & Web Surfaces (AUD-C01 .. AUD-C04)
29. **AUD-C01 (Inline Triage Resolution)**: In `web/src/pages/dashboard.astro`, provide a 1-click modal action to resolve minor triage alerts with a mandatory reason note directly from the table row. [L29]
30. **AUD-C02 (Triage Severity Border & Accent)**: In `web/src/pages/dashboard.astro`, add a 4px left accent border (red for urgent, amber for moderate) and high-contrast status tags to triage patient rows. [L30]
31. **AUD-C03 (Constrained Rx Frequency Picker)**: In `web/src/pages/cases/[caseId]/medications/`, replace free-text frequency input with a constrained clinical schedule picker (QD, BID, TID, QID, PRN). [L31]
32. **AUD-C04 (Truthful Marketing Social Proof)**: In `web/src/pages/landing.astro`, audit and replace placeholder testimonials with verified clinical partner statements and truthful compliance badges. [L32]

## Technical Decisions

1. **Riverpod State Management**: Use `todayAgendaNotifierProvider` for optimistic UI updates with cached SQLite synchronization in `mobile/lib/features/today/`.
2. **ScreenUtil Fluid Typography**: Use `ScreenUtil` `.sp` and `.w` scaling with `clamp()` for responsive layout boundaries across varying phone screen densities.
3. **Accessibility & WCAG Compliance**: Maintain minimum 4.5:1 contrast ratio across light and dark tokens; enforce minimum 48x48dp interactive boundaries on all touch surfaces.
4. **Haptic Feedback**: Invoke `HapticFeedback.mediumImpact()` via `package:flutter/services.dart` for significant positive milestones (celebration ring closure) and `HapticFeedback.heavyImpact()` on emergency triggers.
5. **Web Component Integration**: Implement React/Astro interactive islands for inline triage resolution modals and constrained medication pickers with TypeScript validation.

## Testing Strategy

1. **Flutter Unit & Widget Tests**:
   - `flutter test`: Run full mobile test suite verifying widget rendering, provider state transitions, optimistic dose logging, and form validation.
   - Specific widget tests for `TodayScreen`, `DoseSlotCard`, `CheckInCard`, `AssistantScreen`, `RecoveryScreen`, and `VerifyCodeScreen`.
2. **Web Vitest Suite**:
   - `npm test` in `web/`: Verify landing page copy, triage dashboard table rendering, and medication frequency selector functionality.
3. **Flutter Static Analysis**:
   - `flutter analyze` in `mobile/`: Verify 0 errors, warnings, or lints.
4. **Web Linter & Type Check**:
   - `npm run lint` and `npm run build` in `web/` to ensure clean builds.
