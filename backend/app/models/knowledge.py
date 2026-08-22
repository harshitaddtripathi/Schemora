import uuid
from datetime import datetime, timezone
from typing import Optional, List
from sqlalchemy import String, Integer, Text, DateTime, Boolean, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.database import Base


class KnowledgeDocument(Base):
    __tablename__ = "knowledge_documents"

    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=lambda: str(uuid.uuid4()))
    scheme_id: Mapped[Optional[str]] = mapped_column(
        String(64),
        ForeignKey("schemes.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )

    title: Mapped[str] = mapped_column(String(256), nullable=False)
    source_url: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    doc_type: Mapped[str] = mapped_column(String(64), default="OfficialGuideline", nullable=False)
    file_hash: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    chunks: Mapped[List["KnowledgeChunk"]] = relationship(
        "KnowledgeChunk",
        back_populates="document",
        cascade="all, delete-orphan",
    )


class KnowledgeChunk(Base):
    """A semantic chunk of knowledge extracted from a government scheme.

    Each chunk represents a specific section of a scheme (overview, benefits,
    eligibility, documents, application process, deadlines, or notes).
    Rich metadata is preserved so every AI answer can cite verified sources.
    """
    __tablename__ = "knowledge_chunks"

    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=lambda: str(uuid.uuid4()))
    document_id: Mapped[str] = mapped_column(
        String(64),
        ForeignKey("knowledge_documents.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    scheme_id: Mapped[Optional[str]] = mapped_column(String(64), nullable=True, index=True)

    chunk_index: Mapped[int] = mapped_column(Integer, nullable=False)
    content: Mapped[str] = mapped_column(Text, nullable=False)
    page_number: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)

    # ── Section type ──────────────────────────────────────────────────────────
    # One of: overview | benefits | eligibility | documents | application |
    #         deadlines | notes
    section: Mapped[Optional[str]] = mapped_column(String(64), nullable=True, index=True)

    # ── Scheme metadata preserved per chunk ───────────────────────────────────
    scheme_name: Mapped[Optional[str]] = mapped_column(String(256), nullable=True)
    jurisdiction: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    state: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    category: Mapped[Optional[str]] = mapped_column(String(128), nullable=True)

    # ── Source citation fields ────────────────────────────────────────────────
    source_id: Mapped[Optional[str]] = mapped_column(String(128), nullable=True)
    official_info_url: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    official_app_url: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    last_verified_at: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    scheme_version: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)

    # ── Embedding + legacy metadata ───────────────────────────────────────────
    # embedding_json stores a JSON float array (Gemini embeddings) or
    # a TF-IDF dict {word: score} as fallback.
    embedding_json: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    metadata_json: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    # Whether Gemini semantic embedding has been generated for this chunk
    is_indexed: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    document: Mapped["KnowledgeDocument"] = relationship("KnowledgeDocument", back_populates="chunks")
