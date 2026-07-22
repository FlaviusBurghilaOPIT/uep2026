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
5. [Demo Credentials & Testing Flows](#demo-credentials--testing-flows)
   - [Patient Account (Existing User)](#patient-account-existing-user)
   - [Clinician Account](#clinician-account)
   - [Invitation Code / Onboarding Flow](#invitation-code--onboarding-flow)
6. [Local Testing & Debugging](#local-testing--debugging)
   - [Running Unit & Widget Tests](#running-unit--widget-tests)
   - [Static Analysis](#static-analysis)
   - [Flutter DevTools & Logging](#flutter-devtools--logging)
7. [Architecture & Network Configuration](#architecture--network-configuration)

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
   *(Android automatically maps `http://10.0.2.2:8000` to the host machine backend).*

### iOS Simulator
1. Launch the iOS Simulator:
   ```bash
   open -a Simulator
   ```
2. Launch Flutter app on iOS:
   ```bash
   flutter run -d iphonesimulator
   ```
   *(iOS Simulator uses `http://localhost:8000` to reach the backend).*

---

## Demo Credentials & Testing Flows

### Patient Account (Existing User)
- **Email**: `patient@example.com`
- **Password**: `password123`
- **Surgery**: Total Knee Arthroplasty (TKA)
- **Included Data**: 3 active medications (Oxycodone, Amoxicillin, Ibuprofen), check-ins, recommendations.

### Clinician Account
- **Email**: `clinician@example.com`
- **Password**: `password123`
- **Name**: Dr. Sarah Connor

### Invitation Code / Onboarding Flow
To test the patient invitation / onboarding flow:

1. **Create a Pending Patient User in DB**:
   You can run this quick Python snippet or sqlite query to create an invited patient:
   ```python
   from app.database import SessionLocal
   from app import models

   db = SessionLocal()
   pending_user = models.User(
       email="newpatient@example.com",
       full_name="Alex Mercer",
       role=models.UserRole.patient,
       invite_code="INVITE123",
       status="pending_onboarding",
   )
   db.add(pending_user)
   db.commit()
   ```
2. **On Mobile App**:
   - Tap **"Have an invite code?"** on Login screen.
   - Enter Email: `newpatient@example.com` and Code: `INVITE123`.
   - Tap **Verify Code** (`POST /auth/verify-invite`).
   - Enter password, Date of Birth, and Phone number.
   - Tap **Complete Setup** (`POST /auth/complete-onboarding`).
   - The app verifies, saves the access token, and navigates straight into the Today Agenda!

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
- **Backend Base URL Routing**:
  - Android Emulator: `http://10.0.2.2:8000`
  - iOS Simulator & Web: `http://localhost:8000`
