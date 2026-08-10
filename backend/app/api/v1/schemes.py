from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from sqlalchemy.orm import selectinload

from app.core.database import get_db
from app.core.auth import get_current_user
from app.models.user import User
from app.models.student_profile import StudentProfile
from app.models.scheme import Scheme
from app.schemas.scheme import SchemeResponse, SchemeDetailResponse, RecommendationResponse, RecommendationItem
from app.schemas.common import APIResponse, PaginationMeta
from app.services.eligibility_service import evaluate_scheme_eligibility, rank_and_select_top3

router = APIRouter()


@router.get("", response_model=APIResponse[List[SchemeResponse]], summary="List & Search Scheme Catalog")
async def list_schemes(
    q: Optional[str] = Query(None, description="Search query string"),
    jurisdiction: Optional[str] = Query(None, description="Filter by jurisdiction: Central or State"),
    state: Optional[str] = Query(None, description="Filter by domicile state"),
    page: int = Query(1, ge=1),
    page_size: int = Query(10, ge=1, le=50),
    db: AsyncSession = Depends(get_db),
):
    """Retrieve paginated catalog of published schemes with filtering."""
    query = select(Scheme).where(Scheme.is_published == True)

    if jurisdiction:
        query = query.where(Scheme.jurisdiction == jurisdiction)
    if state:
        query = query.where((Scheme.state == state) | (Scheme.state == None))
    if q:
        q_lower = q.lower()
        query = query.where(
            (func.lower(Scheme.title).contains(q_lower))
            | (func.lower(Scheme.short_description).contains(q_lower))
        )

    result = await db.execute(query)
    all_items = result.scalars().all()

    total_items = len(all_items)
    total_pages = max(1, (total_items + page_size - 1) // page_size)
    start_idx = (page - 1) * page_size
    paginated_items = all_items[start_idx : start_idx + page_size]

    meta = PaginationMeta(
        page=page,
        page_size=page_size,
        total_items=total_items,
        total_pages=total_pages,
        has_next=page < total_pages,
        has_prev=page > 1,
    )

    return APIResponse(
        success=True,
        message="Schemes catalog retrieved successfully",
        data=[SchemeResponse.model_validate(s) for s in paginated_items],
        meta=meta,
    )


@router.get("/{scheme_id}", response_model=APIResponse[SchemeDetailResponse], summary="Get Scheme Details")
async def get_scheme_details(
    scheme_id: str,
    db: AsyncSession = Depends(get_db),
):
    """Retrieve comprehensive details of a scheme including rules and official sources."""
    query = (
        select(Scheme)
        .options(selectinload(Scheme.rules), selectinload(Scheme.sources))
        .where(Scheme.id == scheme_id)
    )
    result = await db.execute(query)
    scheme = result.scalar_one_or_none()

    if not scheme:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Scheme with ID '{scheme_id}' not found.",
        )

    return APIResponse(
        success=True,
        message="Scheme details retrieved successfully",
        data=SchemeDetailResponse.model_validate(scheme),
    )


@router.post("/recommendations", response_model=APIResponse[RecommendationResponse], summary="Calculate Recommendations")
async def get_recommendations(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Calculate real-time scheme recommendations and Top 3 for authenticated student."""
    # Fetch profile
    prof_res = await db.execute(select(StudentProfile).where(StudentProfile.user_id == current_user.id))
    profile = prof_res.scalar_one_or_none()

    if not profile:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Student profile not found. Please complete your profile before requesting recommendations.",
        )

    # Fetch all published schemes with rules
    schemes_res = await db.execute(
        select(Scheme).options(selectinload(Scheme.rules)).where(Scheme.is_published == True)
    )
    schemes = schemes_res.scalars().all()

    evaluations = [evaluate_scheme_eligibility(s, profile) for s in schemes]
    top3 = rank_and_select_top3(evaluations)

    resp_data = RecommendationResponse(
        total_evaluated=len(evaluations),
        top3_recommendations=[RecommendationItem(**item) for item in top3],
        all_evaluations=[RecommendationItem(**item) for item in evaluations],
    )

    return APIResponse(
        success=True,
        message="Scheme recommendations calculated successfully",
        data=resp_data,
    )
