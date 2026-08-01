---
type: Work Item
title: Mobile — Assistant Streaming/Loading/Error Polish
parent: ../spec.md
---

## What to build
Polish the Assistant (the canonical term — see GLOSSARY.md). Render responses progressively (streaming) and provide honest loading and error states with no dead controls. Confirm the persistent informational-only ("never diagnostic") disclaimer banner; its shape is defined by `0001` Req 14 — coordinate to avoid duplicating that work, and use placeholder copy pending clinical sign-off.

## Required context
- `mobile/lib/features/assistant/` — the Assistant screen and `chat_assistant_notifier` (consolidate duplicates per `0001` Req 16 if not already done).
- `ai_specs/0001-mobile-core-loop-hardening-polish/spec.md` Req 14–16 — guardrail banner, refusal box, emergency CTA (banner shape source of truth).
- Backend AI chat endpoint / streaming response shape.
- Test seam: `mobile/test/unit/fake_api_service.dart`.

## Acceptance criteria
- [x] Assistant responses render progressively (streaming) rather than appearing only on completion.
- [x] Loading and error states render honestly; no dead controls.
- [x] The informational-only disclaimer banner is present (shape per `0001` Req 14); copy is placeholder pending ⚕ clinical sign-off.
- [x] Widget tests (FakeApiService) cover streaming, loading, and error states.

## Covers
- User Stories: 8
- Requirements: 26, 27, 28
- Testing Strategy: 2
- Interview Ledger: L5

## Blocked by
None - ready to start
