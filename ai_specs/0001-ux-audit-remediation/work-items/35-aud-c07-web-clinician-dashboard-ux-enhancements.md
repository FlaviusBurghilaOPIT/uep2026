---
type: Work Item
title: AUD-C07 Web Clinician Dashboard Super UX Audit Enhancements
parent: ../spec.md
---

## What to build
Apply full Super UX Audit enhancements to `web/src/pages/dashboard.astro`:
- **Miller's Law / Cowan (Phase 5)**: Constrain KPI stats to 4 concise cards (Critical Alerts, Medium Alerts, Total Monitored, Median Resolution Time).
- **Kahneman System 1 (Phase 2)**: Visual severity indicators and pre-computed risk metrics eliminating cognitive strain.
- **Norman Affordances & Dual-Coding (Phases 4 & 6)**: 4px solid left severity borders on triage table rows with dual-coded status pill badges (icon + text).
- **Tesler's Law (Phase 9)**: 1-click inline resolution modal with required audit reason note directly from table rows.
- **Microinteractions (Phase 8)**: Sub-100ms row status update in-place without page reload.
- **Meaning & Accomplishment (Phases 11 & 12)**: Reassuring zero-state card when all triage exceptions are cleared.

## Required context
- Target file: `web/src/pages/dashboard.astro`
- Target file: `web/src/__tests__/TriageDashboard.test.ts`

## Acceptance criteria
- [x] Dashboard displays exactly 4 chunked KPI summary cards.
- [x] Triage table rows feature 4px left accent borders (`#ef4444` red, `#f59e0b` amber) and dual-coded badges.
- [x] Inline resolution modal allows resolving alerts without navigating away.
- [x] Real-time roster search and severity filter tabs function seamlessly.
- [x] Zero-state card appears when no active triage exceptions exist.

## Covers
- User Stories: US2
- Requirements: Requirement 35
- Interview Ledger: L35

## Blocked by
None - completed
