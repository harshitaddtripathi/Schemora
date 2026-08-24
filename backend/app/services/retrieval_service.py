"""Retrieval Service — Schemora RAG Pipeline.

Retrieves the most semantically relevant knowledge chunks for a user query.

Strategy:
  1. Embed the user query (Gemini dense embedding OR TF-IDF fallback).
  2. Load all stored chunk embeddings from the DB.
  3. Compute cosine similarity between query and each chunk.
  4. Return top-K chunks with metadata for the Gemini prompt.

Filtering:
  - scheme_id: restrict to a specific scheme's chunks
  - state: restrict to state-specific or central schemes
  - category: restrict to a scheme category (Scholarship, Agriculture, etc.)
  - section: restrict to specific section type
"""

import logging
from typing import Any, Dict, List, Optional, Union

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.models.knowledge import KnowledgeChunk
from app.services.embedding_service import (
    embed_text,
    json_to_embedding,
    is_dense_embedding,
    cosine_similarity_dense,
    cosine_similarity_tfidf,
)

logger = logging.getLogger(__name__)

DEFAULT_TOP_K = 8
MIN_SIMILARITY_THRESHOLD = 0.05  # Filter out completely irrelevant chunks


async def retrieve_relevant_chunks(
    db: AsyncSession,
    query: str,
    scheme_id: Optional[str] = None,
    state: Optional[str] = None,
    category: Optional[str] = None,
    section: Optional[str] = None,
    top_k: int = DEFAULT_TOP_K,
) -> List[Dict[str, Any]]:
    """Retrieve the most relevant knowledge chunks for a user query.

    Args:
        db: Async DB session.
        query: The user's question (any language).
        scheme_id: Optional — restrict to a specific scheme.
        state: Optional — restrict to this state OR central schemes.
        category: Optional — restrict to this scheme category.
        section: Optional — restrict to this chunk section type.
        top_k: Maximum number of chunks to return.

    Returns:
        List of chunk dicts sorted by relevance score (descending).
        Each dict contains: content, metadata, similarity_score, citations.
    """
    # Build DB query with filters
    stmt = select(KnowledgeChunk)

    if scheme_id:
        stmt = stmt.where(
            (KnowledgeChunk.scheme_id == scheme_id)
            | (KnowledgeChunk.scheme_id == None)
        )
    if state:
        # Include state-specific chunks AND central (state=NULL) chunks
        stmt = stmt.where(
            (KnowledgeChunk.state == state) | (KnowledgeChunk.state == None)
        )
    if category:
        stmt = stmt.where(KnowledgeChunk.category == category)
    if section:
        stmt = stmt.where(KnowledgeChunk.section == section)

    result = await db.execute(stmt)
    chunks = result.scalars().all()

    if not chunks:
        logger.info(f"No knowledge chunks found for query filters: scheme_id={scheme_id}, state={state}")
        return []

    # Embed the query
    query_embedding, is_semantic = await embed_text(query)

    scored = []
    for chunk in chunks:
        stored = json_to_embedding(chunk.embedding_json)
        if stored is None:
            continue

        # Match embedding types: both dense or both TF-IDF
        chunk_is_dense = is_dense_embedding(stored)
        query_is_dense = is_dense_embedding(query_embedding)

        if query_is_dense and chunk_is_dense:
            score = cosine_similarity_dense(query_embedding, stored)
        elif not query_is_dense and not chunk_is_dense:
            score = cosine_similarity_tfidf(query_embedding, stored)
        else:
            # Mixed types — fall back to TF-IDF on chunk content
            from app.services.embedding_service import _tfidf_vector
            q_tfidf = _tfidf_vector(query) if query_is_dense else query_embedding
            c_tfidf = _tfidf_vector(chunk.content)
            score = cosine_similarity_tfidf(q_tfidf, c_tfidf)

        if score < MIN_SIMILARITY_THRESHOLD:
            continue

        scored.append({
            "chunk_id": chunk.id,
            "scheme_id": chunk.scheme_id,
            "scheme_name": chunk.scheme_name or "",
            "section": chunk.section or "general",
            "content": chunk.content,
            "similarity_score": round(score, 4),

            # Citation fields — use real URLs only, never fall back to myscheme.gov.in
            "source_url": chunk.official_info_url or "",
            "source_title": f"{chunk.scheme_name or 'Official'} — {(chunk.section or 'Guideline').title()}",
            "source_id": chunk.source_id or "",
            "official_app_url": chunk.official_app_url or "",
            "last_verified_at": chunk.last_verified_at or "2026-08-07",
            "scheme_version": chunk.scheme_version or "v1",

            # Context metadata
            "jurisdiction": chunk.jurisdiction or "",
            "state": chunk.state or "",
            "category": chunk.category or "",
            "is_semantic": chunk.is_indexed,
        })

    # Sort by score descending
    scored.sort(key=lambda x: x["similarity_score"], reverse=True)

    # Deduplicate: keep only the best chunk per scheme+section pair
    seen = set()
    deduped = []
    for item in scored:
        key = (item["scheme_id"], item["section"])
        if key not in seen:
            seen.add(key)
            deduped.append(item)
        if len(deduped) >= top_k:
            break

    logger.info(
        f"Retrieved {len(deduped)}/{len(chunks)} chunks for query "
        f"(semantic={is_semantic}, top_score={deduped[0]['similarity_score'] if deduped else 0})"
    )
    return deduped


async def retrieve_scheme_overview(
    db: AsyncSession,
    scheme_id: str,
) -> Optional[Dict[str, Any]]:
    """Retrieve just the overview chunk for a specific scheme."""
    result = await db.execute(
        select(KnowledgeChunk).where(
            KnowledgeChunk.scheme_id == scheme_id,
            KnowledgeChunk.section == "overview",
        )
    )
    chunk = result.scalar_one_or_none()
    if not chunk:
        return None
    return {
        "chunk_id": chunk.id,
        "scheme_id": chunk.scheme_id,
        "scheme_name": chunk.scheme_name,
        "content": chunk.content,
        "section": "overview",
        "source_url": chunk.official_info_url or "",
        "source_title": f"{chunk.scheme_name} — Overview",
        "last_verified_at": chunk.last_verified_at or "2026-08-07",
    }
