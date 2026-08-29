---
type: Work Item
title: AUD-C05 Remove One-Click Clinician Demo Login and Enforce Secure Authentication
parent: ../spec.md
---

## What to build
Remove the one-click demo clinician login shortcuts and prefilled bypasses across the marketing landing page and login form (`web/src/pages/landing.astro`, `web/src/pages/login.astro`, and translation files) so all clinician access requires deliberate, authenticated organizational credentials adhering to clinical security standards (Brignull Truth Gate / Steve Jobs Focus).

## Required context
- Target file: `web/src/pages/landing.astro`
- Target file: `web/src/pages/login.astro`
- Target file: `web/src/i18n/translations/`

## Acceptance criteria
- [x] "Launch Live Demo" / "Launch Live Clinician Demo" buttons are replaced with professional "Clinician Sign In" / "Access Clinician Portal" links directly navigating to `/login`.
- [x] No automatic 1-click credential population or bypass script executes on login.
- [x] Clinician login requires real, deliberate username/password input.
- [x] Security notice regarding authorized healthcare organization credentials is prominently displayed.

## Covers
- User Stories: US2
- Requirements: Requirement 33
- Interview Ledger: L33

## Blocked by
None - completed
