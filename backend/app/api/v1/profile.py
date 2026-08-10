from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.database import get_db
from app.core.auth import get_current_user
from app.models.user import User
from app.models.student_profile import StudentProfile
from app.schemas.profile import StudentProfileCreate, StudentProfileUpdate, StudentProfileResponse
from app.schemas.common import APIResponse

router = APIRouter()


@router.get("/me", response_model=APIResponse[StudentProfileResponse], summary="Get Current Student Profile")
async def get_my_profile(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Retrieve authenticated user's student profile."""
    result = await db.execute(select(StudentProfile).where(StudentProfile.user_id == current_user.id))
    profile = result.scalar_one_or_none()

    if not profile:
        raise HTTPException(
            status_code=status.HTTP_444_PROFILE_NOT_FOUND if hasattr(status, "HTTP_444_PROFILE_NOT_FOUND") else status.HTTP_404_NOT_FOUND,
            detail="Student profile not found. Please complete profile creation.",
        )

    return APIResponse(
        success=True,
        message="Student profile retrieved successfully",
        data=StudentProfileResponse.model_validate(profile),
    )


@router.post("", response_model=APIResponse[StudentProfileResponse], status_code=status.HTTP_201_CREATED, summary="Create Student Profile")
async def create_profile(
    profile_in: StudentProfileCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Create a student profile for authenticated user."""
    # Check if profile already exists
    existing = await db.execute(select(StudentProfile).where(StudentProfile.user_id == current_user.id))
    if existing.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Profile already exists for this user. Use PUT /api/v1/profile to update.",
        )

    profile_data = profile_in.model_dump()
    profile = StudentProfile(
        user_id=current_user.id,
        **profile_data,
    )
    db.add(profile)
    await db.commit()
    await db.refresh(profile)

    return APIResponse(
        success=True,
        message="Student profile created successfully",
        data=StudentProfileResponse.model_validate(profile),
    )


@router.put("", response_model=APIResponse[StudentProfileResponse], summary="Update Student Profile")
async def update_profile(
    profile_in: StudentProfileUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Update existing student profile fields."""
    result = await db.execute(select(StudentProfile).where(StudentProfile.user_id == current_user.id))
    profile = result.scalar_one_or_none()

    if not profile:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Student profile not found",
        )

    update_data = profile_in.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(profile, field, value)

    await db.commit()
    await db.refresh(profile)

    return APIResponse(
        success=True,
        message="Student profile updated successfully",
        data=StudentProfileResponse.model_validate(profile),
    )


@router.delete("", response_model=APIResponse[dict], summary="Delete Account & Profile Cleanup")
async def delete_profile(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Account deletion and complete profile data cleanup."""
    await db.delete(current_user)
    await db.commit()

    return APIResponse(
        success=True,
        message="User account and profile data deleted successfully",
        data={"user_id": current_user.id},
    )
