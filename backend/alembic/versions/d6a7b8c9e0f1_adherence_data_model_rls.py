"""adherence data model + RLS (dose_log_events, corrected_at, discontinued_at, idempotency_key)

Revision ID: d6a7b8c9e0f1
Revises: b2c3d4e5f6a7
Create Date: 2026-07-26

Work Item: ai_specs/work-items/06-adherence-data-model-rls-migration.md
Parent spec: ai_specs/2026-07-26-adherence-pipeline-backend-spec.md §7

RLS verification convention (blocking decision, resolved): the repo's
convention for Postgres-backed RLS tests is the skipif-gated pytest module
pattern established in tests/test_rls_policies.py -- the new
tests/test_rls_adherence_policies.py follows it. These tests no-op (skip)
without a live Postgres and must be run against the Docker stack; SQLite
cannot enforce RLS.
"""
from typing import Sequence, Union

import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "d6a7b8c9e0f1"
down_revision: Union[str, Sequence[str], None] = "b2c3d4e5f6a7"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

# The 'dosestatus' enum type already exists (created by
# 927669cf1a68_initial_models.py for dose_logs.status) -- reference it
# without attempting to CREATE TYPE again.
DOSESTATUS = postgresql.ENUM(
    "pending", "taken", "missed", "skipped", name="dosestatus", create_type=False
)


def upgrade() -> None:
    # dose_log_events is append-only by convention: application code only
    # ever INSERTs (correction audit trail); no UPDATE/DELETE paths exist.
    op.create_table(
        "dose_log_events",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("dose_log_id", sa.String(), nullable=False),
        sa.Column("old_status", DOSESTATUS, nullable=False),
        sa.Column("new_status", DOSESTATUS, nullable=False),
        sa.Column("changed_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(["dose_log_id"], ["dose_logs.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "ix_dose_log_events_dose_log_id", "dose_log_events", ["dose_log_id"]
    )
    # DML grants for the remotecare_app role come from the ALTER DEFAULT
    # PRIVILEGES set by 1ba1b1353734 (migration role = table owner), so no
    # explicit GRANT is needed for this new table.

    op.add_column("dose_logs", sa.Column("corrected_at", sa.DateTime(), nullable=True))
    op.add_column(
        "medications", sa.Column("discontinued_at", sa.DateTime(), nullable=True)
    )
    op.add_column(
        "scheduled_reminders", sa.Column("idempotency_key", sa.String(), nullable=True)
    )
    # Postgres treats NULLs as distinct, so only real keys collide.
    op.create_index(
        "ix_scheduled_reminders_idempotency_key",
        "scheduled_reminders",
        ["idempotency_key"],
        unique=True,
    )

    # RLS -- mirrors 1cee36bcbdad_enable_rls.py (ENABLE + FORCE + policy),
    # extended with a two-level join chain to cases.(clinician_id|patient_id).
    # FORCE is required because the app may connect as the owning role;
    # Postgres exempts owners from RLS unless FORCE is set.
    op.execute("ALTER TABLE scheduled_reminders ENABLE ROW LEVEL SECURITY")
    op.execute("ALTER TABLE scheduled_reminders FORCE ROW LEVEL SECURITY")
    op.execute(
        """
        CREATE POLICY scheduled_reminders_case_access ON scheduled_reminders
        USING (
            current_setting('app.current_role', true) = 'admin'
            OR medication_id IN (
                SELECT m.id FROM medications m
                JOIN cases c ON m.case_id = c.id
                WHERE c.clinician_id = current_setting('app.current_user_id', true)
                   OR c.patient_id = current_setting('app.current_user_id', true)
            )
        )
        """
    )

    op.execute("ALTER TABLE dose_logs ENABLE ROW LEVEL SECURITY")
    op.execute("ALTER TABLE dose_logs FORCE ROW LEVEL SECURITY")
    op.execute(
        """
        CREATE POLICY dose_logs_case_access ON dose_logs
        USING (
            current_setting('app.current_role', true) = 'admin'
            OR scheduled_reminder_id IN (
                SELECT sr.id FROM scheduled_reminders sr
                JOIN medications m ON sr.medication_id = m.id
                JOIN cases c ON m.case_id = c.id
                WHERE c.clinician_id = current_setting('app.current_user_id', true)
                   OR c.patient_id = current_setting('app.current_user_id', true)
            )
        )
        """
    )

    op.execute("ALTER TABLE dose_log_events ENABLE ROW LEVEL SECURITY")
    op.execute("ALTER TABLE dose_log_events FORCE ROW LEVEL SECURITY")
    op.execute(
        """
        CREATE POLICY dose_log_events_case_access ON dose_log_events
        USING (
            current_setting('app.current_role', true) = 'admin'
            OR dose_log_id IN (
                SELECT dl.id FROM dose_logs dl
                JOIN scheduled_reminders sr ON dl.scheduled_reminder_id = sr.id
                JOIN medications m ON sr.medication_id = m.id
                JOIN cases c ON m.case_id = c.id
                WHERE c.clinician_id = current_setting('app.current_user_id', true)
                   OR c.patient_id = current_setting('app.current_user_id', true)
            )
        )
        """
    )


def downgrade() -> None:
    op.execute("DROP POLICY IF EXISTS dose_log_events_case_access ON dose_log_events")
    op.execute("ALTER TABLE dose_log_events DISABLE ROW LEVEL SECURITY")
    op.execute("DROP POLICY IF EXISTS dose_logs_case_access ON dose_logs")
    op.execute("ALTER TABLE dose_logs DISABLE ROW LEVEL SECURITY")
    op.execute(
        "DROP POLICY IF EXISTS scheduled_reminders_case_access ON scheduled_reminders"
    )
    op.execute("ALTER TABLE scheduled_reminders DISABLE ROW LEVEL SECURITY")

    op.drop_index(
        "ix_scheduled_reminders_idempotency_key", table_name="scheduled_reminders"
    )
    op.drop_column("scheduled_reminders", "idempotency_key")
    op.drop_column("medications", "discontinued_at")
    op.drop_column("dose_logs", "corrected_at")
    op.drop_index("ix_dose_log_events_dose_log_id", table_name="dose_log_events")
    op.drop_table("dose_log_events")
