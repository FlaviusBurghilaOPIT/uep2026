"""RLS policy tests for the adherence tables (WI 06).

Covers scheduled_reminders, dose_logs, dose_log_events -- the three tables
given policies by alembic revision d6a7b8c9e0f1. Mirrors the convention from
tests/test_rls_policies.py: the whole module skips unless a real Postgres
(reachable via DATABASE_URL, with the remotecare_app role) is available,
because SQLite cannot enforce RLS.

Run against the Docker stack:
    docker compose up -d db
    cd backend && alembic upgrade head
    python3 -m pytest tests/test_rls_adherence_policies.py -q
"""
import os
from urllib.parse import urlsplit, urlunsplit

import pytest
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker

# See tests/test_rls_policies.py: RLS can only be exercised as the ordinary
# (non-superuser, non-bypassrls) remotecare_app role the RLS migration
# creates; the docker-compose bootstrap user always bypasses row security.
APP_ROLE_USER = "remotecare_app"
APP_ROLE_PASSWORD = os.getenv("POSTGRES_APP_PASSWORD", "dev-only-change-in-prod")


def _app_role_url(admin_url: str) -> str:
    parts = urlsplit(admin_url)
    netloc = f"{APP_ROLE_USER}:{APP_ROLE_PASSWORD}@{parts.hostname}"
    if parts.port:
        netloc += f":{parts.port}"
    return urlunsplit((parts.scheme, netloc, parts.path, parts.query, parts.fragment))


def _is_postgres_available() -> bool:
    db_url = os.getenv("DATABASE_URL", "")
    if "postgresql" not in db_url:
        return False
    try:
        engine = create_engine(_app_role_url(db_url), connect_args={"connect_timeout": 2})
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        return True
    except Exception:
        return False


pytestmark = pytest.mark.skipif(
    not _is_postgres_available(),
    reason="RLS policies require a running PostgreSQL instance with remotecare_app role",
)

@pytest.fixture()
def pg_session():
    """Bootstrap/admin connection (bypasses RLS) -- fixture seeding only."""
    engine = create_engine(os.environ["DATABASE_URL"])
    Session = sessionmaker(bind=engine)
    session = Session()
    yield session
    session.close()


@pytest.fixture()
def app_session():
    engine = create_engine(_app_role_url(os.environ["DATABASE_URL"]))
    Session = sessionmaker(bind=engine)
    session = Session()
    yield session
    session.close()


@pytest.fixture()
def adherence_seed(pg_session):
    """Two clinicians/patients, one case each, one medication + reminder +
    dose log + event per case. ON CONFLICT DO NOTHING keeps it rerunnable."""
    pg_session.execute(
        text(
            "INSERT INTO users (id, email, full_name, role, created_at) VALUES "
            "('rls-adh-clin-1', 'rls-adh-c1@t.com', 'Clin One', 'clinician', now()), "
            "('rls-adh-pat-1', 'rls-adh-p1@t.com', 'Pat One', 'patient', now()), "
            "('rls-adh-pat-2', 'rls-adh-p2@t.com', 'Pat Two', 'patient', now()) "
            "ON CONFLICT (id) DO NOTHING"
        )
    )
    pg_session.execute(
        text(
            "INSERT INTO cases (id, clinician_id, patient_id, surgery_type, status, created_at) "
            "VALUES "
            "('rls-adh-case-1', 'rls-adh-clin-1', 'rls-adh-pat-1', 'knee', 'active', now()), "
            "('rls-adh-case-2', 'rls-adh-clin-1', 'rls-adh-pat-2', 'hip', 'active', now()) "
            "ON CONFLICT (id) DO NOTHING"
        )
    )
    pg_session.execute(
        text(
            "INSERT INTO medications (id, case_id, name, dose, schedule_text, duration, "
            "created_at) VALUES "
            "('rls-adh-med-1', 'rls-adh-case-1', 'Ibuprofen', '400 mg', 'QD', '7 days', now()), "
            "('rls-adh-med-2', 'rls-adh-case-2', 'Tramadol', '50 mg', 'BID', '5 days', now()) "
            "ON CONFLICT (id) DO NOTHING"
        )
    )
    pg_session.execute(
        text(
            "INSERT INTO scheduled_reminders (id, medication_id, scheduled_time, status, "
            "created_at) VALUES "
            "('rls-adh-rem-1', 'rls-adh-med-1', now(), 'pending', now()), "
            "('rls-adh-rem-2', 'rls-adh-med-2', now(), 'pending', now()) "
            "ON CONFLICT (id) DO NOTHING"
        )
    )
    pg_session.execute(
        text(
            "INSERT INTO dose_logs (id, scheduled_reminder_id, status, logged_at) VALUES "
            "('rls-adh-log-1', 'rls-adh-rem-1', 'taken', now()), "
            "('rls-adh-log-2', 'rls-adh-rem-2', 'taken', now()) "
            "ON CONFLICT (id) DO NOTHING"
        )
    )
    pg_session.execute(
        text(
            "INSERT INTO dose_log_events (id, dose_log_id, old_status, new_status, changed_at) "
            "VALUES "
            "('rls-adh-evt-1', 'rls-adh-log-1', 'pending', 'taken', now()), "
            "('rls-adh-evt-2', 'rls-adh-log-2', 'pending', 'taken', now()) "
            "ON CONFLICT (id) DO NOTHING"
        )
    )
    pg_session.commit()
    yield
    for stmt in (
        "DELETE FROM dose_log_events WHERE id IN ('rls-adh-evt-1', 'rls-adh-evt-2')",
        "DELETE FROM dose_logs WHERE id IN ('rls-adh-log-1', 'rls-adh-log-2')",
        "DELETE FROM scheduled_reminders WHERE id IN ('rls-adh-rem-1', 'rls-adh-rem-2')",
        "DELETE FROM medications WHERE id IN ('rls-adh-med-1', 'rls-adh-med-2')",
        "DELETE FROM cases WHERE id IN ('rls-adh-case-1', 'rls-adh-case-2')",
        "DELETE FROM users WHERE id IN "
        "('rls-adh-clin-1', 'rls-adh-pat-1', 'rls-adh-pat-2')",
    ):
        pg_session.execute(text(stmt))
    pg_session.commit()


def _as_user(app_session, user_id: str, role: str = "patient"):
    app_session.execute(text(f'SET LOCAL "app.current_role" = \'{role}\''))
    app_session.execute(text(f"SET LOCAL app.current_user_id = '{user_id}'"))


def test_cross_patient_select_returns_zero_rows(pg_session, app_session, adherence_seed):
    _as_user(app_session, "rls-adh-pat-2")
    for table, pk in (
        ("scheduled_reminders", "rls-adh-rem-1"),
        ("dose_logs", "rls-adh-log-1"),
        ("dose_log_events", "rls-adh-evt-1"),
    ):
        rows = app_session.execute(
            text(f"SELECT id FROM {table} WHERE id = '{pk}'")
        ).fetchall()
        assert rows == [], f"{table}: cross-patient row visible under RLS"


def test_own_rows_visible_and_other_case_hidden(pg_session, app_session, adherence_seed):
    _as_user(app_session, "rls-adh-pat-1")
    for table, own, other in (
        ("scheduled_reminders", "rls-adh-rem-1", "rls-adh-rem-2"),
        ("dose_logs", "rls-adh-log-1", "rls-adh-log-2"),
        ("dose_log_events", "rls-adh-evt-1", "rls-adh-evt-2"),
    ):
        rows = {
            r[0]
            for r in app_session.execute(
                text(f"SELECT id FROM {table} WHERE id IN ('{own}', '{other}')")
            ).fetchall()
        }
        assert rows == {own}, f"{table}: expected only own row, got {rows}"


def test_case_clinician_sees_both_patients_rows(pg_session, app_session, adherence_seed):
    _as_user(app_session, "rls-adh-clin-1", role="clinician")
    for table, ids in (
        ("scheduled_reminders", ("rls-adh-rem-1", "rls-adh-rem-2")),
        ("dose_logs", ("rls-adh-log-1", "rls-adh-log-2")),
        ("dose_log_events", ("rls-adh-evt-1", "rls-adh-evt-2")),
    ):
        rows = {
            r[0]
            for r in app_session.execute(
                text(f"SELECT id FROM {table} WHERE id IN ('{ids[0]}', '{ids[1]}')")
            ).fetchall()
        }
        assert rows == set(ids), f"{table}: clinician should see both cases' rows"


def test_new_columns_present(pg_session, adherence_seed):
    cols = {
        r[0]
        for r in pg_session.execute(
            text(
                "SELECT column_name FROM information_schema.columns "
                "WHERE table_name IN ('dose_logs', 'medications', 'scheduled_reminders')"
            )
        ).fetchall()
    }
    assert {"corrected_at", "discontinued_at", "idempotency_key"} <= cols
