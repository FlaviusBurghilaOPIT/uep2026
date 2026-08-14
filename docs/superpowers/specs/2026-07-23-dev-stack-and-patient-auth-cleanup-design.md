# Local Dev Stack Cleanup, Docs Accuracy & Passwordless Patient Auth

**Date:** 2026-07-23
**Status:** Approved
**Scope:** docker-compose, root/mobile READMEs, mobile auth screens, backend auth router/models, backend email delivery, one existing UX spec doc

---

## Problem Statement

Several things have drifted out of sync or accumulated dead weight:

1. `docker-compose.yml` runs a Prism mock server (`mock/openapi.yaml`) that's only referenced by one README shortcut — a second, parallel way to run the stack that nothing else uses and that undercuts "just run the real backend."
2. Docs repeat environment details (Android emulator IP) in three places and don't tell a developer what they actually need running locally for the thing they're trying to test.
3. Mobile has a non-functional social-login stub (`SocialLoginRow` — tapping any provider just shows a "coming soon" snackbar) and a dead "forgot password" route.
4. Patient auth on mobile is split across two disconnected screens — a password-based `login_screen.dart` for returning patients and a separate 6-digit-invite-code screen (`signup_step1_screen.dart`) for first-time onboarding — with no way for a returning patient to recover access except remembering a password.
5. `docs/ux/engineering-spec-web-e2e-suite.md` claims specific web test files exist and are "Completed & Verified." They don't exist — `web/src` has zero `*.test.*` files despite `vitest` being installed.
6. Root and mobile READMEs don't mention `integration_test/golden_loop_test.dart` at all, or that it needs a live backend + seeded DB + booted simulator, unlike unit/widget tests which need neither.

**Root cause (auth piece):** patient auth was built incrementally (invite-code flow, then a separate password-login screen) without unifying the two, so there's no self-service way back in after a session ends besides a password a post-surgery patient may not remember.

**Non-goal clarification up front:** clinician web auth (email + password) is unaffected by this design. It never had social login or a magic-link mechanism to remove or add.

---

## Design Decision: Approach — Unified OTP for Patients, Docs That Match Reality

Replace patient password auth entirely with a single emailed one-time code (OTP) mechanism that covers both first-time invite-onboarding and every subsequent re-login. Remove the Prism mock path from local dev entirely rather than maintaining it alongside the real backend. Correct docs to describe what the code actually does, including the two testing tiers (unit/widget vs integration/e2e) per platform.

Real tappable deep-linking (App/Universal Links) is explicitly out of scope — there's no existing deep-link infrastructure in the app, and building it is a substantially larger effort than the rest of this design combined. The "magic link" is realized as an emailed code, typed into the app; the email can contain a link, but the link is not load-bearing.

---

## Section 1: Backend — Patient OTP Auth

### Data model (`backend/app/models.py`)

Add to `User`:
```python
invite_code_expires_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
```

New Alembic migration. `invite_code` itself is reused as the OTP value (no new column needed for the code itself) — this also fixes a latent gap where invite codes currently never expire.

Patients never get `password_hash` populated. The column stays on `User` (still used by clinicians); it's simply never set for `role == patient` going forward.

### Endpoints (`backend/app/routers/auth.py`)

**`POST /auth/patient/request-code`** — body `{email}`.
- Looks up a `patient`-role `User` by email, any `status`.
- If found: generates a 6-digit code (`secrets.randbelow`, same generation already used for invites in `patients.py`), sets `invite_code` + `invite_code_expires_at` (now + 15 min), sends it via the email service.
- Always returns generic `200 {"message": "If that email exists, a code was sent."}` regardless of whether a user was found — no enumeration.
- This endpoint is also what `POST /patients/invite` calls at creation time, so a newly invited patient gets emailed immediately instead of the clinician being the only one who sees the code (the web UI still displays it too, as a fallback channel if email delivery is delayed or fails).

**`POST /auth/patient/verify-code`** — body `{email, code}`.
- Rejects if code doesn't match, or `invite_code_expires_at` has passed.
- If `user.status == "pending_onboarding"`: same response shape as today's `verify-invite` (email, full_name, status) — mobile proceeds to onboarding step 2 (DOB/phone).
- If `user.status == "active"`: clears `invite_code`/`invite_code_expires_at` and returns `{access_token, token_type}` directly — this is the returning-patient sign-in path.
- Code is single-use either way (cleared on successful verify).

**`complete-onboarding`**: `schemas.CompleteOnboardingRequest` drops the `password` field. No password is ever set for patients.

**Unchanged**: `/auth/login`, `/auth/verify-invite`, `/auth/dev-login` remain exactly as-is for clinician use. Mobile stops calling them.

### Email delivery (`backend/app/services/email_service.py`, new)

Same shape as `sns_push_service.py`:
```python
class EmailService:
    def __init__(self):
        self.aws_region = os.getenv("AWS_REGION")
        if self.aws_region:
            try:
                import boto3
                self.ses_client = boto3.client("ses", region_name=self.aws_region)
                self.dry_run = False
            except Exception as e:
                logger.warning(f"Failed to initialize boto3 SES client: {e}. Falling back to dry-run.")
                self.ses_client = None
                self.dry_run = True
        else:
            self.ses_client = None
            self.dry_run = True

    def send_patient_code(self, email: str, code: str) -> None:
        if self.dry_run:
            logger.info(f"[DRY RUN] Would email code {code} to {email}")
            return
        # real SES send_email call
```
No local SMTP server needed — local/dev runs always dry-run unless `AWS_REGION` is set, matching how SNS push already behaves.

### Seed data (`backend/app/scripts/seed_data.py`)

Demo patient no longer gets a `password_hash`. Seeded instead with a fixed, long-lived demo code documented in the README, so the golden-loop demo walkthrough doesn't require reading backend logs to find a code (though that also works, via the dry-run log line).

---

## Section 2: Mobile — Merged Auth Screen

### Screen consolidation

`login_screen.dart` and `signup_step1_screen.dart` merge into one flow:
1. Email entry → "Send me a code" → `POST /auth/patient/request-code`.
2. Code entry (reuses the existing 6-digit input UI) → `POST /auth/patient/verify-code`.
3. Response branch in `auth_notifier.dart`:
   - Contains `access_token` → store token, `AuthState.authenticated`.
   - Contains onboarding profile fields, no token → `AuthState.onboarding`, route to `signupStep2` (DOB/phone — no password field).

`onboarding_screen.dart`'s "Sign In" and "Create one" buttons both route to this single screen — new-vs-returning is determined by the backend response, not by which button was tapped.

A "Resend code" action is available on the code-entry step with a 30-second client-side cooldown.

### Removed

- `password` field/controller from the login flow; `signIn(email, password)` from `auth_notifier.dart`.
- `core/shared_widgets/social_login_row.dart` and its only usage (`login_screen.dart`) — dead stub, no other callers.
- `forgotPassword` route and its backing screen (patients have no password to forget).
- `SecurityBadge`'s Cognito-password-specific copy on the login screen, replaced with copy appropriate to code-based sign-in.

### Copy / l10n

Existing invite-code strings ("Verify Invitation", "6-digit invite code...") reworded to be onboarding/re-login agnostic (e.g. "Enter the code we emailed you") across all 5 locale `.arb` files.

---

## Section 3: Local Dev Stack

### `docker-compose.yml`

Delete the `mock` service block (lines defining the `stoplight/prism` container). Delete `mock/openapi.yaml` and the now-empty `mock/` directory.

### Root `README.md`

- Collapse "Full Demo" + "Frontend-Only Quick Start" into one guide: backend (+ Postgres) is step 1, always — via `docker-compose up backend`, no mock alternative.
- Add a "what do you need running" table:

  | Goal | Needs running |
  |------|----------------|
  | Work on the web app | backend + web |
  | Work on the mobile app | backend + seeded DB + mobile |
  | Backend unit tests only | nothing else — `pytest` is self-contained |
  | Mobile unit/widget tests only | nothing else — uses `FakeApiService`, no backend |
  | Mobile integration/e2e test | backend + seeded DB + booted simulator |

- Testing section rewritten per-platform with explicit tiers (see Section 4).
- Demo walkthrough step 4 updated: patient enters email on mobile, receives a code (via demo seed code or backend dry-run log), enters it — no password step.
- Android emulator IP (`10.0.2.2`) mentioned once, pointing to `mobile/README.md` as the single source of truth instead of being repeated three times.

### `mobile/README.md`

Add the missing section for running `integration_test/golden_loop_test.dart`: prerequisites (backend running, DB seeded, simulator booted), the command, and that — unlike `flutter test` — it needs the full stack.

---

## Section 4: Testing — Unit vs. Integration/E2E, Per Platform

| Platform | Unit / Widget tier | Integration / E2E tier |
|----------|--------------------|--------------------------|
| Backend | `pytest tests -q` — in-memory SQLite, no Docker/Postgres, no external services (LLM/SNS/email all mocked or dry-run) | *(none exists — backend's pytest suite already exercises real routes via `TestClient`, so there isn't a separate e2e tier today)* |
| Web | *(none exist yet)* — `vitest`/`@testing-library/react` are installed but unused | *(none exist yet)* |
| Mobile | `flutter test` (`test/unit`, `test/widget`) — uses `FakeApiService`, no backend needed | `flutter test integration_test/golden_loop_test.dart` — needs backend running, DB seeded, simulator booted |

`docs/ux/engineering-spec-web-e2e-suite.md` is rewritten to state this honestly: no web tests exist today, the doc becomes a forward-looking proposal instead of a false "Completed & Verified" record, and the references to `triage_dashboard.test.tsx` / `navbar_i18n.test.tsx` (files that don't exist) are removed.

No existing test doubles are removed: backend's in-memory SQLite and mobile's `FakeApiService` are legitimate unit-test seams, not something this cleanup touches.

---

## Files Changed

| File | Change |
|------|--------|
| `docker-compose.yml` | Remove `mock` service |
| `mock/` | Delete directory |
| `backend/app/models.py` | Add `invite_code_expires_at` to `User` |
| `backend/alembic/versions/*` | New migration for the added column |
| `backend/app/routers/auth.py` | Add `/auth/patient/request-code`, `/auth/patient/verify-code`; drop `password` from `complete-onboarding` |
| `backend/app/routers/patients.py` | `POST /patients/invite` calls the new email-code path on creation |
| `backend/app/schemas.py` | Update `CompleteOnboardingRequest` (drop `password`); add request/response schemas for the two new endpoints |
| `backend/app/services/email_service.py` | New — SES with dry-run fallback |
| `backend/app/scripts/seed_data.py` | Demo patient seeded with a fixed code, no password |
| `mobile/lib/features/auth/login_screen.dart` | Rework into merged email→code screen |
| `mobile/lib/features/auth/signup_step1_screen.dart` | Deleted — its code-entry UI is absorbed into `login_screen.dart` |
| `mobile/lib/features/auth/providers/auth_notifier.dart` | Replace `signIn`/`verifyInvite` with `requestCode`/`verifyCode`; drop password from `completeOnboarding` |
| `mobile/lib/features/auth/onboarding_screen.dart` | Both CTAs route to merged screen |
| `mobile/lib/core/shared_widgets/social_login_row.dart` | Deleted |
| `mobile/lib/core/navigation/app_routes.dart` | Remove `forgotPassword` route |
| `mobile/lib/core/l10n/app_*.arb` (5 locales) | Reword invite/login copy to be flow-agnostic |
| `README.md` | Restructure quick start, testing section, demo walkthrough, IP reference |
| `mobile/README.md` | Add integration-test section, consolidate IP/`--dart-define` docs |
| `docs/ux/engineering-spec-web-e2e-suite.md` | Rewrite to match reality |

---

## Non-Goals

- Real deep-linking (App Links / Universal Links) for the emailed code — future enhancement.
- Building the actual web unit/e2e test suite — only the doc claiming it exists gets corrected.
- Server-side rate-limiting on `request-code` — client-side cooldown only for now.
- Any change to clinician web auth (stays email + password, untouched).
- Alembic migration squashing or unrelated schema cleanup — only `invite_code_expires_at` is added.

---

## Testing

| Layer | Test |
|-------|------|
| Backend unit | `request-code` for unknown email returns generic 200, no user created |
| Backend unit | `verify-code` with expired `invite_code_expires_at` returns 400 |
| Backend unit | `verify-code` for `pending_onboarding` user returns profile fields, no token |
| Backend unit | `verify-code` for `active` user returns `access_token`, clears `invite_code` |
| Backend unit | `complete-onboarding` no longer accepts/persists a `password` field; a patient completing onboarding never gets a `password_hash` set |
| Mobile widget | Merged auth screen: email step → code step → both branches (onboarding vs authenticated) using `FakeApiService` |
| Mobile widget | `SocialLoginRow` and `forgotPassword` route no longer referenced anywhere (`flutter analyze` catches dangling imports) |
| Mobile integration/e2e | `golden_loop_test.dart` updated to drive the new email-code flow instead of password login |
