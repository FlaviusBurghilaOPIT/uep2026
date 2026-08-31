# RemoteCare Pro — Mobile Companion (Flutter)

Cross-platform patient companion app (iOS, Android, macOS) for medication tracking, 1-tap dose logging, daily recovery check-ins, and guardrailed clinical AI assistance.

---

## ⚡ Quick Run (3 Steps)

```bash
# 1. Navigate to mobile directory
cd mobile

# 2. Install dependencies
flutter pub get

# 3. Run the app (connects to local backend at http://localhost:8000 by default)
flutter run
```

---

## 📱 Device & Target Commands

```bash
# iOS Simulator
flutter run -d iphonesimulator

# Android Emulator (automatically uses 10.0.2.2 loopback)
flutter run -d android

# macOS Desktop
flutter run -d macos

# Point to remote / AWS EC2 deployment
flutter run --dart-define=API_BASE_URL=http://<EC2-PUBLIC-IP>:8000
```

---

## 🔑 Patient Sign-In (Passwordless OTP)

Patients authenticate via a **6-digit email OTP** (no password needed):

1. **Email:** `patient@example.com` (or any invited email)
2. **OTP Code:**
   * **Seeded Demo Patient:** Copy the 6-digit code printed in terminal by `seed_data.py`.
   * **Live Web-Invited Patient:** Displayed on the Clinician Web Portal banner upon creation.
   * **Requested Code:** Check backend console (`docker compose logs backend --tail 20`) for `[DRY RUN] Would email code XXXXXX`.
3. **Auto-Paste:** The OTP screen auto-detects clipboard codes and auto-submits on the 6th digit.

---

## 🧪 Testing & Quality

```bash
# Run all 286 unit, widget, and feature tests
flutter test

# Run static analysis / linter
flutter analyze
```

---

## ⚙️ Architecture & Network Resolution

* **State Management:** Riverpod 3.1 (`flutter_riverpod`, `riverpod_annotation`, `freezed`, `Notifier`).
* **Local Cache & Offline Sync:** `SharedPreferences` via `TodayLocalDatasource` with optimistic UI mutations, 5s undo window, and UUIDv4 offline queue synchronization.
* **Network Resolution:** `AppConfig` automatically routes to `http://10.0.2.2:8000` on Android Emulator and `http://localhost:8000` on iOS/macOS/Desktop, or overrides via `--dart-define=API_BASE_URL=...`.
