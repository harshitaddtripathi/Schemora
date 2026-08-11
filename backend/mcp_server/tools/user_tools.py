"""User profile, saved schemes, application tracking, and reminder MCP tools."""

from typing import Optional
import datetime
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.models.student_profile import StudentProfile
from app.models.saved_scheme import SavedScheme, SchemeReminder
from app.models.scheme import Scheme
from mcp_server.schemas.tool_schemas import (
    GetStudentProfileOutput,
    GetSavedSchemesOutput, SavedSchemeItemSchema,
    GetApplicationStatusInput, GetApplicationStatusOutput, ApplicationStatusItemSchema,
    UpdateApplicationStatusInput, UpdateApplicationStatusOutput,
    CreateReminderInput, CreateReminderOutput,
    UserContext,
)
from mcp_server.security import verify_user_authorization, sanitize_output_data


async def get_student_profile_tool(
    db: AsyncSession,
    context: UserContext,
) -> GetStudentProfileOutput:
    """Retrieve authenticated user's student profile for matching and verification."""
    verify_user_authorization(context)

    stmt = select(StudentProfile).where(StudentProfile.user_id == context.user_id)
    res = await db.execute(stmt)
    profile = res.scalar_one_or_none()

    if not profile:
        return GetStudentProfileOutput(success=False, error="Student profile not found.")

    data = {
        "id": profile.id,
        "full_name": profile.full_name,
        "date_of_birth": str(profile.date_of_birth) if profile.date_of_birth else None,
        "gender": profile.gender,
        "state": profile.state,
        "education_level": profile.education_level,
        "course_name": profile.course_name,
        "institution_name": profile.institution_name,
        "social_category": profile.social_category,
        "annual_family_income": profile.annual_family_income,
        "class12_percentile": profile.class12_percentile,
        "attendance_percentage": profile.attendance_percentage,
        "is_full_time_student": profile.is_full_time_student,
        "employment_status": profile.employment_status,
        "citizenship": profile.citizenship,
    }

    sanitized = sanitize_output_data(data)
    return GetStudentProfileOutput(success=True, profile=sanitized)


async def get_saved_schemes_tool(
    db: AsyncSession,
    context: UserContext,
) -> GetSavedSchemesOutput:
    """Retrieve schemes saved/bookmarked by the authenticated user."""
    verify_user_authorization(context)

    stmt = select(SavedScheme).where(SavedScheme.user_id == context.user_id)
    res = await db.execute(stmt)
    saved = res.scalars().all()

    items = []
    for s in saved:
        # Fetch scheme title
        sch_res = await db.execute(select(Scheme).where(Scheme.id == s.scheme_id))
        sch = sch_res.scalar_one_or_none()
        title = sch.title if sch else "Saved Scheme"

        items.append(
            SavedSchemeItemSchema(
                saved_id=s.id,
                scheme_id=s.scheme_id,
                scheme_title=title,
                saved_at=str(s.saved_at) if hasattr(s, "saved_at") else "2026-08-07",
                status=s.application_status if hasattr(s, "application_status") else "Bookmarked",
            )
        )

    return GetSavedSchemesOutput(success=True, saved_schemes=items)


async def get_application_status_tool(
    db: AsyncSession,
    input_data: GetApplicationStatusInput,
    context: UserContext,
) -> GetApplicationStatusOutput:
    """Retrieve application status and history for user's saved schemes."""
    verify_user_authorization(context)

    stmt = select(SavedScheme).where(SavedScheme.user_id == context.user_id)
    if input_data.scheme_id:
        stmt = stmt.where(SavedScheme.scheme_id == input_data.scheme_id)

    res = await db.execute(stmt)
    saved = res.scalars().all()

    apps = [
        ApplicationStatusItemSchema(
            scheme_id=s.scheme_id,
            status=getattr(s, "application_status", "Draft"),
            updated_at=str(getattr(s, "updated_at", "2026-08-07")),
            notes=getattr(s, "notes", None),
        )
        for s in saved
    ]

    return GetApplicationStatusOutput(success=True, applications=apps)


async def update_application_status_tool(
    db: AsyncSession,
    input_data: UpdateApplicationStatusInput,
    context: UserContext,
) -> UpdateApplicationStatusOutput:
    """Update application tracking status for a scheme saved by user."""
    verify_user_authorization(context)

    stmt = select(SavedScheme).where(
        SavedScheme.user_id == context.user_id,
        SavedScheme.scheme_id == input_data.scheme_id
    )
    res = await db.execute(stmt)
    saved = res.scalar_one_or_none()

    now_str = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%d %H:%M:%S")

    if not saved:
        saved = SavedScheme(
            user_id=context.user_id,
            scheme_id=input_data.scheme_id,
            application_status=input_data.status,
            notes=input_data.notes,
        )
        db.add(saved)
    else:
        saved.application_status = input_data.status
        if input_data.notes:
            saved.notes = input_data.notes

    await db.commit()

    return UpdateApplicationStatusOutput(
        success=True,
        scheme_id=input_data.scheme_id,
        status=input_data.status,
        updated_at=now_str,
    )


async def create_reminder_tool(
    db: AsyncSession,
    input_data: CreateReminderInput,
    context: UserContext,
) -> CreateReminderOutput:
    """Create a application deadline reminder for the authenticated user."""
    verify_user_authorization(context)

    reminder = SchemeReminder(
        user_id=context.user_id,
        scheme_id=input_data.scheme_id,
        target_date=input_data.reminder_date,
        title=input_data.title,
        notes=input_data.notes,
        status="Scheduled",
    )
    db.add(reminder)
    await db.commit()
    await db.refresh(reminder)

    return CreateReminderOutput(
        success=True,
        reminder_id=reminder.id,
        scheme_id=input_data.scheme_id,
        reminder_date=input_data.reminder_date,
        status="Scheduled",
    )
