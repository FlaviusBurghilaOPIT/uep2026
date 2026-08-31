# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

**Primary — Post-surgical patient recovering at home.**
A person recently discharged after surgery (e.g., total knee arthroplasty) who has transitioned from 24/7 hospital observation to unsupervised home recovery. They need structured guidance on medication adherence, symptom awareness, and when to escalate. Typical profile: limited medical literacy, potentially managing pain, anxious about what is normal vs. alarming, checking the app several times a day on a mobile device.

**Secondary — Clinical care team (surgeons, surgical nurses, care coordinators).**
Clinicians managing a post-operative cohort from a workstation. They need to see exceptions — patients who missed doses, reported distress, or triggered safety signals — not dashboards of healthy data. They prescribe medication regimens, resolve triage alerts, and review drug-safety intelligence.

## Product Purpose

RemoteCare Pro replaces passive paper discharge instructions with an active, closed-loop recovery ecosystem that connects patients and surgical care teams in real time.

**What it does:** Tracks medication adherence, captures daily symptom check-ins, provides 24/7 AI-grounded recovery guidance, escalates emergencies to clinicians instantly, and surfaces clinical exceptions in a priority-ranked triage queue.

**Why it exists:** The "care cliff" — the 30-day post-discharge window — is when most preventable complications occur. Up to 43% of patients mismanage analgesics, 13–19% are readmitted within 30 days (up to 40% judged preventable), and care teams have zero systematic visibility into recovery until emergencies force ER visits.

**What success means:** Patients complete their recovery regimen with confidence and safety. Clinicians catch complications early through exception-driven monitoring rather than scheduled follow-ups.

## Positioning

The two-tier guardrailed AI recovery assistant is the core differentiator. A deterministic pre-execution classifier intercepts diagnostic and dosage-alteration queries before they reach the LLM, serving standard refusal copy and surfacing direct hotline escalation. The grounded RAG layer answers permissible questions using vector-embedded clinical protocols (NICE, WHO, FDA). A competing product could build a chatbot or a monitoring dashboard, but could not truthfully claim the same deterministic safety architecture that prevents the AI from ever providing clinical advice outside its guardrails.

## Operating Context

### Patient surface (Flutter mobile app)
- Server-driven daily "Today" agenda with scheduled medication timeline
- 1-tap optimistic dose logging (<50ms UI update) with 5-second non-blocking undo
- Offline-first queue synchronization with UUIDv4 deduplication
- Structured 4-tier daily symptom check-in (Great / OK / Not Great / Unwell)
- Acute symptom selection triggers emergency dialer (911 / 112 / surgical hotline) and instant clinician triage escalation
- Guardrailed AI recovery assistant for 24/7 guidance
- Adherence milestone celebrations with haptic feedback and ring-closure animation

### Clinician surface (Astro SSR web portal)
- Urgency-ranked triage exception roster (Critical / Warning / Stable)
- Inline alert resolution with mandatory outreach notes and audit logging
- Patient case authoring and constrained prescription scheduling (QD/BID/TID/QID/PRN)
- openFDA drug safety intelligence: boxed warnings, adverse interactions, recall notices inline during prescribing
- 14-day telemetry trajectories

### Infrastructure
- FastAPI async backend with PostgreSQL 16 + pgvector
- Database-level multi-tenant isolation via Row-Level Security (RLS)
- Passwordless OTP auth for patients; password + JWT for clinicians
- Arize Phoenix self-hosted LLM observability with OpenTelemetry distributed traces and USD cost attribution
- Docker Compose deployment (Nginx gateway, backend, Postgres, Phoenix)

## Capabilities and Constraints

### Confirmed capabilities
- 5-locale i18n support: EN, IT, ES, FR, DE
- Dynamic text scaling up to 200%
- Screen-reader semantic landmarks
- Touch targets ≥ 48×48dp
- Offline-first mobile architecture with sync queue
- openFDA live drug-safety data integration
- Server-Sent Events (SSE) for streaming AI responses

### Technical constraints
- No mock server — the backend with Postgres is required for web and mobile to function (unit/widget tests are self-contained)
- Two parallel code paths exist in the backend (live routers vs. dead `app/api/` code from earlier prototype) — only `app/routers/` is live
- Two auth implementations exist in mobile (ChangeNotifier production flow vs. StateNotifier test-only flow)
- Code generation required after editing `@freezed` / `@riverpod` classes

### Undecided
- Native mobile deployment targets (iOS App Store, Google Play) — not yet decided
- Real clinical regulatory approval path — HIPAA awareness exists but formal compliance is not established

## Evidence on Hand

- 496 automated tests passing across all three tiers (178 backend, 32 web, 286 mobile)
- Real openFDA API integration with live boxed warnings and adverse reaction data
- Arize Phoenix observability with real OpenTelemetry traces, latency metrics, and cost attribution
- Database seeding with two simulation modes (full cohort, clinician-only for live demo)
- App icon at `mobile/assets/images/Icon.png`
- No confirmed user research, testimonials, case studies, or clinical trial data — future work must not fabricate these

## Product Principles

1. **Exception-driven, not dashboard-driven.** Surface what needs attention; hide what doesn't. Clinicians see patients who need intervention, not green-light dashboards.
2. **Safety is deterministic.** The AI guardrail layer uses pre-execution classification, not probabilistic filtering. Dangerous queries are intercepted before they reach the LLM, every time.
3. **Optimistic and offline-first.** Patient interactions (dose logging, check-ins) respond instantly via optimistic updates and queue for sync. Recovery doesn't pause for connectivity.
4. **Escalation is always one tap away.** Whether it's a symptom check-in flagging distress or the AI assistant detecting a dangerous question, the path to a human clinician or emergency services is immediate and prominent.
5. **Earn trust through transparency.** Every AI response is grounded in cited clinical protocols. Every LLM transaction is traced, costed, and auditable. Every triage resolution is logged with clinical notes.

## Accessibility & Inclusion

- WCAG 2.1 AA compliance (implemented in mobile, required across all surfaces going forward)
- HIPAA-awareness: database-level RLS tenant isolation, audit logging, no PHI in client-side logs — formal compliance path undecided
- 5-locale language support is a durable requirement (EN, IT, ES, FR, DE)
- Minimum 48×48dp touch targets on all interactive elements
- Dynamic text scaling support up to 200%

## Context

This is a University Engagement Program 5.0 (OPIT 2026) capstone project by Team CarePro Innovators, intended to evolve toward real clinical deployment. The academic submission, demo workflow, and rubric criteria are near-term constraints; production-grade architecture and clinical safety are long-term commitments.
