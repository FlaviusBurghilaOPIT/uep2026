# Experiments

## Experiment Cards

### EXP-001 — High-Converting Clinician Landing Page & 1-Click Demo Entry
- **Hypothesis**: We believe **Clinician Activation Rate will increase from <5% to >35%** if **prospective clinicians and evaluators** **experience a dedicated value-proposition landing page with a 1-click "Launch Live Demo" CTA** because **they immediately grasp the clinical loop differentiator without facing an authentication barrier**.
- **Type**: A/B & Qualitative Cohort Test
- **Primary metric & threshold (pre-committed)**: Clinician Activation / Demo Engagement Rate ≥ 35%
- **Guardrail metric**: Bounce Rate < 40%, LCP < 1.5s
- **Decision rule (pivot / persevere / iterate)**: Persevere if activation ≥ 30%; iterate headline copy if bounce > 50%.
- **Result & verdict**: Live in production.

### EXP-002 — StoryBrand Above-The-Fold Value Proposition Overhaul
- **Hypothesis**: We believe **Average Time-on-Site and Feature Comprehension will increase by 50%** if **visitors read a clear problem-agitation-solution headline naming internal anxiety (preventing post-op hospital readmissions)** because **strangers evaluate medical software credibility within the first 5 seconds**.
- **Type**: Sprint / Qualitative Usability Pass
- **Primary metric & threshold (pre-committed)**: 5-Second Comprehension Pass Rate ≥ 90%
- **Guardrail metric**: Zero reduction in CTA click-through
- **Decision rule (pivot / persevere / iterate)**: Persevere.

### EXP-003 — 1-Click Demo Login Auto-Fill on Authentication Screen
- **Hypothesis**: We believe **Login Completion Rate will increase to >95%** if **evaluators and judges see a pre-filled "Quick Demo Login" shortcut** because **manual credential lookup creates unnecessary evaluation drop-off**.
- **Type**: Smoke Test / UX Polish
- **Primary metric & threshold (pre-committed)**: 1-Click Login usage ≥ 70% of guest sessions
- **Guardrail metric**: Zero impact on real clinician authentication security
- **Decision rule (pivot / persevere / iterate)**: Persevere.

### EXP-004 — Optimistic Dose Logging & 5-Second Undo Toast (Mobile)
- **Hypothesis**: We believe **Patient Daily Logging Anxiety will drop to 0 and logging speed will improve by 3x (<0.5s)** if **dose logging provides instant optimistic checkmark feedback with a 5-second undo toast** because **patients never wonder if their input registered and feel safe to correct slips**.
- **Type**: A/B & In-App Telemetry Test
- **Primary metric & threshold (pre-committed)**: Dose Log Completion Time < 0.5s; Accidental Skip Correction Rate > 95%
- **Guardrail metric**: Zero sync desynchronization between mobile local state and Postgres backend
- **Decision rule (pivot / persevere / iterate)**: Persevere.

### EXP-005 — Post-Op Emergency Red-Flag Banner & Direct Dial
- **Hypothesis**: We believe **Zero high-risk patients will delay calling emergency services** if **an authoritative Red Flag Warning with 1-tap direct dial (911 / Clinic Direct) is placed prominently above symptom logging** because **patients immediately recognize life-threatening symptoms before attempting app check-ins**.
- **Type**: Safety Verification & Clinician Review
- **Primary metric & threshold (pre-committed)**: 100% clinician approval on emergency protocol compliance
- **Guardrail metric**: Zero false 911 dials from standard minor aches
- **Decision rule (pivot / persevere / iterate)**: Persevere.

## Experiment Backlog (ICE-Ranked)
| Idea | Impact (1-10) | Confidence (1-10) | Ease (1-10) | ICE Score | Status |
|---|---|---|---|---|---|
| Optimistic Dose Logging with 5s Undo Toast on Mobile (EXP-004) | 10 | 9 | 9 | **28** | In Progress |
| Emergency Red-Flag 1-Tap Dial Banner on Symptom Check-in (EXP-005) | 10 | 10 | 8 | **28** | In Progress |
| OTP 6-Digit Auto-Paste & Auto-Submit on Mobile Login (UX-03) | 9 | 9 | 9 | **27** | In Progress |
| Unified Clinician Triage Dashboard Matrix with 1-Click Quick Resolve (UX-04) | 9 | 9 | 8 | **26** | In Progress |
| Build dedicated Clinician Landing Page with SB7 messaging & 1-click demo | 10 | 9 | 8 | **27** | Done |
| Add "Quick Demo Login" 1-click button to `/login` for seamless access | 9 | 9 | 9 | **27** | Done |
| Visual Pill Form Badges & Plain-English Timing Tags on Dose Cards (UX-05) | 8 | 9 | 8 | **25** | In Progress |
| Human-friendly offline & network recovery copy across mobile toasts (UX-06) | 8 | 9 | 8 | **25** | In Progress |
| Persistent Clinical AI Guardrail Badge (UX-07) | 8 | 9 | 8 | **25** | In Progress |
| Multi-language selector prominence in navigation and landing header | 7 | 8 | 9 | **24** | Done |
