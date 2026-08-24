"""AI API — Schemora RAG-powered Assistant (Phase 1 upgrade).

Endpoints:
  POST /ai/chat                      — Main RAG Q&A assistant
  POST /ai/explain-recommendation    — Scheme eligibility explanation
  GET  /ai/knowledge-base/status     — Knowledge base health check
  POST /ai/knowledge-base/index      — Index all Phase 0 schemes
  POST /ai/knowledge-base/reindex/{scheme_id} — Reindex a single scheme

Architecture:
  User Question → Retrieval → Eligibility (if profile) → Gemini → Response
  The LLM never decides eligibility — only the deterministic rule engine does.
"""

import logging
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.core.database import get_db
from app.core.auth import get_current_user
from app.models.user import User
from app.models.student_profile import StudentProfile
from app.models.scheme import Scheme
from app.schemas.ai import (
    AIExplanationRequest,
    AIExplanationResponse,
    AIChatRequest,
    AIChatResponse,
    RetrievedScheme,
    SourceCitation,
    KnowledgeBaseStatusResponse,
    KnowledgeBaseIndexResponse,
)
from app.schemas.common import APIResponse
from app.services.eligibility_service import evaluate_scheme_eligibility
from app.services.retrieval_service import retrieve_relevant_chunks
from app.services.knowledge_base_service import (
    index_all_schemes,
    index_scheme,
    get_knowledge_base_status,
    DATASET_PATH,
)
from app.services.gemini_service import (
    generate_grounded_explanation,
    generate_grounded_chat_response,
)

logger = logging.getLogger(__name__)
router = APIRouter()


# ── /explain-recommendation ───────────────────────────────────────────────────

@router.post(
    "/explain-recommendation",
    response_model=APIResponse[AIExplanationResponse],
    summary="Generate Grounded AI Explanation for a Scheme Recommendation",
)
async def explain_recommendation(
    req: AIExplanationRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Generate source-backed grounded AI explanation for a scheme recommendation."""
    prof_res = await db.execute(
        select(StudentProfile).where(StudentProfile.user_id == current_user.id)
    )
    profile = prof_res.scalar_one_or_none()
    if not profile:
        raise HTTPException(status_code=400, detail="Student profile not found")

    scheme_res = await db.execute(
        select(Scheme)
        .options(selectinload(Scheme.rules), selectinload(Scheme.sources))
        .where(Scheme.id == req.scheme_id)
    )
    scheme = scheme_res.scalar_one_or_none()
    if not scheme:
        raise HTTPException(status_code=404, detail="Scheme not found")

    evaluation = evaluate_scheme_eligibility(scheme, profile)
    sources_list = [
        {"source_name": s.source_name, "url": s.url, "last_verified_at": s.last_verified_at}
        for s in scheme.sources
    ]

    explanation_text, citations_data = generate_grounded_explanation(
        scheme_title=scheme.title,
        status=evaluation["status"],
        matched_rules=evaluation["matched_rules"],
        unresolved_rules=evaluation["unresolved_rules"],
        sources=sources_list,
        language=req.language,
    )

    return APIResponse(
        success=True,
        message="AI explanation generated successfully",
        data=AIExplanationResponse(
            scheme_id=scheme.id,
            explanation=explanation_text,
            citations=[SourceCitation(**c) for c in citations_data],
        ),
    )


# ── /chat — Main RAG-powered Q&A ──────────────────────────────────────────────

@router.post(
    "/chat",
    response_model=APIResponse[AIChatResponse],
    summary="RAG-powered Schemora AI Assistant",
)
async def chat_assistant(
    req: AIChatRequest,
    db: AsyncSession = Depends(get_db),
):
    """Main AI assistant — retrieves verified scheme knowledge and generates grounded answers.

    Flow:
      1. Semantic retrieval from knowledge base
      2. If profile_id provided: run deterministic eligibility engine
      3. Send retrieved context + eligibility result to Gemini
      4. Return grounded answer with citations
    """
    # ── Step 1: Retrieve relevant knowledge ────────────────────────────────
    chunks = await retrieve_relevant_chunks(
        db,
        query=req.question,
        scheme_id=req.scheme_id,
        state=req.state_filter,
        category=req.category_filter,
        top_k=5,
    )

    # ── Step 2: Fallback — query DB schemes directly if knowledge base empty ─
    if not chunks:
        logger.info("Knowledge base empty — using direct scheme DB fallback")
        scheme_stmt = select(Scheme).where(Scheme.is_published == True)
        if req.scheme_id:
            scheme_stmt = scheme_stmt.where(Scheme.id == req.scheme_id)
        schemes_res = await db.execute(scheme_stmt)
        schemes = schemes_res.scalars().all()

        q_words = [w for w in req.question.lower().split() if len(w) > 2]
        matched = []
        for s in schemes:
            s_text = f"{s.title} {s.short_description} {s.benefit_summary}".lower()
            if any(w in s_text for w in q_words):
                matched.append(s)
        if not matched:
            matched = list(schemes[:3])

        for s in matched[:3]:
            chunks.append({
                "chunk_id": f"dyn-{s.id}",
                "scheme_id": s.id,
                "scheme_name": s.title,
                "section": "overview",
                "content": (
                    f"Scheme: {s.title}\n"
                    f"Description: {s.short_description}\n"
                    f"Benefits: {s.benefit_summary}\n"
                    f"Provider: {s.provider} ({s.jurisdiction})\n"
                    f"Eligibility Gender: {s.gender_eligibility}, "
                    f"Social Categories: {s.social_categories}\n"
                    f"Deadline: {s.application_deadline or 'Open'}"
                ),
                "similarity_score": 0.8,
                # Use real official URLs from the scheme record
                "source_url": getattr(s, "official_information_url", "") or getattr(s, "source_url", "") or "",
                "source_title": f"{s.title} Official Guideline",
                "official_app_url": getattr(s, "official_application_url", "") or getattr(s, "application_url", "") or "",
                "last_verified_at": "2026-08-07",
                "scheme_version": "v1",
                "jurisdiction": s.jurisdiction,
                "state": s.state,
                "category": s.benefit_type,
                "is_semantic": False,
            })

    # ── Step 3: Personalized eligibility context (if profile provided) ─────
    eligibility_context: Optional[str] = None
    is_personalized = False

    if req.profile_id and chunks:
        try:
            profile_res = await db.execute(
                select(StudentProfile).where(StudentProfile.id == req.profile_id)
            )
            profile = profile_res.scalar_one_or_none()

            if profile and req.scheme_id:
                scheme_res = await db.execute(
                    select(Scheme)
                    .options(selectinload(Scheme.rules))
                    .where(Scheme.id == req.scheme_id)
                )
                scheme = scheme_res.scalar_one_or_none()
                if scheme and scheme.rules:
                    eval_result = evaluate_scheme_eligibility(scheme, profile)
                    status_label = {
                        "RuleMatched": "✅ Eligible",
                        "NeedsInformation": "⚠️ More info needed",
                        "NotMatched": "❌ Not eligible",
                    }.get(eval_result["status"], eval_result["status"])

                    matched_fields = [r["field_name"] for r in eval_result["matched_rules"]]
                    unresolved_fields = [r["field_name"] for r in eval_result["unresolved_rules"]]
                    failed_fields = [r["field_name"] for r in eval_result["failed_rules"]]

                    eligibility_context = (
                        f"Eligibility Status: {status_label}\n"
                        f"Matched conditions: {', '.join(matched_fields) or 'None'}\n"
                        f"Unresolved (need more info): {', '.join(unresolved_fields) or 'None'}\n"
                        f"Failed conditions: {', '.join(failed_fields) or 'None'}\n"
                        f"Confidence: {eval_result['confidence_score']}"
                    )
                    is_personalized = True
        except Exception as e:
            logger.warning(f"Could not load profile for personalization: {e}")

    # ── Step 4: Generate grounded answer ──────────────────────────────────
    answer_text, citations_data, is_grounded = await generate_grounded_chat_response(
        query=req.question,
        chunks=chunks,
        language=req.language,
        eligibility_context=eligibility_context,
    )

    # ── Step 5: Build response ─────────────────────────────────────────────
    retrieved_schemes = []
    for c in chunks:
        retrieved_schemes.append(RetrievedScheme(
            scheme_id=c.get("scheme_id"),
            scheme_name=c.get("scheme_name", ""),
            section=c.get("section", ""),
            similarity_score=c.get("similarity_score", 0.0),
            jurisdiction=c.get("jurisdiction", ""),
            state=c.get("state"),
            category=c.get("category", ""),
            official_info_url=c.get("source_url", ""),
            official_app_url=c.get("official_app_url", ""),
        ))

    avg_score = (
        round(sum(c.get("similarity_score", 0) for c in chunks) / len(chunks), 3)
        if chunks else 0.0
    )

    # Extract suggested follow-up questions from Gemini answer if present
    suggested_questions = []
    if "You might also want to ask:" in answer_text:
        parts = answer_text.split("You might also want to ask:")
        if len(parts) > 1:
            q_block = parts[1].strip()
            for line in q_block.split("\n"):
                line = line.strip().lstrip("•-–*").strip()
                if line and len(line) > 10:
                    suggested_questions.append(line)
                if len(suggested_questions) >= 3:
                    break

    return APIResponse(
        success=True,
        message="Assistant response generated successfully",
        data=AIChatResponse(
            answer=answer_text,
            is_grounded=is_grounded,
            citations=[SourceCitation(**c) for c in citations_data],
            retrieved_schemes=retrieved_schemes,
            confidence_score=avg_score,
            suggested_questions=suggested_questions,
            is_personalized=is_personalized,
            knowledge_base_used=len(chunks) > 0,
        ),
    )


# ── Knowledge Base Management Endpoints ───────────────────────────────────────

@router.get(
    "/knowledge-base/status",
    response_model=APIResponse[KnowledgeBaseStatusResponse],
    summary="Get Knowledge Base Status",
)
async def knowledge_base_status(db: AsyncSession = Depends(get_db)):
    """Return current knowledge base statistics: chunk counts, embedding status."""
    stat = await get_knowledge_base_status(db)
    return APIResponse(
        success=True,
        message="Knowledge base status retrieved",
        data=KnowledgeBaseStatusResponse(**stat),
    )


@router.post(
    "/knowledge-base/index",
    response_model=APIResponse[KnowledgeBaseIndexResponse],
    summary="Index All Phase 0 Schemes into Knowledge Base",
)
async def knowledge_base_index(db: AsyncSession = Depends(get_db)):
    """Trigger full indexing of the Phase 0 scheme dataset.

    Creates semantic chunks for all schemes and generates embeddings.
    This is idempotent — running it again will re-index all schemes.
    Safe to run without authentication for development.
    """
    if not DATASET_PATH.exists():
        raise HTTPException(
            status_code=404,
            detail=f"Phase 0 dataset not found at {DATASET_PATH}. "
                   "Ensure data/schemes/schemes.v1.json exists.",
        )

    result = await index_all_schemes(db)
    return APIResponse(
        success=True,
        message=(
            f"Successfully indexed {result['indexed_schemes']}/{result['total_schemes']} schemes "
            f"({result['total_chunks']} chunks, {result['semantic_chunks']} semantic)"
        ),
        data=KnowledgeBaseIndexResponse(
            **result,
            message=(
                f"Knowledge base ready: {result['indexed_schemes']} schemes, "
                f"{result['total_chunks']} chunks indexed."
            ),
        ),
    )


@router.post(
    "/knowledge-base/reindex/{scheme_id}",
    response_model=APIResponse[dict],
    summary="Reindex a Single Scheme",
)
async def knowledge_base_reindex_scheme(
    scheme_id: str,
    db: AsyncSession = Depends(get_db),
):
    """Delete and re-index knowledge chunks for a specific scheme.

    Use after updating scheme data in the dataset.
    """
    import json
    if not DATASET_PATH.exists():
        raise HTTPException(status_code=404, detail="Dataset not found")

    with open(DATASET_PATH, "r", encoding="utf-8") as f:
        data = json.load(f)

    scheme_data = next(
        (s for s in data.get("schemes", []) if s.get("scheme_id") == scheme_id),
        None,
    )
    if not scheme_data:
        raise HTTPException(status_code=404, detail=f"Scheme '{scheme_id}' not found in dataset")

    chunks_created, semantic = await index_scheme(db, scheme_data, replace=True)
    return APIResponse(
        success=True,
        message=f"Scheme '{scheme_id}' re-indexed: {chunks_created} chunks ({semantic} semantic)",
        data={
            "scheme_id": scheme_id,
            "chunks_created": chunks_created,
            "semantic_chunks": semantic,
            "tfidf_chunks": chunks_created - semantic,
        },
    )
