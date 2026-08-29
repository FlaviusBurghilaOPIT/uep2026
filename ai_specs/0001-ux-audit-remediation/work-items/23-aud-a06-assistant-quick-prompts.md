---
type: Work Item
title: AUD-A06 AI Assistant Empty State Pre-Seeded Quick Prompts
parent: ../spec.md
---

## What to build
Provide 3 pre-seeded clinical quick prompt chips in empty `AssistantScreen` (`A05`): "Is mild swelling normal?", "When can I shower?", "Medication instructions" to bridge the Gulf of Execution for patients unsure what to ask.

## Required context
- Target file: `mobile/lib/features/assistant/presentation/screens/assistant_screen.dart`
- Widget: `SuggestionChips`

## Acceptance criteria
- [ ] Empty chat screen renders 3 prompt chips: "Is mild swelling normal?", "When can I shower?", "Medication instructions".
- [ ] Tapping a chip fills the message field and sends the query automatically.
- [ ] Chips disappear once the chat contains active messages.

## Covers
- User Stories: US3
- Requirements: Requirement 23
- Interview Ledger: L23

## Blocked by
None - ready to start
