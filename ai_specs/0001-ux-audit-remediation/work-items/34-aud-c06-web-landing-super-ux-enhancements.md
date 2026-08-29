---
type: Work Item
title: AUD-C06 Web Landing Page Super UX Audit Enhancements
parent: ../spec.md
---

## What to build
Apply full Super UX Audit enhancements to `web/src/pages/landing.astro`:
- **Jobs-to-be-Done (Phase 1)**: Clear headline addressing surgical care team progress (*"Close the 30-Day Post-Op Recovery Gap with Real-Time Adherence Telemetry & Automated Clinical Triage"*).
- **Thinking-Fast-Slow (Phase 2)**: Visual telemetry cards showing explicit time deltas and pre-computed risk metrics to eliminate cognitive strain.
- **Don't Make Me Think (Phase 3)**: Billboard scanning structure, front-loaded action verbs, sticky header navigation with active section highlighting.
- **Design Everyday Things (Phase 4)**: Interactive telemetry demo with clear signifiers, tactile simulation buttons, and real-time resolution feedback.
- **Laws of UX (Phase 5)**: Fitts's Law 44px+ touch targets, Miller/Cowan 3–4 chunk layout for feature cards, Von Restorff distinct accent pills.
- **100 Things Every Designer Needs to Know (Phase 6)**: Strict 45–72 characters per line measure (`max-width: 65ch`) on all narrative text blocks, dual-coded color + icon indicators.
- **Refactoring UI (Phase 7)**: Systematic spacing scale, crisp slate neutral hierarchy, WCAG AAA contrast ratios.
- **Cashvertising & Pre-suasion (Phases 13-14)**: AIDPA sequence, Life-Force 8 (protection of health), non-skippable proof step with verified clinical pilot roles.
- **Truth Gate & Deceptive Patterns Veto (Phase 16)**: Full transparency notes, clear non-diagnostic clinical disclaimer, zero synthetic social proof.

## Required context
- Target file: `web/src/pages/landing.astro`
- Target file: `web/src/__tests__/LandingPage.test.tsx`

## Acceptance criteria
- [x] Hero headline and value proposition clearly frame the core clinical job without happy-talk filler.
- [x] Interactive telemetry card allows clinicians to simulate 1-click outreach with immediate visual feedback.
- [x] Body text adheres to 45–75 character measure guidelines for optimal readability.
- [x] Status pills and feature badges employ dual coding (color + Lucide icon + label).
- [x] Verified partner references and clinical compliance disclosures pass the Truth Gate.

## Covers
- User Stories: US1, US2
- Requirements: Requirement 34
- Interview Ledger: L34

## Blocked by
None - completed
