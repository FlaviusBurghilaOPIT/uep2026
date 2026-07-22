---
type: Spec
title: Mobile Core Loop Hardening & Interaction Polish
---

## Problem

The mobile app's Riverpod migration, notifier layer, and i10n (`ai_specs/work-items/01-03`) are complete, but two scoped Work Items remain fully unbuilt: interactive lock-screen notification actions (`04-interactive-notifications-dose-logging.md`, 0/9 AC) and AI assistant guardrail UX (`05-ai-assistant-chat-guardrail-notifier.md`, 0/11 AC). Separately, a code-grounded UX audit (`docs/ux/08-prioritized-ux-backlog.md`) found seven more mobile issues — no dedicated Medications screen (navigation buries prescriptions inside Today), no undo window on dose logging, color-only status pills, no timezone re-anchoring for reminders, no emergency-call path out of an AI refusal, no offline-sync feedback, and no FDA source/freshness indicator. These two efforts overlap directly (the pending notification and guardrail work is exactly where the undo-toast, timezone, and emergency-CTA fixes live) and neither has an explicit visual/interaction polish pass, even though this iteration calls for mobile to read as more finished than web.

## Proposed Outcome

One coherent mobile Work Item sequence that: rebuilds the navigation shell to 5 tabs including a new Medications screen; finishes the interactive-notification and AI-guardrail work already scoped in WI-04/WI-05 while folding in the overlapping backlog fixes (timezone reconciliation, emergency CTA); closes the remaining safety/trust gaps (offline sync banner, FDA provenance badge); and adds a small, explicit polish pass so dose logging feels finished rather than merely functional — all without introducing new backend endpoints, gamification, or scope outside the clinician→patient→clinician adherence loop.

## User Stories

1. As a patient, I want a 5-tab navigation (`Today`, `Medications`, `Recovery`, `Assistant`, `Profile`) with a full prescription list under `Medications`, so I can find my clinician-authored instructions without digging through `Today`. [L3]
2. As a patient with motor tremors, I want a 5-second undo option after logging a dose, so an accidental tap doesn't send the wrong status to my clinician. [L3]
3. As a colorblind patient, I want dose status shown with an icon and text label, not color alone, so I can tell Taken/Skipped/Missed apart. [L3]
4. As a patient, I want to tap `[Take Dose]` or `[Snooze 15m]` directly from a lock-screen notification, and have reminders re-anchor correctly across timezones and DST changes, so logging stays effortless and reminders never fire at the wrong local time. [L1, L3]
5. As a patient asking the AI assistant something out of scope (e.g. a dosage change) or expressing urgency, I want a clear refusal with a 1-tap **Call Emergency Contact** button, so I'm never left without a next step. [L1]
6. As a patient logging a dose while offline, I want a persistent banner telling me my log is queued and will sync, so I don't re-log unnecessarily. [L1]
7. As a patient reading FDA safety content, I want to see whether it's live openFDA data or a cached fixture, and when it was retrieved, so I can judge its freshness.
8. As a patient, I want dose logging to feel polished — smooth status transitions, haptic feedback, a small completion moment — so the app feels finished, without turning into a gamified streak system. [L2]

## Requirements

### Navigation & Medications Screen
1. Bottom navigation shows 5 tabs in order: `Today`, `Medications`, `Recovery`, `Assistant`, `Profile`, replacing the current 4-tab layout (`Today`, `Check-In`, `Assistant`, `Recovery`). [L3]
2. The daily feeling check-in is embedded as a top action card on `Today`, not a standalone tab. [L3]
3. `Medications` renders the full active prescription list (name, dose, schedule, clinician-authored source) fetched via `GET /cases/{id}/medications`. No screen currently exists for this — it is new, not a relocation. [L3]
4. `Profile` is reachable as a tab; the existing `profile_screen.dart` content is reused rather than rebuilt.
5. The stale duplicate `mobile/lib/core/services/api_service.dart` is deleted; all imports resolve to `mobile/lib/core/network/api_service.dart`.

### Dose Logging UX
6. Tapping a status button (`Taken`/`Skipped`/`Missed`) shows a 5-second undo snackbar ("Logged as Taken. Undo") before the log is unrevertable. Tapping Undo within the window reverts the card to pending, locally and via the API. [L3]
7. Each dose status pairs its color with a distinct icon and explicit text label (checkmark/Taken, warning triangle/Skipped, cross/Missed), remaining 100% distinguishable in grayscale. [L3]
8. Status transitions animate rather than swap instantly; logging a dose triggers haptic feedback; completing all doses for a day shows a small, non-blocking, dismissible celebratory state — no streak counters, badges, or shame copy. [L2]

### Interactive Notifications & Reliability (completes WI-04)
9. Notifications reschedule on app launch and on OS timezone-change events via `NotificationService.instance.reinitialize()`, so DST/travel does not shift wall-clock reminder times. [L1, L3]
10. Notifications offer `[Take Dose]` (background-logs `taken` via `POST /adherence/log` with haptic feedback) and `[Snooze 15m]` (reschedules +15 minutes) actions directly on iOS and Android lock screens. [L1, L3]
11. Tapping the notification body (not an action button) opens the app and highlights the target medication card.
12. Background-originated duplicate log attempts (e.g. a delayed retry firing twice) must resolve silently using the backend's 409-conflict response rather than surfacing an error to the patient. This depends on the backend `POST /adherence/log` conflict-handling fix, which is tracked outside this Spec (see Out of Scope).
13. Offline dose logs show a persistent top banner ("Saved offline. Will sync when connected.") that clears automatically once the local pending queue successfully flushes. [L1]

### AI Assistant Guardrail UX (completes WI-05)
14. The assistant screen shows a persistent top guardrail banner ("Informational only, never diagnostic"), one-tap suggestion chips, and an animated 3-dot typing indicator while awaiting a response. [L1]
15. An out-of-scope response renders a prominent red-bordered refusal box containing a bold **Call Emergency Contact ({phone})** button linking to `tel:`, sourced from `GET /cases/{id}/emergency-contact`. [L1]
16. The duplicate `assistant_screen.dart` files (`mobile/lib/features/assistant/assistant_screen.dart` vs. `mobile/lib/features/assistant/screens/assistant_screen.dart`) are consolidated into the one wired into `main_shell_page.dart`; the orphan is deleted. [L1]

### FDA Content Provenance
17. FDA warning content shows a source badge (`📋 Source: openFDA Live` / `Regulatory Cache`) and a `Retrieved: YYYY-MM-DD` timestamp above the warnings, reflecting whether the backend served live data or a fixture fallback.

### Copy & Localization
18. All new or changed user-facing strings source from `docs/ux/06-content-system.md` and are added to all 5 locale-backed ARB files (`en`, `it`, `es`, `fr`, `de`) — no hardcoded strings introduced.

## Technical Decisions

1. WI-04 and WI-05's remaining acceptance criteria are completed as Work Items under this Spec rather than as separate parallel specs; the original `ai_specs/work-items/04-...md` and `05-...md` files are marked superseded (not deleted) for traceability. [L1]
2. Work Items are sequenced around the clinician→patient→clinician loop rather than strictly by technical layer: shell/IA first, then core dose-logging + notification reliability, then safety/resilience, then polish. [L3]
3. No new backend endpoints are introduced by this Spec. All Work Items consume existing REST endpoints (`GET /cases/{id}/medications`, `POST /adherence/log`, `GET /cases/{id}/emergency-contact`). The backend `POST /adherence/log` 409-conflict fix and `ChatMessage.escalate` persistence fix are tracked as separate GitHub Issues per `docs/product/10-implementation-plan.md`, not as Work Items here — Work Items that depend on them note it explicitly under Required Context rather than re-implementing backend logic. [L3]
4. `docs/product/10-implementation-plan.md` is the approved source for each Work Item's description, files-likely-affected, dependencies, Definition of Done, and test plan; Work Items reference it directly under Required Context rather than restating every file path in full. [L4]

## Testing Strategy

1. TDD is expected for logic/state changes in Riverpod notifiers — undo-toast state transitions, navigation index handling, notification reschedule logic — per `act-flutter-tdd` discipline: write the failing test first.
2. Widget tests are required for: the 5-tab shell rendering and switching `IndexedStack` state correctly, status pill icon+text rendering across all 3 states in grayscale, the assistant screen's refusal box + emergency CTA rendering with the correct `tel:` link, and the FDA badge's live/fixture states.
3. No robot/journey test expansion is required beyond what exists in `mobile/test/widget/`. Interactive lock-screen notification actions cannot be exercised in a widget-test harness and must be verified manually on-device (iOS + Android) using the `act-flutter-screenshot` and `act-flutter-driver-mcp` skills.
4. Test Seams: continue using the existing `FakeApiService` (`mobile/test/unit/fake_api_service.dart`) and `http.Client` fakes. No live network or push-notification-service calls in automated tests.
5. Animation/haptic polish (the micro-interactions Work Item) has no meaningful automated assertion; verify via manual visual QA rather than a brittle golden-image test, and say so explicitly in that Work Item's PR rather than fabricating a test.

## Out of Scope

- Backend `POST /adherence/log` 409-conflict handling and `ChatMessage.in_scope`/`escalate` persistence — tracked as GitHub Issues, not Work Items in this Spec.
- The Web Triage & Exceptions Dashboard and all other web/backend issues from `docs/product/10-implementation-plan.md` §4 — tracked as GitHub Issues.
- Documents, caregiver accounts, advanced charts, deep reporting, clinical-guideline integrations.
- Dark mode — not called for by `docs/ux/07-accessibility-spec.md`, not introduced speculatively by the polish Work Item.
- A backend triage-aggregation endpoint, and the Response Time Gauge / event-timestamp analytics infrastructure referenced in `docs/product/09-measurement-plan.md` §4.1 Widget 3.

## Open Questions

- Exact current location/shape of the offline pending-dose-log queue (referred to as `PendingQueueTable` in `docs/ux/08-prioritized-ux-backlog.md` but not yet located in a source-file scan) — confirm during implementation of the offline-sync-banner Work Item.
- Whether `mobile/pubspec.yaml` still carries any transitive reference to the removed `provider` package — confirm clean during the shell-restructure Work Item's `flutter analyze` pass.

## Notes

Supersedes (does not delete) `ai_specs/work-items/04-interactive-notifications-dose-logging.md` and `ai_specs/work-items/05-ai-assistant-chat-guardrail-notifier.md`. Parent context: `docs/product/10-implementation-plan.md` (full iteration plan, all workstreams), `docs/ux/08-prioritized-ux-backlog.md` (originating UX audit), `docs/product/09-measurement-plan.md` (telemetry/experiment guardrails referenced above).
