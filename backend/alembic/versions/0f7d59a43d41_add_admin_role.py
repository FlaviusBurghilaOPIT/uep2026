"""add admin role

Revision ID: 0f7d59a43d41
Revises: 1b0581fc4e9c
Create Date: 2026-07-10 20:05:54.083685

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '0f7d59a43d41'
down_revision: Union[str, Sequence[str], None] = '1b0581fc4e9c'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute("ALTER TYPE userrole ADD VALUE IF NOT EXISTS 'admin'")


def downgrade() -> None:
    # Postgres cannot drop a single enum value; downgrade is a no-op by design.
    pass
