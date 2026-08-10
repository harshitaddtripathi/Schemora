"""Create users and student_profiles tables

Revision ID: 0002_users_and_student_profiles
Revises: 0001_initial_schema
Create Date: 2026-08-10 11:00:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

revision: str = '0002_users_and_student_profiles'
down_revision: Union[str, None] = '0001_initial_schema'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        'users',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('firebase_uid', sa.String(length=128), nullable=False),
        sa.Column('phone_number', sa.String(length=32), nullable=True),
        sa.Column('role', sa.String(length=32), nullable=False, server_default='citizen'),
        sa.Column('is_active', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('phone_number'),
    )
    op.create_index(op.f('ix_users_firebase_uid'), 'users', ['firebase_uid'], unique=True)

    op.create_table(
        'student_profiles',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('user_id', sa.String(length=36), nullable=False),
        sa.Column('full_name', sa.String(length=128), nullable=False),
        sa.Column('date_of_birth', sa.Date(), nullable=False),
        sa.Column('gender', sa.String(length=32), nullable=False),
        sa.Column('state', sa.String(length=64), nullable=False),
        sa.Column('education_level', sa.String(length=64), nullable=False),
        sa.Column('course_name', sa.String(length=128), nullable=True),
        sa.Column('institution_name', sa.String(length=256), nullable=True),
        sa.Column('institution_type', sa.String(length=64), nullable=False, server_default='Regular'),
        sa.Column('social_category', sa.String(length=32), nullable=False),
        sa.Column('annual_family_income', sa.Float(), nullable=True),
        sa.Column('is_full_time_student', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('employment_status', sa.String(length=64), nullable=False, server_default='Unemployed'),
        sa.Column('citizenship', sa.String(length=32), nullable=False, server_default='Indian'),
        sa.Column('class12_percentile', sa.Float(), nullable=True),
        sa.Column('attendance_percentage', sa.Float(), nullable=True),
        sa.Column('education_gap_years', sa.Float(), nullable=False, server_default='0'),
        sa.Column('course_type', sa.String(length=64), nullable=True),
        sa.Column('admission_through_cap', sa.Boolean(), nullable=True),
        sa.Column('family_male_beneficiaries_count', sa.Float(), nullable=False, server_default='0'),
        sa.Column('receiving_other_scholarship', sa.Boolean(), nullable=False, server_default='false'),
        sa.Column('pmis_exclusion_clearance', sa.Boolean(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('user_id'),
    )
    op.create_index(op.f('ix_student_profiles_user_id'), 'student_profiles', ['user_id'], unique=True)


def downgrade() -> None:
    op.drop_index(op.f('ix_student_profiles_user_id'), table_name='student_profiles')
    op.drop_table('student_profiles')
    op.drop_index(op.f('ix_users_firebase_uid'), table_name='users')
    op.drop_table('users')
