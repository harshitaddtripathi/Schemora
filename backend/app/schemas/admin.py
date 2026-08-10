from typing import Optional, List
from pydantic import BaseModel, Field


class AdminSchemeCreateRequest(BaseModel):
    id: str = Field(..., json_schema_extra={"example": "sch-new-pilot-001"})
    title: str = Field(..., json_schema_extra={"example": "New Pilot Scholarship"})
    provider: str = Field(..., json_schema_extra={"example": "Ministry of Education"})
    jurisdiction: str = Field(..., json_schema_extra={"example": "Central"})
    description: str = Field(..., json_schema_extra={"example": "A new pilot scholarship scheme."})
    category: str = Field(..., json_schema_extra={"example": "Scholarship"})
    application_mode: str = Field(..., json_schema_extra={"example": "Online"})
    application_url: Optional[str] = None
    deadline_text: Optional[str] = None


class AdminSchemeUpdateRequest(BaseModel):
    title: Optional[str] = None
    provider: Optional[str] = None
    description: Optional[str] = None
    deadline_text: Optional[str] = None
    application_url: Optional[str] = None


class AdminSchemeResponse(BaseModel):
    id: str
    title: str
    provider: str
    jurisdiction: str
    category: str
    description: str
    application_mode: str
    application_url: Optional[str] = None
    deadline_text: Optional[str] = None
    is_active: bool


class KnowledgePublishRequest(BaseModel):
    scheme_id: str
    source_text: str = Field(..., json_schema_extra={"example": "Official PDF extracted text content..."})
    source_url: Optional[str] = None


class KnowledgeUnpublishRequest(BaseModel):
    scheme_id: str
