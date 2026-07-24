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
