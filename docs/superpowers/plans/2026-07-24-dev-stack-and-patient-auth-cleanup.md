# Dev Stack Cleanup & Passwordless Patient Auth Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove the Prism mock service and dead mobile auth stubs, replace patient (mobile) password auth with a single emailed one-time-code mechanism shared by first-time onboarding and every subsequent re-login, and bring the docs (root README, mobile README, and one UX spec) in line with what the code actually does.

**Architecture:** Backend gains two new patient-only endpoints (`/auth/patient/request-code`, `/auth/patient/verify-code`) built on the existing `invite_code` column (plus a new expiry column) and a new `EmailService` that mirrors the existing SNS push service's dry-run-when-unconfigured pattern. Mobile collapses two separate screens (password login + invite-code signup) into one email→code screen, removing the password field, the non-functional social-login row, and a dead-code duplicate auth implementation discovered during research. Clinician web auth is untouched throughout.

**Tech Stack:** FastAPI + SQLAlchemy + Alembic (backend), Flutter + Riverpod (mobile), React + Vite (web, one small copy change only).

## Global Constraints

- Clinician email+password login (`/auth/login`, `/auth/dev-login`, `web/src/pages/LoginPage.tsx`) is **not modified** by this plan.
- No new third-party dependencies: `boto3` is already a backend dependency (used by `llm.py`, `rag.py`, `sns_push_service.py`); the new `EmailService` uses it the same way.
- Follow the existing dry-run pattern from `backend/app/services/sns_push_service.py` exactly: real AWS call when `AWS_REGION` is set and boto3 initializes cleanly, otherwise log and no-op.
- Backend tests use the `client`/`db_session` fixtures from `backend/tests/conftest.py` (in-memory SQLite) — do not add real-Postgres or real-network dependencies to new tests.
- Mobile tests use `FakeApiService` (`mobile/test/unit/fake_api_service.dart`) — do not introduce mockito/mocktail.
- Real deep-linking (App Links / Universal Links) is out of scope — the emailed code is typed into the app, not tapped from a link.
- No changes to Alembic migrations other than the one new column this plan adds.

---

### Task 1: Remove the Prism mock service

**Files:**
- Modify: `docker-compose.yml`
- Delete: `mock/openapi.yaml`, `mock/` directory

**Interfaces:** None — this task has no code dependents.

- [ ] **Step 1: Remove the `mock` service block from `docker-compose.yml`**

Delete these lines (currently lines 28–36):
```yaml
  mock:
    image: stoplight/prism:4
    command: mock -h 0.0.0.0 -p 8001 /tmp/openapi.yaml
    volumes:
      - ./mock/openapi.yaml:/tmp/openapi.yaml
    ports:
      - "8001:8001"
```
Also remove the blank line directly above it so `db`, `backend`, and `web` remain separated by exactly one blank line each, matching the file's existing style.

- [ ] **Step 2: Delete the mock directory**

Run: `git rm -r mock/`
Expected: removes `mock/openapi.yaml` (the only file in that directory).

- [ ] **Step 3: Verify docker-compose still parses**

Run: `docker-compose config --quiet`
Expected: no output, exit code 0 (confirms the YAML is still valid after the edit).

- [ ] **Step 4: Commit**

```bash
git add docker-compose.yml
git commit -m "chore: remove Prism mock service from docker-compose

The mock service was only used by one README shortcut and duplicated
a second way to run the stack. The real backend is now the only path."
```

---

### Task 2: Delete the dead mobile social-login stub

**Files:**
- Delete: `mobile/lib/core/shared_widgets/social_login_row.dart`
- Modify: `mobile/lib/features/auth/login_screen.dart:11,145` (remove import and usage — this will also be touched by Task 10, but remove it now so the app compiles at every intermediate commit)

**Interfaces:** None — `SocialLoginRow` has no other callers (confirmed via repo-wide grep).

- [ ] **Step 1: Remove the import and usage from `login_screen.dart`**

Remove line 11:
```dart
import '../../core/shared_widgets/social_login_row.dart';
```
Remove lines 145–146:
```dart
                const SocialLoginRow(),
                SizedBox(height: AppSpacing.xxl),
```
(Leave the surrounding `SizedBox(height: AppSpacing.xl)` before it and the button after it in place — this just removes the row itself and its trailing spacer.)

- [ ] **Step 2: Delete the widget file**

Run: `git rm mobile/lib/core/shared_widgets/social_login_row.dart`

- [ ] **Step 3: Verify the app still analyzes cleanly**

Run: `cd mobile && flutter analyze`
Expected: 0 issues (no dangling references to `SocialLoginRow`).

- [ ] **Step 4: Commit**

```bash
git add mobile/lib/features/auth/login_screen.dart
git commit -m "fix(mobile): remove non-functional social-login stub

SocialLoginRow's buttons only ever showed a 'coming soon' snackbar —
dead UI with no backend integration."
```

---

### Task 3: Delete the dead parallel auth implementation

**Files:**
- Delete: `mobile/lib/features/auth/providers/auth_notifier.dart`, `mobile/lib/features/auth/providers/auth_notifier.freezed.dart`
- Delete: `mobile/test/unit/auth_provider_test.dart`
- Modify: `mobile/lib/features/assistant/assistant_screen.dart:7,40-54`

**Interfaces:** None removed that anything outside this task depends on — `authNotifierProvider`/`AuthStateNotifier` are read in exactly one place (`assistant_screen.dart._getCaseId()`), and that read's result is always discarded in practice because nothing in the shipped app ever calls `AuthStateNotifier`'s mutating methods (`signIn`, `verifyInvite`, `completeOnboarding`) — only its own now-deleted test does. The real, live auth state lives in `AuthNotifier`/`authProvider` (`app_providers.dart`), which every screen actually uses.

- [ ] **Step 1: Simplify `_getCaseId()` in `assistant_screen.dart`**

Replace (lines 40–54):
```dart
  String _getCaseId() {
    final authAsync = ref.read(authNotifierProvider);
    final caseIdFromNotifier = authAsync.maybeWhen(
      data: (state) => state.maybeWhen(
        authenticated: (userId, caseId, fullName, email, surgeryType) => caseId,
        orElse: () => null,
      ),
      orElse: () => null,
    );
    if (caseIdFromNotifier != null && caseIdFromNotifier.isNotEmpty) {
      return caseIdFromNotifier;
    }
    final auth = ref.read(authProvider);
    return auth.caseId ?? 'default_case';
  }
```
with:
```dart
  String _getCaseId() {
    final auth = ref.read(authProvider);
    return auth.caseId ?? 'default_case';
  }
```

- [ ] **Step 2: Remove the now-unused import from `assistant_screen.dart`**

Remove line 7:
```dart
import '../auth/providers/auth_notifier.dart';
```

- [ ] **Step 3: Delete the dead files**

Run:
```bash
git rm mobile/lib/features/auth/providers/auth_notifier.dart
git rm mobile/lib/features/auth/providers/auth_notifier.freezed.dart
git rm mobile/test/unit/auth_provider_test.dart
```

- [ ] **Step 4: Verify the app still analyzes and existing tests still pass**

Run: `cd mobile && flutter analyze`
Expected: 0 issues.

Run: `cd mobile && flutter test`
Expected: all remaining tests pass (the deleted `auth_provider_test.dart` no longer runs).

- [ ] **Step 5: Commit**

```bash
git add mobile/lib/features/assistant/assistant_screen.dart
git commit -m "fix(mobile): remove dead parallel auth implementation

AuthStateNotifier/authNotifierProvider was never wired to any real
screen — every screen uses AuthNotifier/authProvider in
app_providers.dart. assistant_screen.dart's fallback read of the dead
notifier always returned null in practice; removed."
```

---

### Task 4: Backend — add code-expiry column

**Files:**
- Modify: `backend/app/models.py:73` (add column after `invite_code`)
- Create: `backend/alembic/versions/f4a9c7d21b3e_add_invite_code_expiry.py`

**Interfaces:**
- Produces: `models.User.invite_code_expires_at: datetime | None` — consumed by Task 6's endpoints.

- [ ] **Step 1: Add the column to the `User` model**

In `backend/app/models.py`, change line 73 from:
```python
    invite_code: Mapped[str | None] = mapped_column(String, nullable=True)
```
to:
```python
    invite_code: Mapped[str | None] = mapped_column(String, nullable=True)
    invite_code_expires_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
```

- [ ] **Step 2: Write the Alembic migration**

Create `backend/alembic/versions/f4a9c7d21b3e_add_invite_code_expiry.py`:
```python
"""add invite code expiry

Revision ID: f4a9c7d21b3e
Revises: 26798872475f
Create Date: 2026-07-24 09:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'f4a9c7d21b3e'
down_revision: Union[str, Sequence[str], None] = '26798872475f'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.add_column('users', sa.Column('invite_code_expires_at', sa.DateTime(), nullable=True))


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_column('users', 'invite_code_expires_at')
```

- [ ] **Step 3: Verify the migration applies against the running dev DB**

Run: `docker-compose exec backend alembic upgrade head`
Expected: output ending in `... -> f4a9c7d21b3e, add invite code expiry`, exit code 0.

If the backend/db containers aren't running locally, this step can instead be verified in Task 6's test run, since the `client`/`db_session` fixture builds tables straight from `models.py` (`Base.metadata.create_all`) and doesn't run Alembic — but the migration file must still exist and be syntactically correct for real deployments.

- [ ] **Step 4: Commit**

```bash
git add backend/app/models.py backend/alembic/versions/f4a9c7d21b3e_add_invite_code_expiry.py
git commit -m "feat(backend): add invite_code_expires_at to User

Invite codes currently never expire. This column backs the new
patient one-time-code auth flow (Task 6), where codes expire 15
minutes after issue."
```

---

### Task 5: Backend — email delivery service

**Files:**
- Create: `backend/app/services/email_service.py`
- Test: `backend/tests/test_email_service.py`

**Interfaces:**
- Produces: `EmailService` class with `send_patient_code(email: str, code: str) -> None` — consumed by Task 6's `request-code` endpoint and Task 7's invite endpoint.

- [ ] **Step 1: Write the failing test**

Create `backend/tests/test_email_service.py`:
```python
import logging

from app.services.email_service import EmailService


def test_send_patient_code_dry_run_logs_when_no_aws_region(monkeypatch, caplog):
    monkeypatch.delenv("AWS_REGION", raising=False)
    service = EmailService()

    with caplog.at_level(logging.INFO):
        service.send_patient_code("patient@example.com", "123456")

    assert service.dry_run is True
    assert any(
        "123456" in record.message and "patient@example.com" in record.message
        for record in caplog.records
    )
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd backend && python3 -m pytest tests/test_email_service.py -v`
Expected: FAIL with `ModuleNotFoundError: No module named 'app.services.email_service'`

- [ ] **Step 3: Write the implementation**

Create `backend/app/services/email_service.py`:
```python
import logging
import os

logger = logging.getLogger(__name__)


class EmailService:
    def __init__(self):
        self.aws_region = os.getenv("AWS_REGION")
        self.sender_address = os.getenv("SES_SENDER_ADDRESS", "no-reply@remotecarepro.local")

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
        subject = "Your RemoteCare Pro sign-in code"
        body = f"Your sign-in code is {code}. It expires in 15 minutes."

        if self.dry_run:
            logger.info(f"[DRY RUN] Would email code {code} to {email}: {subject}")
            return

        self.ses_client.send_email(
            Source=self.sender_address,
            Destination={"ToAddresses": [email]},
            Message={
                "Subject": {"Data": subject},
                "Body": {"Text": {"Data": body}},
            },
        )
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd backend && python3 -m pytest tests/test_email_service.py -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add backend/app/services/email_service.py backend/tests/test_email_service.py
git commit -m "feat(backend): add EmailService with SES dry-run fallback

Mirrors sns_push_service.py's pattern: real SES send when AWS_REGION
is set, otherwise logs instead of sending. No local SMTP server
needed for dev."
```

---

### Task 6: Backend — patient OTP endpoints

**Files:**
- Modify: `backend/app/schemas.py` (add request/response schemas, update `CompleteOnboardingRequest`)
- Modify: `backend/app/routers/auth.py` (add two endpoints, drop password from `complete_onboarding`)
- Test: `backend/tests/test_auth_router.py` (new file)

**Interfaces:**
- Consumes: `EmailService.send_patient_code` (Task 5), `models.User.invite_code_expires_at` (Task 4).
- Produces:
  - `POST /auth/patient/request-code` — body `{"email": str}` → `200 {"message": str}` always.
  - `POST /auth/patient/verify-code` — body `{"email": str, "code": str}` → `200 {"result": "onboarding", "email": str, "full_name": str}` or `200 {"result": "authenticated", "access_token": str, "token_type": "bearer"}` or `400 {"detail": str}`.
  - `complete-onboarding` no longer accepts or persists a `password` field.

- [ ] **Step 1: Write the failing tests**

Create `backend/tests/test_auth_router.py`:
```python
from datetime import datetime, timedelta

from app import models


def _make_patient(db_session, status="pending_onboarding", code="111111", expires_delta=timedelta(minutes=15)):
    patient = models.User(
        email="patient@example.com",
        full_name="Jane Doe",
        role=models.UserRole.patient,
        status=status,
        invite_code=code,
        invite_code_expires_at=datetime.utcnow() + expires_delta,
    )
    db_session.add(patient)
    db_session.commit()
    db_session.refresh(patient)
    return patient


def test_request_code_for_unknown_email_returns_generic_200_and_creates_no_user(client, db_session):
    response = client.post("/auth/patient/request-code", json={"email": "nobody@example.com"})

    assert response.status_code == 200
    assert response.json() == {"message": "If that email exists, a code was sent."}
    assert db_session.query(models.User).filter(models.User.email == "nobody@example.com").first() is None


def test_request_code_for_existing_patient_sets_code_and_expiry(client, db_session):
    patient = _make_patient(db_session, code=None, expires_delta=None)
    patient.invite_code = None
    patient.invite_code_expires_at = None
    db_session.commit()

    response = client.post("/auth/patient/request-code", json={"email": "patient@example.com"})

    assert response.status_code == 200
    db_session.refresh(patient)
    assert patient.invite_code is not None
    assert len(patient.invite_code) == 6
    assert patient.invite_code_expires_at is not None
    assert patient.invite_code_expires_at > datetime.utcnow()


def test_verify_code_with_expired_code_returns_400(client, db_session):
    _make_patient(db_session, expires_delta=timedelta(minutes=-1))

    response = client.post(
        "/auth/patient/verify-code",
        json={"email": "patient@example.com", "code": "111111"},
    )

    assert response.status_code == 400


def test_verify_code_with_wrong_code_returns_400(client, db_session):
    _make_patient(db_session)

    response = client.post(
        "/auth/patient/verify-code",
        json={"email": "patient@example.com", "code": "999999"},
    )

    assert response.status_code == 400


def test_verify_code_for_pending_onboarding_user_returns_onboarding_result(client, db_session):
    _make_patient(db_session, status="pending_onboarding")

    response = client.post(
        "/auth/patient/verify-code",
        json={"email": "patient@example.com", "code": "111111"},
    )

    assert response.status_code == 200
    body = response.json()
    assert body["result"] == "onboarding"
    assert body["email"] == "patient@example.com"
    assert body["full_name"] == "Jane Doe"
    assert "access_token" not in body


def test_verify_code_for_active_user_returns_token_and_clears_code(client, db_session):
    patient = _make_patient(db_session, status="active")

    response = client.post(
        "/auth/patient/verify-code",
        json={"email": "patient@example.com", "code": "111111"},
    )

    assert response.status_code == 200
    body = response.json()
    assert body["result"] == "authenticated"
    assert "access_token" in body

    db_session.refresh(patient)
    assert patient.invite_code is None
    assert patient.invite_code_expires_at is None


def test_complete_onboarding_does_not_accept_or_persist_password(client, db_session):
    _make_patient(db_session, status="pending_onboarding")

    response = client.post(
        "/auth/complete-onboarding",
        json={
            "email": "patient@example.com",
            "invite_code": "111111",
            "date_of_birth": "1990-01-01",
            "phone": "1234567890",
        },
    )

    assert response.status_code == 200
    patient = db_session.query(models.User).filter(models.User.email == "patient@example.com").first()
    assert patient.password_hash is None
    assert patient.status == "active"
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd backend && python3 -m pytest tests/test_auth_router.py -v`
Expected: FAIL — `404 Not Found` for the two new routes, and the `complete-onboarding` test fails validation (schema still requires `password`).

- [ ] **Step 3: Add the new schemas**

In `backend/app/schemas.py`, change `CompleteOnboardingRequest` (currently lines 80–85) from:
```python
class CompleteOnboardingRequest(BaseModel):
    email: str
    invite_code: str
    password: str
    date_of_birth: str
    phone: str
```
to:
```python
class CompleteOnboardingRequest(BaseModel):
    email: str
    invite_code: str
    date_of_birth: str
    phone: str
```

Then add, directly after `CompleteOnboardingRequest`:
```python
class PatientRequestCodeRequest(BaseModel):
    email: str


class PatientRequestCodeResponse(BaseModel):
    message: str = "If that email exists, a code was sent."


class PatientVerifyCodeRequest(BaseModel):
    email: str
    code: str
```

(No response schema for `verify-code` — its two possible shapes are returned as a plain dict, matching the existing precedent of `export_patient_telemetry` in `patients.py`, which also skips `response_model` for a variable-shaped JSON response.)

- [ ] **Step 4: Add the endpoints and update `complete_onboarding`**

In `backend/app/routers/auth.py`, update the imports (top of file) from:
```python
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app import models, schemas
from app.database import get_db
from app.dependencies import get_current_user
from app.security import create_access_token, hash_password, verify_password
```
to:
```python
import secrets
from datetime import datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app import models, schemas
from app.database import get_db
from app.dependencies import get_current_user
from app.security import create_access_token, verify_password
from app.services.email_service import EmailService
```
(`hash_password` is dropped from this import — it's still used by `complete_onboarding` today via `user.password_hash = hash_password(...)`, which this task removes; `patients.py`'s `create_patient` still imports and uses it separately, unaffected.)

Replace `complete_onboarding` (currently lines 54–79) with:
```python
@router.post("/complete-onboarding", response_model=schemas.TokenResponse)
def complete_onboarding(req: schemas.CompleteOnboardingRequest, db: Session = Depends(get_db)):
    user = (
        db.query(models.User)
        .filter(
            models.User.email == req.email,
            models.User.invite_code == req.invite_code,
            models.User.status == "pending_onboarding",
        )
        .first()
    )

    if not user:
        raise HTTPException(status_code=400, detail="Invalid email or invite code")

    user.date_of_birth = req.date_of_birth
    user.phone = req.phone
    user.status = "active"
    user.invite_code = None
    user.invite_code_expires_at = None

    db.commit()
    db.refresh(user)

    token = create_access_token({"sub": user.id, "role": user.role.value, "email": user.email})
    return {"access_token": token, "token_type": "bearer"}
```

Then add these two new endpoints after `get_me` (end of file):
```python
@router.post("/patient/request-code", response_model=schemas.PatientRequestCodeResponse)
def request_patient_code(req: schemas.PatientRequestCodeRequest, db: Session = Depends(get_db)):
    user = (
        db.query(models.User)
        .filter(models.User.email == req.email, models.User.role == models.UserRole.patient)
        .first()
    )

    if user:
        code = f"{secrets.randbelow(900000) + 100000}"
        user.invite_code = code
        user.invite_code_expires_at = datetime.utcnow() + timedelta(minutes=15)
        db.commit()

        email_service = EmailService()
        email_service.send_patient_code(user.email, code)

    return schemas.PatientRequestCodeResponse()


@router.post("/patient/verify-code")
def verify_patient_code(req: schemas.PatientVerifyCodeRequest, db: Session = Depends(get_db)):
    user = (
        db.query(models.User)
        .filter(models.User.email == req.email, models.User.role == models.UserRole.patient)
        .first()
    )

    if (
        not user
        or not user.invite_code
        or user.invite_code != req.code
        or not user.invite_code_expires_at
        or user.invite_code_expires_at < datetime.utcnow()
    ):
        raise HTTPException(status_code=400, detail="Invalid or expired code")

    if user.status == "pending_onboarding":
        return {
            "result": "onboarding",
            "email": user.email,
            "full_name": user.full_name,
        }

    user.invite_code = None
    user.invite_code_expires_at = None
    db.commit()

    token = create_access_token({"sub": user.id, "role": user.role.value, "email": user.email})
    return {"result": "authenticated", "access_token": token, "token_type": "bearer"}
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `cd backend && python3 -m pytest tests/test_auth_router.py -v`
Expected: PASS (7 tests)

- [ ] **Step 6: Run the full backend suite to check for regressions**

Run: `cd backend && python3 -m pytest tests -q`
Expected: all tests pass (no other test file constructs a `CompleteOnboardingRequest` with a `password` field — confirmed via repo-wide search in Task 6 research; `test_auth_router.py` is the only auth-router test file).

- [ ] **Step 7: Commit**

```bash
git add backend/app/schemas.py backend/app/routers/auth.py backend/tests/test_auth_router.py
git commit -m "feat(backend): add patient one-time-code auth endpoints

POST /auth/patient/request-code and /auth/patient/verify-code replace
password auth for patients. complete-onboarding no longer accepts a
password. Clinician /auth/login is unchanged."
```

---

### Task 7: Backend — email the patient at invite time

**Files:**
- Modify: `backend/app/routers/patients.py:1-11,20-59`

**Interfaces:**
- Consumes: `EmailService.send_patient_code` (Task 5).

- [ ] **Step 1: Write the failing test**

Add to `backend/tests/test_auth_router.py` (append):
```python
from unittest.mock import patch


def test_invite_patient_sends_code_via_email(client, db_session):
    clinician = models.User(
        email="c@t.com",
        full_name="Dr. Clinician",
        role=models.UserRole.clinician,
    )
    db_session.add(clinician)
    db_session.commit()

    from app.security import create_access_token

    token = create_access_token({"sub": clinician.id, "role": "clinician", "email": clinician.email})

    with patch("app.routers.patients.EmailService.send_patient_code") as mock_send:
        response = client.post(
            "/patients/invite",
            json={
                "email": "newpatient@example.com",
                "full_name": "New Patient",
                "surgery_type": "knee",
            },
            headers={"Authorization": f"Bearer {token}"},
        )

    assert response.status_code == 200
    invite_code = response.json()["invite_code"]
    mock_send.assert_called_once_with("newpatient@example.com", invite_code)

    patient = db_session.query(models.User).filter(models.User.email == "newpatient@example.com").first()
    assert patient.invite_code_expires_at is not None
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd backend && python3 -m pytest tests/test_auth_router.py::test_invite_patient_sends_code_via_email -v`
Expected: FAIL — `AttributeError` or similar, since `patients.py` doesn't import or call `EmailService` yet.

- [ ] **Step 3: Wire the invite endpoint to send email and set expiry**

In `backend/app/routers/patients.py`, update the imports (currently lines 1-11) from:
```python
import csv
import io
import secrets
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Query, Response
from sqlalchemy.orm import Session

from app import models, schemas
from app.dependencies import get_current_user, get_db_for_user, require_clinician
from app.security import hash_password
```
to:
```python
import csv
import io
import secrets
from datetime import datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException, Query, Response
from sqlalchemy.orm import Session

from app import models, schemas
from app.dependencies import get_current_user, get_db_for_user, require_clinician
from app.security import hash_password
from app.services.email_service import EmailService
```

Replace `invite_patient` (currently lines 20–59) from:
```python
@router.post("/invite", response_model=schemas.PatientInviteResponse)
def invite_patient(
    req: schemas.PatientInviteRequest,
    db: Session = Depends(get_db_for_user),
    current_user: models.User = Depends(require_clinician),
):
    existing_user = db.query(models.User).filter(models.User.email == req.email).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="User with this email already exists")

    invite_code = f"{secrets.randbelow(900000) + 100000}"

    patient = models.User(
        email=req.email,
        full_name=req.full_name,
        role=models.UserRole.patient,
        status="pending_onboarding",
        invite_code=invite_code,
    )
    db.add(patient)
    db.commit()
    db.refresh(patient)
```
to:
```python
@router.post("/invite", response_model=schemas.PatientInviteResponse)
def invite_patient(
    req: schemas.PatientInviteRequest,
    db: Session = Depends(get_db_for_user),
    current_user: models.User = Depends(require_clinician),
):
    existing_user = db.query(models.User).filter(models.User.email == req.email).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="User with this email already exists")

    invite_code = f"{secrets.randbelow(900000) + 100000}"

    patient = models.User(
        email=req.email,
        full_name=req.full_name,
        role=models.UserRole.patient,
        status="pending_onboarding",
        invite_code=invite_code,
        invite_code_expires_at=datetime.utcnow() + timedelta(minutes=15),
    )
    db.add(patient)
    db.commit()
    db.refresh(patient)

    EmailService().send_patient_code(patient.email, invite_code)
```
(The rest of the function — creating the `Case` and returning `PatientInviteResponse` — is unchanged.)

- [ ] **Step 4: Run test to verify it passes**

Run: `cd backend && python3 -m pytest tests/test_auth_router.py -v`
Expected: PASS (all tests in the file, including the new one)

- [ ] **Step 5: Run the full backend suite**

Run: `cd backend && python3 -m pytest tests -q`
Expected: all pass.

- [ ] **Step 6: Commit**

```bash
git add backend/app/routers/patients.py backend/tests/test_auth_router.py
git commit -m "feat(backend): email the invite code to the patient immediately

Previously the clinician was the only one who saw the code and had to
relay it manually. The web UI still displays it too, as a fallback
channel if email delivery is delayed."
```

---

### Task 8: Backend — passwordless demo patient in seed data

**Files:**
- Modify: `backend/app/scripts/seed_data.py:1-59`

**Interfaces:** None new — this only changes seeded data values.

**Note:** `backend/tests/test_seed.py` does **not** test this file — it tests a separate, unrelated module (`backend/app/scripts/seed.py`, a simpler admin/clinician/patient fixture-seeder used only by pytest, with its own `patient@remotecarepro.dev` / `patient1234` test user). That module is out of scope for this plan: it's a test-only DB fixture utility, not part of the product's auth flow or the demo walkthrough, and touching it risks unrelated test breakage for no benefit. `seed_data.py` (the file this task modifies) has no existing automated test — it's verified by actually running it, per Step 2 below.

- [ ] **Step 1: Update the seed script**

In `backend/app/scripts/seed_data.py`, change the imports (currently lines 1-10) from:
```python
import sys
from pathlib import Path

# Ensure backend root is in sys.path when script is executed directly
sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from app import models
from app.database import SessionLocal, engine
from app.models import Base
from app.security import hash_password
```
to:
```python
import sys
from datetime import datetime, timedelta
from pathlib import Path

# Ensure backend root is in sys.path when script is executed directly
sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from app import models
from app.database import SessionLocal, engine
from app.models import Base
from app.security import hash_password

DEMO_PATIENT_CODE = "424242"
```

Replace the patient-seeding block (currently lines 38-59) from:
```python
        # Check or create Patient
        patient = (
            db.query(models.User)
            .filter(models.User.email == "patient@example.com")
            .first()
        )
        if not patient:
            patient = models.User(
                email="patient@example.com",
                full_name="Sarah Mitchell",
                role=models.UserRole.patient,
                password_hash=hash_password("password123"),
                status="active",
                phone="+1 555-0199",
                date_of_birth="1988-04-12",
            )
            db.add(patient)
            db.commit()
            db.refresh(patient)
            print("Seeded patient: patient@example.com")
        else:
            print("Patient patient@example.com already exists.")
```
to:
```python
        # Check or create Patient
        patient = (
            db.query(models.User)
            .filter(models.User.email == "patient@example.com")
            .first()
        )
        if not patient:
            patient = models.User(
                email="patient@example.com",
                full_name="Sarah Mitchell",
                role=models.UserRole.patient,
                status="active",
                phone="+1 555-0199",
                date_of_birth="1988-04-12",
                invite_code=DEMO_PATIENT_CODE,
                invite_code_expires_at=datetime.utcnow() + timedelta(days=365),
            )
            db.add(patient)
            db.commit()
            db.refresh(patient)
            print(f"Seeded patient: patient@example.com (sign-in code: {DEMO_PATIENT_CODE})")
        else:
            print("Patient patient@example.com already exists.")
```
(The clinician block above it, which still uses `hash_password`, is unchanged — `hash_password` stays imported and used for the clinician.)

- [ ] **Step 2: Verify by actually running the script against the dev DB**

Run:
```bash
docker-compose up -d backend
docker-compose exec backend python app/scripts/seed_data.py
docker-compose exec db psql -U caredev -d remotecare -c \
  "SELECT email, password_hash, invite_code, invite_code_expires_at FROM users WHERE email = 'patient@example.com';"
```
Expected: the script prints `Seeded patient: patient@example.com (sign-in code: 424242)` (or `Patient patient@example.com already exists.` if re-run against an already-seeded DB — in that case, drop the row first or point at a fresh DB volume to see the create path), and the `psql` query shows `password_hash` as `NULL`, `invite_code` as `424242`, and a non-null future `invite_code_expires_at`.

- [ ] **Step 3: Run the full backend suite to check for regressions**

Run: `cd backend && python3 -m pytest tests -q`
Expected: all pass — `test_seed.py` is unaffected since it exercises the separate `seed.py` module, not this file.

- [ ] **Step 4: Commit**

```bash
git add backend/app/scripts/seed_data.py
git commit -m "feat(backend): seed demo patient with a fixed sign-in code

Patients no longer have passwords. The demo patient gets a long-lived
fixed code (424242) documented in the README, so the golden-loop demo
doesn't require reading backend logs to find a code."
```

---

### Task 9: Mobile — AuthNotifier request-code / verify-code

**Files:**
- Modify: `mobile/lib/core/providers/app_providers.dart:1-207`
- Test: `mobile/test/unit/auth_notifier_provider_test.dart` (new file — note this replaces the deleted `auth_provider_test.dart` from Task 3, which tested the dead notifier; this new file tests the real one)

**Interfaces:**
- Consumes: `ApiService.post`/`get`/`setToken` (unchanged, `mobile/lib/core/network/api_service.dart`).
- Produces:
  - `AuthNotifier.requestCode({required String email}) -> Future<bool>`
  - `AuthNotifier.verifyCode({required String email, required String code}) -> Future<String?>` (returns `'onboarding'`, `'authenticated'`, or `null` on failure)
  - `AuthNotifier.completeOnboarding({required String email, required String inviteCode, required String dateOfBirth, required String phone}) -> Future<bool>` (password param removed)
  - `AuthNotifier.setSignUpInfo({required String fullName, required String email, required String phone}) -> void` (password param removed)
  - `AuthNotifier.signIn` and `AuthNotifier.verifyInvite` are **removed** — consumed by Task 10/11's screens, which must stop calling them.

- [ ] **Step 1: Write the failing tests**

Create `mobile/test/unit/auth_notifier_provider_test.dart`:
```dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:remotecare/core/network/api_service.dart';
import 'package:remotecare/core/providers/app_providers.dart';

import 'fake_api_service.dart';

void main() {
  late FakeApiService fakeApi;
  late ProviderContainer container;

  setUp(() {
    fakeApi = FakeApiService();
    container = ProviderContainer(
      overrides: [apiServiceProvider.overrideWithValue(fakeApi)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('requestCode success returns true and stores email', () async {
    fakeApi.postHandlers['/auth/patient/request-code'] = (body) {
      return http.Response(jsonEncode({'message': 'If that email exists, a code was sent.'}), 200);
    };

    final auth = container.read(authProvider);
    final success = await auth.requestCode(email: 'jane@example.com');

    expect(success, true);
    expect(auth.email, 'jane@example.com');
  });

  test('verifyCode for a new patient returns onboarding and stores profile fields', () async {
    fakeApi.postHandlers['/auth/patient/verify-code'] = (body) {
      return http.Response(
        jsonEncode({'result': 'onboarding', 'email': 'jane@example.com', 'full_name': 'Jane Doe'}),
        200,
      );
    };

    final auth = container.read(authProvider);
    final result = await auth.verifyCode(email: 'jane@example.com', code: '123456');

    expect(result, 'onboarding');
    expect(auth.fullName, 'Jane Doe');
    expect(auth.inviteCode, '123456');
  });

  test('verifyCode for a returning patient returns authenticated and stores token', () async {
    fakeApi.postHandlers['/auth/patient/verify-code'] = (body) {
      return http.Response(jsonEncode({'result': 'authenticated', 'access_token': 'jwt_1'}), 200);
    };
    fakeApi.getHandlers['/auth/me'] = () {
      return http.Response(jsonEncode({'id': 'user_1', 'email': 'jane@example.com', 'full_name': 'Jane Doe'}), 200);
    };
    fakeApi.getHandlers['/patients/user_1/case'] = () {
      return http.Response(jsonEncode({'id': 'case_1', 'surgery_type': 'Knee Replacement'}), 200);
    };

    final auth = container.read(authProvider);
    final result = await auth.verifyCode(email: 'jane@example.com', code: '123456');

    expect(result, 'authenticated');
    expect(fakeApi.savedToken, 'jwt_1');
    expect(auth.isSignedIn, true);
  });

  test('verifyCode with wrong code returns null and sets errorMessage', () async {
    fakeApi.postHandlers['/auth/patient/verify-code'] = (body) {
      return http.Response(jsonEncode({'detail': 'Invalid or expired code'}), 400);
    };

    final auth = container.read(authProvider);
    final result = await auth.verifyCode(email: 'jane@example.com', code: '000000');

    expect(result, null);
    expect(auth.errorMessage, 'Invalid or expired code');
  });

  test('completeOnboarding no longer sends a password field', () async {
    fakeApi.postHandlers['/auth/complete-onboarding'] = (body) {
      expect(body?.containsKey('password'), false);
      return http.Response(jsonEncode({'access_token': 'jwt_2'}), 200);
    };
    fakeApi.getHandlers['/auth/me'] = () {
      return http.Response(jsonEncode({'id': 'user_2', 'email': 'jane@example.com', 'full_name': 'Jane Doe'}), 200);
    };
    fakeApi.getHandlers['/patients/user_2/case'] = () {
      return http.Response(jsonEncode({'id': 'case_2', 'surgery_type': 'Knee Replacement'}), 200);
    };

    final auth = container.read(authProvider);
    final success = await auth.completeOnboarding(
      email: 'jane@example.com',
      inviteCode: '123456',
      dateOfBirth: '1990-01-01',
      phone: '1234567890',
    );

    expect(success, true);
    expect(fakeApi.savedToken, 'jwt_2');
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd mobile && flutter test test/unit/auth_notifier_provider_test.dart`
Expected: FAIL — `requestCode`/`verifyCode` don't exist yet on `AuthNotifier`.

- [ ] **Step 3: Update `AuthNotifier` in `app_providers.dart`**

Remove the `_tempPassword` field and its getter (currently lines 28, 41):
```dart
  String? _tempPassword;
```
```dart
  String? get tempPassword => _tempPassword;
```

Replace `signIn` (currently lines 81–107) with:
```dart
  Future<bool> requestCode({required String email}) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final res = await _api.post('/auth/patient/request-code', {'email': email});
      if (res.statusCode == 200) {
        _email = email;
        return true;
      } else {
        final err = jsonDecode(res.body);
        _errorMessage = err['detail'] ?? 'Failed to send code';
      }
    } catch (e) {
      _errorMessage = 'Network error: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
    return false;
  }
```

Replace `verifyInvite` (currently lines 109–138) with:
```dart
  /// Returns 'onboarding', 'authenticated', or null on failure (see [errorMessage]).
  Future<String?> verifyCode({required String email, required String code}) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final res = await _api.post('/auth/patient/verify-code', {
        'email': email,
        'code': code,
      });

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final result = data['result'] as String;
        if (result == 'authenticated') {
          final token = data['access_token'];
          await _api.setToken(token);
          await fetchProfile();
        } else {
          _email = data['email'];
          _fullName = data['full_name'];
          _inviteCode = code;
        }
        return result;
      } else {
        final err = jsonDecode(res.body);
        _errorMessage = err['detail'] ?? 'Invalid or expired code';
      }
    } catch (e) {
      _errorMessage = 'Network error: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
    return null;
  }
```

Replace `completeOnboarding` (currently lines 140–175) with:
```dart
  Future<bool> completeOnboarding({
    required String email,
    required String inviteCode,
    required String dateOfBirth,
    required String phone,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final res = await _api.post('/auth/complete-onboarding', {
        'email': email,
        'invite_code': inviteCode,
        'date_of_birth': dateOfBirth,
        'phone': phone,
      });

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final token = data['access_token'];
        await _api.setToken(token);
        await fetchProfile();
        _setLoading(false);
        return true;
      } else {
        final err = jsonDecode(res.body);
        _errorMessage = err['detail'] ?? 'Failed to complete onboarding';
      }
    } catch (e) {
      _errorMessage = 'Network error: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
    return false;
  }
```

Replace `setSignUpInfo` (currently lines 177–187) with:
```dart
  void setSignUpInfo({
    required String fullName,
    required String email,
    required String phone,
  }) {
    _fullName = fullName;
    _email = email;
    _phone = phone;
  }
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd mobile && flutter test test/unit/auth_notifier_provider_test.dart`
Expected: PASS (5 tests)

- [ ] **Step 5: Run `flutter analyze`**

Run: `cd mobile && flutter analyze`
Expected: errors in `login_screen.dart`, `signup_step1_screen.dart`, `signup_step2_screen.dart`, `signup_step3_screen.dart` — these call the now-removed `signIn`/`verifyInvite` methods and the old `setSignUpInfo`/`completeOnboarding` signatures. This is expected at this point in the plan; Tasks 10 and 11 fix them next. Confirm the errors are only in those four files (not e.g. in `app_providers.dart` itself).

- [ ] **Step 6: Commit**

```bash
git add mobile/lib/core/providers/app_providers.dart mobile/test/unit/auth_notifier_provider_test.dart
git commit -m "feat(mobile): replace password signIn/verifyInvite with request/verify code

AuthNotifier now exposes requestCode() and verifyCode(), backing a
single emailed-code auth flow for both first-time onboarding and
returning-patient sign-in. Screen call sites are updated in the next
two commits — flutter analyze will show expected breakage until then."
```

---

### Task 10: Mobile — merge login and invite-code screens

**Files:**
- Modify: `mobile/lib/features/auth/login_screen.dart` (full rewrite of the state/build logic)
- Delete: `mobile/lib/features/auth/signup_step1_screen.dart`, `mobile/lib/features/auth/forgot_password_screen.dart`
- Modify: `mobile/lib/core/navigation/app_routes.dart` (remove `signupStep1` and `forgotPassword` routes)
- Modify: `mobile/lib/features/auth/onboarding_screen.dart` (both CTAs route to `AppRoutes.login`)
- Modify: `mobile/lib/core/constants/app_strings.dart` (remove `orSignInWith`, `passwordHint`, `forgotPassword`, `cognitoSecurityPrefix`, `cognitoSecurityBold`, `cognitoSecuritySuffix` — all now unused; `password`/`passwordMinHint` are still used by `signup_step2_screen.dart` until Task 11)
- Test: `mobile/test/widget/login_screen_test.dart` (new file)

**Interfaces:**
- Consumes: `AuthNotifier.requestCode`/`verifyCode` (Task 9).
- Produces: `AppRoutes.login` now leads to the merged email→code screen; `AppRoutes.signupStep2` is entered directly from it when `verifyCode` returns `'onboarding'`.

- [ ] **Step 1: Write the failing widget test**

Create `mobile/test/widget/login_screen_test.dart`:
```dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:remotecare/core/constants/app_strings.dart';
import 'package:remotecare/core/network/api_service.dart';
import 'package:remotecare/features/auth/login_screen.dart';

import '../unit/fake_api_service.dart';

Widget _buildMaterialApp(BuildContext context, Widget? child) {
  return const MaterialApp(home: LoginScreen());
}

Widget buildTestApp(FakeApiService fakeApi) {
  return ProviderScope(
    overrides: [apiServiceProvider.overrideWithValue(fakeApi)],
    child: const ScreenUtilInit(
      designSize: Size(375, 812),
      minTextAdapt: true,
      builder: _buildMaterialApp,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('email stage has no password field, sending a code moves to the code stage', (tester) async {
    final fakeApi = FakeApiService();
    fakeApi.postHandlers['/auth/patient/request-code'] = (body) {
      return http.Response(jsonEncode({'message': 'sent'}), 200);
    };

    await tester.pumpWidget(buildTestApp(fakeApi));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.password), findsNothing);

    await tester.enterText(find.byType(TextFormField).first, 'jane@example.com');
    await tester.tap(find.text(AppStrings.signIn));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.verifyEmail), findsOneWidget);
    expect(fakeApi.requestsLog.first['path'], '/auth/patient/request-code');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd mobile && flutter test test/widget/login_screen_test.dart`
Expected: FAIL — `login_screen.dart` doesn't compile yet against the new `AuthNotifier` API (from Task 9, Step 5's known breakage).

- [ ] **Step 3: Rewrite `login_screen.dart`**

Replace the entire file with:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_strings.dart';
import '../../core/providers/app_providers.dart';
import '../../core/shared_widgets/app_text_field.dart';
import '../../core/shared_widgets/app_button.dart';
import '../../core/navigation/app_routes.dart';

enum _AuthStage { email, code }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  _AuthStage _stage = _AuthStage.email;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleSendCode() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = ref.read(authProvider);
    final success = await auth.requestCode(email: _emailController.text.trim());

    if (success && mounted) {
      setState(() => _stage = _AuthStage.code);
    } else if (mounted && auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.errorMessage!)));
    }
  }

  Future<void> _handleVerifyCode() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = ref.read(authProvider);
    final result = await auth.verifyCode(
      email: _emailController.text.trim(),
      code: _codeController.text.trim(),
    );

    if (!mounted) return;
    if (result == 'authenticated') {
      AppRoutes.navigateAndClearStack(context, AppRoutes.main);
    } else if (result == 'onboarding') {
      AppRoutes.navigateTo(context, AppRoutes.signupStep2);
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isEmailStage = _stage == _AuthStage.email;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingH),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: AppSpacing.lg),

                GestureDetector(
                  onTap: () => Navigator.maybePop(context),
                  child: Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: const BoxDecoration(
                      color: AppColors.inputFill,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_back,
                      color: AppColors.black,
                      size: AppSpacing.iconMd,
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.xxl),

                Text(
                  isEmailStage ? AppStrings.welcomeBack : AppStrings.verifyEmail,
                  style: AppTextStyles.heading1,
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  isEmailStage ? AppStrings.signInSubtitle : AppStrings.verificationSent,
                  style: AppTextStyles.subtitle,
                ),
                SizedBox(height: AppSpacing.xxl),

                if (isEmailStage)
                  AppTextField(
                    label: AppStrings.email,
                    hintText: AppStrings.emailHint,
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    controller: _emailController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  )
                else ...[
                  AppTextField(
                    label: AppStrings.enterCode,
                    hintText: '000000',
                    prefixIcon: Icons.vpn_key_outlined,
                    keyboardType: TextInputType.number,
                    controller: _codeController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your code';
                      }
                      if (value.trim().length < 6) {
                        return 'Code must be 6 digits';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _handleSendCode,
                      child: Text(
                        AppStrings.resendCode,
                        style: AppTextStyles.linkText.copyWith(decoration: TextDecoration.none),
                      ),
                    ),
                  ),
                ],
                SizedBox(height: AppSpacing.xl),

                AppButton(
                  text: isEmailStage ? AppStrings.signIn : AppStrings.verifyAndContinue,
                  isLoading: auth.isLoading,
                  onPressed: isEmailStage ? _handleSendCode : _handleVerifyCode,
                ),
                SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Delete the now-redundant screens**

Run:
```bash
git rm mobile/lib/features/auth/signup_step1_screen.dart
git rm mobile/lib/features/auth/forgot_password_screen.dart
```

- [ ] **Step 5: Update `app_routes.dart`**

Remove the imports (lines 4, 7):
```dart
import '../../features/auth/signup_step1_screen.dart';
```
```dart
import '../../features/auth/forgot_password_screen.dart';
```

Remove the route constants (lines 16, 19):
```dart
  static const String signupStep1 = '/signup/step1';
```
```dart
  static const String forgotPassword = '/forgot-password';
```

Remove the switch cases (currently):
```dart
      case signupStep1:
        return _buildRoute(const SignupStep1Screen(), settings);
```
```dart
      case forgotPassword:
        return _buildRoute(const ForgotPasswordScreen(), settings);
```

- [ ] **Step 6: Update `onboarding_screen.dart`**

Change the "Sign In" button's route (it already points to `AppRoutes.login` — no change needed there).

Change the "Create account" button from:
```dart
                    AppButton(
                      text: AppStrings.createAccount,
                      isOutlined: true,
                      onPressed: () =>
                          AppRoutes.navigateTo(context, AppRoutes.signupStep1),
                    ),
```
to:
```dart
                    AppButton(
                      text: AppStrings.createAccount,
                      isOutlined: true,
                      onPressed: () =>
                          AppRoutes.navigateTo(context, AppRoutes.login),
                    ),
```

- [ ] **Step 7: Remove now-unused strings from `app_strings.dart`**

Remove these lines (the merged screen and its removed siblings no longer reference them; `password`/`passwordMinHint` are left in place — `signup_step2_screen.dart` still uses them until Task 11):
```dart
  static const String forgotPassword = 'Forgot password?';
```
```dart
  static const String orSignInWith = 'or sign in with';
```
```dart
  static const String passwordHint = 'Enter your password';
```
```dart
  static const String cognitoSecurityPrefix =
      'Authentication secured by ';
  static const String cognitoSecurityBold = 'Secure Clinic Account';
  static const String cognitoSecuritySuffix =
      ', your credentials never touch our servers.';
```

- [ ] **Step 8: Run test to verify it passes**

Run: `cd mobile && flutter test test/widget/login_screen_test.dart`
Expected: PASS

- [ ] **Step 9: Run `flutter analyze`**

Run: `cd mobile && flutter analyze`
Expected: remaining errors only in `signup_step2_screen.dart` and `signup_step3_screen.dart` (fixed in Task 11) and the `golden_loop_test.dart` reference to the old 2-password-field login flow (fixed in Task 12).

- [ ] **Step 10: Commit**

```bash
git add mobile/lib/features/auth/login_screen.dart \
        mobile/lib/core/navigation/app_routes.dart \
        mobile/lib/features/auth/onboarding_screen.dart \
        mobile/lib/core/constants/app_strings.dart \
        mobile/test/widget/login_screen_test.dart
git commit -m "feat(mobile): merge login and invite-code screens into one email->code flow

Both onboarding CTAs now lead to a single screen: enter email, get a
code, enter it. The backend response determines whether this is a
first-time onboarding (-> DOB/phone step) or a returning sign-in
(-> straight into the app). Removes the password field, the dead
forgot-password stub, and the now-redundant separate invite-code
screen."
```

---

### Task 11: Mobile — drop password from onboarding steps 2 and 3

**Files:**
- Modify: `mobile/lib/features/auth/signup_step2_screen.dart`
- Modify: `mobile/lib/features/auth/signup_step3_screen.dart:69-76`
- Modify: `mobile/lib/core/constants/app_strings.dart` (remove `password`, `passwordMinHint`)
- Test: `mobile/test/widget/signup_step2_screen_test.dart` (new file)

**Interfaces:**
- Consumes: `AuthNotifier.setSignUpInfo({fullName, email, phone})` and `AuthNotifier.completeOnboarding({email, inviteCode, dateOfBirth, phone})` (both from Task 9).

- [ ] **Step 1: Write the failing widget test**

Create `mobile/test/widget/signup_step2_screen_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remotecare/core/constants/app_strings.dart';
import 'package:remotecare/core/network/api_service.dart';
import 'package:remotecare/features/auth/signup_step2_screen.dart';

import '../unit/fake_api_service.dart';

Widget _buildMaterialApp(BuildContext context, Widget? child) {
  return const MaterialApp(home: SignupStep2Screen());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('signup step 2 has no password field', (tester) async {
    final fakeApi = FakeApiService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiServiceProvider.overrideWithValue(fakeApi)],
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          builder: _buildMaterialApp,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.password), findsNothing);
    expect(find.byType(TextFormField), findsOneWidget); // phone only
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd mobile && flutter test test/widget/signup_step2_screen_test.dart`
Expected: FAIL — the screen still renders a password field (2 `TextFormField`s), and `flutter analyze` already flags `signup_step2_screen.dart` as broken against the new `AuthNotifier` API from Task 9.

- [ ] **Step 3: Update `signup_step2_screen.dart`**

Remove the password controller (currently lines 22, 27):
```dart
  final _passwordController = TextEditingController();
```
```dart
    _passwordController.dispose();
```

Replace `_handleContinue` (currently lines 31-43) from:
```dart
  void _handleContinue() {
    if (!_formKey.currentState!.validate()) return;

    final auth = ref.read(authProvider);
    auth.setSignUpInfo(
      fullName: auth.fullName ?? '',
      email: auth.email ?? '',
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
    );

    AppRoutes.navigateTo(context, AppRoutes.signupStep3);
  }
```
to:
```dart
  void _handleContinue() {
    if (!_formKey.currentState!.validate()) return;

    final auth = ref.read(authProvider);
    auth.setSignUpInfo(
      fullName: auth.fullName ?? '',
      email: auth.email ?? '',
      phone: _phoneController.text.trim(),
    );

    AppRoutes.navigateTo(context, AppRoutes.signupStep3);
  }
```

Remove the password field from the build method (currently lines 82-97):
```dart
                AppTextField(
                  label: AppStrings.password,
                  hintText: AppStrings.passwordMinHint,
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  controller: _passwordController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppSpacing.xxxl),
```
Replace with just:
```dart
                SizedBox(height: AppSpacing.xxxl),
```
(One `SizedBox(height: AppSpacing.xl)` already sits directly above the removed block, after the phone field — leave that one in place.)

- [ ] **Step 4: Update `signup_step3_screen.dart`**

Replace `_handleComplete`'s call to `completeOnboarding` (currently lines 69-76) from:
```dart
    final auth = ref.read(authProvider);
    final success = await auth.completeOnboarding(
      email: auth.email ?? '',
      inviteCode: auth.inviteCode ?? '',
      password: auth.tempPassword ?? 'password123',
      dateOfBirth: _formattedIsoDate,
      phone: auth.phone ?? '',
    );
```
to:
```dart
    final auth = ref.read(authProvider);
    final success = await auth.completeOnboarding(
      email: auth.email ?? '',
      inviteCode: auth.inviteCode ?? '',
      dateOfBirth: _formattedIsoDate,
      phone: auth.phone ?? '',
    );
```

- [ ] **Step 5: Remove now-unused strings from `app_strings.dart`**

Remove:
```dart
  static const String password = 'PASSWORD';
```
```dart
  static const String passwordMinHint = 'Min. 8 characters';
```

- [ ] **Step 6: Run test to verify it passes**

Run: `cd mobile && flutter test test/widget/signup_step2_screen_test.dart`
Expected: PASS

- [ ] **Step 7: Run `flutter analyze` and the full mobile unit/widget suite**

Run: `cd mobile && flutter analyze`
Expected: 0 issues (all four previously-broken screens are now fixed; `golden_loop_test.dart` is a separate `integration_test/` target not covered by `flutter analyze`'s default lib+test scan — verify it separately in Task 12).

Run: `cd mobile && flutter test`
Expected: all pass.

- [ ] **Step 8: Commit**

```bash
git add mobile/lib/features/auth/signup_step2_screen.dart \
        mobile/lib/features/auth/signup_step3_screen.dart \
        mobile/lib/core/constants/app_strings.dart \
        mobile/test/widget/signup_step2_screen_test.dart
git commit -m "feat(mobile): drop password field from onboarding steps 2-3

Onboarding now only collects phone (step 2) and date of birth (step
3) — no password is ever created for a patient."
```

---

### Task 12: Mobile — update the golden-loop integration test

**Files:**
- Modify: `mobile/integration_test/golden_loop_test.dart:44-56`

**Interfaces:**
- Consumes: the merged `login_screen.dart` (Task 10) and the seeded demo patient's fixed code `"424242"` (Task 8, backend-side — requires the backend to be running with fresh seed data for this test to pass live).

- [ ] **Step 1: Update the login section of the test**

Replace (currently lines 45-56):
```dart
      // --- Onboarding -> Login ---
      await tester.tap(find.text(AppStrings.signInToAccount));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      expect(textFields, findsNWidgets(2));
      await tester.enterText(textFields.at(0), 'patient@example.com');
      await tester.enterText(textFields.at(1), 'password123');
      await tester.tap(find.text(AppStrings.signIn));

      // Real network round trip: POST /auth/login, GET /auth/me, GET /patients/{id}/case.
      await pumpUntilFound(tester, find.text(AppStrings.taken));
      await tester.pumpAndSettle();
```
with:
```dart
      // --- Onboarding -> Sign in with the seeded patient's demo code ---
      await tester.tap(find.text(AppStrings.signInToAccount));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'patient@example.com');
      await tester.tap(find.text(AppStrings.signIn));
      await tester.pumpAndSettle();

      // Real network round trip: POST /auth/patient/request-code.
      await pumpUntilFound(tester, find.text(AppStrings.verifyEmail));
      await tester.enterText(find.byType(TextFormField).first, '424242');
      await tester.tap(find.text(AppStrings.verifyAndContinue));

      // Real network round trip: POST /auth/patient/verify-code, GET /auth/me, GET /patients/{id}/case.
      await pumpUntilFound(tester, find.text(AppStrings.taken));
      await tester.pumpAndSettle();
```

- [ ] **Step 2: Update the file-level doc comment**

Update the comment at the top (currently lines 1-15) to describe the new login step; change:
```
// Live-backend integration test for the mobile "golden loop":
// patient login -> Assistant (in-scope reply + language-agnostic guardrail
```
to:
```
// Live-backend integration test for the mobile "golden loop":
// patient sign-in via emailed code -> Assistant (in-scope reply + language-agnostic guardrail
```
and add, after the existing `Requires the real FastAPI backend...` sentence:
```
// Signs in with the seeded demo patient's fixed, long-lived code
// (424242, set in seed_data.py) rather than a password — patients no
// longer have passwords.
```

- [ ] **Step 3: Verify against a live backend (manual — requires the full stack)**

This test cannot be verified by static analysis alone since it drives a real simulator against a real backend. Follow the existing project convention:
```bash
docker-compose up backend
docker-compose exec backend python app/scripts/seed_data.py
cd mobile && flutter test integration_test/golden_loop_test.dart
```
Expected: `EXIT_CODE=0`, `All tests passed!` — confirm the run reaches the "Today" screen with `AppStrings.taken` visible, same as the test's prior passing runs, now via the code flow instead of password.

- [ ] **Step 4: Commit**

```bash
git add mobile/integration_test/golden_loop_test.dart
git commit -m "test(mobile): update golden-loop test for email+code sign-in

Drives the new merged login screen with the seeded demo patient's
fixed code instead of a password."
```

---

### Task 13: Web — note that the code was emailed

**Files:**
- Modify: `web/src/pages/CreatePatientPage.tsx:47-57`

**Interfaces:** None — purely a copy change, no schema or API change.

- [ ] **Step 1: Update the confirmation copy**

Replace (currently lines 47-57):
```tsx
  if (inviteCode) {
    return (
      <div style={styles.container}>
        <div style={styles.card}>
          <h1 style={styles.title}>Patient Invited ✓</h1>
          <p style={styles.subtitle}>Patient invitation generated for {fullName}.</p>
          <div style={styles.inviteBox}>
            <p style={styles.inviteLabel}>6-Digit Invite Code:</p>
            <p style={styles.inviteCode}>{inviteCode}</p>
            <p style={styles.inviteSubtext}>Provide this code to the patient to complete onboarding in the mobile app.</p>
          </div>
```
with:
```tsx
  if (inviteCode) {
    return (
      <div style={styles.container}>
        <div style={styles.card}>
          <h1 style={styles.title}>Patient Invited ✓</h1>
          <p style={styles.subtitle}>An email with a sign-in code was sent to {email}.</p>
          <div style={styles.inviteBox}>
            <p style={styles.inviteLabel}>Sign-In Code (backup, in case the email doesn't arrive):</p>
            <p style={styles.inviteCode}>{inviteCode}</p>
            <p style={styles.inviteSubtext}>The patient can enter this code directly in the mobile app if needed.</p>
          </div>
```

- [ ] **Step 2: Verify the web app still builds**

Run: `cd web && npm run build && npm run lint`
Expected: both pass with no new errors.

- [ ] **Step 3: Commit**

```bash
git add web/src/pages/CreatePatientPage.tsx
git commit -m "docs(web): clarify that the patient's sign-in code is emailed

The code is now the primary auth mechanism for patients (backend
sends it automatically); the web UI's display of it is a fallback,
not the only channel."
```

---

### Task 14: Docs — root README restructure

**Files:**
- Modify: `README.md` (full restructure of the quick-start, testing, and demo-walkthrough sections)

**Interfaces:** None — documentation only.

- [ ] **Step 1: Replace the "Full Demo" and "Frontend-Only Quick Start" sections**

Replace everything from the `## Full Demo — Clinician + Patient, End to End` heading through the end of the `## Frontend-Only Quick Start (no backend, mocked API)` section (currently lines 14-92) with:
```markdown
## Running the Stack Locally

The backend (+ Postgres) is required for almost everything below — there is no mock server anymore. Pick the row that matches what you're doing:

| Goal | What you need running |
|------|------------------------|
| Work on the web app | Backend + web |
| Work on the mobile app | Backend + seeded DB + mobile |
| Backend unit tests only | Nothing else — `pytest` is self-contained |
| Mobile unit/widget tests only | Nothing else — uses a fake API client, no backend |
| Mobile integration/e2e test | Backend + seeded DB + a booted simulator |

### 1. Clone and configure

```bash
git clone https://github.com/FlaviusBurghilaOPIT/uep2026.git
cd uep2026
cp .env.example .env
```

### 2. Start Postgres + the backend

```bash
docker-compose up backend
```

This also starts the `db` service (Postgres) as a dependency. Leave it running in this terminal. Verify it's up at `http://localhost:8000/docs`.

### 3. Seed demo data (new terminal tab)

```bash
docker-compose exec backend python app/scripts/seed_data.py
```

Creates the database tables from the current models and seeds a demo clinician + patient (see credentials below). Safe to re-run — it skips users that already exist. It does **not** run Alembic migrations; for a fresh container this is fine since it creates tables straight from the current SQLAlchemy models. If you're upgrading an existing, already-seeded database instead of starting fresh, run `docker-compose exec backend alembic upgrade head` first.

### 4. Start the web app (only if you're working on the clinician dashboard)

```bash
cd web
npm install
npm run dev
```

Open `http://localhost:5173`. The web app talks to the real backend at `http://localhost:8000` by default — no extra config needed.

### 5. Start the mobile app (only if you're working on the patient app)

```bash
cd mobile
flutter pub get
flutter run -d android   # or: flutter run -d iphonesimulator
```

The app resolves the backend URL automatically per platform. See **[mobile/README.md](mobile/README.md)** for simulator setup, device IDs, and `--dart-define` overrides for pointing at a remote demo backend.

### Demo credentials

| Role | Email | How to sign in |
|---|---|---|
| Clinician | `clinician@example.com` | Password: `password123` |
| Patient (already onboarded) | `patient@example.com` | Sign-in code: `424242` (fixed, long-lived, seeded by `seed_data.py`) |

Patients don't have passwords — sign-in is always an emailed one-time code. In real deployments the code is emailed via SES; locally (no `AWS_REGION` set), the code is logged to the backend's console output instead, so you can always find it there too, in addition to the fixed demo code above.

### Demo walkthrough (the golden loop)

1. **Web** — log in as the clinician at `http://localhost:5173/login`.
2. **Web** — `Patients` → `+ New Patient`, invite a new patient. A sign-in code is emailed to them immediately (or logged to the backend console in local dev) and also shown on screen as a backup.
3. **Web** — `+ New Case` for the invited patient, then prescribe 1–2 medications from the case's `Medications` screen.
4. **Mobile** — on the onboarding screen, tap **Sign In** (or **Create account** — both lead to the same flow), enter the patient's email, tap to send a code, then enter it. First-time patients continue to a short profile step (phone, date of birth); returning patients go straight in.
5. **Mobile** — land on `Today`, log a dose as `Taken`/`Skipped`.
6. **Mobile** — open `Assistant` and ask an in-scope question (e.g. "when should I take my medication?") to see a real AI reply, or an out-of-scope one (e.g. "can I take a double dose?") to see the safety guardrail refuse it.
7. **Web** — back on `Patients`, open the patient's case to see the prescribed medications and (once logged) the recorded dose.

Note: a dedicated clinician "Needs Attention" triage view (surfacing missed doses / AI escalations without opening each patient) is planned but not yet built — see [Project Status](#project-status) below. Today's web demo shows the roster and per-patient case detail.

---
```

- [ ] **Step 2: Replace the Testing section**

Replace the `## Testing` section (currently lines 103-116) with:
```markdown
## Testing

Two tiers per platform — unit/widget tests need nothing but the language toolchain; integration/e2e tests need the full stack running.

| Platform | Unit / Widget (no backend needed) | Integration / E2E (needs the full stack) |
|----------|-------------------------------------|-------------------------------------------|
| Backend | `cd backend && python3 -m pytest tests -q` — in-memory SQLite, no Docker/Postgres, LLM/SNS/email all mocked or dry-run | *(none — the pytest suite already exercises real routes via FastAPI's `TestClient`)* |
| Web | `cd web && npm run build && npm run lint` — no automated tests exist yet (`vitest` is installed but unused) | *(none yet)* |
| Mobile | `cd mobile && flutter test && flutter analyze` — uses a fake API client, no backend needed | `cd mobile && flutter test integration_test/golden_loop_test.dart` — requires: backend running, DB seeded (`seed_data.py`), a booted simulator |
```

- [ ] **Step 3: Consolidate the Android IP reference**

In the mobile-app step (Step 1 of this task already points to `mobile/README.md` for this — no further change needed here beyond confirming the root README no longer repeats the `10.0.2.2` detail itself. Search for it to confirm.)

Run: `rtk grep -n "10.0.2.2" README.md`
Expected: no matches (it was only mentioned once, in the now-replaced mobile step, and that replacement defers to `mobile/README.md`).

- [ ] **Step 4: Verify the README renders sensibly**

Run: `rtk grep -c "^#" README.md`
Expected: a reasonable heading count (roughly the same as before minus the two merged sections) — sanity-check by eye that no heading level is broken (e.g. no stray `##` where `###` was intended).

- [ ] **Step 5: Commit**

```bash
git add README.md
git commit -m "docs: restructure quick start around 'backend is always required'

Removes the now-nonexistent mock-server shortcut, adds a 'what do you
need running' table, separates unit/widget from integration/e2e
testing per platform, and updates the demo walkthrough for the new
passwordless patient sign-in."
```

---

### Task 15: Docs — mobile README

**Files:**
- Modify: `mobile/README.md`

**Interfaces:** None — documentation only.

- [ ] **Step 1: Read the current file in full**

Read `mobile/README.md` before editing, to place the new section consistently with its existing structure and heading levels (it's 7.3K — read it whole, don't guess at placement).

- [ ] **Step 2: Add the integration test section**

Add a new section (placed near the existing "Testing" content — match the file's existing heading level for sibling sections):
```markdown
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
```

- [ ] **Step 3: Consolidate the Android IP / `--dart-define` explanation**

Confirm the existing IP/`--dart-define` explanation (around lines 212-218 per prior research) stays as the single source of truth — no duplicate explanation should be added elsewhere in this file. If the file already explains it clearly in one place, no further edit is needed beyond ensuring the root README (Task 14) links here rather than repeating it.

- [ ] **Step 4: Commit**

```bash
git add mobile/README.md
git commit -m "docs(mobile): document how to run the integration/e2e test

Previously undocumented — only unit/widget tests (flutter test) were
covered. Explains the live-backend prerequisites the integration test
needs that unit tests don't."
```

---

### Task 16: Docs — correct the fabricated web e2e spec

**Files:**
- Modify: `docs/ux/engineering-spec-web-e2e-suite.md`

**Interfaces:** None — documentation only.

- [ ] **Step 1: Read the current file in full**

Read `docs/ux/engineering-spec-web-e2e-suite.md` before editing — it currently claims a "Completed & Verified" status and references `web/src/__tests__/triage_dashboard.test.tsx` and `navbar_i18n.test.tsx`, neither of which exists in the repo (confirmed via `find` during brainstorming research).

- [ ] **Step 2: Rewrite the status and file references**

Change the document's status marker (wherever it says "Completed", "Implemented", or "Verified") to reflect reality: web has **zero** automated tests today. `vitest` and `@testing-library/react` are installed as devDependencies in `web/package.json` but there is no `test` script and no `*.test.*`/`*.spec.*` file anywhere in `web/src`.

Remove every reference to `triage_dashboard.test.tsx` and `navbar_i18n.test.tsx` as existing deliverables. Reframe the document's remaining content (test scenarios, component coverage plans) as a **forward-looking proposal** for if/when the web test suite gets built, not a record of completed work. Retitle the status line at the top of the doc to something like `**Status:** Proposed — not yet implemented` (matching the `**Status:**` field convention used in `docs/superpowers/specs/*.md`).

- [ ] **Step 3: Verify no other doc points to the same fabricated file names**

Run: `rtk grep -rln "triage_dashboard.test.tsx\|navbar_i18n.test.tsx" docs README.md web/README.md mobile/README.md`
Expected: only the file just edited (or no matches, once fixed).

- [ ] **Step 4: Commit**

```bash
git add docs/ux/engineering-spec-web-e2e-suite.md
git commit -m "docs: correct web e2e spec to match reality — no web tests exist yet

The doc previously claimed specific test files were 'Completed &
Verified'; they don't exist in the repo. Reframed as a forward-looking
proposal instead of a false completion record."
```

---

## Plan Self-Review Notes

**Spec coverage:** every section of `docs/superpowers/specs/2026-07-23-dev-stack-and-patient-auth-cleanup-design.md` maps to a task above — mock removal (Task 1), social-login removal (Task 2), backend OTP endpoints + email (Tasks 4-8), mobile OTP flow (Tasks 9-12), web copy (Task 13), and all three doc rewrites (Tasks 14-16).

**Correction from the spec:** the spec's Section 2 said auth copy changes would span "all 5 locale `.arb` files" — research during planning found `AppStrings` (used by every auth screen) is a single non-localized Dart file (`app_strings.dart`), not backed by `.arb` files at all; the `.arb` files hold unrelated strings (e.g. medication frequency labels). Tasks 10-11 edit `app_strings.dart` only, which is what's actually true.

**Discovery folded in beyond the spec's literal text:** Task 3 (deleting the dead `AuthStateNotifier`/`authNotifierProvider` parallel implementation) wasn't in the spec, because the spec was written before this plan's research surfaced it. It's included because leaving it in place would mean this plan ships a live, correct auth system (`AuthNotifier`) alongside a dead, now-doubly-incorrect one (`AuthStateNotifier`, whose own test asserted password-based semantics that no longer exist anywhere else in the app) — confusing for the next person who greps for "auth" in this codebase.
