# Remote CarePro Mobile App (Flutter)

A cross-platform Flutter application for post-surgery patient companion, medication tracking, daily symptom check-in, interactive notifications, and AI recovery assistant.

---

## Table of Contents
1. [System Requirements](#system-requirements)
2. [Prerequisites & Environment Setup](#prerequisites--environment-setup)
   - [Android Setup & Minimums](#android-setup--minimums)
   - [iOS Setup & Minimums](#ios-setup--minimums)
3. [Running the Backend & Seeding Data](#running-the-backend--seeding-data)
4. [Running the Mobile App](#running-the-mobile-app)
   - [Android Emulator](#android-emulator)
   - [iOS Simulator](#ios-simulator)
   - [Demo Environment Injection (`--dart-define`)](#demo-environment-injection---dart-define)
5. [Demo Credentials & Testing Flows](#demo-credentials--testing-flows)
   - [Patient Account (Existing User)](#patient-account-existing-user)
   - [Clinician Account](#clinician-account)
   - [Patient Invitation / Sign-In Flow](#patient-invitation--sign-in-flow)
6. [Local Testing & Debugging](#local-testing--debugging)
   - [Running Unit & Widget Tests](#running-unit--widget-tests)
   - [Integration / E2E test](#integration--e2e-test)
   - [Static Analysis](#static-analysis)
   - [Flutter DevTools & Logging](#flutter-devtools--logging)
7. [Architecture & Network Configuration](#architecture--network-configuration)
   - [Why `10.0.2.2` on Android vs `localhost` on iOS](#why-10022-on-android-vs-localhost-on-ios)

---

## System Requirements

- **Flutter SDK**: `^3.12.0` (or Flutter 3.27+)
- **Dart SDK**: `^3.12.0`
- **Java Development Kit (JDK)**: JDK 17 (Java 17 required for Gradle 8+)
- **Python**: 3.10+ (for running backend locally)
- **Xcode**: 15+ (for iOS Simulator on macOS)
- **Android Studio / Command Line Tools**: SDK Platform 34, Build Tools 34.0.0

---

## Prerequisites & Environment Setup

### Android Setup & Minimums
- **Minimum Android SDK (`minSdk`)**: API Level 26 (Android 8.0 Oreo)
- **Target SDK (`targetSdk`)**: API Level 34 (Android 14)
- **Core Library Desugaring**: Enabled via `isCoreLibraryDesugaringEnabled = true` and `com.android.tools:desugar_jdk_libs:2.0.4` in `android/app/build.gradle.kts`.
- **Recommended AVD (Android Virtual Device)**:
  - Device: Pixel 6 / Pixel 7
  - System Image: API 34 (ARM64 for Apple Silicon / x86_64 for Intel)
  - RAM: 2048 MB+

### iOS Setup & Minimums
- **Minimum iOS Deployment Target**: iOS 14.0
- **CocoaPods**: Installed (`sudo gem install cocoapods` or `brew install cocoapods`)
- **Simulator**: iPhone 15 / iPhone 16 running iOS 17.0+

---

## Running the Backend & Seeding Data

Before launching the mobile app, start the FastAPI Python backend on port `8000`:

### Option A: Running with Python Virtual Environment
```bash
# 1. Navigate to backend root
cd backend

# 2. Create and activate virtualenv
python3 -m venv venv
source venv/bin/activate

# 3. Install dependencies
pip install -r requirements.txt

# 4. Seed database with dummy users & cases
python app/scripts/seed_data.py

# 5. Start backend server
uvicorn app.main:app --reload --port 8000
```

### Option B: Running with Docker Compose
```bash
# From the repository root directory
docker-compose up backend
```

> **Note**: Verify backend is running by opening `http://localhost:8000/docs` in your browser.

---

## Running the Mobile App

Navigate to the `mobile` directory:
```bash
cd mobile
flutter pub get
```

### Android Emulator
1. Start your AVD in Android Studio or via CLI:
   ```bash
   emulator -avd Pixel_6_API_34
   ```
2. Launch Flutter app on Android:
   ```bash
   flutter run -d android
   ```

### iOS Simulator
1. Launch the iOS Simulator:
   ```bash
   open -a Simulator
   ```
2. Launch Flutter app on iOS:
   ```bash
   flutter run -d iphonesimulator
   # or specify exact device ID
   flutter run -d CD6BF108-E362-4D7E-B0CE-80F94C407F98
   ```

### Demo Environment Injection (`--dart-define`)
To point the app at a custom remote API URL for demo presentations (overriding local defaults):

```bash
# Live demo run:
flutter run --dart-define=API_BASE_URL=https://api.remotecare-demo.org

# Build standalone Android APK for demo:
flutter build apk --release --dart-define=API_BASE_URL=https://api.remotecare-demo.org

# Build standalone iOS IPA for demo:
flutter build ipa --release --dart-define=API_BASE_URL=https://api.remotecare-demo.org
```

---

## Demo Credentials & Testing Flows

Patients don't have passwords — sign-in is always an emailed one-time code, entered on a single merged email → code screen (`LoginScreen`). Clinicians still sign in with email + password on the web dashboard.

### Patient Account (Existing User)
- **Email**: `patient@example.com`
- **Sign-in code**: `424242` (fixed, long-lived, seeded by `seed_data.py` — no password field exists for patients)
- **Surgery**: Total Knee Arthroplasty (TKA)
- **Included Data**: 3 active medications (Oxycodone, Amoxicillin, Ibuprofen), check-ins, recommendations.

### Clinician Account
- **Email**: `clinician@example.com`
- **Password**: `CarePro#2026!Secure` (configured via `CLINICIAN_PASSWORD` in `.env`)
- **Name**: Dr. Sarah Connor

### Patient Invitation / Sign-In Flow
The old invite-code-on-login-screen + password-during-onboarding flow is gone. Patients are invited from the web dashboard, and both new and returning patients sign in through the same email → code screen on mobile.

1. **Invite the patient (web dashboard)**:
   - Log in as the clinician and go to `Patients` → `+ New Patient`.
   - This creates the patient record and sends them a one-time sign-in code by email (via SES in real deployments; logged to the backend console in local dev when `AWS_REGION` isn't set — the code is also shown on screen as a backup).
2. **On the mobile app**:
   - From the onboarding screen, tap either **"Sign in to your account"** (`AppStrings.signInToAccount`) or **"Create account"** — both routes lead to the same `LoginScreen`.
   - Enter the patient's email and tap **Sign In** (`AppStrings.signIn`). This calls `POST /auth/patient/request-code` with `{"email"}`.
   - The screen switches to the code-entry stage ("Verify your email" / `AppStrings.verifyEmail`). Enter the 6-digit code and tap **Verify & Continue** (`AppStrings.verifyAndContinue`). This calls `POST /auth/patient/verify-code` with `{"email", "code"}`.
   - **New patient**: the response comes back as onboarding data (email, full name) and the app continues to the phone/date-of-birth profile step — no password is ever collected.
   - **Returning patient**: the response comes back with an access token, which the app stores, navigating straight into the Today Agenda.
   - For the seeded demo patient above, you can skip step 1 and go straight to step 2 using the fixed code `424242` — it's pre-seeded with a long expiry.

---

## Local Testing & Debugging

### Running Unit & Widget Tests
```bash
# Run all unit and widget tests
flutter test

# Run specific test files
flutter test test/unit/chat_provider_test.dart
flutter test test/widget/assistant_screen_test.dart
```

### Integration / E2E test

`integration_test/golden_loop_test.dart` drives the app against a **real, running backend** — unlike unit/widget tests, it needs:

1. The backend running: `docker-compose up backend` (from the repo root).
2. The database seeded: `docker-compose exec backend python app/scripts/seed_data.py`.
3. A booted simulator (see device setup above).

Then run:
```bash
flutter test integration_test/golden_loop_test.dart
```

It signs in as the seeded demo patient (`patient@example.com`, code `424242`), asks the AI assistant an in-scope and an out-of-scope question, and logs a dose — verifying the real network path end to end. This is not a substitute for the unit/widget suite (`flutter test`), which runs against a fake API client and needs none of the above.

### Static Analysis
```bash
flutter analyze
```

### Flutter DevTools & Logging
- **Hot Reload**: Press `r` in the terminal while `flutter run` is active.
- **Hot Restart**: Press `R` in the terminal.
- **DevTools**: Open the URL printed in terminal (`http://127.0.0.1:54060/.../devtools/`) for widget inspection, network profiling, and performance tracking.

---

## Architecture & Network Configuration

- **State Management**: Riverpod (`flutter_riverpod`, `freezed`, `AsyncNotifier`, `Notifier`).
- **Local Storage**: `SharedPreferences` for auth JWT token persistence.
- **Network Layer**: `ApiService` abstract class with `HttpApiService` (production) and `FakeApiService` (unit & widget tests).
- **Environment Resolution**: [AppConfig](file://./mobile/lib/core/config/app_config.dart) resolves `API_BASE_URL` dynamically.

### Why `10.0.2.2` on Android vs `localhost` on iOS

| Target | Resolved URL | Network Explanation |
| :--- | :--- | :--- |
| **Android Emulator** | `http://10.0.2.2:8000` | The Android Emulator runs inside a QEMU Virtual Machine. To the VM, `localhost` means the Android OS itself. `10.0.2.2` is the special virtual loopback alias that bridges to your host Mac/PC `localhost`. |
| **iOS Simulator** | `http://localhost:8000` | The iOS Simulator is a native macOS process, not a VM. It shares your Mac's network stack directly. |
| **Demo / Staging** | Overridden via `--dart-define` | Inject custom remote API URL at compile or runtime without code modifications. |
