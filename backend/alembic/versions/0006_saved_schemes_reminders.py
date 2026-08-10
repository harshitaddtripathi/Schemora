"""Create saved_schemes, scheme_reminders, and analytics_events tables

Revision ID: 0006_saved_schemes_reminders
Revises: 0005_user_documents
Create Date: 2026-08-10 15:00:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

revision: str = '0006_saved_schemes_reminders'
down_revision: Union[str, None] = '0005_user_documents'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        'saved_schemes',
        sa.Column('id', sa.String(length=64), nullable=False),
        sa.Column('user_id', sa.String(length=64), nullable=False),
        sa.Column('scheme_id', sa.String(length=64), nullable=False),
        sa.Column('status', sa.String(length=64), nullable=False, server_default='Saved'),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['scheme_id'], ['schemes.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_saved_schemes_scheme_id'), 'saved_schemes', ['scheme_id'], unique=False)
    op.create_index(op.f('ix_saved_schemes_user_id'), 'saved_schemes', ['user_id'], unique=False)

    op.create_table(
        'scheme_reminders',
        sa.Column('id', sa.String(length=64), nullable=False),
        sa.Column('user_id', sa.String(length=64), nullable=False),
        sa.Column('scheme_id', sa.String(length=64), nullable=False),
        sa.Column('title', sa.String(length=256), nullable=False),
        sa.Column('reminder_date', sa.DateTime(timezone=True), nullable=False),
        sa.Column('is_completed', sa.Boolean(), nullable=False, server_default='0'),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['scheme_id'], ['schemes.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_scheme_reminders_scheme_id'), 'scheme_reminders', ['scheme_id'], unique=False)
    op.create_index(op.f('ix_scheme_reminders_user_id'), 'scheme_reminders', ['user_id'], unique=False)

    op.create_table(
        'analytics_events',
        sa.Column('id', sa.String(length=64), nullable=False),
        sa.Column('user_id', sa.String(length=64), nullable=True),
        sa.Column('scheme_id', sa.String(length=64), nullable=True),
        sa.Column('event_type', sa.String(length=64), nullable=False),
        sa.Column('metadata_json', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='SET NULL'),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_analytics_events_scheme_id'), 'analytics_events', ['scheme_id'], unique=False)
    op.create_index(op.f('ix_analytics_events_user_id'), 'analytics_events', ['user_id'], unique=False)


def downgrade() -> None:
    op.drop_index(op.f('ix_analytics_events_user_id'), table_name='analytics_events')
    op.drop_index(op.f('ix_analytics_events_scheme_id'), table_name='analytics_events')
    op.drop_table('analytics_events')
    op.drop_index(op.f('ix_scheme_reminders_user_id'), table_name='scheme_reminders')
    op.drop_index(op.f('ix_scheme_reminders_scheme_id'), table_name='scheme_reminders')
    op.drop_table('scheme_reminders')
    op.drop_index(op.f('ix_saved_schemes_user_id'), table_name='saved_schemes')
    op.drop_index(op.f('ix_saved_schemes_scheme_id'), table_name='saved_schemes')
    op.drop_table('saved_schemes')
