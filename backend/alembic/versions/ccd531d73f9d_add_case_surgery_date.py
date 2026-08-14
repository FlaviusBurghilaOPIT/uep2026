"""add case surgery_date

Revision ID: ccd531d73f9d
Revises: d6a7b8c9e0f1
Create Date: 2026-08-01

Work Item: ai_specs/0002-patient-experience-server-truth-hybrid-auth/
           work-items/02-backend-intake-data-model.md
Parent spec: ai_specs/0002-patient-experience-server-truth-hybrid-auth/spec.md
             (Req 8, 16)

Adds a nullable ``surgery_date`` to ``cases``. It is captured at clinician
intake for newly created cases; existing/seeded cases pre-date it and remain
valid with NULL. No RLS/grant changes are needed -- the column is added to an
existing table whose policies and privileges are already in place.
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'ccd531d73f9d'
down_revision: Union[str, Sequence[str], None] = 'd6a7b8c9e0f1'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.add_column('cases', sa.Column('surgery_date', sa.String(), nullable=True))


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_column('cases', 'surgery_date')
