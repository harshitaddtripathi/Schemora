from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, Field

VALID_STATUSES = [
    "Saved",
    "Drafting",
    "DocumentsPending",
    "AppliedOnOfficialPortal",
    "UnderReview",
    "Approved",
    "Rejected",
]


class StatusUpdateRequest(BaseModel):
    status: str = Field(..., json_schema_extra={"example": "AppliedOnOfficialPortal"})
    notes: Optional[str] = Field(None, json_schema_extra={"example": "Submitted application on NSP portal"})


class SavedSchemeResponse(BaseModel):
    id: str
    scheme_id: str
    scheme_title: str
    provider: str
    jurisdiction: str
    status: str
    notes: Optional[str] = None
    updated_at: str


class ReminderCreateRequest(BaseModel):
    title: str = Field(..., json_schema_extra={"example": "Submit application before deadline"})
    reminder_date: str = Field(..., json_schema_extra={"example": "2026-10-28T10:00:00Z"})


class ReminderResponse(BaseModel):
    id: str
    scheme_id: str
    title: str
    reminder_date: str
    is_completed: bool
