from typing import Optional, List
from pydantic import BaseModel, Field


class SourceCitation(BaseModel):
    source_name: str
    url: str
    last_verified_at: str = "2026-08-07"


class AIExplanationRequest(BaseModel):
    scheme_id: str
    language: str = Field("en", json_schema_extra={"example": "en"})  # en, hi, mr


class AIExplanationResponse(BaseModel):
    scheme_id: str
    explanation: str
    citations: List[SourceCitation] = []


class AIChatRequest(BaseModel):
    question: str = Field(..., min_length=2, json_schema_extra={"example": "What documents are needed for CSSS scholarship?"})
    scheme_id: Optional[str] = Field(None, json_schema_extra={"example": "sch-central-csss-001"})
    language: str = Field("en", json_schema_extra={"example": "en"})


class AIChatResponse(BaseModel):
    answer: str
    is_grounded: bool
    citations: List[SourceCitation] = []
