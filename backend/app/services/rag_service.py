"""RAG Service — Schemora (upgraded Phase 1).

This module provides the public RAG API used by ai.py and admin.py.
It wraps knowledge_base_service + retrieval_service + gemini_service
into clean, callable functions.

Backward compatibility: The original `ingest_document` and
`retrieve_relevant_chunks` functions are preserved so existing admin
endpoints continue to work without changes.
"""

import json
import logging
import math
import re
from typing import Any, Dict, List, Optional

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.models.knowledge import KnowledgeDocument, KnowledgeChunk
from app.services.embedding_service import (
    embed_text,
    embedding_to_json,
    json_to_embedding,
    is_dense_embedding,
    cosine_similarity_dense,
    cosine_similarity_tfidf,
    _tfidf_vector,
)

logger = logging.getLogger(__name__)


# ── Backward-compatible helpers (used by legacy admin endpoints) ───────────────

def chunk_text(text: str, chunk_size: int = 500, overlap: int = 50) -> List[str]:
    """Splits document text into overlapping chunks (legacy support)."""
    text = text.strip()
    if not text:
        return []
    chunks = []
    start = 0
    while start < len(text):
        end = start + chunk_size
        chunks.append(text[start:end])
        start += chunk_size - overlap
    return chunks


def compute_tfidf_vector(text: str) -> Dict[str, float]:
    """TF-IDF word frequency vector (legacy support)."""
    return _tfidf_vector(text)


def cosine_similarity(v1: Dict[str, float], v2: Dict[str, float]) -> float:
    """Cosine similarity between TF-IDF dicts (legacy support)."""
    return cosine_similarity_tfidf(v1, v2)


async def ingest_document(
    db: AsyncSession,
    title: str,
    content: str,
    scheme_id: Optional[str] = None,
    source_url: Optional[str] = None,
    doc_type: str = "OfficialGuideline",
) -> KnowledgeDocument:
    """Ingest an admin-uploaded document (legacy admin endpoint support).

    Uses semantic chunking + embeddings when possible, TF-IDF fallback otherwise.
    """
    doc = KnowledgeDocument(
        title=title,
        scheme_id=scheme_id,
        source_url=source_url,
        doc_type=doc_type,
    )
    db.add(doc)
    await db.flush()

    raw_chunks = chunk_text(content)
    for idx, chunk_content in enumerate(raw_chunks):
        embedding, is_semantic = await embed_text(chunk_content)
        chunk_obj = KnowledgeChunk(
            document_id=doc.id,
            scheme_id=scheme_id,
            chunk_index=idx,
            content=chunk_content,
            section="general",
            scheme_name=title,
            official_info_url=source_url or "",
            official_app_url="",
            last_verified_at="",
            scheme_version="v1",
            page_number=1,
            metadata_json=json.dumps({"source_url": source_url or "", "title": title}),
            embedding_json=embedding_to_json(embedding),
            is_indexed=is_semantic,
        )
        db.add(chunk_obj)

    await db.commit()
    await db.refresh(doc)
    return doc


async def retrieve_relevant_chunks(
    db: AsyncSession,
    query: str,
    scheme_id: Optional[str] = None,
    top_k: int = 3,
) -> List[Dict[str, Any]]:
    """Retrieve relevant chunks (enhanced — now uses semantic search).

    This function signature is preserved for backward compatibility with ai.py.
    It internally delegates to the new retrieval_service logic.
    """
    from app.services.retrieval_service import retrieve_relevant_chunks as _retrieve
    return await _retrieve(db, query, scheme_id=scheme_id, top_k=top_k)
