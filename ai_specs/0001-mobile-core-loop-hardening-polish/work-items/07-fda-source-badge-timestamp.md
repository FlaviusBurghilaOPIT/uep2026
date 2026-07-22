---
type: Work Item
title: openFDA / Fixture Source Badge & Retrieval Timestamp
parent: ../spec.md
---

## What to build

Render an explicit source badge (`📋 Source: openFDA Live` / `Regulatory Cache`) and a `Retrieved: YYYY-MM-DD` timestamp above FDA safety warning content, so patients can judge the freshness and provenance of what they're reading.

## Required context

- `docs/product/10-implementation-plan.md` Issue #13.
- `mobile/lib/features/recovery/recovery_screen.dart` — FDA content section (backlog references an `FDAPage` as well; confirm current widget structure while implementing).
- `docs/product/03-safety-and-edge-cases.md` Case 12 (FDA Source Is Unavailable) — the badge must correctly reflect fixture-fallback state.
- `docs/ux/06-content-system.md` Category 12 for exact badge/timestamp copy.
- Backend: `backend.fda.fallback_to_fixture_triggered` telemetry event (per `docs/product/09-measurement-plan.md` §3.1) indicates when a request fell back to fixture data — the mobile client needs the corresponding response metadata to render the correct badge state (confirm the FDA response schema exposes this while implementing; do not add a new backend field speculatively without checking what already exists).

## Acceptance criteria

- [ ] Source badge and `Retrieved: YYYY-MM-DD` timestamp render above FDA warning content.
- [ ] Badge correctly switches between `openFDA Live` and `Regulatory Cache` states based on the API response's source metadata.
- [ ] Widget test asserting both badge states render correctly from mocked API responses.

## Covers

- User Stories: 7
- Requirements: FDA Content Provenance 17

## Blocked by

1 — only needs the shell restructure done; independent screen, can run in parallel with Work Items 2-6.
