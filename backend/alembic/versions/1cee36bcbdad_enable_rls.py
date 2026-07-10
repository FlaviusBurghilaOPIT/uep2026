"""enable rls

Revision ID: 1cee36bcbdad
Revises: 0f7d59a43d41
Create Date: 2026-07-10

"""
import os

from alembic import op

revision = "1cee36bcbdad"
down_revision = "0f7d59a43d41"
branch_labels = None
depends_on = None

TABLES_VIA_CASE_ID = [
    "medications",
    "recommendations",
    "checkins",
    "chat_messages",
]


APP_ROLE = "remotecare_app"
# Migration-time code reading a trusted env var (not runtime SQL built from
# untrusted/request input), so an f-string is acceptable here -- just avoid a
# password value containing a `'`, which would break out of the literal.
APP_ROLE_PASSWORD = os.getenv("POSTGRES_APP_PASSWORD", "dev-only-change-in-prod")


def upgrade() -> None:
    # Postgres never enforces RLS for a superuser connection, no matter what
    # FORCE ROW LEVEL SECURITY says (superusers unconditionally bypass RLS,
    # and the bootstrap/POSTGRES_USER role that docker-compose creates for
    # this dev Postgres cannot have SUPERUSER stripped from it). Create a
    # dedicated, ordinary (non-superuser, non-bypassrls) login role that is
    # subject to RLS, and grant it the DML it needs on the RLS-covered
    # tables. Application code that wants RLS enforcement must connect as
    # this role rather than the bootstrap superuser -- see the RLS gap note
    # in the README (Task 12) for the follow-up needed to point the app's
    # own DATABASE_URL at this role in this dev environment.
    op.execute(
        f"""
        DO $$
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '{APP_ROLE}') THEN
                CREATE ROLE {APP_ROLE} LOGIN PASSWORD '{APP_ROLE_PASSWORD}' NOSUPERUSER NOBYPASSRLS;
            ELSE
                ALTER ROLE {APP_ROLE} PASSWORD '{APP_ROLE_PASSWORD}';
            END IF;
        END $$;
        """
    )
    op.execute(f"GRANT USAGE ON SCHEMA public TO {APP_ROLE}")
    op.execute(
        f"GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO {APP_ROLE}"
    )

    op.execute("ALTER TABLE cases ENABLE ROW LEVEL SECURITY")
    # FORCE is required because the app connects as the tables' owning role;
    # Postgres exempts owners from RLS unless FORCE is set, which would make
    # the policies a silent no-op for the app's own connections.
    op.execute("ALTER TABLE cases FORCE ROW LEVEL SECURITY")
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
        op.execute(f"ALTER TABLE {table} FORCE ROW LEVEL SECURITY")
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

    op.execute(
        f"""
        DO $$
        BEGIN
            IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '{APP_ROLE}') THEN
                EXECUTE 'REASSIGN OWNED BY {APP_ROLE} TO CURRENT_USER';
                EXECUTE 'DROP OWNED BY {APP_ROLE}';
                EXECUTE 'DROP ROLE {APP_ROLE}';
            END IF;
        END $$;
        """
    )
