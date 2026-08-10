"""Create scheme catalog, rules, and sources tables

Revision ID: 0003_scheme_catalog
Revises: 0002_users_and_student_profiles
Create Date: 2026-08-10 12:00:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

revision: str = '0003_scheme_catalog'
down_revision: Union[str, None] = '0002_users_and_student_profiles'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        'schemes',
        sa.Column('id', sa.String(length=64), nullable=False),
        sa.Column('slug', sa.String(length=128), nullable=False),
        sa.Column('title', sa.String(length=256), nullable=False),
        sa.Column('short_description', sa.Text(), nullable=False),
        sa.Column('detailed_description', sa.Text(), nullable=True),
        sa.Column('provider', sa.String(length=128), nullable=False),
        sa.Column('jurisdiction', sa.String(length=32), nullable=False),
        sa.Column('state', sa.String(length=64), nullable=True),
        sa.Column('gender_eligibility', sa.String(length=32), nullable=False, server_default='All'),
        sa.Column('social_categories', sa.String(length=128), nullable=False, server_default='All'),
        sa.Column('min_age', sa.Float(), nullable=True),
        sa.Column('max_age', sa.Float(), nullable=True),
        sa.Column('max_family_income', sa.Float(), nullable=True),
        sa.Column('benefit_type', sa.String(length=64), nullable=False, server_default='Financial'),
        sa.Column('benefit_amount', sa.Float(), nullable=True),
        sa.Column('benefit_summary', sa.Text(), nullable=False),
        sa.Column('implementation_status', sa.String(length=32), nullable=False, server_default='Implemented'),
        sa.Column('is_published', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('application_deadline', sa.String(length=64), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_schemes_slug'), 'schemes', ['slug'], unique=True)

    op.create_table(
        'scheme_rules',
        sa.Column('id', sa.String(length=64), nullable=False),
        sa.Column('scheme_id', sa.String(length=64), nullable=False),
        sa.Column('rule_id', sa.String(length=64), nullable=False),
        sa.Column('field_name', sa.String(length=64), nullable=False),
        sa.Column('operator', sa.String(length=32), nullable=False),
        sa.Column('expected_value', sa.Text(), nullable=False),
        sa.Column('rule_type', sa.String(length=32), nullable=False, server_default='mandatory'),
        sa.Column('failure_reason', sa.Text(), nullable=True),
        sa.ForeignKeyConstraint(['scheme_id'], ['schemes.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_scheme_rules_scheme_id'), 'scheme_rules', ['scheme_id'], unique=False)

    op.create_table(
        'scheme_sources',
        sa.Column('id', sa.String(length=64), nullable=False),
        sa.Column('scheme_id', sa.String(length=64), nullable=False),
        sa.Column('source_name', sa.String(length=256), nullable=False),
        sa.Column('url', sa.Text(), nullable=False),
        sa.Column('source_type', sa.String(length=64), nullable=False, server_default='OfficialPortal'),
        sa.Column('last_verified_at', sa.String(length=32), nullable=True),
        sa.ForeignKeyConstraint(['scheme_id'], ['schemes.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_scheme_sources_scheme_id'), 'scheme_sources', ['scheme_id'], unique=False)


def downgrade() -> None:
    op.drop_index(op.f('ix_scheme_sources_scheme_id'), table_name='scheme_sources')
    op.drop_table('scheme_sources')
    op.drop_index(op.f('ix_scheme_rules_scheme_id'), table_name='scheme_rules')
    op.drop_table('scheme_rules')
    op.drop_index(op.f('ix_schemes_slug'), table_name='schemes')
    op.drop_table('schemes')
