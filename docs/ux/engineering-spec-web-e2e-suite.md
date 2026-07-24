# RemoteCare Pro — Automated Web E2E Integration Suite Specification (`/specify`)

**Document ID:** `docs/ux/engineering-spec-web-e2e-suite.md`  
**Domain & System:** Clinician Web Dashboard (`web/`) Automated Integration Testing  
**Status:** Proposed — not yet implemented

---

## 1. Ownership & Context
- **Owner**: Lead Front-End & Quality Engineer
- **Date**: July 22, 2026
- **Status**: Proposed — no automated tests exist in `web/` today
- **Design Spec Version**: v2.1

---

## 2. Problem & User Need
Clinicians depend on the **RemoteCare Pro Dashboard** to triage at-risk post-surgery patients accurately under high time pressure. Regression errors in risk badge filtering, triage alert resolution, or language switching could result in missed clinical escalations. An automated integration test suite would guarantee zero regressions across core clinical workflows — but as of this writing, `web/` has **zero** automated tests. `vitest` and `@testing-library/react` are installed as devDependencies in `web/package.json`, but there is no `test` script defined and no `*.test.*`/`*.spec.*` file anywhere in `web/src`. This document proposes the suite that would close that gap.

---

## 3. Proposed Test Architecture & Coverage Matrix

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                  PROPOSED WEB INTEGRATION SUITE MATRIX                      │
├─────────────────────────────────────────────────────────────────────────────┤
│ Test Suite                │ Target Component          │ Key Assertions      │
├───────────────────────────┼───────────────────────────┼─────────────────────┤
│ Triage Flow Suite         │ `TriageDashboardPage.tsx` │ Filter tabs, search │
│ Resolution Modal Suite    │ `TriageDashboardPage.tsx` │ Outreach & note log │
│ i18n Navigation Suite     │ `NavBar.tsx`              │ EN / ES / IT toggle │
│ FDA Safety Review Suite   │ `MedicationsPage.tsx`     │ Pill badge & link   │
└─────────────────────────────────────────────────────────────────────────────┘
```

None of the suites above exist yet. This matrix is a proposed starting scope, not a status report.

---

## 4. Proposed Test Cases & Assertions

The scenarios below describe what a first iteration of this suite *should* cover if built. They are written as candidate test cases for engineering to pick up, not as a record of tests that have been written or run.

### Proposed Test Case 1: Triage Dashboard Risk Filtering & Search
- **Intent**: Verify clinicians can isolate high-risk patients instantly.
- **Steps**:
  1. Render `TriageDashboardPage`.
  2. Verify initial badge metrics (Red Urgent: 1, Amber Caution: 2).
  3. Click `🚨 Red Urgent` tab $\rightarrow$ confirm only Maria Rossi (missed 2+ doses) is displayed.
  4. Type `"Maria"` into the search input $\rightarrow$ confirm matching cards persist.

### Proposed Test Case 2: Triage Exception Resolution Modal
- **Intent**: Confirm clinicians can resolve alerts with mandatory clinical notes.
- **Steps**:
  1. Click `✅ Resolve Exception` on Red Urgent card.
  2. Verify modal renders patient alert context and outreach method choices.
  3. Select `Phone Call` and enter clinical note: `"Spoke with patient; reminded regarding morning dose."`.
  4. Click `Resolve & Archive Alert` $\rightarrow$ confirm success toast appears and alert card is archived.

### Proposed Test Case 3: Multi-Language i18n Switcher
- **Intent**: Verify seamless language switching for international clinic staff.
- **Steps**:
  1. Render `NavBar` inside `LanguageProvider`.
  2. Click language dropdown and select `ES` (Español).
  3. Assert navbar links update (`Triage Dashboard` $\rightarrow$ `Panel de Triaje`, `Patients` $\rightarrow$ `Pacientes`).
  4. Select `IT` (Italiano) $\rightarrow$ assert links update to Italian.

---

## 5. Assets & Deliverables (Proposed, Not Yet Created)
- **Spec Document**: `docs/ux/engineering-spec-web-e2e-suite.md` (this document)
- **Integration Test Files (proposed, do not yet exist)**: a suite along the lines of `web/src/__tests__/triage_dashboard.test.tsx` and `web/src/__tests__/navbar_i18n.test.tsx` would need to be written from scratch, along with a `test` script added to `web/package.json` (e.g. `"test": "vitest"`), to make any of the above executable.
