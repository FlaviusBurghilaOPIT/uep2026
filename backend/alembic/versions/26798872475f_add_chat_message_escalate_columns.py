"""add chat message escalate columns

Revision ID: 26798872475f
Revises: 1ba1b1353734
Create Date: 2026-07-22 12:15:56.803659

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '26798872475f'
down_revision: Union[str, Sequence[str], None] = '1ba1b1353734'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.add_column(
        'chat_messages',
        sa.Column('in_scope', sa.Boolean(), nullable=False, server_default=sa.true()),
    )
    op.add_column(
        'chat_messages',
        sa.Column('escalate', sa.Boolean(), nullable=False, server_default=sa.false()),
    )


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_column('chat_messages', 'escalate')
    op.drop_column('chat_messages', 'in_scope')
