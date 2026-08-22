from typing import Optional, List, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel, Field
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
from app.services.eligibility_service import evaluate_scheme_eligibility, rank_and_select_top3, evaluate_user_against_scheme_dict

router = APIRouter()


class DirectEligibilityRequest(BaseModel):
    age: Optional[float] = None
    gender: Optional[str] = None
    annual_income: Optional[float] = None
    state: Optional[str] = None
    occupation: Optional[str] = None
    social_category: Optional[str] = None
    education: Optional[str] = None
    disability: Optional[bool] = None


class DirectEligibilityResponse(BaseModel):
    eligible_schemes: List[Dict[str, Any]] = Field(default_factory=list)
    needs_review: List[Dict[str, Any]] = Field(default_factory=list)
    not_eligible: List[Dict[str, Any]] = Field(default_factory=list)


@router.get("", response_model=APIResponse[List[SchemeResponse]], summary="List & Search Scheme Catalog")
@router.get("/search", response_model=APIResponse[List[SchemeResponse]], summary="Search Scheme Catalog")
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

    count_query = select(func.count()).select_from(query.subquery())
    count_res = await db.execute(count_query)
    total_items = count_res.scalar() or 0

    start_idx = (page - 1) * page_size
    paginated_query = query.offset(start_idx).limit(page_size)
    result = await db.execute(paginated_query)
    paginated_items = result.scalars().all()

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


@router.get("/categories", response_model=APIResponse[List[str]], summary="Get Scheme Categories")
async def get_categories(db: AsyncSession = Depends(get_db)):
    """Return available unique scheme categories."""
    categories = [
        "Agriculture",
        "Education",
        "Skill & Employment",
        "Business & MSME",
        "Women & Child Development",
        "Senior Citizen & Pension",
        "Health & Healthcare",
        "Housing & Social Welfare",
    ]
    return APIResponse(
        success=True,
        message="Scheme categories retrieved successfully",
        data=categories,
    )


@router.get("/states", response_model=APIResponse[List[str]], summary="Get Supported States/UTs")
async def get_states(db: AsyncSession = Depends(get_db)):
    """Return supported Indian States and Union Territories."""
    states = [
        "Maharashtra",
        "Uttar Pradesh",
        "Gujarat",
        "Karnataka",
        "Tamil Nadu",
        "West Bengal",
        "Delhi",
        "Bihar",
        "Rajasthan",
        "Madhya Pradesh",
        "Kerala",
        "Punjab",
        "Haryana",
        "Andhra Pradesh",
        "Telangana",
        "Odisha",
        "Assam",
        "Jharkhand",
        "Uttarakhand",
        "Himachal Pradesh",
        "Chhattisgarh",
        "Goa",
        "Jammu and Kashmir",
    ]
    return APIResponse(
        success=True,
        message="Supported states retrieved successfully",
        data=states,
    )


@router.post("/eligibility", response_model=APIResponse[DirectEligibilityResponse], summary="Direct Deterministic Eligibility Check")
async def check_eligibility_direct(
    req: DirectEligibilityRequest,
    db: AsyncSession = Depends(get_db),
):
    """Evaluate user profile dictionary deterministically against all schemes."""
    query = select(Scheme).options(selectinload(Scheme.rules)).where(Scheme.is_published == True)
    schemes_res = await db.execute(query)
    schemes = schemes_res.scalars().all()

    user_dict = req.model_dump()
    eligible = []
    needs_review = []
    not_eligible = []

    for s in schemes:
        # Convert DB model to dict format for evaluation
        s_dict = {
            "scheme_id": s.id,
            "scheme_name": s.title,
            "government_level": s.jurisdiction.lower(),
            "state": s.state,
            "eligibility": {
                "age": {"min": s.min_age, "max": s.max_age},
                "gender": [s.gender_eligibility] if s.gender_eligibility else ["all"],
                "income": {"maximum": s.max_family_income},
                "social_category": s.social_categories.split(",") if s.social_categories else [],
                "states": [s.state] if s.state else [],
            },
        }

        res = evaluate_user_against_scheme_dict(user_dict, s_dict)
        status_val = res.get("eligibility")

        if status_val == "eligible":
            eligible.append(res)
        elif status_val == "needs_review":
            needs_review.append(res)
        else:
            not_eligible.append(res)

    resp_data = DirectEligibilityResponse(
        eligible_schemes=eligible,
        needs_review=needs_review,
        not_eligible=not_eligible,
    )

    return APIResponse(
        success=True,
        message="Deterministic scheme eligibility evaluated successfully",
        data=resp_data,
    )


@router.get("/recommendations", response_model=APIResponse[RecommendationResponse], summary="Calculate Recommendations")
@router.post("/recommendations", response_model=APIResponse[RecommendationResponse], summary="Calculate Recommendations")
async def get_recommendations(
    category: Optional[str] = Query(None, description="Active profile category filter"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Calculate real-time scheme recommendations and Top 3 for authenticated student."""
    prof_res = await db.execute(select(StudentProfile).where(StudentProfile.user_id == current_user.id))
    profile = prof_res.scalar_one_or_none()

    if not profile:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Student profile not found. Please complete your profile before requesting recommendations.",
        )

    query = select(Scheme).options(selectinload(Scheme.rules)).where(Scheme.is_published == True)
    schemes_res = await db.execute(query)
    schemes = schemes_res.scalars().all()

    evaluations = [evaluate_scheme_eligibility(s, profile) for s in schemes]

    for ev in evaluations:
        scheme_id = ev["scheme_id"]
        matched_scheme = next((s for s in schemes if s.id == scheme_id), None)
        if matched_scheme:
            if category and matched_scheme.scheme_category and matched_scheme.scheme_category.lower() == category.lower():
                ev["confidence_score"] = min(1.0, ev["confidence_score"] + 0.3)
            if profile and profile.state and matched_scheme.state and matched_scheme.state.lower() == profile.state.lower():
                ev["confidence_score"] = min(1.0, ev["confidence_score"] + 0.2)

    evaluations.sort(key=lambda x: (x["status"] == "RuleMatched", x["confidence_score"]), reverse=True)

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
