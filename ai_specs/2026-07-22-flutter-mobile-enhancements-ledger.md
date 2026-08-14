---
type: Interview Ledger
parent: 2026-07-22-flutter-mobile-enhancements-spec.md
---

## Records

### L1

Status: current

Question: How should we structure the state management migration to Riverpod across the mobile app?

Recommended Answer:
- Replace `provider` in `pubspec.yaml` with `flutter_riverpod: ^2.5.1`.
- Wrap the root `RemoteCareApp` with `ProviderScope`.
- Convert existing `AuthProvider`, `TodayProvider`, `CheckinProvider`, and `AssistantProvider` into strongly-typed Riverpod `Notifier` or `AsyncNotifier` providers (`authNotifierProvider`, `todayAgendaNotifierProvider`, `symptomCheckinNotifierProvider`, `chatAssistantNotifierProvider`).
- Use `ref.watch` / `ref.read` across screens with immutable state objects (`AuthState`, `AgendaState`, `ChatState`) enforcing explicit loading, data, and error state transitions.
- Negative Requirement: Do not maintain dual state managers (e.g. keeping both Provider and Riverpod in parallel) to prevent state synchronization drift.

Answer: Use the latest riverpod depdencies, apply all the pattern you know in act workflow

Decision: Complete migration of Flutter mobile state management to `flutter_riverpod: ^2.5.1` with immutable state objects and `ProviderScope`.

Reason: Provides compile-safe dependency injection, seamless `AsyncValue` handling for network calls to the Python backend, and clean testability without requiring a `BuildContext`.

---

### L2

Status: current

Question: How should internationalization and locale management be configured in the Flutter mobile application?

Recommended Answer:
- Add `flutter_localizations` from Flutter SDK and use official ARB (`.arb`) files in `lib/l10n/`.
- Support **English (`en`)**, **Italian (`it`)**, **Spanish (`es`)**, **French (`fr`)**, and **German (`de`)**.
- Create `localeNotifierProvider` allowing runtime locale toggling.
- Persist patient language choice in `SharedPreferences` (`user_locale`).
- Negative Requirement: No hardcoded text strings in UI widgets; all user-facing text must source exclusively from `AppLocalizations.of(context)`.

Answer: perfect, enable en, it, es, fr, deutsch, apply and refactoring also the folder to improve the features, libs, screen etc as you know in act-patterns

Decision: Full i10n support with 5 languages (`en`, `it`, `es`, `fr`, `de`), ARB localization files, dynamic runtime language switching via Riverpod `localeNotifierProvider`, and folder refactoring to feature-first clean architecture.

Reason: Provides complete internationalization for post-surgery care across multiple regions with zero-restart language switching.

---

### L3

Status: current

Question: How should medication reminder notifications and instant dose logging be handled across iOS and Android?

Recommended Answer:
- Notification Engine (`flutter_local_notifications: ^17.0.0+`).
- Notification Scheduling: Automatically calculate and schedule local notifications based on prescribed medication frequencies whenever the patient syncs their regimen from the Python backend (`GET /cases/{id}/medications`).
- Interactive Notification Actions:
  - Display interactive action buttons directly in notification shade / lock screen (`[Take Dose]` and `[Snooze 15m]`).
  - `[Take Dose]` logs dose immediately as `taken` (`POST /adherence/log`) in background with haptic feedback.
  - Tapping notification opens app and highlights target medication card with celebratory animation/toast.
- Permissions Handling: Request notification permissions during onboarding.

Answer: use the recommended one

Decision: Implement interactive local medication notifications via `flutter_local_notifications` with lock-screen dose logging, background adherence sync, and animated UI feedback.

Reason: Reduces friction for post-surgery patients, allowing single-tap dose logging while guaranteeing real-time synchronization back to the clinician dashboard.

---

### L4

Status: current

Question: How should the mobile app's folder structure, UI/UX aesthetics, AI Chat interface, and automated testing suite be refactored?

Recommended Answer:
- Folder Structure: Feature-First Clean Architecture (`lib/core/`, `lib/features/auth/`, `lib/features/today/`, `lib/features/checkin/`, `lib/features/assistant/`, `lib/features/recovery/`, `lib/features/profile/`).
- Medical Design System: Palette with Deep Teal (`#0D9488`), Soft Cyan (`#F0FDF4`), Clinical Emerald (`#059669`), Slate Dark (`#0F172A`), GoogleFonts `Outfit` / `Inter`, responsive layout scaling via `flutter_screenutil`.
- AI Chat Experience: Top Guardrail Banner ("Informational only, never diagnostic"), Quick Suggestion Chips, 3-dot typing indicator.
- Testing Suite: Unit tests for Riverpod Notifiers + Widget journey tests for TodayScreen and LanguagePicker.

Answer: perfect proceed

Decision: Re-architect mobile folder structure to feature-first clean architecture, upgrade UI/UX with modern healthcare design tokens, enrich AI Chat interface with guardrail banners and suggestion chips, and implement unit + widget test suite.

Reason: Ensures maintainability, strict alignment with `docs/PLAN.md` and `docs/DESIGN.md`, and robust automated test coverage.
