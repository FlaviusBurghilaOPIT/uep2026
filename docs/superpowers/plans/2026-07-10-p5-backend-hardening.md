# Remote CarePro — p5/backend Hardening & Features Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring `p5/backend` up to date with `main`, harden the backend (infra, auth factory, RLS, seed script, docs, tests), then implement Person 5's feature set (FDA warnings workflow, AI assistant with guardrails, check-in trend, surgery wiki, emergency contact).

**Architecture:** FastAPI + SQLAlchemy 2.x + Alembic on Postgres, unchanged. New work slots into the existing router/model/schema layout; the existing `AuthProvider`/`FDAProvider`/`LLMProvider` factories in `backend/app/providers/` get wired in instead of being replaced.

**Tech Stack:** Python 3.12, FastAPI, SQLAlchemy 2.x, Alembic, Postgres 18, pytest, black, ruff.

## Global Constraints

- **No git commits.** Every task ends with changes left in the working tree — the user commits personally. Do not run `git commit` or `git push` at any point in this plan.
- **No live AWS calls.** `CognitoAuthProvider`, `BedrockProvider` remain uncalled by default (`AUTH_PROVIDER=local`, `LLM_PROVIDER=mock` in `.env`); their code must be correct but is expected to fail without real credentials — do not stub around that by skipping their implementation.
- **Backend-only.** No changes under `web/` (beyond the two version bumps in Task 2) or `mobile/`.
- All new DB tables/columns go through Alembic migrations generated with `alembic revision --autogenerate`, run from `backend/` with `DATABASE_URL` pointed at the running dev Postgres container.
- All new endpoints require `Depends(get_current_user)` unless the spec says otherwise, matching existing router conventions.
- Follow existing code style exactly (multi-line `Depends(...)` args, blank line between route functions, no docstrings) until Task 13 (formatting) normalizes it.

---

## Task 1: Create p5/backend and merge main

**Files:** none (git operations only).

- [ ] **Step 1: Fetch and create the local branch**

Run: `git -C /Users/flavius/OPIT/git/uep2026 fetch origin`
Expected: updates for `p5/backend` (or "up to date").

- [ ] **Step 2: Create local `p5/backend` tracking the remote**

Run: `git -C /Users/flavius/OPIT/git/uep2026 checkout -b p5/backend origin/p5/backend`
Expected: `Switched to a new branch 'p5/backend'`.

- [ ] **Step 3: Merge main in**

Run: `git -C /Users/flavius/OPIT/git/uep2026 merge origin/main --no-edit`
Expected: `Fast-forward` (confirmed ancestor relationship — no conflicts expected). If it is not a fast-forward when this runs (branch state may have changed since this plan was written), stop and report the conflict instead of resolving it unilaterally.

- [ ] **Step 4: Verify working tree matches main**

Run: `git -C /Users/flavius/OPIT/git/uep2026 diff origin/main -- backend/ | head -5`
Expected: empty output (no diff).

Do not commit — this is a merge commit that already exists from Step 3's fast-forward; no separate commit is needed or permitted beyond that.

---

## Task 2: Docker/infra version bumps and volume fix

**Files:**
- Modify: `docker-compose.yml`
- Modify: `web/Dockerfile`

**Interfaces:** none (infra only).

- [ ] **Step 1: Bump Postgres and fix the volume mount**

In `docker-compose.yml`, change:
```yaml
  db:
    image: postgres:16
    environment:
      POSTGRES_USER: caredev
      POSTGRES_PASSWORD: caredev
      POSTGRES_DB: remotecare
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/docker/data
```
to:
```yaml
  db:
    image: postgres:18
    environment:
      POSTGRES_USER: caredev
      POSTGRES_PASSWORD: caredev
      POSTGRES_DB: remotecare
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U caredev -d remotecare"]
      interval: 5s
      timeout: 5s
      retries: 10
```

- [ ] **Step 2: Make backend wait for a healthy db and auto-migrate on start**

In `docker-compose.yml`, change the `backend` service's `depends_on` and `command`:
```yaml
  backend:
    build: ./backend
    ports:
      - "8000:8000"
    env_file: .env
    depends_on:
      db:
        condition: service_healthy
    volumes:
      - ./backend:/app
    command: sh -c "alembic upgrade head && uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload"
```

- [ ] **Step 3: Bump Node in web/Dockerfile**

In `web/Dockerfile`, change `FROM node:20-alpine` to `FROM node:24-alpine`.

- [ ] **Step 4: Validate compose file syntax**

Run: `cd /Users/flavius/OPIT/git/uep2026 && docker compose config --quiet`
Expected: no output, exit code 0.

- [ ] **Step 5: Bring the stack up and confirm auto-migration works**

Run: `cd /Users/flavius/OPIT/git/uep2026 && docker compose up -d --build && sleep 3 && docker compose logs backend | tail -20`
Expected: log shows Alembic running migrations to `1b0581fc4e9c` (or later, once Task 6/14/17/19 migrations exist) followed by `Uvicorn running on http://0.0.0.0:8000`.

- [ ] **Step 6: Confirm tables exist without manual alembic step**

Run: `curl -s http://localhost:8000/health/db`
Expected: `{"database":"connected"}`

Do not commit. Leave `docker-compose.yml` and `web/Dockerfile` modified in the working tree.

---

## Task 3: pytest scaffolding

**Files:**
- Create: `backend/tests/__init__.py`
- Create: `backend/tests/conftest.py`
- Modify: `backend/requirements.txt`

**Interfaces:**
- Produces: `db_session` fixture (SQLAlchemy `Session` bound to an in-memory SQLite engine with `Base.metadata.create_all()` applied) and `client` fixture (FastAPI `TestClient` with `get_db` overridden to yield `db_session`) — every later test task in this plan imports these from `conftest.py` implicitly via pytest fixture injection.

- [ ] **Step 1: Add test/dev dependencies**

In `backend/requirements.txt`, append:
```
pytest
httpx
black
ruff
```

- [ ] **Step 2: Install them**

Run: `cd /Users/flavius/OPIT/git/uep2026/backend && pip install -r requirements.txt`
Expected: successful install, no errors.

- [ ] **Step 3: Create the tests package**

Create `backend/tests/__init__.py` (empty file).

- [ ] **Step 4: Write conftest.py**

Create `backend/tests/conftest.py`:
```python
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from fastapi.testclient import TestClient

from app.models import Base
from app.database import get_db
from app.main import app


@pytest.fixture()
def db_session():
    engine = create_engine(
        "sqlite:///:memory:",
        connect_args={"check_same_thread": False},
    )
    Base.metadata.create_all(bind=engine)
    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    session = TestingSessionLocal()
    try:
        yield session
    finally:
        session.close()
        Base.metadata.drop_all(bind=engine)


@pytest.fixture()
def client(db_session):
    def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db
    yield TestClient(app)
    app.dependency_overrides.clear()
```

- [ ] **Step 5: Verify the fixtures load (smoke test)**

Create `backend/tests/test_smoke.py` temporarily:
```python
def test_client_fixture_loads(client):
    response = client.get("/")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"
```

Run: `cd /Users/flavius/OPIT/git/uep2026/backend && python -m pytest tests/test_smoke.py -v`
Expected: `1 passed`.

Keep `tests/test_smoke.py` — it's a legitimate root-endpoint test, not scaffolding to delete.

Do not commit.

---

## Task 4: Admin role

**Files:**
- Modify: `backend/app/models.py` (the `UserRole` enum)
- Create: `backend/alembic/versions/<autogen>_add_admin_role.py`
- Test: `backend/tests/test_models.py`

**Interfaces:**
- Produces: `models.UserRole.admin` — used by Task 8 (seed script) and Task 7 (RLS bypass check).

- [ ] **Step 1: Write the failing test**

Create `backend/tests/test_models.py`:
```python
from app.models import UserRole


def test_user_role_has_admin():
    assert UserRole.admin.value == "admin"
    assert set(r.value for r in UserRole) == {"admin", "clinician", "patient"}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/flavius/OPIT/git/uep2026/backend && python -m pytest tests/test_models.py -v`
Expected: FAIL with `AttributeError: admin`.

- [ ] **Step 3: Add the role**

In `backend/app/models.py`, change:
```python
class UserRole(str, enum.Enum):
    clinician = "clinician"
    patient = "patient"
```
to:
```python
class UserRole(str, enum.Enum):
    admin = "admin"
    clinician = "clinician"
    patient = "patient"
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /Users/flavius/OPIT/git/uep2026/backend && python -m pytest tests/test_models.py -v`
Expected: `1 passed`.

- [ ] **Step 5: Generate and apply the migration**

Run (with the dev Postgres up from Task 2, `DATABASE_URL` pointed at it):
```bash
cd /Users/flavius/OPIT/git/uep2026/backend && alembic revision --autogenerate -m "add admin role"
```
Expected: a new file `backend/alembic/versions/<hash>_add_admin_role.py` is created. Postgres enums require `ALTER TYPE ... ADD VALUE` rather than a plain column alter — open the generated file and confirm/replace its `upgrade()` body with:
```python
def upgrade() -> None:
    op.execute("ALTER TYPE userrole ADD VALUE IF NOT EXISTS 'admin'")


def downgrade() -> None:
    # Postgres cannot drop a single enum value; downgrade is a no-op by design.
    pass
```

- [ ] **Step 6: Apply it**

Run: `cd /Users/flavius/OPIT/git/uep2026/backend && alembic upgrade head`
Expected: `Running upgrade ... -> <hash>, add admin role`, no errors.

Do not commit.

---

## Task 5: Wire the auth factory into dependencies

**Files:**
- Modify: `backend/app/dependencies.py`
- Modify: `backend/app/providers/auth.py` (flesh out `CognitoAuthProvider.verify_token`)
- Modify: `backend/requirements.txt` (add `httpx` already added in Task 3; add `cachetools` for JWKS caching)
- Test: `backend/tests/test_providers.py`

**Interfaces:**
- Consumes: `models.User`, `get_db` (`backend/app/database.py`).
- Produces: `dependencies.get_current_user(credentials, db)` now resolves the token via `providers.auth.get_auth_provider().verify_token(token)` returning `{"sub": ..., "role": ..., "email": ...}`, then loads `models.User` by `sub`. This return-shape contract is unchanged from today's `/me` endpoint usage in `backend/app/main.py:57-65`, so no caller changes are needed.

- [ ] **Step 1: Write the failing test for provider selection**

Create `backend/tests/test_providers.py`:
```python
import os

from app.providers.auth import get_auth_provider, LocalAuthProvider, CognitoAuthProvider
from app.providers.fda import get_fda_provider, LiveFDAProvider, FixtureFDAProvider
from app.providers.llm import get_llm_provider, MockLLMProvider, OpenRouterProvider, BedrockProvider


def test_get_auth_provider_defaults_to_local(monkeypatch):
    monkeypatch.delenv("AUTH_PROVIDER", raising=False)
    assert isinstance(get_auth_provider(), LocalAuthProvider)


def test_get_auth_provider_cognito(monkeypatch):
    monkeypatch.setenv("AUTH_PROVIDER", "cognito")
    assert isinstance(get_auth_provider(), CognitoAuthProvider)


def test_get_fda_provider_defaults_to_live(monkeypatch):
    monkeypatch.delenv("FDA_PROVIDER", raising=False)
    assert isinstance(get_fda_provider(), LiveFDAProvider)


def test_get_fda_provider_fixture(monkeypatch):
    monkeypatch.setenv("FDA_PROVIDER", "fixture")
    assert isinstance(get_fda_provider(), FixtureFDAProvider)


def test_get_llm_provider_defaults_to_mock(monkeypatch):
    monkeypatch.delenv("LLM_PROVIDER", raising=False)
    assert isinstance(get_llm_provider(), MockLLMProvider)


def test_get_llm_provider_openrouter(monkeypatch):
    monkeypatch.setenv("LLM_PROVIDER", "openrouter")
    assert isinstance(get_llm_provider(), OpenRouterProvider)


def test_get_llm_provider_bedrock(monkeypatch):
    monkeypatch.setenv("LLM_PROVIDER", "bedrock")
    assert isinstance(get_llm_provider(), BedrockProvider)
```

- [ ] **Step 2: Run test to verify it passes already**

Run: `cd /Users/flavius/OPIT/git/uep2026/backend && python -m pytest tests/test_providers.py -v`
Expected: `7 passed` — the factories already exist and work standalone; this locks their contract in place before Step 3 changes how they're consumed.

- [ ] **Step 3: Implement real Cognito token verification**

Replace `backend/app/providers/auth.py` in full:
```python
import os
from abc import ABC, abstractmethod

import httpx
import jwt
from jwt import PyJWKClient


class AuthProvider(ABC):
    @abstractmethod
    async def verify_token(self, token: str) -> dict:
        # returns { sub, role, email }
        pass


class LocalAuthProvider(AuthProvider):
    async def verify_token(self, token: str) -> dict:
        secret = os.getenv("JWT_SECRET", "dev-secret-change-in-prod")
        return jwt.decode(token, secret, algorithms=["HS256"])


class CognitoAuthProvider(AuthProvider):
    def __init__(self):
        self._jwk_client: PyJWKClient | None = None

    def _jwks_url(self) -> str:
        region = os.getenv("COGNITO_REGION")
        pool_id = os.getenv("COGNITO_USER_POOL_ID")
        if not region or not pool_id:
            raise RuntimeError(
                "COGNITO_REGION and COGNITO_USER_POOL_ID must be set to use AUTH_PROVIDER=cognito"
            )
        return (
            f"https://cognito-idp.{region}.amazonaws.com/{pool_id}"
            "/.well-known/jwks.json"
        )

    async def verify_token(self, token: str) -> dict:
        if self._jwk_client is None:
            self._jwk_client = PyJWKClient(self._jwks_url())

        signing_key = self._jwk_client.get_signing_key_from_jwt(token)
        client_id = os.getenv("COGNITO_APP_CLIENT_ID")
        claims = jwt.decode(
            token,
            signing_key.key,
            algorithms=["RS256"],
            audience=client_id,
        )
        return {
            "sub": claims["sub"],
            "role": claims.get("custom:role", "patient"),
            "email": claims.get("email"),
        }


def get_auth_provider() -> AuthProvider:
    p = os.getenv("AUTH_PROVIDER", "local")
    if p == "cognito":
        return CognitoAuthProvider()
    return LocalAuthProvider()
```

Note: this uses `pyjwt` (`import jwt`), not `python-jose`. Add it to `backend/requirements.txt`:
```
pyjwt[crypto]
```
Run: `cd /Users/flavius/OPIT/git/uep2026/backend && pip install -r requirements.txt`

- [ ] **Step 4: Wire dependencies.get_current_user to the factory**

Replace `backend/app/dependencies.py` in full:
```python
from fastapi import Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session

from app.database import get_db
from app.providers.auth import get_auth_provider
from app import models


security = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db)
):

    token = credentials.credentials

    try:
        payload = await get_auth_provider().verify_token(token)
        user_id = payload.get("sub")

    except Exception:
        raise HTTPException(
            status_code=401,
            detail="Invalid token"
        )

    user = db.query(models.User).filter(
        models.User.id == user_id
    ).first()

    if not user:
        raise HTTPException(
            status_code=401,
            detail="User not found"
        )

    return user
```

Note this changes `get_current_user` to an `async def` (it now awaits `verify_token`) — FastAPI supports async dependencies transparently, no caller changes needed.

- [ ] **Step 5: Write an end-to-end test through the local provider**

Add to `backend/tests/test_providers.py`:
```python
from app.security import create_access_token, hash_password
from app import models


def test_get_current_user_via_local_provider(client, db_session, monkeypatch):
    monkeypatch.delenv("AUTH_PROVIDER", raising=False)

    user = models.User(
        email="factory-test@example.com",
        full_name="Factory Test",
        role=models.UserRole.clinician,
        password_hash=hash_password("pw"),
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)

    token = create_access_token({"sub": user.id, "role": "clinician", "email": user.email})
    response = client.get("/me", headers={"Authorization": f"Bearer {token}"})

    assert response.status_code == 200
    assert response.json()["email"] == "factory-test@example.com"
```

- [ ] **Step 6: Run the full provider test file**

Run: `cd /Users/flavius/OPIT/git/uep2026/backend && python -m pytest tests/test_providers.py -v`
Expected: `8 passed`.

Do not commit.

---

## Task 6: Restructure RLS session-variable wiring

**Files:**
- Modify: `backend/app/database.py`
- Modify: `backend/app/dependencies.py`
- Test: `backend/tests/test_rls_session.py`

**Interfaces:**
- Consumes: `models.User` (from Task 5's `get_current_user`).
- Produces: `dependencies.get_db_for_user(current_user, db)` — a dependency that, given an already-resolved `current_user` and a plain `db` session, issues `SET LOCAL app.current_user_id` / `SET LOCAL app.current_role` on that session and yields it. Routers that need RLS-scoped queries depend on this instead of the bare `get_db`. This is additive — `get_db` itself is unchanged so every existing router keeps working exactly as before.

- [ ] **Step 1: Write the failing test**

Create `backend/tests/test_rls_session.py`:
```python
from sqlalchemy import text

from app.dependencies import get_db_for_user
from app import models


def test_get_db_for_user_sets_session_vars(db_session):
    user = models.User(
        id="user-1",
        email="rls@example.com",
        full_name="RLS Test",
        role=models.UserRole.clinician,
    )

    gen = get_db_for_user(current_user=user, db=db_session)
    scoped_db = next(gen)

    # SQLite has no SET LOCAL / current_setting; the dependency must skip
    # the Postgres-only statement gracefully on any other dialect.
    assert scoped_db is db_session
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/flavius/OPIT/git/uep2026/backend && python -m pytest tests/test_rls_session.py -v`
Expected: FAIL with `ImportError: cannot import name 'get_db_for_user'`.

- [ ] **Step 3: Implement the dependency**

Append to `backend/app/dependencies.py`:
```python
from sqlalchemy import text
from app.database import get_db as _get_db


def get_db_for_user(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(_get_db),
):
    if db.bind.dialect.name == "postgresql":
        db.execute(
            text("SET LOCAL app.current_user_id = :uid"),
            {"uid": current_user.id},
        )
        db.execute(
            text("SET LOCAL app.current_role = :role"),
            {"role": current_user.role.value},
        )
    yield db
```

Note `get_db_for_user`'s own `db` parameter still depends on the real `get_db` — only tests construct it manually with a pre-made session (as `test_rls_session.py` does), exercising the function body directly rather than through FastAPI's DI.

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /Users/flavius/OPIT/git/uep2026/backend && python -m pytest tests/test_rls_session.py -v`
Expected: `1 passed`.

Do not commit.

---

## Task 7: Row-level security migration

**Files:**
- Create: `backend/alembic/versions/<autogen>_enable_rls.py`
- Modify: `backend/app/routers/cases.py`, `patients.py`, `adherence.py`, `checkins.py`, `recommendations.py`, `reminders.py` (swap `Depends(get_db)` for `Depends(get_db_for_user)` on read/write routes)
- Test: `backend/tests/test_rls_policies.py` (integration test against the real Postgres container)

**Interfaces:**
- Consumes: `dependencies.get_db_for_user` (Task 6).

- [ ] **Step 1: Write the migration**

Create `backend/alembic/versions/<hash>_enable_rls.py` (get `<hash>` and `down_revision` by running `alembic revision -m "enable rls"` first, then fill in the body):
```python
"""enable rls

Revision ID: <hash>
Revises: <previous head>
Create Date: 2026-07-10

"""
from alembic import op

revision = "<hash>"
down_revision = "<previous head>"
branch_labels = None
depends_on = None

TABLES_VIA_CASE_ID = [
    "medications",
    "recommendations",
    "checkins",
    "chat_messages",
]


def upgrade() -> None:
    op.execute("ALTER TABLE cases ENABLE ROW LEVEL SECURITY")
    op.execute(
        """
        CREATE POLICY cases_clinician_access ON cases
        USING (
            current_setting('app.current_role', true) = 'admin'
            OR clinician_id = current_setting('app.current_user_id', true)
            OR patient_id = current_setting('app.current_user_id', true)
        )
        """
    )

    for table in TABLES_VIA_CASE_ID:
        op.execute(f"ALTER TABLE {table} ENABLE ROW LEVEL SECURITY")
        op.execute(
            f"""
            CREATE POLICY {table}_case_access ON {table}
            USING (
                current_setting('app.current_role', true) = 'admin'
                OR case_id IN (
                    SELECT id FROM cases
                    WHERE clinician_id = current_setting('app.current_user_id', true)
                       OR patient_id = current_setting('app.current_user_id', true)
                )
            )
            """
        )


def downgrade() -> None:
    for table in TABLES_VIA_CASE_ID:
        op.execute(f"DROP POLICY IF EXISTS {table}_case_access ON {table}")
        op.execute(f"ALTER TABLE {table} DISABLE ROW LEVEL SECURITY")
    op.execute("DROP POLICY IF EXISTS cases_clinician_access ON cases")
    op.execute("ALTER TABLE cases DISABLE ROW LEVEL SECURITY")
```

Note `medications`/`scheduled_reminders`/`dose_logs` are two joins deep from `cases` (`case → medication → scheduled_reminder → dose_log`); this migration covers `medications` directly and leaves `scheduled_reminders`/`dose_logs` unprotected by RLS in this pass — call this out in the README (Task 12) as a known gap rather than silently expanding scope.

- [ ] **Step 2: Apply it**

Run: `cd /Users/flavius/OPIT/git/uep2026/backend && alembic upgrade head`
Expected: `Running upgrade ... -> <hash>, enable rls`, no errors.

- [ ] **Step 3: Write the integration test (requires the dev Postgres container running from Task 2)**

Create `backend/tests/test_rls_policies.py`:
```python
import os

import pytest
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker

pytestmark = pytest.mark.skipif(
    "postgresql" not in os.getenv("DATABASE_URL", ""),
    reason="RLS policies only exist on Postgres; run with the dev docker-compose db up",
)


@pytest.fixture()
def pg_session():
    engine = create_engine(os.environ["DATABASE_URL"])
    Session = sessionmaker(bind=engine)
    session = Session()
    yield session
    session.close()


def test_patient_cannot_see_other_patients_case(pg_session):
    pg_session.execute(text("BEGIN"))
    pg_session.execute(
        text(
            "INSERT INTO users (id, email, full_name, role, created_at) "
            "VALUES ('clin-1', 'c1@t.com', 'Clin One', 'clinician', now()), "
            "('pat-1', 'p1@t.com', 'Pat One', 'patient', now()), "
            "('pat-2', 'p2@t.com', 'Pat Two', 'patient', now()) "
            "ON CONFLICT (id) DO NOTHING"
        )
    )
    pg_session.execute(
        text(
            "INSERT INTO cases (id, clinician_id, patient_id, surgery_type, status, created_at) "
            "VALUES ('case-1', 'clin-1', 'pat-1', 'knee', 'active', now()) "
            "ON CONFLICT (id) DO NOTHING"
        )
    )
    pg_session.commit()

    pg_session.execute(text("SET LOCAL app.current_role = 'patient'"))
    pg_session.execute(text("SET LOCAL app.current_user_id = 'pat-2'"))
    rows = pg_session.execute(text("SELECT id FROM cases WHERE id = 'case-1'")).fetchall()
    assert rows == []

    pg_session.execute(text("SET LOCAL app.current_role = 'patient'"))
    pg_session.execute(text("SET LOCAL app.current_user_id = 'pat-1'"))
    rows = pg_session.execute(text("SELECT id FROM cases WHERE id = 'case-1'")).fetchall()
    assert len(rows) == 1
```

- [ ] **Step 4: Run it against the dev container**

Run: `cd /Users/flavius/OPIT/git/uep2026/backend && DATABASE_URL=postgresql://caredev:caredev@localhost:5432/remotecare python -m pytest tests/test_rls_policies.py -v`
Expected: `1 passed`.

- [ ] **Step 5: Switch read routes to the RLS-scoped dependency**

In `backend/app/routers/cases.py`, `patients.py`, `adherence.py`, `checkins.py`, `recommendations.py`, `reminders.py`: change every `db: Session = Depends(get_db)` to `db: Session = Depends(get_db_for_user)` and add `from app.dependencies import get_db_for_user` (alongside the existing `get_current_user` import) to each file's imports. Because RLS policies already scope `cases` to the caller's own rows, the existing manual `models.Case.clinician_id == current_user.id` filters in `cases.py` become redundant but harmless (defense in depth) — leave them in place.

- [ ] **Step 6: Re-run the full suite to confirm nothing broke**

Run: `cd /Users/flavius/OPIT/git/uep2026/backend && python -m pytest -v`
Expected: all tests pass.

Do not commit.

---

## Task 8: Seed script

**Files:**
- Create: `backend/app/scripts/__init__.py`
- Create: `backend/app/scripts/seed.py`
- Test: `backend/tests/test_seed.py`

**Interfaces:**
- Produces: `scripts.seed.seed(db: Session) -> dict` returning `{"admin": User, "clinician": User, "patient": User}` (or the pre-existing rows if already seeded) — used by the CLI entrypoint and directly importable in tests.

- [ ] **Step 1: Write the failing test**

Create `backend/tests/test_seed.py`:
```python
from app.scripts.seed import seed
from app import models


def test_seed_creates_one_of_each_role(db_session):
    result = seed(db_session)

    assert result["admin"].role == models.UserRole.admin
    assert result["clinician"].role == models.UserRole.clinician
    assert result["patient"].role == models.UserRole.patient
    assert db_session.query(models.User).count() == 3


def test_seed_is_idempotent(db_session):
    seed(db_session)
    seed(db_session)

    assert db_session.query(models.User).count() == 3
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/flavius/OPIT/git/uep2026/backend && python -m pytest tests/test_seed.py -v`
Expected: FAIL with `ModuleNotFoundError: No module named 'app.scripts'`.

- [ ] **Step 3: Implement the seed script**

Create `backend/app/scripts/__init__.py` (empty).

Create `backend/app/scripts/seed.py`:
```python
from sqlalchemy.orm import Session

from app import models
from app.security import hash_password

SEED_USERS = [
    ("admin@remotecarepro.dev", "Seed Admin", models.UserRole.admin, "admin1234"),
    ("clinician@remotecarepro.dev", "Seed Clinician", models.UserRole.clinician, "clinician1234"),
    ("patient@remotecarepro.dev", "Seed Patient", models.UserRole.patient, "patient1234"),
]


def seed(db: Session) -> dict:
    result = {}
    for email, full_name, role, password in SEED_USERS:
        existing = db.query(models.User).filter(models.User.email == email).first()
        if existing:
            result[role.value] = existing
            continue

        user = models.User(
            email=email,
            full_name=full_name,
            role=role,
            password_hash=hash_password(password),
        )
        db.add(user)
        db.commit()
        db.refresh(user)
        result[role.value] = user

    return result


if __name__ == "__main__":
    from app.database import SessionLocal

    db = SessionLocal()
    try:
        created = seed(db)
        print("Seeded users (email / password):")
        for email, _, role, password in SEED_USERS:
            print(f"  {role.value}: {email} / {password}")
    finally:
        db.close()
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /Users/flavius/OPIT/git/uep2026/backend && python -m pytest tests/test_seed.py -v`
Expected: `2 passed`.

- [ ] **Step 5: Run it against the dev container**

Run: `cd /Users/flavius/OPIT/git/uep2026/backend && DATABASE_URL=postgresql://caredev:caredev@localhost:5432/remotecare python -m app.scripts.seed`
Expected: prints the three seeded email/password pairs.

Do not commit.

---

## Task 9: .env / .env.example

**Files:**
- Modify: `.env`
- Modify: `.env.example`

- [ ] **Step 1: Update .env with the new variables**

Replace `/Users/flavius/OPIT/git/uep2026/.env` in full:
```
# Database
DATABASE_URL=postgresql://caredev:caredev@db:5432/remotecare
POSTGRES_IMAGE_TAG=18

# Auth
AUTH_PROVIDER=local
JWT_SECRET=dev-secret-change-in-prod
COGNITO_REGION=
COGNITO_USER_POOL_ID=
COGNITO_APP_CLIENT_ID=

# AI
LLM_PROVIDER=mock
OPENROUTER_API_KEY=
OPENROUTER_MODEL=openai/gpt-4o-mini

# FDA
FDA_PROVIDER=live
```

- [ ] **Step 2: Populate .env.example mirroring it with placeholders**

Replace `/Users/flavius/OPIT/git/uep2026/.env.example` in full:
```
# Database
DATABASE_URL=postgresql://caredev:caredev@db:5432/remotecare
POSTGRES_IMAGE_TAG=18

# Auth
# local = dev-login against the local users table (default)
# cognito = verify AWS Cognito JWTs (requires the three COGNITO_* vars below)
AUTH_PROVIDER=local
JWT_SECRET=change-me
COGNITO_REGION=
COGNITO_USER_POOL_ID=
COGNITO_APP_CLIENT_ID=

# AI
# mock = canned response, no external call (default)
# openrouter / bedrock = real LLM calls, require the matching credentials
LLM_PROVIDER=mock
OPENROUTER_API_KEY=
OPENROUTER_MODEL=openai/gpt-4o-mini

# FDA
# live = calls the real openFDA public API (default)
# fixture = returns canned safety data, useful offline/in tests
FDA_PROVIDER=live
```

- [ ] **Step 3: Confirm docker compose still reads it correctly**

Run: `cd /Users/flavius/OPIT/git/uep2026 && docker compose config | grep -A2 DATABASE_URL`
Expected: shows the resolved `DATABASE_URL` value from `.env`.

Do not commit.

---

## Task 10: FastAPI/Swagger metadata

**Files:**
- Modify: `backend/app/main.py`
- Modify: `backend/app/routers/*.py` (add `description` to each `APIRouter(...)` call — no behavior change)

- [ ] **Step 1: Add app-level metadata**

In `backend/app/main.py`, change:
```python
app = FastAPI(title="Remote CarePro API")
```
to:
```python
app = FastAPI(
    title="Remote CarePro API",
    description=(
        "Backend for Remote CarePro: clinician-authored post-surgery cases, "
        "medication adherence tracking, an AI recovery assistant with guardrails, "
        "and openFDA safety integration."
    ),
    version="0.2.0",
)
```

- [ ] **Step 2: Add router descriptions**

For each router file under `backend/app/routers/`, add a `description=` kwarg to its `APIRouter(...)` call, e.g. in `backend/app/routers/auth.py`:
```python
router = APIRouter(
    prefix="/auth",
    tags=["auth"],
    description="Local email/password login (see AuthProvider factory for Cognito)."
)
```
Apply the same pattern (one short, accurate sentence per router) to `cases.py`, `patients.py`, `medications.py`, `adherence.py`, `reminders.py`, `recommendations.py`, `checkins.py`, `ai.py`, `fda.py`, `users.py`.

- [ ] **Step 3: Verify Swagger renders**

Run: `cd /Users/flavius/OPIT/git/uep2026 && docker compose up -d backend && curl -s http://localhost:8000/openapi.json | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['info']['title'], d['info']['version'])"`
Expected: `Remote CarePro API 0.2.0`

Do not commit.

---

## Task 11: Code formatting (black + ruff)

**Files:**
- Create: `backend/pyproject.toml`
- Modify: all files under `backend/app/` and `backend/tests/` (formatting only, via tool)

- [ ] **Step 1: Add config**

Create `backend/pyproject.toml`:
```toml
[tool.black]
line-length = 100
target-version = ["py312"]

[tool.ruff]
line-length = 100
target-version = "py312"

[tool.ruff.lint]
select = ["E", "F", "I"]
```

- [ ] **Step 2: Run black**

Run: `cd /Users/flavius/OPIT/git/uep2026/backend && black app tests`
Expected: reports N files reformatted.

- [ ] **Step 3: Run ruff and fix auto-fixable issues**

Run: `cd /Users/flavius/OPIT/git/uep2026/backend && ruff check app tests --fix`
Expected: reports fixed issues or "All checks passed!".

- [ ] **Step 4: Re-run the full test suite to confirm formatting didn't break anything**

Run: `cd /Users/flavius/OPIT/git/uep2026/backend && python -m pytest -v`
Expected: all tests still pass.

Do not commit.

---

## Task 12: README

**Files:**
- Create/Modify: `/Users/flavius/OPIT/git/uep2026/README.md` (currently `REadme.md` — see Step 1)

- [ ] **Step 1: Check the existing misnamed file, then replace it**

Run: `cat /Users/flavius/OPIT/git/uep2026/REadme.md` to see current content, then create `/Users/flavius/OPIT/git/uep2026/README.md` (new, correctly-cased file — leave `REadme.md` in place untouched since deleting/renaming tracked files is a git operation outside this task's scope; note the duplicate for the user to clean up in their own commit) with:
```markdown
# Remote CarePro

Two-sided post-surgery care platform: a clinician web dashboard (source of truth for
cases, prescriptions, and recovery plans) and a patient mobile app (receives the
regimen automatically, logs adherence, gets AI-assisted answers bounded to what the
clinician prescribed).

## Architecture

- `backend/` — FastAPI + SQLAlchemy 2.x + Alembic, Postgres 18.
- `web/` — clinician dashboard (React, `web/Dockerfile`, Node 24).
- `mobile/` — patient app (Flutter).
- `mock/openapi.yaml` — API contract used by `stoplight/prism` for contract testing.

Auth, the AI assistant, and FDA lookups are each behind a factory in
`backend/app/providers/`, selected by an env var, so local dev never needs live AWS
credentials:

| Concern | Env var | Local default | Production option |
|---|---|---|---|
| Auth | `AUTH_PROVIDER` | `local` — password login against the app's own `users` table (`POST /auth/dev-login`) | `cognito` — verifies AWS Cognito JWTs |
| AI | `LLM_PROVIDER` | `mock` — canned response | `openrouter` / `bedrock` |
| FDA | `FDA_PROVIDER` | `live` — calls the real openFDA public API | `fixture` — canned data for offline/tests |

Row-level security is enabled on `cases`, `medications`, `recommendations`, `checkins`,
and `chat_messages`: clinicians see only cases where they're `clinician_id`, patients
only where they're `patient_id`, and `admin` bypasses both. `scheduled_reminders` and
`dose_logs` are not yet RLS-protected (tracked as a follow-up).

## Local development

```bash
docker compose up -d --build
```

This starts Postgres 18 (healthchecked), the FastAPI backend (auto-runs
`alembic upgrade head` before serving), and a Prism mock server for the OpenAPI
contract. No manual migration step is needed.

Seed one admin/clinician/patient user for local testing:

```bash
docker compose exec backend python -m app.scripts.seed
```

Prints the seeded email/password pairs. Log in via `POST /auth/dev-login`.

API docs: `http://localhost:8000/docs` (Swagger UI, auto-generated by FastAPI).

## Tests

```bash
cd backend && python -m pytest -v
```

RLS policy tests only run against real Postgres (skipped automatically unless
`DATABASE_URL` points at a `postgresql://` connection):

```bash
cd backend && DATABASE_URL=postgresql://caredev:caredev@localhost:5432/remotecare python -m pytest -v
```
```

- [ ] **Step 2: Verify it renders sensibly**

Run: `cd /Users/flavius/OPIT/git/uep2026 && head -5 README.md`
Expected: shows the `# Remote CarePro` heading.

Do not commit.

---

## Task 13: FDA warning model + migration

**Files:**
- Modify: `backend/app/models.py` (add `FDAWarning`, `CaseFDAWarning`)
- Create: `backend/alembic/versions/<autogen>_add_fda_warnings.py`
- Test: `backend/tests/test_fda_models.py`

**Interfaces:**
- Produces: `models.FDAWarningStatus` (enum: `pending`/`approved`/`dismissed`), `models.FDAWarning` (`id`, `drug_name`, `summary`, `severity`, `status`, `source_payload`, `created_at`, `reviewed_by`, `reviewed_at`), `models.CaseFDAWarning` (`id`, `case_id`, `fda_warning_id`, `created_at`) — used by Task 14.

- [ ] **Step 1: Write the failing test**

Create `backend/tests/test_fda_models.py`:
```python
from app.models import FDAWarning, FDAWarningStatus, CaseFDAWarning


def test_fda_warning_defaults_to_pending(db_session):
    warning = FDAWarning(drug_name="ibuprofen", summary="test", severity="moderate")
    db_session.add(warning)
    db_session.commit()
    db_session.refresh(warning)

    assert warning.status == FDAWarningStatus.pending
    assert warning.reviewed_by is None


def test_case_fda_warning_links_case_and_warning(db_session):
    from app import models

    clinician = models.User(email="c@t.com", full_name="C", role=models.UserRole.clinician)
    patient = models.User(email="p@t.com", full_name="P", role=models.UserRole.patient)
    db_session.add_all([clinician, patient])
    db_session.commit()

    case = models.Case(clinician_id=clinician.id, patient_id=patient.id, surgery_type="knee")
    warning = FDAWarning(drug_name="ibuprofen", summary="test", severity="moderate")
    db_session.add_all([case, warning])
    db_session.commit()

    link = CaseFDAWarning(case_id=case.id, fda_warning_id=warning.id)
    db_session.add(link)
    db_session.commit()
    db_session.refresh(link)

    assert link.case_id == case.id
    assert link.fda_warning_id == warning.id
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/flavius/OPIT/git/uep2026/backend && python -m pytest tests/test_fda_models.py -v`
Expected: FAIL with `ImportError: cannot import name 'FDAWarning'`.

- [ ] **Step 3: Add the models**

Append to `backend/app/models.py` (after the `ChatMessage` class):
```python
class FDAWarningStatus(str, enum.Enum):
    pending = "pending"
    approved = "approved"
    dismissed = "dismissed"


class FDAWarning(Base):
    __tablename__ = "fda_warnings"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=gen_uuid)
    drug_name: Mapped[str] = mapped_column(String, nullable=False, index=True)
    summary: Mapped[str] = mapped_column(Text, nullable=False)
    severity: Mapped[str] = mapped_column(String, nullable=False)
    status: Mapped[FDAWarningStatus] = mapped_column(
        Enum(FDAWarningStatus), default=FDAWarningStatus.pending
    )
    source_payload: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    reviewed_by: Mapped[str | None] = mapped_column(ForeignKey("users.id"), nullable=True)
    reviewed_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)

    cases: Mapped[list["CaseFDAWarning"]] = relationship(
        back_populates="fda_warning", cascade="all, delete-orphan"
    )


class CaseFDAWarning(Base):
    __tablename__ = "case_fda_warnings"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=gen_uuid)
    case_id: Mapped[str] = mapped_column(ForeignKey("cases.id"), nullable=False)
    fda_warning_id: Mapped[str] = mapped_column(ForeignKey("fda_warnings.id"), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    fda_warning: Mapped["FDAWarning"] = relationship(back_populates="cases")
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /Users/flavius/OPIT/git/uep2026/backend && python -m pytest tests/test_fda_models.py -v`
Expected: `2 passed`.

- [ ] **Step 5: Generate and apply the migration**

Run:
```bash
cd /Users/flavius/OPIT/git/uep2026/backend && alembic revision --autogenerate -m "add fda warnings"
alembic upgrade head
```
Expected: new migration file created, then `Running upgrade ... -> <hash>, add fda warnings` with no errors. Inspect the generated file to confirm it creates `fda_warnings` and `case_fda_warnings` tables — Alembic autogenerate reliably picks up new tables/columns from ORM models, no manual edit expected here (unlike Task 4/7, which needed Postgres-specific enum/RLS SQL).

Do not commit.

---

## Task 14: FDA endpoints (queue, approve, dismiss, refresh, live lookup)

**Files:**
- Modify: `backend/app/routers/fda.py`
- Create: `backend/app/schemas.py` additions (see Step 1)
- Test: `backend/tests/test_fda_router.py`

**Interfaces:**
- Consumes: `models.FDAWarning`, `models.FDAWarningStatus`, `models.CaseFDAWarning`, `models.Case`, `models.Medication` (Task 13), `providers.fda.get_fda_provider()`.

- [ ] **Step 1: Add response schemas**

Append to `backend/app/schemas.py`:
```python
class FDAWarningResponse(BaseModel):
    id: str
    drug_name: str
    summary: str
    severity: str
    status: str
    created_at: datetime
    reviewed_by: str | None
    reviewed_at: datetime | None

    class Config:
        from_attributes = True
```

- [ ] **Step 2: Write the failing tests**

Create `backend/tests/test_fda_router.py`:
```python
from app import models
from app.security import hash_password, create_access_token


def _make_clinician(db_session):
    clinician = models.User(
        email="clin@t.com", full_name="Clin", role=models.UserRole.clinician,
        password_hash=hash_password("pw"),
    )
    db_session.add(clinician)
    db_session.commit()
    db_session.refresh(clinician)
    return clinician


def _auth_headers(user):
    token = create_access_token({"sub": user.id, "role": user.role.value, "email": user.email})
    return {"Authorization": f"Bearer {token}"}


def test_warnings_queue_lists_pending_only(client, db_session):
    clinician = _make_clinician(db_session)
    pending = models.FDAWarning(drug_name="ibuprofen", summary="s", severity="moderate")
    approved = models.FDAWarning(
        drug_name="aspirin", summary="s", severity="low",
        status=models.FDAWarningStatus.approved,
    )
    db_session.add_all([pending, approved])
    db_session.commit()

    response = client.get("/fda/warnings", headers=_auth_headers(clinician))

    assert response.status_code == 200
    drugs = [w["drug_name"] for w in response.json()]
    assert drugs == ["ibuprofen"]


def test_approve_propagates_to_active_cases_with_matching_drug(client, db_session):
    clinician = _make_clinician(db_session)
    patient = models.User(email="pat@t.com", full_name="Pat", role=models.UserRole.patient)
    db_session.add(patient)
    db_session.commit()

    case = models.Case(
        clinician_id=clinician.id, patient_id=patient.id,
        surgery_type="knee", status="active",
    )
    db_session.add(case)
    db_session.commit()

    med = models.Medication(
        case_id=case.id, name="Ibuprofen", dose="200mg",
        schedule_text="daily", duration="7 days",
    )
    warning = models.FDAWarning(drug_name="ibuprofen", summary="s", severity="moderate")
    db_session.add_all([med, warning])
    db_session.commit()
    db_session.refresh(warning)

    response = client.post(
        f"/fda/warnings/{warning.id}/approve", headers=_auth_headers(clinician)
    )

    assert response.status_code == 200
    links = db_session.query(models.CaseFDAWarning).filter_by(case_id=case.id).all()
    assert len(links) == 1

    db_session.refresh(warning)
    assert warning.status == models.FDAWarningStatus.approved
    assert warning.reviewed_by == clinician.id


def test_dismiss_does_not_propagate(client, db_session):
    clinician = _make_clinician(db_session)
    warning = models.FDAWarning(drug_name="ibuprofen", summary="s", severity="moderate")
    db_session.add(warning)
    db_session.commit()
    db_session.refresh(warning)

    response = client.post(
        f"/fda/warnings/{warning.id}/dismiss", headers=_auth_headers(clinician)
    )

    assert response.status_code == 200
    db_session.refresh(warning)
    assert warning.status == models.FDAWarningStatus.dismissed
    assert db_session.query(models.CaseFDAWarning).count() == 0
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `cd /Users/flavius/OPIT/git/uep2026/backend && python -m pytest tests/test_fda_router.py -v`
Expected: FAIL — `404 Not Found` for `/fda/warnings` (route doesn't exist yet).

- [ ] **Step 4: Implement the endpoints**

Replace `backend/app/routers/fda.py` in full:
```python
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_current_user
from app.providers.fda import get_fda_provider
from app import models, schemas


router = APIRouter(
    prefix="/fda",
    tags=["fda"]
)


@router.get("/drug/{name}")
async def get_drug_info(
    name: str,
    current_user: models.User = Depends(get_current_user)
):
    provider = get_fda_provider()
    return await provider.get_drug_info(name)


@router.get("/warnings", response_model=list[schemas.FDAWarningResponse])
def list_pending_warnings(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    warnings = db.query(models.FDAWarning).filter(
        models.FDAWarning.status == models.FDAWarningStatus.pending
    ).all()

    return warnings


@router.post("/warnings/{warning_id}/approve", response_model=schemas.FDAWarningResponse)
def approve_warning(
    warning_id: str,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    warning = db.query(models.FDAWarning).filter(
        models.FDAWarning.id == warning_id
    ).first()

    if not warning:
        raise HTTPException(status_code=404, detail="Warning not found")

    warning.status = models.FDAWarningStatus.approved
    warning.reviewed_by = current_user.id
    warning.reviewed_at = datetime.utcnow()

    affected_cases = (
        db.query(models.Case)
        .join(models.Medication, models.Medication.case_id == models.Case.id)
        .filter(
            models.Case.status == "active",
            models.Medication.name.ilike(warning.drug_name)
        )
        .all()
    )

    for case in affected_cases:
        db.add(models.CaseFDAWarning(case_id=case.id, fda_warning_id=warning.id))

    db.commit()
    db.refresh(warning)

    return warning


@router.post("/warnings/{warning_id}/dismiss", response_model=schemas.FDAWarningResponse)
def dismiss_warning(
    warning_id: str,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    warning = db.query(models.FDAWarning).filter(
        models.FDAWarning.id == warning_id
    ).first()

    if not warning:
        raise HTTPException(status_code=404, detail="Warning not found")

    warning.status = models.FDAWarningStatus.dismissed
    warning.reviewed_by = current_user.id
    warning.reviewed_at = datetime.utcnow()

    db.commit()
    db.refresh(warning)

    return warning


@router.post("/warnings/refresh", response_model=list[schemas.FDAWarningResponse])
async def refresh_warnings(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    provider = get_fda_provider()
    distinct_names = [
        row[0] for row in db.query(models.Medication.name).distinct().all()
    ]

    created = []
    for name in distinct_names:
        info = await provider.get_drug_info(name)
        summary = str(info.get("warnings", info))[:2000]

        existing = db.query(models.FDAWarning).filter(
            models.FDAWarning.drug_name.ilike(name),
            models.FDAWarning.summary == summary,
        ).first()
        if existing:
            continue

        warning = models.FDAWarning(
            drug_name=name,
            summary=summary,
            severity="unknown",
            source_payload=str(info)[:4000],
        )
        db.add(warning)
        created.append(warning)

    db.commit()
    for w in created:
        db.refresh(w)

    return created
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `cd /Users/flavius/OPIT/git/uep2026/backend && python -m pytest tests/test_fda_router.py -v`
Expected: `3 passed`.

- [ ] **Step 6: Run the full suite**

Run: `cd /Users/flavius/OPIT/git/uep2026/backend && python -m pytest -v`
Expected: all pass.

Do not commit.

---

## Task 15: AI chat with guardrails

**Files:**
- Modify: `backend/app/routers/ai.py`
- Modify: `backend/app/schemas.py` (`ChatResponse`)
- Test: `backend/tests/test_ai_router.py`

**Interfaces:**
- Consumes: `providers.llm.get_llm_provider()`, `models.ChatMessage`, `models.Case`, `models.Medication`, `models.Recommendation`.
- Produces: `schemas.ChatResponse` now has `reply: str`, `in_scope: bool`, `escalate: bool`.

- [ ] **Step 1: Extend the schema**

In `backend/app/schemas.py`, change:
```python
class ChatResponse(BaseModel):
    reply: str
```
to:
```python
class ChatResponse(BaseModel):
    reply: str
    in_scope: bool = True
    escalate: bool = False
```

- [ ] **Step 2: Write the failing tests**

Create `backend/tests/test_ai_router.py`:
```python
from app import models
from app.security import hash_password, create_access_token


def _auth_headers(user):
    token = create_access_token({"sub": user.id, "role": user.role.value, "email": user.email})
    return {"Authorization": f"Bearer {token}"}


def _make_case_with_meds(db_session):
    clinician = models.User(
        email="c@t.com", full_name="C", role=models.UserRole.clinician,
        password_hash=hash_password("pw"),
    )
    patient = models.User(
        email="p@t.com", full_name="P", role=models.UserRole.patient,
        password_hash=hash_password("pw"),
    )
    db_session.add_all([clinician, patient])
    db_session.commit()

    case = models.Case(clinician_id=clinician.id, patient_id=patient.id, surgery_type="knee")
    db_session.add(case)
    db_session.commit()

    med = models.Medication(
        case_id=case.id, name="Ibuprofen", dose="200mg",
        schedule_text="twice daily", duration="7 days",
    )
    db_session.add(med)
    db_session.commit()

    return patient, case


def test_chat_persists_both_turns(client, db_session, monkeypatch):
    monkeypatch.setenv("LLM_PROVIDER", "mock")
    patient, case = _make_case_with_meds(db_session)

    response = client.post(
        "/ai/chat",
        json={"case_id": case.id, "message": "How should I take my ibuprofen?"},
        headers=_auth_headers(patient),
    )

    assert response.status_code == 200
    body = response.json()
    assert body["in_scope"] is True
    assert body["escalate"] is False

    messages = db_session.query(models.ChatMessage).filter_by(case_id=case.id).all()
    assert len(messages) == 2
    assert messages[0].role == models.ChatRole.user
    assert messages[1].role == models.ChatRole.assistant


def test_chat_flags_dosage_change_language_as_out_of_scope(client, db_session, monkeypatch):
    monkeypatch.setenv("LLM_PROVIDER", "mock")
    patient, case = _make_case_with_meds(db_session)

    response = client.post(
        "/ai/chat",
        json={"case_id": case.id, "message": "Should I take a double dose today?"},
        headers=_auth_headers(patient),
    )

    body = response.json()
    assert body["in_scope"] is False
    assert body["escalate"] is True
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `cd /Users/flavius/OPIT/git/uep2026/backend && python -m pytest tests/test_ai_router.py -v`
Expected: FAIL — only 1 `ChatMessage` persisted (none today), `in_scope`/`escalate` keys missing.

- [ ] **Step 4: Implement**

Replace `backend/app/routers/ai.py` in full:
```python
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_current_user
from app.providers.llm import get_llm_provider
from app import schemas, models


router = APIRouter(
    prefix="/ai",
    tags=["ai"]
)

GUARDRAIL_PREAMBLE = (
    "You are a post-surgery recovery assistant. Answer only using the patient's "
    "prescribed medications and recovery recommendations below. You are strictly "
    "informational: never diagnose, never suggest changing a dose or schedule, and "
    "never recommend a new medication. If asked to do any of those, say you can't "
    "and suggest contacting the clinician or emergency contact."
)

OUT_OF_SCOPE_MARKERS = [
    "double dose",
    "extra dose",
    "stop taking",
    "change your dose",
    "increase your dose",
    "decrease your dose",
    "diagnose",
]


def _build_system_prompt(case: models.Case) -> str:
    meds = "\n".join(
        f"- {m.name} {m.dose}, {m.schedule_text}, for {m.duration}"
        for m in case.medications
    ) or "(no medications on file)"
    recs = "\n".join(f"- {r.text}" for r in case.recommendations) or "(no recommendations on file)"

    return (
        f"{GUARDRAIL_PREAMBLE}\n\n"
        f"Prescribed medications:\n{meds}\n\n"
        f"Recovery recommendations:\n{recs}"
    )


def _check_guardrail(user_message: str) -> tuple[bool, bool]:
    lowered = user_message.lower()
    flagged = any(marker in lowered for marker in OUT_OF_SCOPE_MARKERS)
    return (not flagged, flagged)


@router.post("/chat", response_model=schemas.ChatResponse)
async def chat(
    request: schemas.ChatRequest,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    case = db.query(models.Case).filter(models.Case.id == request.case_id).first()
    if not case:
        raise HTTPException(status_code=404, detail="Case not found")

    in_scope, escalate = _check_guardrail(request.message)

    db.add(models.ChatMessage(
        case_id=case.id, role=models.ChatRole.user, content=request.message,
    ))
    db.commit()

    if not in_scope:
        reply = (
            "I can't help with changing medication doses or schedules — that's a "
            "clinical decision. Please contact your clinician or use the emergency "
            "contact option for anything urgent."
        )
    else:
        provider = get_llm_provider()
        system_prompt = _build_system_prompt(case)
        reply = await provider.chat(
            messages=[{"role": "user", "content": request.message}],
            system=system_prompt,
        )

    db.add(models.ChatMessage(
        case_id=case.id, role=models.ChatRole.assistant, content=reply,
    ))
    db.commit()

    return schemas.ChatResponse(reply=reply, in_scope=in_scope, escalate=escalate)
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `cd /Users/flavius/OPIT/git/uep2026/backend && python -m pytest tests/test_ai_router.py -v`
Expected: `2 passed`.

Do not commit.

---

## Task 16: Check-in trend endpoint

**Files:**
- Modify: `backend/app/routers/checkins.py`
- Test: `backend/tests/test_checkins_trend.py`

**Interfaces:**
- Consumes: `models.CheckIn`, `models.Case`.
- Produces: `GET /symptoms/patients/{patient_id}/symptoms/trend?days=N` → `{"great": int, "ok": int, "not_great": int, "bad": int}`.

- [ ] **Step 1: Write the failing test**

Create `backend/tests/test_checkins_trend.py`:
```python
from datetime import date, timedelta

from app import models
from app.security import create_access_token


def test_trend_counts_checkins_by_feeling(client, db_session):
    clinician = models.User(email="c@t.com", full_name="C", role=models.UserRole.clinician)
    patient = models.User(email="p@t.com", full_name="P", role=models.UserRole.patient)
    db_session.add_all([clinician, patient])
    db_session.commit()

    case = models.Case(clinician_id=clinician.id, patient_id=patient.id, surgery_type="knee")
    db_session.add(case)
    db_session.commit()

    db_session.add_all([
        models.CheckIn(case_id=case.id, feeling=models.CheckInFeeling.great, checkin_date=date.today()),
        models.CheckIn(case_id=case.id, feeling=models.CheckInFeeling.great, checkin_date=date.today()),
        models.CheckIn(case_id=case.id, feeling=models.CheckInFeeling.bad, checkin_date=date.today()),
    ])
    db_session.commit()

    token = create_access_token({"sub": clinician.id, "role": "clinician", "email": clinician.email})
    response = client.get(
        f"/symptoms/patients/{patient.id}/symptoms/trend",
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 200
    assert response.json() == {"great": 2, "ok": 0, "not_great": 0, "bad": 1}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/flavius/OPIT/git/uep2026/backend && python -m pytest tests/test_checkins_trend.py -v`
Expected: FAIL with `404 Not Found`.

- [ ] **Step 3: Implement**

Append to `backend/app/routers/checkins.py`:
```python
from datetime import date, timedelta


@router.get("/patients/{patient_id}/symptoms/trend")
def get_patient_checkin_trend(
    patient_id: str,
    days: int = 14,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    since = date.today() - timedelta(days=days)

    checkins = (
        db.query(models.CheckIn)
        .join(models.Case)
        .filter(
            models.Case.patient_id == patient_id,
            models.CheckIn.checkin_date >= since,
        )
        .all()
    )

    counts = {feeling.value: 0 for feeling in models.CheckInFeeling}
    for checkin in checkins:
        counts[checkin.feeling.value] += 1

    return counts
```

Note the route path is `/symptoms/patients/{patient_id}/symptoms/trend` because `router` is already mounted at prefix `/symptoms` and the existing sibling route (`get_patient_checkins`) uses the same `/patients/{patient_id}/symptoms` shape — this keeps the new route consistent with that existing (slightly redundant) path structure rather than introducing a new convention.

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /Users/flavius/OPIT/git/uep2026/backend && python -m pytest tests/test_checkins_trend.py -v`
Expected: `1 passed`.

Do not commit.

---

## Task 17: Surgery knowledge wiki

**Files:**
- Modify: `backend/app/models.py` (add `WikiArticle`, `WikiArticleStatus`)
- Create: `backend/alembic/versions/<autogen>_add_wiki_articles.py`
- Create: `backend/app/routers/wiki.py`
- Modify: `backend/app/schemas.py` (add `WikiArticleResponse`)
- Modify: `backend/app/main.py` (register the router)
- Test: `backend/tests/test_wiki_router.py`

**Interfaces:**
- Produces: `models.WikiArticle` (`id`, `surgery_type`, `content_md`, `status`, `source_case_ids`, `created_at`, `approved_by`), endpoints `POST /wiki/generate`, `GET /wiki`, `GET /wiki/{id}`, `PATCH /wiki/{id}`.

- [ ] **Step 1: Add the model**

Append to `backend/app/models.py`:
```python
class WikiArticleStatus(str, enum.Enum):
    draft = "draft"
    approved = "approved"


class WikiArticle(Base):
    __tablename__ = "wiki_articles"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=gen_uuid)
    surgery_type: Mapped[str] = mapped_column(String, nullable=False, index=True)
    content_md: Mapped[str] = mapped_column(Text, nullable=False)
    status: Mapped[WikiArticleStatus] = mapped_column(
        Enum(WikiArticleStatus), default=WikiArticleStatus.draft
    )
    source_case_ids: Mapped[str] = mapped_column(Text, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    approved_by: Mapped[str | None] = mapped_column(ForeignKey("users.id"), nullable=True)
```

`source_case_ids` stores a JSON-encoded list of case ids as text (matching this codebase's existing preference for plain `String`/`Text` columns over Postgres-specific `ARRAY`/`JSON` types — see `Medication.notes`, `FDAWarning.source_payload`).

- [ ] **Step 2: Add the schema**

Append to `backend/app/schemas.py`:
```python
class WikiArticleResponse(BaseModel):
    id: str
    surgery_type: str
    content_md: str
    status: str
    source_case_ids: str
    created_at: datetime
    approved_by: str | None

    class Config:
        from_attributes = True


class WikiArticleUpdate(BaseModel):
    content_md: str | None = None
    status: str | None = None
```

- [ ] **Step 3: Write the failing tests**

Create `backend/tests/test_wiki_router.py`:
```python
import json

from app import models
from app.security import create_access_token


def _clinician_headers(db_session):
    clinician = models.User(email="c@t.com", full_name="C", role=models.UserRole.clinician)
    db_session.add(clinician)
    db_session.commit()
    db_session.refresh(clinician)
    token = create_access_token({"sub": clinician.id, "role": "clinician", "email": clinician.email})
    return clinician, {"Authorization": f"Bearer {token}"}


def test_generate_aggregates_recommendations_for_surgery_type(client, db_session):
    clinician, headers = _clinician_headers(db_session)
    patient = models.User(email="p@t.com", full_name="P", role=models.UserRole.patient)
    db_session.add(patient)
    db_session.commit()

    case = models.Case(clinician_id=clinician.id, patient_id=patient.id, surgery_type="knee")
    db_session.add(case)
    db_session.commit()

    db_session.add(models.Recommendation(case_id=case.id, text="Elevate the leg for 3 days."))
    db_session.commit()

    response = client.post("/wiki/generate?surgery_type=knee", headers=headers)

    assert response.status_code == 200
    body = response.json()
    assert body["surgery_type"] == "knee"
    assert body["status"] == "draft"
    assert "Elevate the leg for 3 days." in body["content_md"]
    assert json.loads(body["source_case_ids"]) == [case.id]


def test_index_lists_by_surgery_type(client, db_session):
    _, headers = _clinician_headers(db_session)
    article = models.WikiArticle(
        surgery_type="hip", content_md="content", source_case_ids="[]"
    )
    db_session.add(article)
    db_session.commit()

    response = client.get("/wiki", headers=headers)

    assert response.status_code == 200
    assert any(a["surgery_type"] == "hip" for a in response.json())


def test_patch_approves_article(client, db_session):
    clinician, headers = _clinician_headers(db_session)
    article = models.WikiArticle(
        surgery_type="hip", content_md="draft content", source_case_ids="[]"
    )
    db_session.add(article)
    db_session.commit()
    db_session.refresh(article)

    response = client.patch(
        f"/wiki/{article.id}",
        json={"status": "approved"},
        headers=headers,
    )

    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "approved"
    assert body["approved_by"] == clinician.id
```

- [ ] **Step 4: Run tests to verify they fail**

Run: `cd /Users/flavius/OPIT/git/uep2026/backend && python -m pytest tests/test_wiki_router.py -v`
Expected: FAIL — `404 Not Found` (no `/wiki` routes registered yet).

- [ ] **Step 5: Implement the router**

Create `backend/app/routers/wiki.py`:
```python
import json

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_current_user
from app import models, schemas


router = APIRouter(
    prefix="/wiki",
    tags=["wiki"]
)


@router.post("/generate", response_model=schemas.WikiArticleResponse)
def generate_article(
    surgery_type: str,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    cases = db.query(models.Case).filter(models.Case.surgery_type == surgery_type).all()

    lines = [f"# Recovery notes for {surgery_type}\n"]
    case_ids = []
    for case in cases:
        recs = db.query(models.Recommendation).filter(
            models.Recommendation.case_id == case.id
        ).all()
        for rec in recs:
            lines.append(f"- {rec.text}")
        if recs:
            case_ids.append(case.id)

    article = models.WikiArticle(
        surgery_type=surgery_type,
        content_md="\n".join(lines),
        source_case_ids=json.dumps(case_ids),
    )
    db.add(article)
    db.commit()
    db.refresh(article)

    return article


@router.get("/", response_model=list[schemas.WikiArticleResponse])
def list_articles(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    return db.query(models.WikiArticle).all()


@router.get("/{article_id}", response_model=schemas.WikiArticleResponse)
def get_article(
    article_id: str,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    article = db.query(models.WikiArticle).filter(models.WikiArticle.id == article_id).first()
    if not article:
        raise HTTPException(status_code=404, detail="Article not found")
    return article


@router.patch("/{article_id}", response_model=schemas.WikiArticleResponse)
def update_article(
    article_id: str,
    update: schemas.WikiArticleUpdate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    article = db.query(models.WikiArticle).filter(models.WikiArticle.id == article_id).first()
    if not article:
        raise HTTPException(status_code=404, detail="Article not found")

    if update.content_md is not None:
        article.content_md = update.content_md
    if update.status is not None:
        article.status = models.WikiArticleStatus(update.status)
        if article.status == models.WikiArticleStatus.approved:
            article.approved_by = current_user.id

    db.commit()
    db.refresh(article)

    return article
```

Note: `list_articles` is registered at `GET /wiki/` (trailing slash, matching this codebase's existing convention in `cases.py`/`reminders.py`); FastAPI's default redirect makes `GET /wiki` also work.

- [ ] **Step 6: Register the router**

In `backend/app/main.py`, add `from app.routers import wiki` alongside the other router imports, and `app.include_router(wiki.router)` alongside the other `include_router` calls.

- [ ] **Step 7: Run tests to verify they pass**

Run: `cd /Users/flavius/OPIT/git/uep2026/backend && python -m pytest tests/test_wiki_router.py -v`
Expected: `3 passed`.

- [ ] **Step 8: Generate and apply the migration**

Run:
```bash
cd /Users/flavius/OPIT/git/uep2026/backend && alembic revision --autogenerate -m "add wiki articles"
alembic upgrade head
```
Expected: migration created and applied with no errors.

Do not commit.

---

## Task 18: Emergency contact

**Files:**
- Modify: `backend/app/models.py` (`Case` gains two columns)
- Modify: `backend/app/schemas.py` (`CaseCreate`, `CaseResponse`)
- Modify: `backend/app/routers/cases.py` (`create_case`, new `GET /{case_id}/emergency-contact`)
- Create: `backend/alembic/versions/<autogen>_add_case_emergency_contact.py`
- Test: `backend/tests/test_emergency_contact.py`

**Interfaces:**
- Produces: `Case.emergency_contact_name`, `Case.emergency_contact_phone` (nullable strings); `GET /cases/{case_id}/emergency-contact` → `{"name": str, "phone": str}`.

- [ ] **Step 1: Add the columns**

In `backend/app/models.py`, in the `Case` class, add after `status`:
```python
    emergency_contact_name: Mapped[str | None] = mapped_column(String, nullable=True)
    emergency_contact_phone: Mapped[str | None] = mapped_column(String, nullable=True)
```

- [ ] **Step 2: Update schemas**

In `backend/app/schemas.py`, change `CaseCreate` to:
```python
class CaseCreate(BaseModel):
    patient_id: str
    surgery_type: str
    emergency_contact_name: str | None = None
    emergency_contact_phone: str | None = None
```
and add the two fields to `CaseResponse` (after `status`):
```python
    emergency_contact_name: str | None
    emergency_contact_phone: str | None
```

- [ ] **Step 3: Write the failing tests**

Create `backend/tests/test_emergency_contact.py`:
```python
from app import models
from app.security import create_access_token


def test_create_case_defaults_emergency_contact_to_clinician(client, db_session):
    clinician = models.User(
        email="c@t.com", full_name="Dr. Clinician", role=models.UserRole.clinician,
    )
    patient = models.User(email="p@t.com", full_name="P", role=models.UserRole.patient)
    db_session.add_all([clinician, patient])
    db_session.commit()

    token = create_access_token({"sub": clinician.id, "role": "clinician", "email": clinician.email})
    response = client.post(
        "/cases/",
        json={"patient_id": patient.id, "surgery_type": "knee"},
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 200
    body = response.json()
    assert body["emergency_contact_name"] == "Dr. Clinician"


def test_emergency_contact_endpoint_returns_name_and_phone(client, db_session):
    clinician = models.User(
        email="c@t.com", full_name="Dr. Clinician", role=models.UserRole.clinician,
    )
    patient = models.User(email="p@t.com", full_name="P", role=models.UserRole.patient)
    db_session.add_all([clinician, patient])
    db_session.commit()

    case = models.Case(
        clinician_id=clinician.id, patient_id=patient.id, surgery_type="knee",
        emergency_contact_name="Dr. Clinician", emergency_contact_phone="+1-555-0100",
    )
    db_session.add(case)
    db_session.commit()
    db_session.refresh(case)

    token = create_access_token({"sub": patient.id, "role": "patient", "email": patient.email})
    response = client.get(
        f"/cases/{case.id}/emergency-contact",
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 200
    assert response.json() == {"name": "Dr. Clinician", "phone": "+1-555-0100"}
```

- [ ] **Step 4: Run tests to verify they fail**

Run: `cd /Users/flavius/OPIT/git/uep2026/backend && python -m pytest tests/test_emergency_contact.py -v`
Expected: FAIL — response missing `emergency_contact_name` key, and `404` on the new route.

- [ ] **Step 5: Implement**

In `backend/app/routers/cases.py`, change `create_case`:
```python
@router.post("/")
def create_case(
    case: schemas.CaseCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):

    new_case = models.Case(
        clinician_id=current_user.id,
        patient_id=case.patient_id,
        surgery_type=case.surgery_type,
        emergency_contact_name=case.emergency_contact_name or current_user.full_name,
        emergency_contact_phone=case.emergency_contact_phone,
    )

    db.add(new_case)
    db.commit()
    db.refresh(new_case)

    return new_case
```

And add a new route at the end of the file:
```python
@router.get("/{case_id}/emergency-contact")
def get_emergency_contact(
    case_id: str,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    case = db.query(models.Case).filter(models.Case.id == case_id).first()

    if not case:
        raise HTTPException(status_code=404, detail="Case not found")

    return {
        "name": case.emergency_contact_name,
        "phone": case.emergency_contact_phone,
    }
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `cd /Users/flavius/OPIT/git/uep2026/backend && python -m pytest tests/test_emergency_contact.py -v`
Expected: `2 passed`.

- [ ] **Step 7: Generate and apply the migration**

Run:
```bash
cd /Users/flavius/OPIT/git/uep2026/backend && alembic revision --autogenerate -m "add case emergency contact"
alembic upgrade head
```
Expected: migration created and applied with no errors.

Do not commit.

---

## Task 19: Full regression pass

**Files:** none (verification only).

- [ ] **Step 1: Run the entire test suite**

Run: `cd /Users/flavius/OPIT/git/uep2026/backend && python -m pytest -v`
Expected: all tests pass (unit tests; Postgres-only RLS test auto-skips without a `postgresql://` `DATABASE_URL`).

- [ ] **Step 2: Run the Postgres-dependent tests against the dev container**

Run:
```bash
cd /Users/flavius/OPIT/git/uep2026 && docker compose up -d --build
sleep 5
cd backend && DATABASE_URL=postgresql://caredev:caredev@localhost:5432/remotecare python -m pytest -v
```
Expected: all tests pass, including `test_rls_policies.py`.

- [ ] **Step 3: Confirm formatting is clean**

Run: `cd /Users/flavius/OPIT/git/uep2026/backend && black --check app tests && ruff check app tests`
Expected: no output from black (already formatted), `All checks passed!` from ruff.

- [ ] **Step 4: Confirm the seed script + a full manual smoke flow**

Run:
```bash
docker compose exec backend python -m app.scripts.seed
curl -s -X POST http://localhost:8000/auth/dev-login -H "Content-Type: application/json" \
  -d '{"email":"clinician@remotecarepro.dev","password":"clinician1234"}'
```
Expected: seed prints credentials; login returns a JWT.

Leave everything in the working tree uncommitted — this task only verifies, it makes no file changes.
