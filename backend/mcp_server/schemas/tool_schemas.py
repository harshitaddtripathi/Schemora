"""Pydantic schemas for Schemora MCP tools."""

from typing import List, Dict, Any, Optional
from pydantic import BaseModel, Field, ConfigDict


# ─── Auth Context Schema ───────────────────────────────────────────────────

class UserContext(BaseModel):
    """Authenticated user context propagated to authorization-sensitive MCP tools."""
    model_config = ConfigDict(frozen=True)

    user_id: str
    firebase_uid: str
    role: str = "citizen"


# ─── Tool Inputs & Outputs ─────────────────────────────────────────────────

class SearchSchemesInput(BaseModel):
    query: Optional[str] = Field(None, description="Search query string for filtering schemes")
    state: Optional[str] = Field(None, description="Filter by state (e.g. Maharashtra)")
    social_category: Optional[str] = Field(None, description="Filter by social category (e.g. OBC, SC, ST, General)")
    limit: int = Field(10, ge=1, le=50, description="Maximum number of schemes to return")


class SchemeItemSchema(BaseModel):
    scheme_id: str
    title: str
    short_description: str
    provider: str
    jurisdiction: str
    state: Optional[str] = None
    benefit_summary: str
    is_published: bool = True
    application_deadline: Optional[str] = None


class SearchSchemesOutput(BaseModel):
    success: bool = True
    count: int
    schemes: List[SchemeItemSchema]


class GetSchemeInput(BaseModel):
    scheme_id: str = Field(..., description="Unique scheme ID (e.g. sch-central-csss-001)")


class SchemeDetailSchema(BaseModel):
    id: str
    title: str
    short_description: str
    detailed_description: str
    provider: str
    jurisdiction: str
    state: Optional[str] = None
    gender_eligibility: str
    social_categories: str
    benefit_type: str
    benefit_summary: str
    implementation_status: str
    is_published: bool
    application_deadline: Optional[str] = None
    rules_count: int = 0
    sources_count: int = 0


class GetSchemeOutput(BaseModel):
    success: bool = True
    scheme: Optional[SchemeDetailSchema] = None
    error: Optional[str] = None


class GetSchemeSourcesInput(BaseModel):
    scheme_id: str = Field(..., description="Unique scheme ID")


class SourceItemSchema(BaseModel):
    source_id: str
    source_name: str
    url: str
    source_type: str
    last_verified_at: str


class GetSchemeSourcesOutput(BaseModel):
    success: bool = True
    scheme_id: str
    sources: List[SourceItemSchema]


class EvaluateEligibilityInput(BaseModel):
    scheme_id: str = Field(..., description="Scheme ID to evaluate against user profile")


class RuleEvaluationResultSchema(BaseModel):
    rule_id: str
    field_name: str
    operator: str
    expected_value: Any
    rule_type: str
    status: str  # passed, failed, unresolved
    failure_reason: str


class EvaluateEligibilityOutput(BaseModel):
    success: bool = True
    scheme_id: str
    overall_status: str  # RuleMatched, NeedsInformation, NotMatched
    match_score: float
    passed_rules: List[RuleEvaluationResultSchema]
    failed_rules: List[RuleEvaluationResultSchema]
    unresolved_rules: List[RuleEvaluationResultSchema]
    explanation: str


class GetRequiredDocumentsInput(BaseModel):
    scheme_id: str = Field(..., description="Scheme ID")


class RequiredDocumentSchema(BaseModel):
    doc_type: str
    title: str
    description: str
    is_mandatory: bool = True


class GetRequiredDocumentsOutput(BaseModel):
    success: bool = True
    scheme_id: str
    required_documents: List[RequiredDocumentSchema]


class GetApplicationStepsInput(BaseModel):
    scheme_id: str = Field(..., description="Scheme ID")


class StepSchema(BaseModel):
    step_number: int
    title: str
    instruction: str
    official_url: Optional[str] = None


class GetApplicationStepsOutput(BaseModel):
    success: bool = True
    scheme_id: str
    application_mode: str = "Online"
    portal_url: str
    steps: List[StepSchema]


class GetApplicationWindowsInput(BaseModel):
    scheme_id: Optional[str] = Field(None, description="Optional scheme ID filter")


class WindowSchema(BaseModel):
    scheme_id: str
    scheme_title: str
    status: str  # Open, ClosingSoon, Closed
    opening_date: str
    closing_date: str


class GetApplicationWindowsOutput(BaseModel):
    success: bool = True
    windows: List[WindowSchema]


class GetStudentProfileOutput(BaseModel):
    success: bool = True
    profile: Optional[Dict[str, Any]] = None
    error: Optional[str] = None


class SavedSchemeItemSchema(BaseModel):
    saved_id: str
    scheme_id: str
    scheme_title: str
    saved_at: str
    status: str


class GetSavedSchemesOutput(BaseModel):
    success: bool = True
    saved_schemes: List[SavedSchemeItemSchema]


class GetApplicationStatusInput(BaseModel):
    scheme_id: Optional[str] = Field(None, description="Optional scheme ID filter")


class ApplicationStatusItemSchema(BaseModel):
    scheme_id: str
    status: str  # Draft, Submitted, UnderReview, Approved, Rejected
    updated_at: str
    notes: Optional[str] = None


class GetApplicationStatusOutput(BaseModel):
    success: bool = True
    applications: List[ApplicationStatusItemSchema]


class UpdateApplicationStatusInput(BaseModel):
    scheme_id: str = Field(..., description="Scheme ID")
    status: str = Field(..., description="New status (Draft, Submitted, UnderReview, Approved, Rejected)")
    notes: Optional[str] = Field(None, description="Optional notes")


class UpdateApplicationStatusOutput(BaseModel):
    success: bool = True
    scheme_id: str
    status: str
    updated_at: str


class AnalyzeDocumentInput(BaseModel):
    doc_type: str = Field(..., description="Document type (Aadhaar, PAN, IncomeCertificate, Marksheet)")
    file_name: str = Field(..., description="Document file name")
    raw_content: str = Field(..., description="Raw text/JSON document content")


class AnalyzeDocumentOutput(BaseModel):
    success: bool = True
    document_id: str
    doc_type: str
    masked_identifier: str
    verification_status: str  # Verified, DiscrepancyDetected, CorrectionRequired
    verification_notes: str


class GetDocumentChecklistInput(BaseModel):
    scheme_id: str = Field(..., description="Scheme ID")


class ChecklistItemSchema(BaseModel):
    doc_type: str
    status: str  # Available, Missing, VerificationRequired
    masked_identifier: Optional[str] = None


class GetDocumentChecklistOutput(BaseModel):
    success: bool = True
    scheme_id: str
    readiness_percentage: float
    items: List[ChecklistItemSchema]


class SearchKnowledgeBaseInput(BaseModel):
    query: str = Field(..., description="Search query string")
    scheme_id: Optional[str] = Field(None, description="Optional scheme ID filter")
    limit: int = Field(5, ge=1, le=20, description="Max results")


class KnowledgeChunkSchema(BaseModel):
    chunk_id: str
    scheme_id: str
    source_id: str
    source_title: str
    official_url: str
    content_snippet: str
    last_verified_at: str
    relevance_score: float


class SearchKnowledgeBaseOutput(BaseModel):
    success: bool = True
    query: str
    results: List[KnowledgeChunkSchema]
    fallback_message: Optional[str] = None


class GetOfficialSourceInput(BaseModel):
    source_id: str = Field(..., description="Source ID")


class GetOfficialSourceOutput(BaseModel):
    success: bool = True
    source_id: str
    source_name: str
    url: str
    source_type: str
    last_verified_at: str


class CreateReminderInput(BaseModel):
    scheme_id: str = Field(..., description="Scheme ID")
    reminder_date: str = Field(..., description="Target ISO date (YYYY-MM-DD)")
    title: str = Field(..., description="Reminder title")
    notes: Optional[str] = Field(None, description="Optional notes")


class CreateReminderOutput(BaseModel):
    success: bool = True
    reminder_id: str
    scheme_id: str
    reminder_date: str
    status: str = "Scheduled"
