"""Create user_documents table

Revision ID: 0005_user_documents
Revises: 0004_knowledge_rag
Create Date: 2026-08-10 14:00:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

revision: str = '0005_user_documents'
down_revision: Union[str, None] = '0004_knowledge_rag'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        'user_documents',
        sa.Column('id', sa.String(length=64), nullable=False),
        sa.Column('user_id', sa.String(length=64), nullable=False),
        sa.Column('doc_type', sa.String(length=64), nullable=False),
        sa.Column('file_name', sa.String(length=256), nullable=False),
        sa.Column('file_hash', sa.String(length=64), nullable=True),
        sa.Column('masked_identifier', sa.String(length=64), nullable=True),
        sa.Column('extracted_data_json', sa.Text(), nullable=True),
        sa.Column('verification_status', sa.String(length=64), nullable=False, server_default='Verified'),
        sa.Column('verification_notes', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_user_documents_user_id'), 'user_documents', ['user_id'], unique=False)


def downgrade() -> None:
    op.drop_index(op.f('ix_user_documents_user_id'), table_name='user_documents')
    op.drop_table('user_documents')
