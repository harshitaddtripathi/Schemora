"""Initial schema baseline

Revision ID: 0001_initial_schema
Revises: 
Create Date: 2026-08-10 10:00:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

revision: str = '0001_initial_schema'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Baseline migration placeholder for Phase 1
    pass


def downgrade() -> None:
    pass
