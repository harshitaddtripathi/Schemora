from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field
from app.services.document_service import NON_LEGAL_DISCLAIMER

SAMPLE_RAW_CONTENT = '{"full_name": "Aarav Sharma", "date_of_birth": "2005-06-15", "aadhaar_number": "9999_8888_1234"}'


class DocumentUploadRequest(BaseModel):
    doc_type: str = Field(..., json_schema_extra={"example": "Aadhaar"})  # Aadhaar, PAN, IncomeCertificate
    file_name: str = Field(..., json_schema_extra={"example": "aadhaar_card.png"})
    raw_content: str = Field(..., json_schema_extra={"example": SAMPLE_RAW_CONTENT})


class DocumentResponse(BaseModel):
    id: str
    doc_type: str
    file_name: str
    masked_identifier: Optional[str] = None
    verification_status: str
    verification_notes: Optional[str] = None
    non_legal_disclaimer: str = NON_LEGAL_DISCLAIMER


class ChecklistItem(BaseModel):
    doc_type: str
    title: str
    is_mandatory: bool
    status: str  # Available, Missing, Warning, CorrectionRequired
    masked_identifier: Optional[str] = None
    notes: str


class SchemeChecklistResponse(BaseModel):
    scheme_id: str
    scheme_title: str
    readiness_percentage: float
    is_ready_for_application: bool
    items: List[ChecklistItem]
    application_steps: List[str]
