from typing import Optional, List
from pydantic import BaseModel, ConfigDict, Field


class SchemeSourceResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    source_name: str
    url: str
    source_type: str
    last_verified_at: Optional[str] = None


class SchemeRuleResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    rule_id: str
    field_name: str
    operator: str
    expected_value: str
    rule_type: str
    failure_reason: Optional[str] = None


class SchemeResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    slug: str
    title: str
    short_description: str
    provider: str
    jurisdiction: str
    state: Optional[str] = None
    benefit_type: str
    benefit_summary: str
    implementation_status: str
    is_published: bool
    application_deadline: Optional[str] = None


class SchemeDetailResponse(SchemeResponse):
    detailed_description: Optional[str] = None
    gender_eligibility: str
    social_categories: str
    min_age: Optional[float] = None
    max_age: Optional[float] = None
    max_family_income: Optional[float] = None
    rules: List[SchemeRuleResponse] = []
    sources: List[SchemeSourceResponse] = []


class RecommendationItem(BaseModel):
    scheme_id: str
    scheme_title: str
    provider: str
    jurisdiction: str
    benefit_summary: str
    status: str  # RuleMatched, NeedsInformation, NotMatched
    confidence_score: float
    matched_rules_count: int
    unresolved_rules_count: int
    failed_rules_count: int
    unresolved_fields: List[str] = []


class RecommendationResponse(BaseModel):
    total_evaluated: int
    top3_recommendations: List[RecommendationItem]
    all_evaluations: List[RecommendationItem]
