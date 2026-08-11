"""Document analysis, validation, and checklist MCP tools for Schemora."""

import json
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.models.scheme import Scheme
from app.models.student_profile import StudentProfile
from app.models.user_document import UserDocument
from app.services.document_service import parse_document_content, compare_document_with_profile
from app.services.checklist_service import generate_scheme_checklist
from mcp_server.schemas.tool_schemas import (
    GetRequiredDocumentsInput, GetRequiredDocumentsOutput, RequiredDocumentSchema,
    AnalyzeDocumentInput, AnalyzeDocumentOutput,
    GetDocumentChecklistInput, GetDocumentChecklistOutput, ChecklistItemSchema,
    UserContext,
)
from mcp_server.security import verify_user_authorization


async def get_required_documents_tool(
    db: AsyncSession,
    input_data: GetRequiredDocumentsInput,
) -> GetRequiredDocumentsOutput:
    """Retrieve standard required documents for a given scheme."""
    stmt = select(Scheme).where(Scheme.id == input_data.scheme_id)
    res = await db.execute(stmt)
    scheme = res.scalar_one_or_none()

    docs = [
        RequiredDocumentSchema(
            doc_type="Aadhaar",
            title="Aadhaar Card",
            description="Identity & Age verification proof",
            is_mandatory=True,
        ),
        RequiredDocumentSchema(
            doc_type="IncomeCertificate",
            title="Annual Income Certificate",
            description="Family income threshold verification",
            is_mandatory=True,
        ),
    ]

    if scheme and "obc" in scheme.id.lower():
        docs.append(
            RequiredDocumentSchema(
                doc_type="CasteCertificate",
                title="OBC Caste / Non-Creamy Layer Certificate",
                description="Social category verification",
                is_mandatory=True,
            )
        )

    return GetRequiredDocumentsOutput(
        success=True,
        scheme_id=input_data.scheme_id,
        required_documents=docs,
    )


async def analyze_document_tool(
    db: AsyncSession,
    input_data: AnalyzeDocumentInput,
    context: UserContext,
) -> AnalyzeDocumentOutput:
    """Parse document content, mask sensitive PII, cross-verify against user profile, and persist."""
    verify_user_authorization(context)

    prof_res = await db.execute(select(StudentProfile).where(StudentProfile.user_id == context.user_id))
    profile = prof_res.scalar_one_or_none()

    if not profile:
        return AnalyzeDocumentOutput(
            success=False,
            document_id="",
            doc_type=input_data.doc_type,
            masked_identifier="",
            verification_status="CorrectionRequired",
            verification_notes="Student profile not found. Please complete profile first.",
        )

    extracted = parse_document_content(input_data.doc_type, input_data.raw_content)
    status_ver, notes_ver = compare_document_with_profile(input_data.doc_type, extracted, profile)

    user_doc = UserDocument(
        user_id=context.user_id,
        doc_type=input_data.doc_type,
        file_name=input_data.file_name,
        masked_identifier=extracted.get("masked_identifier", "XXXX-XXXX-XXXX"),
        extracted_data_json=json.dumps(extracted),
        verification_status=status_ver,
        verification_notes=notes_ver,
    )

    db.add(user_doc)
    await db.commit()
    await db.refresh(user_doc)

    return AnalyzeDocumentOutput(
        success=True,
        document_id=user_doc.id,
        doc_type=user_doc.doc_type,
        masked_identifier=user_doc.masked_identifier,
        verification_status=user_doc.verification_status,
        verification_notes=user_doc.verification_notes,
    )


async def get_document_checklist_tool(
    db: AsyncSession,
    input_data: GetDocumentChecklistInput,
    context: UserContext,
) -> GetDocumentChecklistOutput:
    """Build application document checklist & readiness score for user."""
    verify_user_authorization(context)

    scheme_res = await db.execute(
        select(Scheme).options(selectinload(Scheme.sources)).where(Scheme.id == input_data.scheme_id)
    )
    scheme = scheme_res.scalar_one_or_none()

    if not scheme:
        return GetDocumentChecklistOutput(
            success=False,
            scheme_id=input_data.scheme_id,
            readiness_percentage=0.0,
            items=[],
        )

    docs_res = await db.execute(select(UserDocument).where(UserDocument.user_id == context.user_id))
    user_docs = docs_res.scalars().all()

    checklist_data = generate_scheme_checklist(scheme, user_docs=user_docs)

    items = [
        ChecklistItemSchema(
            doc_type=it["doc_type"],
            status=it["status"],
            masked_identifier=it.get("masked_identifier"),
        )
        for it in checklist_data.get("items", [])
    ]

    return GetDocumentChecklistOutput(
        success=True,
        scheme_id=input_data.scheme_id,
        readiness_percentage=float(checklist_data.get("readiness_percentage", 0.0)),
        items=items,
    )
