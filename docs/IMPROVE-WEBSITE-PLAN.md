# Improve Website Plan

## Context
- **Target Surface**: Clinician Landing & Portal Onboarding (RemoteCare Pro)
- **Primary Conversion Action**: Convert prospective clinicians / clinics to request a demo and create their first patient case
- **Problem Statement**: Visitors bounce without grasping the core value proposition (closed-loop post-op adherence, Clinical AI guardrails, live FDA safety) and interface currently defaulted to raw login without an authoritative value proposition
- **Traffic Profile**: Early-stage / Hackathon / Pitch demo (<500 weekly visits) — qualitative CRO, Nielsen heuristics, StoryBrand messaging, and Refactoring UI visual hierarchy
- **Top Complaint**: "Nobody understands what we do or why it's different from generic reminder apps"
- **Date Started**: 2026-08-23

## Phase Status
| Phase | Skill | Status | Artifact | Date |
|---|---|---|---|---|
| 1 | cro-methodology | done | METRICS.md, WEBSITE.md, EXPERIMENTS.md | 2026-08-23 |
| 2 | ux-heuristics | done | DESIGN.md, EXPERIMENTS.md | 2026-08-23 |
| 3 | refactoring-ui | done | DESIGN.md, EXPERIMENTS.md | 2026-08-23 |
| 4 | web-typography | done | DESIGN.md, EXPERIMENTS.md | 2026-08-23 |
| 5 | storybrand-messaging | done | POSITIONING.md, EXPERIMENTS.md | 2026-08-23 |
| 6 | high-perf-browser | done | METRICS.md, WEBSITE.md, EXPERIMENTS.md | 2026-08-23 |
| 7 | made-to-stick | done | POSITIONING.md, EXPERIMENTS.md | 2026-08-23 |
| 8 | design-everyday-things | done | DESIGN.md, EXPERIMENTS.md | 2026-08-23 |
| Opt A | influence-psychology | done | WEBSITE.md, POSITIONING.md | 2026-08-23 |
| Opt B | microinteractions | done | DESIGN.md | 2026-08-23 |
| Opt C | top-design | done | DESIGN.md, LandingPage.tsx | 2026-08-23 |
| Opt D | code-reviewer | done | Review Summary, Vitest Suite | 2026-08-23 |
| Opt E | web-performance-auditor | done | Code Splitting, Memoization | 2026-08-23 |

*Statuses: pending · in-progress · awaiting-evidence · done · deferred: &lt;reason&gt; · skipped: &lt;reason&gt;*

## Key Decisions
| Date | Phase | Decision | Rationale |
|---|---|---|---|
| 2026-08-23 | Intake | Scoped to Clinician Landing & Onboarding Portal with ONE primary action: "Launch Live Demo / Create Patient Case" | Clear focus avoids competing CTAs; aligns with clinician & judge personas |
| 2026-08-23 | Phase 1 (CRO) | Mapped blocked arteries & O/CO table for Big 5 objections; established OMTM as Clinician Activation Rate (target >35%) | Solves root cause of bounce: strangers lacked value prop and had an auth wall |
| 2026-08-23 | Phase 2 (UX Heuristics) | Built dedicated `/landing` page and added 1-click demo login shortcut on `/login` | Eliminates Nielsen H8/H10 friction where guest evaluators could not experience the platform |
| 2026-08-23 | Phase 3 (Refactoring UI) | Applied 8-point spacing scale, tinted slate grays, elevation shadows, and high-contrast clinical status pills | Creates immediate clinical visual hierarchy and authority |
| 2026-08-23 | Phase 4 (Typography) | Fluid clamp display heading (`clamp(2rem, 3.5vw + 1rem, 3.25rem)`), 66ch measure, zero external font blocking | Instant 0ms FOIT/FOUT rendering with high legibility across viewports |
| 2026-08-23 | Phase 5 (StoryBrand) | Implemented SB7 framework: Character (Surgeon), Problem (Blind post-op gap), Guide (RemoteCare Pro), Plan (3-Step Loop) | Replaces confusing tech jargon with clear clinical value proposition in EN, ES, IT |
| 2026-08-23 | Phase 6 (Performance) | Optimized bundle chunks with `React.lazy()` and `<Suspense>`, memoized `LanguageProvider`, eliminated inline style injection in Select; LCP target <1.2s | Initial chunk size reduced from 652KB to 449KB; page built in 175ms |
| 2026-08-23 | Phase 7 (Made to Stick) | Added concrete SUCCESs stats (>92% adherence, sub-60s triage response) and Sinatra test | Concrete proof beats vague marketing claims |
| 2026-08-23 | Phase 8 (Design Everyday Things) | Integrated Norman constraints, instant feedback toasts, and 1-click simulated triage resolution with unmount timer cleanup | Bridges gulf of execution and evaluation for first-time visitors |
| 2026-08-23 | Code Review & QA | Added automated test suite with Vitest and `@testing-library/react` (100% passing across Landing, Login, and i18n) | Ensures regression-free clinical workflows |

## Next Actions
- [x] Create and verify `SPEC.md` (`spec-driven-development`)
- [x] Create and verify `tasks/plan.md` and `tasks/todo.md` (`planning-and-task-breakdown`)
- [x] Validate build with `npm test`, `npm run build`, and `npm run lint`
- [ ] Run live demo walkthrough with AWS Hackathon mentors/judges (P1/P2)
