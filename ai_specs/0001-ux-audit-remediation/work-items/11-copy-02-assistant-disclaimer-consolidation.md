---
type: Work Item
title: COPY-02 Consolidated AI Assistant Guardrail Disclaimers
parent: ../spec.md
---

## What to build
Remove repetitive medical disclaimers prepended to individual assistant chat bubbles in `AssistantScreen` (`A05`), relying on the persistent top guardrail banner to keep chat messages natural, focused, and conversational.

## Required context
- Target file: `mobile/lib/features/assistant/presentation/screens/assistant_screen.dart`
- Target file: `mobile/lib/features/assistant/presentation/providers/chat_assistant_notifier.dart`

## Acceptance criteria
- [ ] Chat bubbles render conversational medical responses without boilerplate disclaimer prefixes.
- [ ] The persistent `GuardrailBanner` at the top of the screen provides the legal guardrail context.

## Covers
- User Stories: US3
- Requirements: Requirement 11
- Interview Ledger: L11

## Blocked by
None - ready to start
