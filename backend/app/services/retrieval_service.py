"""Retrieval Service — Schemora RAG Pipeline.

Retrieves the most semantically relevant knowledge chunks for a user query.

Strategy:
  1. Detect query intent (SCHEME_DISCOVERY, ELIGIBILITY, APPLICATION_PROCESS, etc.)
  2. Expand query with synonyms based on intent.
  3. Embed the user query (Gemini dense embedding OR TF-IDF fallback).
  4. Load all stored chunk embeddings from the DB.
  5. Compute cosine similarity between query and each chunk.
  6. Apply section-affinity boost based on detected intent.
  7. Apply keyword matching boost for scheme title, category, and state.
  8. Return top-K chunks with metadata for the Gemini prompt.

Filtering:
  - scheme_id: restrict to a specific scheme's chunks
  - state: restrict to state-specific or central schemes
  - category: restrict to a scheme category (Scholarship, Agriculture, etc.)
  - section: restrict to specific section type

Intent detection ensures that:
  - "What documents do I need?" → boosts 'documents' section chunks
  - "How do I apply?" → boosts 'application' section chunks
  - "What benefits?" → boosts 'benefits' section chunks
  - "Am I eligible?" → boosts 'eligibility' section chunks
  - "Tell me OBC schemes" → boosts 'overview'+'eligibility' section chunks

This dramatically improves retrieval quality without requiring semantic embeddings.
"""

import re
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
MIN_SIMILARITY_THRESHOLD = 0.03  # Lowered: TF-IDF scores are naturally low


# ── Intent Detection ──────────────────────────────────────────────────────────

INTENT_PATTERNS = {
    # REQUIRED_DOCUMENTS checked FIRST — before APPLICATION_PROCESS
    # so "what documents are required" doesn't match 'required' → APPLICATION_PROCESS
    "REQUIRED_DOCUMENTS": [
        r"\bdocuments?\b", r"\bpaper\b", r"\bcertificate\b",
        r"\bchecklist\b", r"\bupload\b", r"\bproof\b", r"\bkyc\b",
        r"\bpapers?\b",
        r"\bwhat.*need\b",   # "what do I need"
        r"\bwhat.*require\b",  # "what are the requirements / required docs"
        r"\brequired.*doc\b",  # "required documents"
        r"\bdoc.*needed?\b",  # "documents needed"
    ],
    "APPLICATION_PROCESS": [
        r"\bhow.*(?:do|can|should|to).*apply\b",
        r"\bprocess\b",
        r"\bprocedure\b",
        r"\bfill\b",
        r"\bfilling\b",
        r"\bhow.*fill\b",
        r"\bapplication.*process\b",
        r"\bstep.*(?:apply|fill|submit|register)\b",
        r"\bsubmit.*application\b",
        r"\bregister.*(?:on|at|in|for)?\b",
        r"\bsteps?.*scholarship\b",
        r"\bsteps?.*apply\b",
        r"\bapply.*online\b",
        r"\bapplication.*form\b",
        r"\bscholarship.*form\b",
        r"\bhow.*to.*(?:fill|apply|register|submit)\b",
    ],
    "ELIGIBILITY": [
        r"\bam i (?:eligible|qualified|fit)\b",
        r"\bcan i (?:get|apply|qualify|receive)\b",
        r"\bwho (?:can|is|are) eligible\b",
        r"\beligib\b", r"\bqualif\b", r"\bcriteria\b",
        r"\bfor whom\b",
    ],
    "BENEFITS": [
        r"\bbenefit\b", r"\bamount\b", r"\bstipend\b",
        r"\bgrant\b", r"\bhow much\b", r"\brupees?\b", r"\binr\b",
        r"\bfinancial.*help\b", r"\bfinancial.*assist\b", r"\bfinancial.*support\b",
        r"\bprovide\b", r"\bgive.*money\b", r"\bget.*money\b",
        r"\bcan.*i get\b",  # "can I get financial help"
        r"\bsupport.*studying\b", r"\bhelp.*studying\b",
        r"\bscholarship.*amount\b", r"\bmoney.*stud\b",
    ],
    "DEADLINE": [
        r"\bdeadline\b", r"\blast date\b",
        r"\bwindow\b", r"\bapply.*by\b", r"\bopen.*till\b",
        r"\bwhen.*apply\b", r"\bclose.*date\b",
    ],
    "STATUS": [
        r"\bstatus\b", r"\btrack\b", r"\breminder\b", r"\bbookmark\b",
    ],
}

# Map intent to preferred sections for scoring boost
INTENT_SECTION_BOOST = {
    "REQUIRED_DOCUMENTS": {"documents": 0.35, "application": 0.15, "overview": 0.05},
    "APPLICATION_PROCESS": {"application": 0.35, "documents": 0.15, "overview": 0.10},
    "ELIGIBILITY": {"eligibility": 0.25, "overview": 0.10},
    "BENEFITS": {"benefits": 0.30, "overview": 0.10},
    "DEADLINE": {"deadlines": 0.30, "application": 0.10},
    "STATUS": {"notes": 0.20, "deadlines": 0.10},
    "SCHEME_DISCOVERY": {"overview": 0.20, "eligibility": 0.10, "benefits": 0.10},
    "GENERAL": {"overview": 0.10},
}

# Map intent to query expansion terms (improves TF-IDF recall)
INTENT_QUERY_EXPANSIONS = {
    "REQUIRED_DOCUMENTS": " required documents certificate aadhaar marksheet income",
    "APPLICATION_PROCESS": " apply application process portal steps online register procedure fill form guidelines",
    "ELIGIBILITY": " eligible eligibility criteria who can apply conditions requirements",
    "BENEFITS": " benefits financial assistance amount scholarship grant stipend",
    "DEADLINE": " deadline date window opens closes application cycle",
    "SCHEME_DISCOVERY": " scheme scholarship overview category description",
}

# Social category synonyms for better OBC/SC/ST retrieval
SOCIAL_CATEGORY_SYNONYMS = {
    "obc": "OBC other backward class caste backward",
    "sc": "SC scheduled caste dalit",
    "st": "ST scheduled tribe tribal adivasi",
    "general": "general open category",
    "ews": "EWS economically weaker section",
    "minority": "minority religion muslim christian sikh",
}


def detect_intent(query: str) -> str:
    """Detect the primary intent of the user's query.

    Priority order: REQUIRED_DOCUMENTS > APPLICATION_PROCESS > ELIGIBILITY >
    BENEFITS > DEADLINE > STATUS > SCHEME_DISCOVERY > GENERAL

    Important edge cases handled:
    - "Which scholarships can I apply for?" → SCHEME_DISCOVERY (not APPLICATION_PROCESS)
      because 'which' + 'scholarship' indicates discovery, not a process question.
    - "What documents are required?" → REQUIRED_DOCUMENTS (not APPLICATION_PROCESS)
      because REQUIRED_DOCUMENTS is checked first.
    - "Can I get financial help for studying?" → BENEFITS (not ELIGIBILITY)
      because BENEFITS patterns match 'can i get'.
    """
    q = query.lower()

    # Special case: "which scholarships/schemes can I apply for?" -> SCHEME_DISCOVERY
    if re.search(r"\bwhich\b", q) and re.search(r"\b(?:scholarships?|schemes?|programs?|yojana)\b", q):
        return "SCHEME_DISCOVERY"

    # Special case: "list scholarships", "tell me schemes", "show me programs"
    if re.search(r"\b(?:list|tell|show|find|what are).*(?:scholarships?|schemes?|programs?)\b", q):
        return "SCHEME_DISCOVERY"

    for intent, patterns in INTENT_PATTERNS.items():
        for pat in patterns:
            if re.search(pat, q):
                return intent
    # Fallback: if it mentions specific scheme/scholarship keywords
    if any(w in q for w in ["scheme", "scholarship", "program", "yojana", "nidhi", "prakalpa"]):
        return "SCHEME_DISCOVERY"
    return "GENERAL"


def expand_query(query: str, intent: str) -> str:
    """Expand query with relevant terms based on intent and social category mentions."""
    q_lower = query.lower()

    # Social category expansion
    for category, synonyms in SOCIAL_CATEGORY_SYNONYMS.items():
        if category in q_lower:
            query = f"{query} {synonyms}"
            break

    # Intent-based expansion
    expansion = INTENT_QUERY_EXPANSIONS.get(intent, "")
    if expansion:
        query = f"{query}{expansion}"

    return query


# ── Keyword Boost ─────────────────────────────────────────────────────────────

def _compute_keyword_boost(query: str, chunk: KnowledgeChunk) -> float:
    """Calculate a keyword matching boost to enhance retrieval quality.

    Works for both TF-IDF and dense embedding modes.
    Intent-aware section boosts are applied separately.
    """
    q_words = [w.lower() for w in re.findall(r"\w+", query) if len(w) > 2]
    if not q_words:
        return 0.0

    # Exclude common stop words from boosting
    stop_words = {
        "the", "and", "for", "are", "that", "with", "from", "this",
        "can", "have", "about", "what", "how", "tell", "show", "give",
        "please", "need", "want", "like", "does", "should", "which",
    }
    q_words = [w for w in q_words if w not in stop_words]

    boost = 0.0
    scheme_name = (chunk.scheme_name or "").lower()
    category = (chunk.category or "").lower()
    section = (chunk.section or "").lower()
    content = (chunk.content or "").lower()
    state = (chunk.state or "").lower()

    for w in q_words:
        if w in scheme_name:
            boost += 0.12
        if w in category:
            boost += 0.10
        if w in section:
            boost += 0.05
        if state and w in state:
            boost += 0.10
        if w in content:
            boost += 0.02

    return min(0.40, boost)


# ── Main Retrieval ────────────────────────────────────────────────────────────

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

    Improvements over v1:
      - Intent detection: automatically identifies query type.
      - Query expansion: adds relevant terms to improve TF-IDF recall.
      - Section-affinity boosting: rewards chunks from sections matching intent.
      - Lowered MIN_SIMILARITY_THRESHOLD for better recall with TF-IDF.

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
    # Detect intent and expand query
    intent = detect_intent(query)
    expanded_query = expand_query(query, intent)

    logger.info(f"Retrieval: intent={intent}, query='{query[:80]}'")

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
        logger.info(f"No knowledge chunks found for filters: scheme_id={scheme_id}, state={state}")
        return []

    # Embed the expanded query
    query_embedding, is_semantic = await embed_text(expanded_query)

    # Section boost map for this intent
    section_boosts = INTENT_SECTION_BOOST.get(intent, {})

    scored = []
    for chunk in chunks:
        stored = json_to_embedding(chunk.embedding_json)

        # Base vector similarity score
        score = 0.0
        if stored is not None:
            chunk_is_dense = is_dense_embedding(stored)
            query_is_dense = is_dense_embedding(query_embedding)

            if query_is_dense and chunk_is_dense:
                score = cosine_similarity_dense(query_embedding, stored)
            elif not query_is_dense and not chunk_is_dense:
                score = cosine_similarity_tfidf(query_embedding, stored)
            else:
                # Mismatch: compute TF-IDF on both sides
                from app.services.embedding_service import _tfidf_vector
                q_tfidf = _tfidf_vector(expanded_query) if query_is_dense else query_embedding
                c_tfidf = _tfidf_vector(chunk.content)
                score = cosine_similarity_tfidf(q_tfidf, c_tfidf)

        # Intent-based section affinity boost
        section_boost = section_boosts.get(chunk.section or "", 0.0)

        # Keyword matching boost
        kw_boost = _compute_keyword_boost(expanded_query, chunk)

        total_score = min(1.0, score + section_boost + kw_boost)

        if total_score < MIN_SIMILARITY_THRESHOLD:
            continue

        scored.append({
            "chunk_id": chunk.id,
            "scheme_id": chunk.scheme_id,
            "scheme_name": chunk.scheme_name or "",
            "section": chunk.section or "general",
            "content": chunk.content,
            "similarity_score": round(total_score, 4),
            "intent": intent,

            # Citation fields — use real URLs only
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
        f"(intent={intent}, semantic={is_semantic}, "
        f"top_score={deduped[0]['similarity_score'] if deduped else 0})"
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
