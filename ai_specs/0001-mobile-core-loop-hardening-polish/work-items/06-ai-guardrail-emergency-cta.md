---
type: Work Item
title: AI Assistant Guardrail UX + Emergency Call CTA (completes WI-05)
parent: ../spec.md
---

## What to build

Complete the previously-scoped, unbuilt AI assistant guardrail UX work (`ai_specs/work-items/05-ai-assistant-chat-guardrail-notifier.md`, 0/11 AC, now superseded by this Work Item): a persistent top guardrail banner, one-tap suggestion chips, an animated typing indicator, and — folding in the previously separate FIND-M04 finding — a prominent red-bordered refusal box with a 1-tap **Call Emergency Contact** button whenever the backend's guardrail intercepts an out-of-scope query. Also consolidate the duplicate `assistant_screen.dart` files left over from an earlier refactor.

## Required context

- `docs/product/10-implementation-plan.md` Issue #11.
- `ai_specs/work-items/05-ai-assistant-chat-guardrail-notifier.md` — now marked superseded; its "What to build" still applies as background, but its checkboxes are completed here.
- **File duplication to resolve:** `mobile/lib/features/assistant/assistant_screen.dart` and `mobile/lib/features/assistant/screens/assistant_screen.dart` both currently exist. `main_shell_page.dart` imports the former (`features/assistant/assistant_screen.dart`) — keep that one, delete the orphan under `screens/`, and confirm no other file references it before deleting.
- `mobile/lib/features/assistant/providers/chat_assistant_notifier.dart` (+ `.freezed.dart`).
- Backend guardrail: `backend/app/routers/ai.py` `_check_guardrail()` / `POST /ai/chat` already returns `in_scope`/`escalate` in the response (persistence to the DB is tracked separately as GitHub Issue #2 — not part of this Work Item).
- `GET /cases/{id}/emergency-contact` (`backend/app/routers/cases.py:131`) — existing endpoint for the CTA's phone number.
- `docs/ux/06-content-system.md` Category 13 (AI Assistant Welcome, Refusal & Handoff copy).
- `mobile/test/widget/assistant_screen_test.dart`, `mobile/test/unit/chat_provider_test.dart` — existing test files to extend.

## Acceptance criteria

- [x] Top guardrail banner ("Informational only, never diagnostic") is persistently visible on the assistant screen.
- [x] Four one-tap suggestion chips render per `docs/ux/06-content-system.md` Category 13.
- [x] Animated 3-dot typing indicator shows while awaiting a `POST /ai/chat` response.
- [x] When a response has `in_scope: false`, render a prominent red-bordered refusal box containing a bold **Call Emergency Contact ({phone})** button linking to `tel:{phone}`, sourced from `GET /cases/{id}/emergency-contact`.
- [x] Tapping the emergency CTA launches the device dialer with the correct number.
- [x] `mobile.assistant.guardrail_triggered` and `mobile.assistant.emergency_cta_tapped` telemetry events fire correctly per `docs/product/09-measurement-plan.md` §3.1-3.2.
- [x] Duplicate `mobile/lib/features/assistant/screens/assistant_screen.dart` is deleted; `flutter analyze` shows zero orphan-file/unused-import warnings.
- [x] `mobile/test/widget/assistant_screen_test.dart` extended: out-of-scope message → refusal box + emergency CTA render, and CTA's `tel:` link matches the case's emergency contact.

## Covers

- User Stories: 5
- Requirements: AI Assistant Guardrail UX 14-16
- Interview Ledger: L1

## Blocked by

1 — only needs the shell restructure done; independent of the Today/notifications track (Work Items 2-5) and can run in parallel with them.
