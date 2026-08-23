# Website

## Sitemap
- `/` — Clinician Landing Page & Value Proposition (Public)
- `/login` — Clinician Authentication & 1-Click Demo Access
- `/dashboard` (or authenticated `/`) — Real-Time Triage Dashboard & Patient Escalation Monitor
- `/patients` — Patient Directory & Adherence Overview
- `/patients/new` — Patient Intake & Mobile Invite Code Generator
- `/cases/new` — Surgical Case Creator & Prescription Builder
- `/cases/:caseId` — Comprehensive Patient Case Detail & Adherence Timeline
- `/fda` — Live openFDA Safety Signal & Recalls Explorer

## Page Briefs

### / (Clinician Landing Page)
- **Purpose & Primary Conversion Action**: Convert prospective clinic decision-makers and hackathon evaluators into active users via 1-click "Launch Live Clinician Demo" (Direct CTA) and "Explore Clinical Capabilities" (Transitional CTA).
- **Message (StoryBrand)**: "Transform Post-Operative Care with Proactive Triage, Bedrock AI Guardrails, and Live FDA Safety Intelligence."
- **Direct CTA**: `[Launch Live Clinician Demo →]` (prefills demo session and drops user into the triage dashboard).
- **Transitional CTA**: `[View 3-Minute Demo Playbook]` / `[Explore FDA Safety Engine]`.
- **Copy Blocks**:
  1. *Hero*: High-contrast headline, one-liner subtext, dual CTAs, verified trust badges (AWS Healthcare Track, openFDA FAERS, Bedrock Guardrails).
  2. *The Closed-Loop Problem vs Solution*: Compare traditional blind recovery (missed doses, late complications) vs RemoteCare Pro closed-loop triage.
  3. *Core Differentiators*: (A) Zero-Effort Mobile Ingestion, (B) Guardrailed Clinical AI Assistant, (C) Live openFDA Drug Safety Signal Detection.
  4. *Live Interactive Preview*: Embedded triage exception cards showcasing real-time Red/Amber alert triage and instant SMS/Call outreach triggers.

### /login (Clinician Sign-in Portal)
- **Purpose & Primary Conversion Action**: Fast, frictionless access for registered clinicians and 1-click test credentials for evaluators.
- **Direct CTA**: `[Log In]` & `[Quick Demo Clinician Login]` (instant auto-fill & login).
- **Copy Blocks**: Brand logo, clinical credential inputs, demo credential helper badge.

## Conversion Elements (Big 5 Objections & Counters)
| Objection (Big 5) | Counter | Placement | Status |
|---|---|---|---|
| **Trust**: "Is AI safe for surgical patients?" | Amazon Bedrock Guardrails enforce strict non-diagnostic, informational advice; clinicians remain the sole prescribing authority. | Hero subtitle & Safety Architecture section | Live |
| **Effort**: "Clinicians and patients don't have time for complex data entry." | 30-second clinician prescription builder; patient regimen auto-populates on mobile with zero manual drug typing. | "How it Works" 3-step timeline | Live |
| **Price / Value**: "Why not use a standard reminder app?" | Generic apps don't close the clinical loop; RemoteCare Pro provides real-time triage dashboards, adherence alerts, and automated FDA safety signal detection. | Comparison Matrix section | Live |
| **Fit**: "Does this support our surgery types and dose schedules?" | Pre-configured for orthopedics, cardiac, and general surgery with QD, BID, TID, QID, and PRN schedule automation. | Features grid & Case Creation | Live |
| **Timing**: "We need to see it working immediately without setting up accounts." | 1-Click instant demo mode with pre-seeded patient cohorts, live telemetry, and simulated adherence logs. | Sticky Header & Login Page | Live |

## Audit Findings
| Issue | Severity (0-4) | Fix | Status |
|---|---|---|---|
| Missing public landing page — root URL immediately redirects to blank login box | 4 (Blocker) | Build dedicated high-converting Clinician Landing Page at `/` with direct demo launch CTA | Done |
| No 1-click demo access for evaluators/judges (forced manual password entry) | 3 (High) | Add "Instant Demo Login" button on `/login` and landing page | Done |
| Clinician portal lacks visual hierarchy and spacing consistency across forms | 3 (High) | Refactor with standard spacing scale (4/8/16/24/32/48/64px) and WCAG-compliant color tokens | Done |
| Typography lacked modular scaling and line-height constraints | 2 (Medium) | Apply fluid clamp modular typography scale with strict 45-75ch line length | Done |
| Missing clear value proposition above the fold | 4 (Blocker) | Implement StoryBrand SB7 one-liner with direct and transitional CTAs | Done |

## Lead Capture & Evaluator Onboarding
- **Instant Demo Mode**: 1-click bypass button populates active clinician JWT session with full mock/seeded triage state.
- **Clinician Invite Onboarding**: Streamlined 6-digit one-time code distribution for mobile patient companion onboarding.
