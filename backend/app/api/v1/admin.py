"""Admin API - Scheme Management & Knowledge Publication (P0-705 to P0-713)."""
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, delete
from sqlalchemy.orm import selectinload
import uuid

from app.core.database import get_db
from app.core.auth import get_current_admin_user
from app.models.user import User
from app.models.scheme import Scheme, SchemeSource
from app.models.knowledge import KnowledgeDocument, KnowledgeChunk
from app.services.rag_service import ingest_document
from app.schemas.admin import (
    AdminSchemeCreateRequest,
    AdminSchemeUpdateRequest,
    AdminSchemeResponse,
    KnowledgePublishRequest,
    KnowledgeUnpublishRequest,
)
from app.schemas.common import APIResponse

router = APIRouter()


def _scheme_to_resp(scheme: Scheme) -> AdminSchemeResponse:
    return AdminSchemeResponse(
        id=scheme.id,
        title=scheme.title,
        provider=scheme.provider,
        jurisdiction=scheme.jurisdiction,
        category=scheme.benefit_type,
        description=scheme.short_description,
        application_mode="Online",
        application_url=None,
        deadline_text=scheme.application_deadline,
        is_active=scheme.is_published,
    )


# ─── Scheme Management ───────────────────────────────────────────────


@router.get("/schemes", response_model=APIResponse[List[AdminSchemeResponse]], summary="[Admin] List All Schemes")
async def admin_list_schemes(
    admin: User = Depends(get_current_admin_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Scheme))
    schemes = result.scalars().all()
    return APIResponse(success=True, message="Schemes retrieved", data=[_scheme_to_resp(s) for s in schemes])


@router.post("/schemes", response_model=APIResponse[AdminSchemeResponse], summary="[Admin] Create Scheme")
async def admin_create_scheme(
    req: AdminSchemeCreateRequest,
    admin: User = Depends(get_current_admin_user),
    db: AsyncSession = Depends(get_db),
):
    existing = await db.execute(select(Scheme).where(Scheme.id == req.id))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=409, detail=f"Scheme with id '{req.id}' already exists")

    scheme = Scheme(
        id=req.id,
        slug=req.id.replace("-", "_"),
        title=req.title,
        provider=req.provider,
        jurisdiction=req.jurisdiction,
        short_description=req.description,
        detailed_description=req.description,
        benefit_type=req.category,
        benefit_summary=req.description,
        application_deadline=req.deadline_text,
        is_published=True,
    )
    db.add(scheme)
    await db.commit()
    await db.refresh(scheme)

    return APIResponse(success=True, message="Scheme created successfully", data=_scheme_to_resp(scheme))


@router.put("/schemes/{scheme_id}", response_model=APIResponse[AdminSchemeResponse], summary="[Admin] Update Scheme")
async def admin_update_scheme(
    scheme_id: str,
    req: AdminSchemeUpdateRequest,
    admin: User = Depends(get_current_admin_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Scheme).where(Scheme.id == scheme_id))
    scheme = result.scalar_one_or_none()
    if not scheme:
        raise HTTPException(status_code=404, detail="Scheme not found")

    if req.title is not None:
        scheme.title = req.title
    if req.provider is not None:
        scheme.provider = req.provider
    if req.description is not None:
        scheme.short_description = req.description
        scheme.detailed_description = req.description
    if req.deadline_text is not None:
        scheme.application_deadline = req.deadline_text

    await db.commit()
    await db.refresh(scheme)
    return APIResponse(success=True, message="Scheme updated successfully", data=_scheme_to_resp(scheme))


@router.delete("/schemes/{scheme_id}", response_model=APIResponse[dict], summary="[Admin] Delete Scheme")
async def admin_delete_scheme(
    scheme_id: str,
    admin: User = Depends(get_current_admin_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Scheme).where(Scheme.id == scheme_id))
    scheme = result.scalar_one_or_none()
    if not scheme:
        raise HTTPException(status_code=404, detail="Scheme not found")

    await db.delete(scheme)
    await db.commit()
    return APIResponse(success=True, message=f"Scheme '{scheme_id}' deleted successfully", data={"scheme_id": scheme_id})


# ─── Knowledge Publication ────────────────────────────────────────────


@router.post("/knowledge/publish", response_model=APIResponse[dict], summary="[Admin] Publish Source Text as Knowledge Chunks")
async def admin_publish_knowledge(
    req: KnowledgePublishRequest,
    admin: User = Depends(get_current_admin_user),
    db: AsyncSession = Depends(get_db),
):
    """Ingest reviewed source text: chunk, embed (TF-IDF), and store for RAG retrieval."""
    scheme_result = await db.execute(select(Scheme).where(Scheme.id == req.scheme_id))
    scheme = scheme_result.scalar_one_or_none()
    if not scheme:
        raise HTTPException(status_code=404, detail="Scheme not found")

    doc = await ingest_document(
        db=db,
        title=f"Official Source: {scheme.title}",
        content=req.source_text,
        scheme_id=req.scheme_id,
        source_url=req.source_url,
        doc_type="AdminPublished",
    )

    return APIResponse(
        success=True,
        message=f"Source text published: {doc.id} (chunks ingested and indexed for RAG retrieval)",
        data={"document_id": doc.id, "scheme_id": req.scheme_id, "status": "published"},
    )


@router.post("/knowledge/unpublish", response_model=APIResponse[dict], summary="[Admin] Unpublish Scheme Knowledge Chunks")
async def admin_unpublish_knowledge(
    req: KnowledgeUnpublishRequest,
    admin: User = Depends(get_current_admin_user),
    db: AsyncSession = Depends(get_db),
):
    """Remove all knowledge chunks for a scheme from RAG retrieval (soft delete)."""
    # Find and delete all chunks for this scheme
    chunks_result = await db.execute(
        select(KnowledgeChunk).where(KnowledgeChunk.scheme_id == req.scheme_id)
    )
    chunks = chunks_result.scalars().all()
    chunk_count = len(chunks)

    for chunk in chunks:
        await db.delete(chunk)

    # Mark documents as deleted
    docs_result = await db.execute(
        select(KnowledgeDocument).where(KnowledgeDocument.scheme_id == req.scheme_id)
    )
    for doc in docs_result.scalars().all():
        await db.delete(doc)

    await db.commit()

    return APIResponse(
        success=True,
        message=f"Unpublished {chunk_count} knowledge chunks for scheme '{req.scheme_id}'",
        data={"scheme_id": req.scheme_id, "chunks_removed": chunk_count, "status": "unpublished"},
    )
