---
type: Work Item
title: Internationalization — 5-Language ARB Setup, l10n.yaml, localeNotifierProvider & Profile Language Picker
parent: ../2026-07-22-flutter-mobile-enhancements-spec.md
---

## What to build

Implement the complete 5-language internationalization stack: configure `l10n.yaml`, create all ARB files with parameterized string placeholders, implement `localeNotifierProvider` persisting the patient's locale choice, build the Profile screen language picker UI, and add a widget test for locale switching.

### `mobile/l10n.yaml`

```yaml
arb-dir: lib/core/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
nullable-getter: false
```

### ARB files — `lib/core/l10n/`

All 5 files (`app_en.arb`, `app_it.arb`, `app_es.arb`, `app_fr.arb`, `app_de.arb`) must contain every key listed below. English is the template and source of truth.

Required keys (English values shown):
```json
{
  "@@locale": "en",

  "appTitle": "Remote CarePro",
  "loginTitle": "Welcome Back",
  "loginEmailLabel": "Email address",
  "loginPasswordLabel": "Password",
  "loginButton": "Sign In",

  "onboardingTitle": "You've been invited",
  "onboardingSubtitle": "Enter your email and the code your clinician sent you.",
  "inviteCodeLabel": "Invitation code",
  "verifyButton": "Verify Code",
  "completeSetupButton": "Complete Setup",

  "todayTitle": "Today",
  "medicationCardTitle": "Take {medicationName}",
  "@medicationCardTitle": {
    "placeholders": { "medicationName": { "type": "String" } }
  },
  "doseAmount": "{doseAmount} dose",
  "@doseAmount": {
    "placeholders": { "doseAmount": { "type": "String" } }
  },
  "scheduledAt": "Scheduled at {scheduledTime}",
  "@scheduledAt": {
    "placeholders": { "scheduledTime": { "type": "String" } }
  },
  "doseStatusTaken": "Taken",
  "doseStatusMissed": "Missed",
  "doseStatusSkipped": "Skipped",
  "takeDoseButton": "Take Dose",
  "skipDoseButton": "Skip",
  "missedDoseButton": "Missed",

  "checkinTitle": "Daily Check-in",
  "symptomQuestion": "How are you feeling today?",
  "severityMild": "Mild",
  "severityModerate": "Moderate",
  "severitySevere": "Severe",
  "submitCheckinButton": "Submit",

  "assistantTitle": "AI Assistant",
  "assistantGuardrailBanner": "AI Assistant • Informational only, never diagnostic",
  "typeMessagePlaceholder": "Type your question...",
  "chipMedicationSideEffects": "Medication side effects",
  "chipWoundCareTips": "Wound care tips",
  "chipPhysioTargets": "Physio targets",
  "chipEmergencyContact": "Emergency contact",

  "profileTitle": "Profile",
  "languageSectionTitle": "Language",
  "languageEnglish": "English",
  "languageItalian": "Italian",
  "languageSpanish": "Spanish",
  "languageFrench": "French",
  "languageGerman": "German",
  "signOutButton": "Sign Out",

  "notificationReminderTitle": "Medication Reminder",
  "notificationReminderBody": "Time to take {medicationName} — {doseAmount}",
  "@notificationReminderBody": {
    "placeholders": {
      "medicationName": { "type": "String" },
      "doseAmount": { "type": "String" }
    }
  },
  "notificationActionTake": "Take Dose",
  "notificationActionSnooze": "Snooze 15 min",

  "errorGeneric": "Something went wrong. Please try again.",
  "errorNetwork": "No connection. Please check your internet.",
  "loadingLabel": "Loading..."
}
```

Translate all keys faithfully into `app_it.arb` (Italian), `app_es.arb` (Spanish), `app_fr.arb` (French), `app_de.arb` (German). Preserve all `@` metadata blocks and placeholder definitions unchanged.

### `localeNotifierProvider` — `lib/core/l10n/locale_notifier.dart`

```dart
@riverpod
class LocaleNotifier extends _$LocaleNotifier {
  static const _key = 'user_locale';

  @override
  Locale build() => const Locale('en');

  Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
    state = locale;
  }

  Future<void> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code != null) state = Locale(code);
  }
}
```

Wire into `main.dart`:
- `MaterialApp.router(locale: ref.watch(localeNotifierProvider), supportedLocales: AppLocalizations.supportedLocales, localizationsDelegates: AppLocalizations.localizationsDelegates)`
- Call `ref.read(localeNotifierProvider.notifier).loadSaved()` in `main()` after `ProviderScope` initialization.

### Profile language picker — `lib/features/profile/screens/profile_screen.dart`

Render a `ListView` of 5 language options (English, Italian, Spanish, French, German). Tapping an option calls `ref.read(localeNotifierProvider.notifier).setLocale(Locale(code))`. The currently selected locale shows a `AppColors.deepTeal` checkmark trailing icon.

### Widget test — `mobile/test/widget/language_picker_test.dart`

```dart
// Test 1: Default locale is English — find 'Today' label via AppLocalizations
// Test 2: Tap 'Italian' in ProfileScreen locale picker → rebuild → find Italian 'Oggi' label
// Test 3: Tap 'German' → rebuild → find German 'Heute' label
// All tests use ProviderScope + overrides; no SharedPreferences I/O (use mock SharedPreferences)
```

Run `flutter gen-l10n` before tests to ensure generated `AppLocalizations` class exists.

## Required context

- `mobile/pubspec.yaml` (from WI-01) — add `flutter_localizations` SDK dependency and `generate: true` under `flutter:` section.
- `mobile/lib/main.dart` (from WI-01) — wire `localeNotifierProvider` and `AppLocalizations` delegates.
- `mobile/lib/core/theme/app_colors.dart` (from WI-01) — `AppColors.deepTeal` for selected language checkmark.
- Run `flutter gen-l10n` to generate `AppLocalizations`. Run `flutter test test/widget/language_picker_test.dart` to verify.

## Acceptance criteria

- [ ] `mobile/l10n.yaml` exists with the exact configuration above.
- [ ] All 5 ARB files exist under `lib/core/l10n/` with every key from the template translated.
- [ ] Parameterized keys (`medicationCardTitle`, `doseAmount`, `scheduledAt`, `notificationReminderBody`) work with `AppLocalizations.of(context).medicationCardTitle('Ibuprofen')` syntax.
- [ ] `localeNotifierProvider` persists selected locale to `SharedPreferences` key `user_locale` and loads it on startup.
- [ ] `MaterialApp` is configured with `supportedLocales` and `localizationsDelegates` from `AppLocalizations`.
- [ ] Profile screen renders 5 language options; tapping one switches the app locale instantly without restart.
- [ ] No hardcoded UI text strings remain in any widget — all sourced from `AppLocalizations.of(context)`.
- [ ] `flutter test test/widget/language_picker_test.dart` passes.
- [ ] `flutter analyze` reports zero errors.

## Covers

- User Stories: 1
- Requirements: Internationalization 1–5; Technical Decisions: 3
- Testing Strategy: Widget journey tests (language_picker_test)
- Interview Ledger: L2

## Blocked by

`01-foundation-riverpod-architecture-design-system.md`
