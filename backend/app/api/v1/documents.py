import json
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.core.database import get_db
from app.core.auth import get_current_user
from app.models.user import User
from app.models.student_profile import StudentProfile
from app.models.scheme import Scheme
from app.models.user_document import UserDocument
from app.schemas.document import DocumentUploadRequest, DocumentResponse, SchemeChecklistResponse
from app.schemas.common import APIResponse
from app.services.document_service import parse_document_content, compare_document_with_profile
from app.services.checklist_service import generate_scheme_checklist

router = APIRouter()


@router.post("/upload-parse", response_model=APIResponse[DocumentResponse], summary="Upload, Parse & Mask Document")
async def upload_and_parse_document(
    req: DocumentUploadRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Parse document, mask sensitive identifiers, and compare against student profile."""
    prof_res = await db.execute(select(StudentProfile).where(StudentProfile.user_id == current_user.id))
    profile = prof_res.scalar_one_or_none()

    if not profile:
        # Auto-create default profile for user if they haven't filled profile form yet
        from datetime import date
        profile = StudentProfile(
            user_id=current_user.id,
            full_name=current_user.full_name or "Citizen Applicant",
            date_of_birth=date(2005, 6, 15),
            gender="Other",
            state="Maharashtra",
            education_level="Undergraduate",
            social_category="General",
            annual_family_income=250000.0,
        )
        db.add(profile)
        await db.flush()

    extracted = parse_document_content(req.doc_type, req.raw_content)
    verification_status, verification_notes = compare_document_with_profile(req.doc_type, extracted, profile)

    user_doc = UserDocument(
        user_id=current_user.id,
        doc_type=req.doc_type,
        file_name=req.file_name,
        masked_identifier=extracted.get("masked_identifier"),
        extracted_data_json=json.dumps(extracted),
        verification_status=verification_status,
        verification_notes=verification_notes,
    )

    db.add(user_doc)
    await db.commit()
    await db.refresh(user_doc)

    resp_data = DocumentResponse(
        id=user_doc.id,
        doc_type=user_doc.doc_type,
        file_name=user_doc.file_name,
        masked_identifier=user_doc.masked_identifier,
        verification_status=user_doc.verification_status,
        verification_notes=user_doc.verification_notes,
    )

    return APIResponse(
        success=True,
        message="Document uploaded, parsed, masked, and cross-verified successfully",
        data=resp_data,
    )


@router.delete("/{doc_id}", response_model=APIResponse[dict], summary="Delete User Document")
async def delete_user_document(
    doc_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Delete a document from user's vault."""
    result = await db.execute(
        select(UserDocument).where(UserDocument.id == doc_id, UserDocument.user_id == current_user.id)
    )
    doc = result.scalar_one_or_none()
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")

    await db.delete(doc)
    await db.commit()
    return APIResponse(success=True, message="Document deleted successfully", data={"document_id": doc_id})


@router.get("/my-documents", response_model=APIResponse[List[DocumentResponse]], summary="List User Documents")
async def list_user_documents(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Retrieve list of authenticated user's uploaded documents."""
    result = await db.execute(select(UserDocument).where(UserDocument.user_id == current_user.id))
    docs = result.scalars().all()

    resp_list = [
        DocumentResponse(
            id=d.id,
            doc_type=d.doc_type,
            file_name=d.file_name,
            masked_identifier=d.masked_identifier,
            verification_status=d.verification_status,
            verification_notes=d.verification_notes,
        )
        for d in docs
    ]

    return APIResponse(
        success=True,
        message="User documents retrieved successfully",
        data=resp_list,
    )


@router.get("/checklist/{scheme_id}", response_model=APIResponse[SchemeChecklistResponse], summary="Get Scheme Application Checklist")
async def get_scheme_checklist(
    scheme_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Generate scheme application readiness checklist."""
    scheme_res = await db.execute(
        select(Scheme).options(selectinload(Scheme.sources)).where(Scheme.id == scheme_id)
    )
    scheme = scheme_res.scalar_one_or_none()

    if not scheme:
        raise HTTPException(status_code=404, detail="Scheme not found")

    docs_res = await db.execute(select(UserDocument).where(UserDocument.user_id == current_user.id))
    user_docs = docs_res.scalars().all()

    checklist_data = generate_scheme_checklist(scheme, user_docs)

    return APIResponse(
        success=True,
        message="Scheme application checklist generated successfully",
        data=SchemeChecklistResponse(**checklist_data),
    )
