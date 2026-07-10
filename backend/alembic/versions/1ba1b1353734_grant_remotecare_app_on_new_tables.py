"""grant remotecare_app on new tables

Revision ID: 1ba1b1353734
Revises: 137b46a7e768
Create Date: 2026-07-10 22:15:35.620522

"""
import os
from typing import Sequence, Union

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "1ba1b1353734"
down_revision: Union[str, Sequence[str], None] = "137b46a7e768"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

APP_ROLE = "remotecare_app"

# The role migrations run/connect as (docker-compose's POSTGRES_USER, which
# owns every table created via `alembic upgrade`). `GRANT ... ON ALL TABLES
# IN SCHEMA public` in 1cee36bcbdad_enable_rls.py only covered tables that
# existed at the time it ran -- tables created by LATER migrations
# (fda_warnings, case_fda_warnings, wiki_articles) never got the grant,
# which is why the app role hits `permission denied for table` on them.
# Reading this from an env var (not request/user input) mirrors the
# APP_ROLE_PASSWORD pattern in 1cee36bcbdad_enable_rls.py.
MIGRATION_ROLE = os.getenv("POSTGRES_USER", "caredev")

NEW_TABLES = [
    "fda_warnings",
    "case_fda_warnings",
    "wiki_articles",
]


def upgrade() -> None:
    # 1. Re-grant on the specific tables that were created after the RLS
    #    migration's blanket GRANT already ran, and so missed it.
    for table in NEW_TABLES:
        op.execute(f"GRANT SELECT, INSERT, UPDATE, DELETE ON {table} TO {APP_ROLE}")

    # 2. Make sure this never has to happen again: any table the migration
    #    role creates from now on automatically grants remotecare_app DML,
    #    with no separate re-grant migration required.
    op.execute(
        f"ALTER DEFAULT PRIVILEGES FOR ROLE {MIGRATION_ROLE} IN SCHEMA public "
        f"GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO {APP_ROLE}"
    )


def downgrade() -> None:
    op.execute(
        f"ALTER DEFAULT PRIVILEGES FOR ROLE {MIGRATION_ROLE} IN SCHEMA public "
        f"REVOKE SELECT, INSERT, UPDATE, DELETE ON TABLES FROM {APP_ROLE}"
    )
    for table in NEW_TABLES:
        op.execute(f"REVOKE SELECT, INSERT, UPDATE, DELETE ON {table} FROM {APP_ROLE}")
