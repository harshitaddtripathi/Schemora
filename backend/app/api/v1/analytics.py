import json
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.auth import get_current_user
from app.models.user import User
from app.models.analytics import AnalyticsEvent
from app.schemas.analytics import AnalyticsEventRequest, AnalyticsEventResponse
from app.schemas.common import APIResponse

router = APIRouter()


@router.post("/event", response_model=APIResponse[AnalyticsEventResponse], summary="Record Privacy-Safe Analytics Event")
async def record_analytics_event(
    req: AnalyticsEventRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Log privacy-safe analytics event (e.g. OfficialPortalOpened, SchemeSaved)."""
    meta_json = json.dumps(req.metadata) if req.metadata else None

    event = AnalyticsEvent(
        user_id=current_user.id,
        scheme_id=req.scheme_id,
        event_type=req.event_type,
        metadata_json=meta_json,
    )

    db.add(event)
    await db.commit()
    await db.refresh(event)

    resp_data = AnalyticsEventResponse(
        id=event.id,
        event_type=event.event_type,
        scheme_id=event.scheme_id,
        created_at=event.created_at.isoformat(),
    )

    return APIResponse(
        success=True,
        message="Analytics event recorded successfully",
        data=resp_data,
    )
