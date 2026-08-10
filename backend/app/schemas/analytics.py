from typing import Optional, Dict, Any
from pydantic import BaseModel, Field


class AnalyticsEventRequest(BaseModel):
    event_type: str = Field(..., json_schema_extra={"example": "OfficialPortalOpened"})
    scheme_id: Optional[str] = Field(None, json_schema_extra={"example": "sch-central-csss-001"})
    metadata: Optional[Dict[str, Any]] = None


class AnalyticsEventResponse(BaseModel):
    id: str
    event_type: str
    scheme_id: Optional[str] = None
    created_at: str
