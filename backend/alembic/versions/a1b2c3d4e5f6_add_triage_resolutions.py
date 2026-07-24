"""add triage resolutions

Revision ID: a1b2c3d4e5f6
Revises: f4a9c7d21b3e
Create Date: 2026-07-25 00:10:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'a1b2c3d4e5f6'
down_revision: Union[str, Sequence[str], None] = 'f4a9c7d21b3e'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.create_table(
        'triage_resolutions',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('patient_id', sa.String(), nullable=False),
        sa.Column('clinician_id', sa.String(), nullable=False),
        sa.Column('outreach_method', sa.String(), nullable=False),
        sa.Column('clinical_note', sa.Text(), nullable=False),
        sa.Column('resolved_at', sa.DateTime(), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['patient_id'], ['users.id']),
        sa.ForeignKeyConstraint(['clinician_id'], ['users.id']),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(
        'ix_triage_resolutions_patient_id', 'triage_resolutions', ['patient_id']
    )


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_index('ix_triage_resolutions_patient_id', table_name='triage_resolutions')
    op.drop_table('triage_resolutions')
