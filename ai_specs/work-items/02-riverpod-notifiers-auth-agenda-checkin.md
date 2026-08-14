---
type: Work Item
title: Riverpod Notifiers — Auth, Today Agenda & Symptom Check-in with Unit Tests
parent: ../2026-07-22-flutter-mobile-enhancements-spec.md
---

## What to build

Implement the three core Riverpod `AsyncNotifier` providers for authentication, daily medication agenda, and symptom check-in. Each provider communicates exclusively with the Python backend via `ApiService`. Include unit tests for all three using `ApiService` fakes (no live network calls).

### `authNotifierProvider` — `lib/features/auth/providers/auth_notifier.dart`

State: immutable `AuthState`:
```dart
@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial() = _Initial;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.authenticated({
    required String userId,
    required String caseId,
    required String fullName,
    required String email,
    required String surgeryType,
  }) = _Authenticated;
  const factory AuthState.onboarding({
    required String email,
    required String fullName,
    required String surgeryType,
  }) = _Onboarding;
  const factory AuthState.error(String message) = _Error;
}
```

Methods:
- `verifyInvite(String email, String inviteCode)` — `POST /auth/verify-invite`, transitions to `onboarding` on success.
- `completeOnboarding({required String email, required String inviteCode, required String password, required String dateOfBirth, required String phone})` — `POST /auth/complete-onboarding`, saves JWT via `ApiService.setToken()`, transitions to `authenticated`.
- `signIn(String email, String password)` — `POST /auth/login`, fetches `/auth/me` and `/patients/{id}/case`, transitions to `authenticated`.
- `signOut()` — clears token, transitions to `initial`.

### `todayAgendaNotifierProvider` — `lib/features/today/providers/today_agenda_notifier.dart`

State: immutable `AgendaState`:
```dart
@freezed
class AgendaState with _$AgendaState {
  const factory AgendaState({
    required AsyncValue<List<MedicationItem>> medications,
    required Map<String, DoseStatus> doseStatuses,
  }) = _AgendaState;
}

enum DoseStatus { pending, taken, missed, skipped }

@freezed
class MedicationItem with _$MedicationItem {
  const factory MedicationItem({
    required String id,
    required String name,
    required String dose,
    required String scheduleText,
    required String duration,
    String? notes,
  }) = _MedicationItem;
}
```

Methods:
- `loadAgenda(String caseId)` — `GET /cases/{caseId}/medications`, populates `medications`.
- `logDose({required String reminderId, required DoseStatus status})` — `POST /adherence/log` with `{reminder_id, status}`, updates `doseStatuses[reminderId]`.

### `symptomCheckinNotifierProvider` — `lib/features/checkin/providers/symptom_checkin_notifier.dart`

State: `AsyncValue<bool>` (idle/loading/success/error).

Methods:
- `submit({required String caseId, required String severity, String? notes})` — `POST /checkins` with `{case_id, severity, notes, checked_in_at: DateTime.now().toIso8601String()}`.

### Unit tests — `mobile/test/unit/`

`auth_provider_test.dart`:
```dart
// Test 1: verifyInvite success → AuthState.onboarding
// Test 2: verifyInvite with wrong code → AuthState.error('Invalid invite code')
// Test 3: completeOnboarding success → AuthState.authenticated
// Test 4: signIn success → AuthState.authenticated with userId populated
```

`today_agenda_test.dart`:
```dart
// Test 1: loadAgenda populates medications list from fake JSON
// Test 2: logDose(taken) → doseStatuses[id] == DoseStatus.taken
// Test 3: logDose when ApiService throws → AgendaState.medications stays AsyncError
```

`symptom_checkin_test.dart`:
```dart
// Test 1: submit success → AsyncData(true)
// Test 2: submit network failure → AsyncError with message
```

All tests use a `FakeApiService` that implements `ApiService` and returns controlled `http.Response` fixtures. No live network calls.

Add `freezed: ^2.5.2`, `freezed_annotation: ^2.4.4`, `json_annotation: ^4.9.0` to `pubspec.yaml` dependencies and `freezed: ^2.5.2`, `json_serializable: ^6.8.0` to `dev_dependencies`.

## Required context

- `mobile/lib/core/network/api_service.dart` (from WI-01) — import path for all providers.
- `mobile/pubspec.yaml` (from WI-01) — confirm `flutter_riverpod: ^2.5.1` is present before adding `freezed`.
- Python backend endpoint contracts:
  - `POST /auth/verify-invite` → `{full_name, email, surgery_type, clinician_name}`
  - `POST /auth/complete-onboarding` → `{access_token}`
  - `POST /auth/login` → `{access_token}`
  - `GET /auth/me` → `{id, email, full_name, role}`
  - `GET /patients/{id}/case` → `{id, patient_id, surgery_type, status}`
  - `GET /cases/{id}/medications` → `[{id, name, dose, schedule_text, duration, notes}]`
  - `POST /adherence/log` → `{reminder_id, status}` → 200 ok
  - `POST /checkins` → `{case_id, severity, notes, checked_in_at}` → 200 ok
- Run `flutter pub get` after pubspec changes. Run `flutter test test/unit/` to verify all unit tests pass.

## Acceptance criteria

- [x] `authNotifierProvider`, `todayAgendaNotifierProvider`, `symptomCheckinNotifierProvider` exist as `AsyncNotifier` classes in their feature directories.
- [x] `AuthState`, `AgendaState`, `MedicationItem` are immutable `freezed` union types.
- [x] `verifyInvite` transitions to `AuthState.onboarding` on HTTP 200 and `AuthState.error` on non-200.
- [x] `logDose` updates `doseStatuses` map immediately (optimistic) and POSTs to `/adherence/log`.
- [x] `symptomCheckinNotifierProvider.submit` POSTs to `/checkins` and resolves `AsyncData(true)`.
- [x] All unit tests in `test/unit/` pass with `flutter test test/unit/` using `FakeApiService` only.
- [x] `flutter analyze` reports zero errors.

## Covers

- User Stories: 3
- Requirements: State Management 2–3; Testing Strategy: Unit tests (auth, today_agenda, symptom_checkin)
- Technical Decisions: 1, 2
- Interview Ledger: L1, L4

## Blocked by

`01-foundation-riverpod-architecture-design-system.md`
