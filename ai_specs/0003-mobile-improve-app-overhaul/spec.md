# Spec: RemoteCare Pro Mobile Flutter Experience Overhaul

## Objective
Elevate the RemoteCare Pro Flutter mobile patient application from a functioning prototype to an effortless, frictionless, visually authoritative clinical companion. Grounded in the 9-phase `improve-app` evidence base, this overhaul implements sub-100ms optimistic dose logging with 5s non-blocking Undo, the "Day Complete" Ring Closure signature moment with haptic feedback, a prominent Emergency Red-Flag Banner with 1-tap direct dial (911 / Clinic Direct), 6-digit OTP auto-paste and auto-submit, visual drug form icons, and strict WCAG AAA tinted slate/sky design tokens.

---

## Tech Stack & Dependencies
- **Framework**: Flutter 3.27+ / Dart 3.6+
- **State Management & DI**: `flutter_riverpod` (v3.x) with code generation and immutable states (`freezed`)
- **Responsive Sizing**: `flutter_screenutil` (base design canvas 375x812)
- **Local Notifications**: `flutter_local_notifications` with timezone re-anchoring
- **Icons**: `lucide_icons_flutter` & Material Symbols
- **Typography & Localization**: System Sans stack with 5-locale ARB support (`en`, `es`, `it`, `fr`, `de`)
- **Network & Offline**: Riverpod `apiServiceProvider`, local SQLite queue, optimistic state mutation
- **Platform Actions**: `url_launcher` for emergency `tel:` calls, `HapticFeedback` for tactile confirmation

---

## Commands
```bash
# Mobile Static Analysis
cd mobile && flutter analyze

# Mobile Automated Test Suite (Unit & Widget Tests)
cd mobile && flutter test

# Run Code Generation (Riverpod / Freezed)
cd mobile && dart run build_runner build --delete-conflicting-outputs
```

---

## Architecture & Project Structure
```
mobile/lib/
├── core/
│   ├── config/app_config.dart
│   ├── theme/
│   │   ├── app_colors.dart         # WCAG AAA Slate/Sky palette tokens
│   │   ├── app_spacing.dart        # 8-point spacing grid (4/8/12/16/24/32/48/64)
│   │   ├── app_text_styles.dart    # System sans modular typography
│   │   └── app_theme.dart          # Unified ThemeData
│   ├── network/api_service.dart    # Riverpod-injected REST client
│   ├── notifications/              # Local notifications & timezone re-anchor controller
│   └── widgets/                    # Core UI kit (AppButton, AppSkeletonLoader, etc.)
└── features/
    ├── auth/                       # Hybrid auth (passwordless code + password fallback), OTP auto-paste
    ├── today/                      # Today Agenda, optimistic dose logging, 5s undo snackbar, celebration ring
    │   ├── presentation/
    │   │   ├── screens/today_screen.dart
    │   │   ├── widgets/
    │   │   │   ├── dose_slot_card.dart      # Optimistic 1-tap action card with pill form badge
    │   │   │   ├── progress_ring_card.dart  # "Day Complete" Ring Closure & Sparkle Canvas
    │   │   │   ├── emergency_banner.dart    # Pinned 1-tap direct dial (911 / Clinic Direct)
    │   │   │   └── correction_sheet.dart    # Slot state slip correction
    │   │   └── providers/today_agenda_notifier.dart
    ├── checkin/                    # Daily feeling check-in with emergency red-flag escalation
    ├── medications/                # Full prescription schedule & drug guide
    ├── recovery/                   # Server-truth milestones & 7-day adherence chart
    ├── assistant/                  # Guardrailed Amazon Bedrock assistant with persistent safety seal
    └── profile/                    # Patient profile, notification toggles & change-password
```

---

## User Stories

1. **Daily Habit Loop (Dose Logging)**: As a post-op patient recovering at home, I want to log my scheduled doses in 1 tap (<0.5s) with tactile haptic feedback and a 5-second non-blocking undo snackbar, so I never wonder if my dose was registered and can immediately correct accidental slips. `[L1]`
2. **Emotional Closure (Day Complete)**: As a patient adhering to my surgeon's regimen, I want to experience a celebratory circular progress sweep ("Ring Closure") with recovery reassurance when I finish my final daily dose, so I feel motivated and peaceful about my healing progress. `[L1, L2]`
3. **Emergency Escalation (Red Flag Banner)**: As a patient experiencing severe symptoms, I want an immediate emergency red-flag escalation banner with 1-tap direct dial (911 / Care Team) upon reporting acute discomfort, so I am never stranded without immediate clinical triage. `[L3]`
4. **Frictionless Discharge Onboarding**: As a fatigued patient discharged with an access code, I want the app to automatically detect and paste my 6-digit OTP code from my clipboard and submit automatically, so I can access my care plan without friction. `[L1]`
5. **Safe AI Inquiries**: As a patient with medication questions, I want a 24/7 guardrailed AI companion with a persistent clinical seal that answers safely and immediately redirects medical emergencies to 911 or my clinic. `[L1]`

---

## Requirements & Acceptance Criteria

### 1. Daily Habit Loop & Optimistic Dose Logging (EXP-004, UX-02, ND-01)
- **1.1 Optimistic State Update**: Tapping `[Taken]`, `[Skipped]`, or `[Missed]` updates Riverpod local state in `<10ms` with light haptic feedback (`HapticFeedback.lightImpact()`), queues local persistence, and issues non-blocking API write to `POST /adherence/log`.
- **1.2 5-Second Non-Blocking Undo**: Displays a floating 5-second `SnackBar` ("Logged as Taken. [Undo]") in `AppColors.slateDark`. Tapping `[Undo]` reverts the slot locally and issues rollback to the backend without blocking navigation.
- **1.3 Visual Pill Form & Timing Tags (UX-05)**: Every dose card displays an intuitive pill form badge (Capsule `pill`, Tablet `tablet`, Liquid `liquid`) and plain-English timing tags (`Take with breakfast`, `Take with food`).
- **1.4 Dual-Identifier Status Badges**: All dose statuses pair WCAG-compliant colors with explicit text and icons (Taken: checkmark/green, Skipped: warning-amber/triangle, Missed: error-red/cross), 100% distinguishable in grayscale.

### 2. "Day Complete" Ring Closure Signature Moment (EXP-004, Phase 5)
- **2.1 Trigger Lifecycle**: The celebration triggers **only** when a live user dose logging action causes the active day's completed doses to reach 100% (`taken == total && total > 0`). It does not trigger upon opening the app if the day was already completed previously.
- **2.2 Animation & Haptics**: Executes a 600ms circular sweep (`Curves.easeInOutCubic`) via `CustomPainter` with an emerald glow and recovery sparkle effect, accompanied by `HapticFeedback.mediumImpact()`.
- **2.3 Reassuring Copy**: Displays empathetic non-gamified closure: *"All doses completed for Day X. Rest well and heal."* Includes a dismiss `IconButton` (minimum 48x48dp hit area) with `Key('ring_closure_celebration')`.
- **2.4 Accessibility & Reduced Motion**: Automatically falls back to a static completion badge when `MediaQuery.of(context).disableAnimations` is true or during headless testing.

### 3. Acute Symptom Check-in & Emergency Red-Flag Banner (EXP-005, UX-01)
- **3.1 Deterministic Escalation & Fallback**:
  - Selecting `'bad'` immediately expands the **Emergency Red Flag Banner** above check-in with 1-tap direct dial buttons (`tel:911` and `tel:{emergencyPhone}`) and issues urgent alert telemetry to the care team.
  - If `emergencyPhone` is null or empty, the secondary CTA falls back cleanly to `Call Care Team` (`emergencyCallClinicFallback`) with graceful dialog guidance.
  - Selecting `'not_great'` prompts for structured symptom notes and confirms care team notification (*"Dr. Miller's surgical care team alerted"*).
  - Selecting `'great'` or `'ok'` records the mood and provides calming positive reinforcement.
- **3.2 Riverpod Seam Compliance**: `CheckInCard` and `symptomCheckinNotifierProvider` consume `apiServiceProvider` via Riverpod `ref.read(apiServiceProvider)` — direct instantiation of `HttpApiService()` is strictly prohibited.
- **3.3 Micro-interaction Animation**: Mood selection pills pop with a 100ms spring scale (`AnimatedScale` 0.96) and active border transition before expanding notes in 150ms.

### 4. Patient Discharge Onboarding & Frictionless OTP (UX-03, L1-L3)
- **4.1 6-Digit Auto-Paste**: The OTP verification screen automatically detects clipboard content matching a 6-digit numeric pattern upon focus.
- **4.2 Auto-Submit**: Filling the 6th digit automatically triggers verification without requiring an extra tap on "Continue".
- **4.3 Hybrid Authentication**: Supports 1-click email magic code login or email+password login with seamless password creation during first-run onboarding.

### 5. Amazon Bedrock AI Assistant Guardrails (UX-07, GLOSSARY)
- **5.1 Persistent Clinical Safety Seal**: The Assistant screen displays a top pinned guardrail banner (*"Clinical AI Companion: Doctor-vetted guidance, 100% non-diagnostic"*). Individual chat bubbles remain clean without repetitive disclaimer paragraphs.
- **5.2 Out-of-Scope Red Flag Refusal**: Out-of-scope or emergency prompts render a prominent red-bordered refusal card with a bold **Call Emergency Contact ({phone})** 1-tap `tel:` button.
- **5.3 Stream Typewriter & Physics**: SSE streaming renders tokens progressively with smooth auto-scroll to the bottom of the list.

### 6. Design System Tokens & Steve Jobs Cuts (Phase 4, Phase 9)
- **6.1 Spacing & Layout**: Strict 8-point grid tokens (4, 8, 12, 16, 24, 32, 48, 64dp). Touch targets are strictly ≥ 48x48dp.
- **6.2 Color Palette**: Tinted Slate neutrals (`#0f172a`, `#334155`, `#e2e8f0`, `#f8fafc`), Sky Primary (`#0284c7`), and functional alert tokens.
- **6.3 Brutal Cuts Executed**:
  - Zero artificial paywalls or tier locks (100% all-inclusive clinical license).
  - Zero modal confirmation dialogs on daily dose logging (replaced with 5s non-blocking Undo snackbars).
  - Zero raw decimal clinical stats displayed to patients.

---

## Out of Scope
- Backend database migrations or schema alterations (all endpoints and schemas remain stable).
- Dedicated Caregiver / Family Portal account management (deferred).
- Dark Mode theme toggle (scoped for future release per accessibility roadmap).
- Custom audio chime asset packages (relies exclusively on native platform `HapticFeedback`).
- Redesigning the Clinician Web Portal (tracked in separate web workstreams).

---

## Testing Strategy & Seams
1. **Notifier Unit Tests (`flutter test test/unit/`)**:
   - `today_agenda_notifier_test.dart`: Optimistic dose log state mutation, 5s undo window expiration, rollback on write error, and offline queue syncing.
   - `symptom_checkin_test.dart`: Mood state transitions, emergency flag dispatch on `'bad'`, and telemetry transmission.
2. **Widget Tests (`flutter test test/widget/`)**:
   - `dose_slot_card_test.dart`: Verify pill form icon rendering, time format, grayscale accessibility, and tap interactions.
   - `today_screen_test.dart`: Verify "Day Complete" Ring Closure renders only when `taken == total` on active log, and 5s Undo snackbar triggers reversion.
   - `checkin_card_test.dart`: Verify Emergency Red Flag Banner displays direct dial buttons on `'bad'` selection with mock `url_launcher`.
   - `otp_screen_test.dart`: Verify 6-digit auto-paste and auto-submit on 6th digit.
3. **Test Seams**:
   - `FakeApiService` (`mobile/test/unit/fake_api_service.dart`) for 100% deterministic network fakes.
   - `FakeNotificationScheduler` for local push notifications without OS platform dependencies.
   - Guarded haptic calls wrapped in `try { HapticFeedback... } catch (_) {}` for clean headless execution.

---

## Boundaries & Constraints
- **Always**:
  - Keep 100% of automated tests passing (`flutter test` ≥ 201 passing tests).
  - Ensure `flutter analyze` reports zero warnings or errors.
  - Maintain all ARB localized strings across `en`, `es`, `it`, `fr`, `de`.
  - Maintain minimum 48x48dp interactive hit targets.
- **Ask First**:
  - Adding new dependencies to `pubspec.yaml`.
  - Modifying backend REST API contracts or database schemas.
- **Never**:
  - Hardcode raw user-facing English strings in widget code.
  - Instantiate `HttpApiService()` directly in presentation widgets.
  - Block the UI thread with synchronous modal alert dialogs for routine dose logging.

---

## Localization Key Mapping (5-Locale ARB Tokens)
| Key | English (`en`) | Italian (`it`) | Spanish (`es`) | French (`fr`) | German (`de`) |
|---|---|---|---|---|---|
| `doseStatusTaken` | `Taken` | `Assunto` | `Tomado` | `Pris` | `Eingenommen` |
| `doseStatusSkipped` | `Skipped` | `Saltato` | `Omitido` | `Ignoré` | `Übersprungen` |
| `doseStatusMissed` | `Missed` | `Mancato` | `Perdido` | `Manqué` | `Verpasst` |
| `todayLogUndo` | `Undo` | `Annulla` | `Deshacer` | `Annuler` | `Rückgängig` |
| `todayCelebration` | `All doses completed for Day {day}. Rest well and heal.` | `Tutte le dosi completate per il Giorno {day}. Riposa e guarisci.` | `Todas las dosis completadas para el Día {day}. Descansa y recupérate.` | `Toutes les doses terminées pour le Jour {day}. Reposez-vous bien.` | `Alle Dosen für Tag {day} abgeschlossen. Ruhen Sie sich aus.` |
| `emergencyBannerTitle` | `Emergency Red Flag Warning` | `Avviso di Emergenza Rosso` | `Aviso de Emergencia Rojo` | `Alerte d'Urgence Rouge` | `Rote Notfallwarnung` |
| `emergencyCall911` | `Call Emergency (911)` | `Chiama Emergenza (112)` | `Llamar a Emergencias (911)` | `Appeler les Urgences (15)` | `Notruf wählen (112)` |
| `emergencyCallClinic` | `Call Care Team ({phone})` | `Chiama Reparto ({phone})` | `Llamar al Equipo ({phone})` | `Appeler l'Équipe ({phone})` | `Pflegeteam anrufen ({phone})` |
| `emergencyCallClinicFallback` | `Call Care Team` | `Chiama Reparto` | `Llamar al Equipo` | `Appeler l'Équipe` | `Pflegeteam anrufen` |
| `pillFormCapsule` | `Capsule` | `Capsula` | `Cápsula` | `Gélule` | `Kapsel` |
| `pillFormTablet` | `Tablet` | `Compressa` | `Comprimido` | `Comprimé` | `Tablette` |
| `pillFormLiquid` | `Liquid` | `Liquido` | `Líquido` | `Liquide` | `Flüssig` |


