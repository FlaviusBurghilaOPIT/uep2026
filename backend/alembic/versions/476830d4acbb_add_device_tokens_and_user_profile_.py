"""add device tokens and user profile fields

Revision ID: 476830d4acbb
Revises: e47f0e02fdff
Create Date: 2026-08-16 16:06:21.174544

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "476830d4acbb"
down_revision: Union[str, Sequence[str], None] = "e47f0e02fdff"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""

    op.create_table(
        "device_tokens",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("user_id", sa.String(), nullable=False),
        sa.Column("token", sa.String(length=512), nullable=False),
        sa.Column("platform", sa.String(length=32), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
    )

    op.create_index(
        "ix_device_tokens_token",
        "device_tokens",
        ["token"],
        unique=True,
    )

    op.add_column(
        "users",
        sa.Column("invite_code", sa.String(), nullable=True),
    )

    op.add_column(
        "users",
        sa.Column("status", sa.String(), nullable=False, server_default="active"),
    )

    op.add_column(
        "users",
        sa.Column("phone", sa.String(), nullable=True),
    )

    op.add_column(
        "users",
        sa.Column("date_of_birth", sa.String(), nullable=True),
    )


def downgrade() -> None:
    """Downgrade schema."""

    op.drop_column("users", "date_of_birth")
    op.drop_column("users", "phone")
    op.drop_column("users", "status")
    op.drop_column("users", "invite_code")

    op.drop_index(
        "ix_device_tokens_token",
        table_name="device_tokens",
    )

    op.drop_table("device_tokens")

