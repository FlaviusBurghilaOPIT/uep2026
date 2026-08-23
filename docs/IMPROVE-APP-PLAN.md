# Improve App Plan

## Context
- **Product**: RemoteCare Pro (Post-Surgery Recovery & Closed-Loop Clinician Triage Platform)
- **Platforms**: Flutter Mobile App (iOS / Android Patient Companion) + React/Vite Clinician Web Portal & FastAPI Backend
- **Commercial Model**: All-inclusive clinical license — 100% features included for clinics from Day 1 (zero artificial tier gating or paywalls).
- **Core Problem**: Post-op patients struggle with complex medication regimens and anxiety after hospital discharge; clinicians suffer from blind recovery windows and non-adherence drop-off.
- **Goal**: Elevate product experience from a functioning prototype to an effortless, frictionless, visually authoritative clinical companion with truthful persuasion, crisp feedback, and brutal quality standards.
- **Date Started**: 2026-08-23
- **Date Completed**: 2026-08-23

## Phase Status
| Phase | Skill | Status | Artifact | Date |
|---|---|---|---|---|
| 1 | jobs-to-be-done | done | CUSTOMER.md | 2026-08-23 |
| 2 | ux-heuristics | done | DESIGN.md, EXPERIMENTS.md | 2026-08-23 |
| 3 | design-everyday-things | done | DESIGN.md, EXPERIMENTS.md | 2026-08-23 |
| 4 | refactoring-ui | done | DESIGN.md, EXPERIMENTS.md | 2026-08-23 |
| 5 | microinteractions | done | DESIGN.md, EXPERIMENTS.md | 2026-08-23 |
| 6 | made-to-stick | done | POSITIONING.md, EXPERIMENTS.md | 2026-08-23 |
| 7 | influence-psychology | done | POSITIONING.md, EXPERIMENTS.md | 2026-08-23 |
| 8 | high-perf-browser | done | DESIGN.md, EXPERIMENTS.md | 2026-08-23 |
| 9 | steve-jobs-design-review | done | PRODUCT.md, DESIGN.md, EXPERIMENTS.md | 2026-08-23 |

*Statuses: pending · in-progress · awaiting-evidence · done · deferred: <reason> · skipped: <reason>*

## Key Decisions
| Date | Phase | Decision | Rationale |
|---|---|---|---|
| 2026-08-23 | Intake | Initiated full 9-phase improve-app journey across Mobile Patient App and Clinician Web Portal | Ensures end-to-end evidence-based experience improvement from JTBD to Steve Jobs review |
| 2026-08-23 | Phase 1 (JTBD) | Defined product-agnostic job statements; established Emotional & Functional underdelivery as co-primary targets | Patients need instant reassurance and frictionless dose logging; care teams need automated triage |
| 2026-08-23 | Phase 2 (UX Heuristics) | Prioritized Severity-4 emergency escalation banner (UX-01) and Severity-3 optimistic dose logging (UX-02) and OTP ease (UX-03) | Eliminates critical patient safety risks and daily logging friction; queued as EXP-004 & EXP-005 |
| 2026-08-23 | Phase 3 (Norman Design) | Replaced modal confirmation dialogs with 5-second non-blocking Undo snackbars; locked Rx creation to validated time slots | Eliminates slip anxiety while preserving speed and data integrity |
| 2026-08-23 | Phase 4 (Refactoring UI) | Enforced strict 8-point spacing scale, tinted slate neutrals, 1-dominant hero action per view, and Flutter 3.27+ `spacing:` / widget-class patterns | Guarantees clean visual hierarchy and maintainable Riverpod architecture across platforms |
| 2026-08-23 | Phase 5 (Microinteractions) | Established sub-100ms haptic feedback for dose logging and "Day Complete" Ring Closure as the core signature moment | Delivers emotional payoff and immediate direct-manipulation clarity |
| 2026-08-23 | Phase 6 (Made to Stick) | Defined single-focus Commander's Intent per view and replaced robotic jargon with concrete SUCCESs copy | Transforms sterile logs into comforting, clear human guidance |
| 2026-08-23 | Phase 7 (Influence Psychology) | Clarified all-inclusive clinical license model (no artificial paywalls) and grounded patient prompts in genuine Commitment & Consistency | Protects clinical integrity and ensures 100% truthful persuasion |
| 2026-08-23 | Phase 8 (Performance) | Set strict targets: INP < 100ms, LCP < 1.2s, CLS < 0.01; masked network latency with optimistic state & skeleton loaders | Perceived instantaneous speed is non-negotiable for medical applications |
| 2026-08-23 | Phase 9 (Steve Jobs Review) | Executed cold walkthrough: Cut artificial tier gates, chat disclaimer repeats, and modal popups; committed back-of-the-fence polish | Reduces steps-to-value to 1 single tap (<2s) and elevates whole experience to insanely great |

## Next Actions (Transferred to Owning Artifacts)
- [x] All core findings, cuts, and fixes mapped into `docs/PRODUCT.md`, `docs/DESIGN.md`, `docs/POSITIONING.md`, `docs/CUSTOMER.md`, and `docs/EXPERIMENTS.md`
- [x] Full improve-app journey closed with 100% phase completion
