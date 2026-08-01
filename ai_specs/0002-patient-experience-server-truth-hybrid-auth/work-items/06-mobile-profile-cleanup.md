---
type: Work Item
title: Mobile — Profile Cleanup + Change Password
parent: ../spec.md
---

## What to build
Clean up the Profile so it only shows what the backend supports. Remove the "Two-factor authentication" and "Connected devices" rows and the dead top-bar notification bell / fake badge. Wire "Change password" to the new backend endpoint. Replace every hardcoded fallback (e.g. Sarah Mitchell, Mar 14 1988, Knee Arthroscopy, Jun 18 2025, Dr. Claire Moreau, RC-4827-XK, the fake email/phone, Post-surgical recovery) with real auth/Case data or honest absence; fields with no backend source (notably Condition) show honest absence. Drop the "Invite code" row. Make "Medication reminders" and "Daily check-in" toggles persist to shared_preferences and gate scheduling only while OS notification permission is granted (inert + C1 banner if denied); remove the "FDA safety alerts" toggle.

## Required context
- `mobile/lib/features/profile/presentation/screens/profile_screen.dart` — current sections, dead rows, and hardcoded fallbacks.
- `mobile/lib/features/auth/presentation/providers/auth_provider.dart` and the `/auth/me` response — source of personal info.
- Backend change-password endpoint from `01-backend-hybrid-auth.md`; case data (DOB/surgery_date) from `02-backend-intake-data-model.md`.
- Notification permission model: coordinate with the first-run reminder primer / `0001` (C1 reminders-off banner owns recovery when permission denied).
- `shared_preferences` for toggle persistence.

## Acceptance criteria
- [ ] The 2FA row, Connected-devices row, and dead notification bell / fake badge are removed.
- [ ] "Change password" invokes the new endpoint (current password required only if one exists).
- [ ] No hardcoded fallbacks remain; personal info comes from `/auth/me` and is editable; unsupported fields (e.g. Condition) show honest absence; the Invite-code row is gone.
- [ ] Med-reminders and Daily-check-in toggles persist to shared_preferences and gate scheduling only while OS permission is granted; the FDA-alerts toggle is removed.
- [ ] Widget tests (FakeApiService) assert the removed rows are absent and real data renders.

## Covers
- User Stories: 6, 7
- Requirements: 20, 21, 22, 23, 24, 25
- Testing Strategy: 2
- Interview Ledger: L3, L6

## Blocked by
- 01-backend-hybrid-auth.md
- 02-backend-intake-data-model.md
