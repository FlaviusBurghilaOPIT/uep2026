import os
from urllib.parse import urlsplit, urlunsplit

import pytest
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker

pytestmark = pytest.mark.skipif(
    "postgresql" not in os.getenv("DATABASE_URL", ""),
    reason="RLS policies only exist on Postgres; run with the dev docker-compose db up",
)

# The migration's RLS policies apply to any ordinary (non-superuser,
# non-bypassrls) role. The dev docker-compose Postgres creates its
# POSTGRES_USER as the bootstrap superuser, which Postgres *always* lets
# bypass row security -- so exercising RLS requires connecting as the
# dedicated `remotecare_app` role the migration creates for exactly this
# purpose, rather than as the bootstrap user in DATABASE_URL.
APP_ROLE_USER = "remotecare_app"
APP_ROLE_PASSWORD = os.getenv("POSTGRES_APP_PASSWORD", "dev-only-change-in-prod")


def _app_role_url(admin_url: str) -> str:
    parts = urlsplit(admin_url)
    netloc = f"{APP_ROLE_USER}:{APP_ROLE_PASSWORD}@{parts.hostname}"
    if parts.port:
        netloc += f":{parts.port}"
    return urlunsplit((parts.scheme, netloc, parts.path, parts.query, parts.fragment))


@pytest.fixture()
def pg_session():
    """Bootstrap/admin connection, used only to seed fixture data.

    This role bypasses RLS (it's the docker-compose superuser), which is
    fine for seeding -- the isolation assertions below run over a separate
    connection as the non-privileged `remotecare_app` role.
    """
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


def test_patient_cannot_see_other_patients_case(pg_session, app_session):
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

    app_session.execute(text("SET LOCAL \"app.current_role\" = 'patient'"))
    app_session.execute(text("SET LOCAL app.current_user_id = 'pat-2'"))
    rows = app_session.execute(text("SELECT id FROM cases WHERE id = 'case-1'")).fetchall()
    assert rows == []

    app_session.execute(text("SET LOCAL \"app.current_role\" = 'patient'"))
    app_session.execute(text("SET LOCAL app.current_user_id = 'pat-1'"))
    rows = app_session.execute(text("SELECT id FROM cases WHERE id = 'case-1'")).fetchall()
    assert len(rows) == 1
