---
type: Spec
title: Flutter Mobile Companion App Architecture, Riverpod Migration, i10n & Interactive Notifications
---

## Problem

The post-surgery patient mobile application (`mobile/`) currently uses legacy Provider (`ChangeNotifier`) state management with limited localization support, basic UI components, non-interactive notification stubs, and no automated Flutter unit or widget tests. Additionally, the mobile app codebase structure needs clean feature-first architecture alignment with `docs/PLAN.md` and `docs/DESIGN.md` to ensure seamless real-time integration with the Python backend (`http://localhost:8000`).

## Proposed Outcome

Refactor the Flutter mobile companion application into a feature-first clean architecture using the latest `flutter_riverpod` (v2.5+), complete 5-language internationalization (`en`, `it`, `es`, `fr`, `de`), interactive lock-screen medication reminder notifications with background dose confirmation, a medical UI/UX design system with rich AI chat guardrail controls, and a unit & widget journey test suite.

## User Stories

1. **Patient Language Selection**: As a post-surgery patient, I want to select my preferred language (English, Italian, Spanish, French, or German) in the profile settings, so that all app interfaces, medication cards, symptom check-in forms, and AI assistant prompts are rendered in my language. [L2]
2. **Interactive Dose Notification & Logging**: As a patient recovering at home, I want to receive scheduled medication reminders on iOS and Android with a `[Take Dose]` lock-screen action button, so I can log my dose in one tap without navigating complex menus. [L3]
3. **Riverpod State-Driven Regimen Agenda**: As a patient, I want my daily medication schedule and recovery guidelines to sync automatically from the clinician's prescribed plan via Python backend REST calls (`GET /cases/{id}/medications`), displaying clear loading shimmers, explicit status chips (`Taken`, `Missed`, `Skipped`), and instant adherence logging. [L1, L4]
4. **AI Assistant with Guardrails & Presets**: As a patient, I want to ask questions about my prescribed medications and post-op care in a modern chat interface that highlights clinical guardrails and provides one-tap suggestion chips. [L4]

## Requirements

### State Management & Architecture
1. Migrate `mobile/pubspec.yaml` to `flutter_riverpod: ^2.5.1` and `flutter_localizations`. Wrap `RemoteCareApp` with `ProviderScope`. [L1]
2. Convert all providers to Riverpod `Notifier` / `AsyncNotifier` classes (`authNotifierProvider`, `todayAgendaNotifierProvider`, `symptomCheckinNotifierProvider`, `chatAssistantNotifierProvider`, `localeNotifierProvider`). [L1]
3. Enforce immutable state objects (`AuthState`, `AgendaState`, `ChatState`) handling `AsyncValue` loading, data, and error state transitions. [L1]
4. Refactor codebase into Feature-First Clean Architecture:
   - `lib/core/` (l10n, network, notifications, theme, widgets)
   - `lib/features/auth/`
   - `lib/features/today/`
   - `lib/features/checkin/`
   - `lib/features/assistant/`
   - `lib/features/recovery/`
   - `lib/features/profile/` [L4]

### Internationalization (i10n)
1. Add ARB files under `lib/l10n/`: `app_en.arb`, `app_it.arb`, `app_es.arb`, `app_fr.arb`, `app_de.arb`. [L2]
2. Implement dynamic language switching in Profile screen, persisting `user_locale` in `SharedPreferences`. [L2]
3. Require all UI text to source exclusively from `AppLocalizations.of(context)`. [L2]

### Interactive Notifications & Dose Adherence
1. Integrate `flutter_local_notifications` to schedule local reminders for prescribed dose times (e.g. 08:00, 14:00, 20:00). [L3]
2. Provide interactive action buttons on iOS & Android notifications: `[Take Dose]` (logs `taken` via `POST /adherence/log` in background with haptic feedback) and `[Snooze 15m]`. [L3]
3. Tapping a notification opens `TodayScreen` and auto-scrolls to the target medication card with a celebratory checkmark toast. [L3]

### Medical UI/UX & AI Chat Experience
1. Implement a medical color palette: Deep Teal (`#0D9488`), Soft Cyan (`#F0FDF4`), Clinical Emerald (`#059669`), Slate Dark (`#0F172A`), GoogleFonts `Outfit` for headers and `Inter` for body text. [L4]
2. Add a persistent top guardrail banner to the AI Chat screen: *"AI Assistant • Informational only, never diagnostic"*. [L4]
3. Provide one-tap suggestion chips: `[Medication side effects]`, `[Wound care tips]`, `[Physio targets]`, `[Emergency contact]`. [L4]
4. Show an animated 3-dot typing indicator while awaiting backend responses from `POST /ai/chat`. [L4]

## Technical Decisions

1. **State Injection**: Use Riverpod `ref.watch` for reactive widget rebuilds and `ref.read` for event handler callbacks. [L1]
2. **Network Client**: Use central `ApiService` with dynamic base URL (`http://10.0.2.2:8000` on Android emulator, `http://localhost:8000` on iOS/Web/Desktop) and automatic `Authorization: Bearer <token>` injection. [L1, L4]
3. **Locale Persistence**: Store selected ISO language code (`en`, `it`, `es`, `fr`, `de`) in `SharedPreferences` and load on app startup. [L2]

## Testing Strategy

1. **Riverpod Unit Tests (`test/unit/`)**:
   - `auth_provider_test.dart`: Verify invite code verification, onboarding completion, and token storage.
   - `today_agenda_test.dart`: Verify medication agenda state transitions and dose adherence logging (`taken`, `missed`, `skipped`).
   - `chat_provider_test.dart`: Verify chat message state appending and error handling. [L4]
2. **Widget Journey Tests (`test/widget/`)**:
   - `today_screen_test.dart`: Verify medication card rendering, action button taps, and localized text.
   - `language_picker_test.dart`: Verify locale switching between EN, IT, ES, FR, and DE updates rendered text instantly. [L4]
3. **Test Seams**: Mock `ApiService` responses using `http.Client` fakes; no live network calls required during `flutter test`. [L4]
