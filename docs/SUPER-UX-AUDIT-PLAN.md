# Super UX Audit Plan

## Context
- **Product**: RemoteCare Pro (Cross-platform Mobile Patient Recovery App & Web Clinician Triage Portal)
- **Primary Job to be Done**: Enable surgical care teams to actively monitor patient medication adherence and post-operative symptoms, automatically surfacing complications within 60 seconds before they lead to 30-day emergency readmissions.
- **Canonical Viewports**:
  - Web: Desktop 1440px / 1280px (Clinician Portal)
  - Mobile: iOS 393x852 (iPhone 16 Pro) / Android 360x800
- **Audience Archetypes**:
  1. *Post-Operative Surgical Patient* (recovering at home, mild cognitive fatigue, needs effortless 1-tap adherence logging and reassuring AI guidance).
  2. *Attending Orthopedic/General Surgeon* (prescribing constrained medication regimens in under 30 seconds, requiring high governance peace of mind).
  3. *Transitional Care Nurse / Clinical Coordinator* (triaging multi-patient rosters, monitoring missed doses, logging proactive outreach in under 60 seconds).

---

## Phase Status

| Phase | Skill | Scope / Focus | Status | Artifact |
|---|---|---|---|---|
| **Phase 0** | Repo & Screen Ingestion | Screen inventory, state capture mapping, archetypes | **done** | `docs/SUPER-UX-AUDIT-PLAN.md` |
| **Phase 1** | `jobs-to-be-done` | Big Hire vs Little Hire, functional/emotional/social dimensions | **done** | `docs/CUSTOMER.md` |
| **Phase 2** | `thinking-fast-slow` | Cognitive ease, pre-computed time deltas, WYSIATI triage promotion | **done** | `docs/DESIGN.md` |
| **Phase 3** | `dont-make-me-think`, `ux-heuristics` | Trunk test, billboard scanning, Nielsen 10 heuristics audit | **done** | `docs/DESIGN.md`, `docs/EXPERIMENTS.md` |
| **Phase 4** | `design-everyday-things` | Norman gulfs, signifiers, constrained schedule pickers, feedback | **done** | `docs/DESIGN.md`, `docs/PRODUCT.md` |
| **Phase 5** | `laws-of-ux` | Fitts (48x48dp), Miller/Cowan (4 KPIs), Hick (3 filters), Peak-End | **done** | `docs/DESIGN.md`, `docs/PRODUCT.md` |
| **Phase 6** | `100-things-designer-knows` | 45–72 CPL measure, dual-coding (color + icon glyphs), chunking | **done** | `docs/DESIGN.md` |
| **Phase 7** | `refactoring-ui` | 8-pt spacing, slate neutral hierarchy, WCAG AAA contrast, depth | **done** | `docs/DESIGN.md` |
| **Phase 8** | `microinteractions` | Optimistic Riverpod (<50ms), 5s undo snackbar, live pulse indicator | **done** | `docs/DESIGN.md` |
| **Phase 9** | `designing-interfaces` | High-density triage table, 1-click inline resolution modal | **done** | `docs/DESIGN.md` |
| **Phase 10** | `designing-behavior-change` | CREATE action funnel: automated cues, friction-free 1-tap logging | **done** | `docs/PRODUCT.md` |
| **Phase 11** | `hooked-ux` | Hook model: trigger -> 1-tap action -> variable reassurance -> investment | **done** | `docs/PRODUCT.md` |
| **Phase 12** | `actionable-gamification` | Octalysis Core Drive 1 (Epic Meaning) & Drive 2 (Progress Ring Closure) | **done** | `docs/PRODUCT.md` |
| **Phase 13** | `cashvertising` | AIDPA sequence, Life-Force 8 (health/protection), benefit vs feature copy | **done** | `docs/POSITIONING.md` |
| **Phase 14** | `pre-suasion` | Privileged moments: Trust anchors (AWS Healthcare, HIPAA, FDA CDS) | **done** | `docs/POSITIONING.md` |
| **Phase 15** | `priceless`, `predictably-irrational` | Transparent value contrast (Paper Discharge vs Active RemoteCare Pro) | **done** | `docs/POSITIONING.md` |
| **Phase 16** | `deceptive-patterns`, `nudge`, `jux-research` | Truth Gate: zero synthetic social proof, transparent disclaimers | **done** | `docs/DESIGN.md` (GATE) |
| **Phase 17** | `steve-jobs-design-review` | Ruthless simplicity, 0 gimmicks, remove 1-click clinician bypass | **done** | `docs/PRODUCT.md`, `docs/DESIGN.md` |

---

## Screen Inventory

| Screen ID | Route / View | Role | Viewport | Core Interaction / State |
|---|---|---|---|---|
| **S-01** | `web/src/pages/landing.astro` (`/`, `/landing`) | Public / Clinician Prospect | Desktop / Mobile | Marketing hero, interactive triage preview, verified pilot proof, compliance standards |
| **S-02** | `web/src/pages/login.astro` (`/login`) | Clinician | Desktop / Mobile | Strict organization credential authentication with security badge |
| **S-03** | `web/src/pages/dashboard.astro` (`/dashboard`) | Clinician | Desktop (1280px+) | 4-KPI chunked stats, live telemetry table, severity left borders, inline resolution modal |
| **S-04** | `web/src/pages/patients/index.astro` (`/patients`) | Clinician | Desktop | Full patient cohort roster, search/filter, onboarding invitation code issuance |
| **S-05** | `web/src/pages/cases/[caseId]/index.astro` | Clinician | Desktop | Patient case detail, real-time adherence history, symptom trend charts |
| **S-06** | `web/src/pages/cases/[caseId]/medications/` | Clinician | Desktop | Constrained frequency picker (QD/BID/TID/QID/PRN) & dosage schedule builder |
| **S-07** | `web/src/pages/fda.astro` (`/fda`) | Clinician | Desktop | Real-time openFDA FAERS adverse event search & black-box warning lookup |
| **S-08** | `mobile/TodayScreen` (`A01`) | Patient | iOS / Android | Daily medication agenda, optimistic dose logging, forgiving all-day marking, Day Complete ring |
| **S-09** | `mobile/DoseSlotCard` (`A02`) | Patient | iOS / Android | Format badges (Capsule, Tablet, Liquid), 5s undo snackbar, retroactive timestamps |
| **S-10** | `mobile/CheckInCard` (`A03`) | Patient | iOS / Android | 4 simplified feelings (Great, OK, Not Great, Unwell), emergency callout banner, telemetry confirmation |
| **S-11** | `mobile/RecoveryScreen` (`A04`) | Patient | iOS / Android | Verified recovery day calculation, clinician recommendations, honest care team attribution |
| **S-12** | `mobile/AssistantScreen` (`A05`) | Patient | iOS / Android | Clinical AI chat streaming, quick prompt chips, dose-change refusal guardrail box & emergency CTA |
| **S-13** | `mobile/ProfileScreen` (`A06`) | Patient | iOS / Android | Patient details, language picker, 48x48dp ergonomic settings rows, sign out |
| **S-14** | `mobile/WelcomeScreen` (`B01`) | Patient / Clinician | iOS / Android | Disambiguated auth choices (Clinic Invite vs One-Time Code vs Clinician Login) |
| **S-15** | `mobile/VerifyCodeScreen` (`B03`) | Patient | iOS / Android | 6-digit segmented OTP auto-paste, auto-advance, auto-submit, 60s cooldown timer |
| **S-16** | `mobile/CreatePasswordScreen` (`B05`) | Patient | iOS / Android | Live password criteria checklist, progressive entropy meter, enabled confirm field |

---

## Key Decisions & Audit Determinations

1. **Removal of One-Click Clinician Demo Bypass (Steve Jobs Review & HIPAA Security)**:
   - *Decision*: Completely removed the one-click demo login shortcut from both the landing page CTAs and the clinician login form. Clinician authentication now requires deliberate, authorized organization credential entry.
   - *Rationale*: Elevates clinical software credibility and reinforces hospital governance standards (Brignull Truth Gate & Phase 16).

2. **4-KPI Cognitive Chunking on Dashboard (Miller's Law & Kahneman System 1)**:
   - *Decision*: Constrained dashboard overview stats into exactly four distinct KPI cards: Critical Alerts (Red), Moderate Alerts (Amber), Monitored Patients (Blue), and Median Resolution Time (Green).
   - *Rationale*: Eliminates cognitive strain, enabling coordinators to perceive immediate cohort risk in <250ms.

3. **Dual-Coded Visual Severity Accent Borders (Norman Affordances & Weinschenk Dual Coding)**:
   - *Decision*: Added 4px solid colored left borders (`#ef4444` for high priority, `#f59e0b` for moderate priority) combined with high-contrast icon badges (`TriangleAlert`, `AlertCircle`, `CheckCircle2`) to all patient table rows.
   - *Rationale*: Avoids single-signal color reliance (supporting users with color-vision deficiencies) while accelerating scanning speed.

4. **1-Click Inline Triage Resolution with Mandatory Audit Note (Tesler's Law)**:
   - *Decision*: Embedded an inline resolution modal directly in the triage table so coordinators resolve exceptions without navigating away from the dashboard.
   - *Rationale*: Absorbs workflow friction into the system, keeping triage cycle time under 60 seconds.

5. **Verified Social Proof & Compliance Truth Gate (Brignull & Cialdini)**:
   - *Decision*: Replaced placeholder marketing claims with verified clinical pilot partner statements (attributing real roles in orthopedics, clinical informatics, and transitional care) paired with official HIPAA, FDA CDS, and openFDA FAERS compliance standards.
   - *Rationale*: Passes the publicity litmus test and avoids deceptive patterns.
