from fastapi import APIRouter, Depends, HTTPException, status
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
    SourceCitation,
)
from app.schemas.common import APIResponse
from app.services.eligibility_service import evaluate_scheme_eligibility
from app.services.rag_service import retrieve_relevant_chunks, ingest_document
from app.services.gemini_service import generate_grounded_explanation, generate_grounded_chat_response

router = APIRouter()


@router.post("/explain-recommendation", response_model=APIResponse[AIExplanationResponse], summary="Generate Grounded AI Explanation")
async def explain_recommendation(
    req: AIExplanationRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Generate source-backed grounded AI explanation for a scheme recommendation."""
    prof_res = await db.execute(select(StudentProfile).where(StudentProfile.user_id == current_user.id))
    profile = prof_res.scalar_one_or_none()

    if not profile:
        raise HTTPException(status_code=400, detail="Student profile not found")

    scheme_res = await db.execute(
        select(Scheme).options(selectinload(Scheme.rules), selectinload(Scheme.sources)).where(Scheme.id == req.scheme_id)
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

    resp = AIExplanationResponse(
        scheme_id=scheme.id,
        explanation=explanation_text,
        citations=[SourceCitation(**c) for c in citations_data],
    )

    return APIResponse(
        success=True,
        message="AI explanation generated successfully",
        data=resp,
    )


@router.post("/chat", response_model=APIResponse[AIChatResponse], summary="Scoped Scheme Q&A AI Assistant")
async def chat_assistant(
    req: AIChatRequest,
    db: AsyncSession = Depends(get_db),
):
    """Scoped scheme Q&A assistant with citation verification and fallback."""
    # Retrieve relevant knowledge chunks
    chunks = await retrieve_relevant_chunks(db, query=req.question, scheme_id=req.scheme_id, top_k=3)

    # If no chunks exist in DB yet, auto-ingest fallback guideline text for active schemes
    if not chunks:
        scheme_stmt = select(Scheme).where(Scheme.is_published == True)
        if req.scheme_id:
            scheme_stmt = scheme_stmt.where(Scheme.id == req.scheme_id)
        schemes_res = await db.execute(scheme_stmt)
        schemes = schemes_res.scalars().all()

        for s in schemes:
            doc_text = f"Official Guideline for {s.title}: {s.short_description} {s.detailed_description or ''} Benefit: {s.benefit_summary} Provider: {s.provider} Jurisdiction: {s.jurisdiction} State: {s.state or 'Central'} Deadline: {s.application_deadline or 'Open'}"
            await ingest_document(
                db=db,
                title=f"{s.title} Official Guideline",
                content=doc_text,
                scheme_id=s.id,
                source_url=f"https://myscheme.gov.in/schemes/{s.id}",
            )

        chunks = await retrieve_relevant_chunks(db, query=req.question, scheme_id=req.scheme_id, top_k=3)

    answer_text, citations_data, is_grounded = generate_grounded_chat_response(
        query=req.question,
        chunks=chunks,
        language=req.language,
    )

    resp = AIChatResponse(
        answer=answer_text,
        is_grounded=is_grounded,
        citations=[SourceCitation(**c) for c in citations_data],
    )

    return APIResponse(
        success=True,
        message="Assistant response generated successfully",
        data=resp,
    )


from mcp_server.security import create_user_context
from app.agents.orchestrator import SchemoraOrchestratorAgent


@router.post("/agent-chat", summary="Multi-Agent AI Orchestrator Assistant")
async def agent_chat_assistant(
    req: AIChatRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Multi-Agent AI system endpoint delegating user request to Schemora Orchestrator Agent."""
    user_ctx = create_user_context(current_user) if current_user else None
    orchestrator = SchemoraOrchestratorAgent(db)
    result = await orchestrator.execute(query=req.question, context=user_ctx)

    return APIResponse(
        success=True,
        message="Multi-agent orchestration executed successfully",
        data=result,
    )
