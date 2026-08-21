from typing import List, Optional, Any, Dict
from pydantic import BaseModel, Field, HttpUrl


class AgeEligibilitySchema(BaseModel):
    min: Optional[float] = None
    max: Optional[float] = None


class IncomeEligibilitySchema(BaseModel):
    minimum: Optional[float] = None
    maximum: Optional[float] = None
    currency: str = "INR"


class EligibilitySchema(BaseModel):
    age: AgeEligibilitySchema = Field(default_factory=AgeEligibilitySchema)
    gender: List[str] = Field(default_factory=list)  # ["all"], ["female"], ["male"], etc.
    income: IncomeEligibilitySchema = Field(default_factory=IncomeEligibilitySchema)
    occupation: List[str] = Field(default_factory=list)
    education: List[str] = Field(default_factory=list)
    social_category: List[str] = Field(default_factory=list)  # ["SC", "ST", "OBC", "General", "EWS"]
    disability: Optional[bool] = None
    marital_status: List[str] = Field(default_factory=list)
    residence: List[str] = Field(default_factory=list)
    states: List[str] = Field(default_factory=list)
    raw_rules_text: Optional[str] = None
    needs_review: bool = False


class ApplicationSchema(BaseModel):
    mode: List[str] = Field(default_factory=list)  # ["Online", "Offline", "CSC"]
    process: str = ""
    url: str = ""


class OfficialSourceSchema(BaseModel):
    name: str = ""
    url: str = ""
    source_id: str = ""
    last_verified: str = ""
    verification_status: str = "verified"  # verified, needs_review, outdated, unverified


class BenefitItemSchema(BaseModel):
    description: str = ""
    amount: Optional[float] = None
    currency: Optional[str] = "INR"
    benefit_type: str = "Financial"


class NormalizedScheme(BaseModel):
    scheme_id: str
    scheme_name: str
    slug: str

    government_level: str = "central"  # central, state
    state: Optional[str] = None

    ministry: str = ""
    department: str = ""

    category: List[str] = Field(default_factory=list)

    description: str = ""

    benefits: List[BenefitItemSchema] = Field(default_factory=list)

    eligibility: EligibilitySchema = Field(default_factory=EligibilitySchema)

    documents_required: List[str] = Field(default_factory=list)

    application: ApplicationSchema = Field(default_factory=ApplicationSchema)

    official_source: OfficialSourceSchema = Field(default_factory=OfficialSourceSchema)

    last_verified: str = ""
    content_hash: str = ""
    status: str = "active"  # active, inactive, draft
