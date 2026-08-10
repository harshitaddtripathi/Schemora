from datetime import datetime, timezone
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.core.database import get_db
from app.core.auth import get_current_user
from app.models.user import User
from app.models.scheme import Scheme
from app.models.saved_scheme import SavedScheme, SchemeReminder
from app.schemas.saved_scheme import (
    StatusUpdateRequest,
    SavedSchemeResponse,
    ReminderCreateRequest,
    ReminderResponse,
    VALID_STATUSES,
)
from app.schemas.common import APIResponse

router = APIRouter()


@router.post("/{scheme_id}/toggle-save", response_model=APIResponse[SavedSchemeResponse], summary="Save or Unsave Scheme")
async def toggle_save_scheme(
    scheme_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Save a scheme or toggle save status."""
    scheme_res = await db.execute(select(Scheme).where(Scheme.id == scheme_id))
    scheme = scheme_res.scalar_one_or_none()
    if not scheme:
        raise HTTPException(status_code=404, detail="Scheme not found")

    stmt = select(SavedScheme).where(SavedScheme.user_id == current_user.id, SavedScheme.scheme_id == scheme_id)
    res = await db.execute(stmt)
    saved = res.scalar_one_or_none()

    if saved:
        # Toggle or return existing
        pass
    else:
        saved = SavedScheme(
            user_id=current_user.id,
            scheme_id=scheme_id,
            status="Saved",
        )
        db.add(saved)
        await db.commit()
        await db.refresh(saved)

    resp_data = SavedSchemeResponse(
        id=saved.id,
        scheme_id=scheme.id,
        scheme_title=scheme.title,
        provider=scheme.provider,
        jurisdiction=scheme.jurisdiction,
        status=saved.status,
        notes=saved.notes,
        updated_at=saved.updated_at.isoformat(),
    )

    return APIResponse(
        success=True,
        message="Scheme saved successfully",
        data=resp_data,
    )


@router.get("", response_model=APIResponse[List[SavedSchemeResponse]], summary="List User Saved Schemes")
async def list_saved_schemes(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Retrieve list of user's saved schemes with manual application statuses."""
    stmt = (
        select(SavedScheme)
        .options(selectinload(SavedScheme.scheme))
        .where(SavedScheme.user_id == current_user.id)
    )
    result = await db.execute(stmt)
    saved_list = result.scalars().all()

    resp_data = [
        SavedSchemeResponse(
            id=s.id,
            scheme_id=s.scheme.id,
            scheme_title=s.scheme.title,
            provider=s.scheme.provider,
            jurisdiction=s.scheme.jurisdiction,
            status=s.status,
            notes=s.notes,
            updated_at=s.updated_at.isoformat(),
        )
        for s in saved_list
    ]

    return APIResponse(
        success=True,
        message="Saved schemes retrieved successfully",
        data=resp_data,
    )


@router.put("/{scheme_id}/status", response_model=APIResponse[SavedSchemeResponse], summary="Update Manual Application Status")
async def update_application_status(
    scheme_id: str,
    req: StatusUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Update manual application status (supports all 7 statuses)."""
    if req.status not in VALID_STATUSES:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid status '{req.status}'. Must be one of: {', '.join(VALID_STATUSES)}",
        )

    stmt = (
        select(SavedScheme)
        .options(selectinload(SavedScheme.scheme))
        .where(SavedScheme.user_id == current_user.id, SavedScheme.scheme_id == scheme_id)
    )
    res = await db.execute(stmt)
    saved = res.scalar_one_or_none()

    if not saved:
        # Auto-create saved record if updating status
        scheme_res = await db.execute(select(Scheme).where(Scheme.id == scheme_id))
        scheme = scheme_res.scalar_one_or_none()
        if not scheme:
            raise HTTPException(status_code=404, detail="Scheme not found")

        saved = SavedScheme(
            user_id=current_user.id,
            scheme_id=scheme_id,
            status=req.status,
            notes=req.notes,
        )
        db.add(saved)
    else:
        saved.status = req.status
        if req.notes:
            saved.notes = req.notes

    await db.commit()
    await db.refresh(saved)

    scheme_res = await db.execute(select(Scheme).where(Scheme.id == scheme_id))
    scheme = scheme_res.scalar_one()

    resp_data = SavedSchemeResponse(
        id=saved.id,
        scheme_id=scheme.id,
        scheme_title=scheme.title,
        provider=scheme.provider,
        jurisdiction=scheme.jurisdiction,
        status=saved.status,
        notes=saved.notes,
        updated_at=saved.updated_at.isoformat(),
    )

    return APIResponse(
        success=True,
        message=f"Application status updated to '{saved.status}'",
        data=resp_data,
    )


@router.post("/{scheme_id}/reminders", response_model=APIResponse[ReminderResponse], summary="Create Deadline Reminder")
async def create_reminder(
    scheme_id: str,
    req: ReminderCreateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Create deadline reminder for a scheme."""
    try:
        rem_date = datetime.fromisoformat(req.reminder_date.replace("Z", "+00:00"))
    except Exception:
        rem_date = datetime.now(timezone.utc)

    reminder = SchemeReminder(
        user_id=current_user.id,
        scheme_id=scheme_id,
        title=req.title,
        reminder_date=rem_date,
    )
    db.add(reminder)
    await db.commit()
    await db.refresh(reminder)

    resp_data = ReminderResponse(
        id=reminder.id,
        scheme_id=reminder.scheme_id,
        title=reminder.title,
        reminder_date=reminder.reminder_date.isoformat(),
        is_completed=reminder.is_completed,
    )

    return APIResponse(
        success=True,
        message="Deadline reminder created successfully",
        data=resp_data,
    )
