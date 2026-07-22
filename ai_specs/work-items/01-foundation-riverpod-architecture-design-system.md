---
type: Work Item
title: Foundation — Riverpod Migration, Clean Architecture Folder Restructure & Design System
parent: ../2026-07-22-flutter-mobile-enhancements-spec.md
---

## What to build

Replace the legacy `provider` package with `flutter_riverpod: ^2.5.1` in `mobile/pubspec.yaml`. Wrap the root `RemoteCareApp` widget with `ProviderScope`. Restructure the entire `lib/` directory into feature-first clean architecture. Implement the medical design system tokens in `lib/core/theme/`. Move `ApiService` to `lib/core/network/`.

### Folder structure target

```
mobile/lib/
├── core/
│   ├── l10n/                     # ARB files & generated AppLocalizations (empty placeholder)
│   ├── network/
│   │   └── api_service.dart      # Moved from lib/core/services/
│   ├── notifications/            # Empty placeholder for WI-04
│   ├── theme/
│   │   ├── app_colors.dart       # Medical palette constants
│   │   ├── app_text_styles.dart  # GoogleFonts.outfit() / GoogleFonts.inter()
│   │   └── app_theme.dart        # ThemeData using palette + text styles
│   └── widgets/                  # Shared shimmer, error, empty state widgets
├── features/
│   ├── auth/                     # Existing auth screens moved here
│   ├── today/                    # Existing today_screen.dart moved here
│   ├── checkin/                  # Existing checkin_screen.dart moved here
│   ├── assistant/                # Existing assistant_screen.dart moved here
│   ├── recovery/                 # Existing recovery screens moved here
│   └── profile/                  # Existing profile screens moved here
└── main.dart
```

### Design system tokens

`lib/core/theme/app_colors.dart`:
```dart
import 'package:flutter/material.dart';

class AppColors {
  static const deepTeal = Color(0xFF0D9488);
  static const softCyan = Color(0xFFF0FDF4);
  static const clinicalEmerald = Color(0xFF059669);
  static const slateDark = Color(0xFF0F172A);
  static const white = Color(0xFFFFFFFF);
  static const errorRed = Color(0xFFDC2626);
}
```

`lib/core/theme/app_text_styles.dart` — use `GoogleFonts.outfit()` for all heading/display text and `GoogleFonts.inter()` for body/caption text.

`lib/core/theme/app_theme.dart` — build `ThemeData` using the palette and text theme. Set `colorScheme` seed to `AppColors.deepTeal`.

### pubspec.yaml changes

Remove `provider: ^6.1.5+1`. Add:
```yaml
flutter_riverpod: ^2.5.1
riverpod_annotation: ^2.3.5
```

Keep: `flutter_localizations` (will be configured in WI-03), `flutter_local_notifications` (configured in WI-04), `google_fonts`, `flutter_screenutil`, `http`, `shared_preferences`, `intl`.

Add to `dev_dependencies`:
```yaml
riverpod_generator: ^2.4.0
build_runner: ^2.4.0
custom_lint: ^0.6.0
riverpod_lint: ^2.3.0
```

## Required context

- Current `mobile/pubspec.yaml` — used to confirm which packages to keep vs. remove.
- Current `mobile/lib/core/services/api_service.dart` — move to `lib/core/network/api_service.dart`; update all import paths throughout the project.
- Current `mobile/lib/main.dart` — add `ProviderScope` wrapper.
- `docs/DESIGN.md` — confirms the medical color palette and typography.
- Run `flutter pub get` after pubspec changes. Run `flutter analyze` to confirm zero errors before committing.

## Acceptance criteria

- [ ] `pubspec.yaml` contains `flutter_riverpod: ^2.5.1`; `provider` package is fully removed.
- [ ] `RemoteCareApp` in `main.dart` is wrapped with `ProviderScope`.
- [ ] `lib/` directory matches the feature-first folder structure above; no Dart files remain at old paths.
- [ ] `ApiService` is importable from `package:remotecare/core/network/api_service.dart`.
- [ ] `AppColors`, `AppTextStyles`, `AppTheme` exist and are applied in `main.dart` via `theme: AppTheme.light()`.
- [ ] `flutter analyze` reports zero errors.
- [ ] `flutter test` passes (existing tests, even if trivial).

## Covers

- User Stories: 3
- Requirements: State Management 1, 4; Medical UI/UX 1
- Technical Decisions: 1, 2
- Interview Ledger: L1, L4

## Blocked by

None — ready to start
