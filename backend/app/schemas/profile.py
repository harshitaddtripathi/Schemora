from datetime import date
from typing import Optional
from pydantic import BaseModel, Field, ConfigDict, model_validator


class StudentProfileBase(BaseModel):
    full_name: str = Field(..., min_length=2, max_length=128, json_schema_extra={"example": "Aarav Sharma"})
    date_of_birth: date = Field(..., json_schema_extra={"example": "2005-06-15"})
    gender: str = Field(..., json_schema_extra={"example": "Male"})
    state: str = Field(..., json_schema_extra={"example": "Maharashtra"})
    education_level: str = Field(..., json_schema_extra={"example": "Undergraduate"})
    course_name: Optional[str] = Field(None, json_schema_extra={"example": "B.Tech Computer Engineering"})
    institution_name: Optional[str] = Field(None, json_schema_extra={"example": "COEP Technological University"})
    institution_type: str = Field("Regular", json_schema_extra={"example": "Regular"})

    social_category: str = Field(..., json_schema_extra={"example": "OBC"})
    annual_family_income: Optional[float] = Field(None, ge=0, json_schema_extra={"example": 200000.0})
    is_full_time_student: bool = Field(True, json_schema_extra={"example": True})
    employment_status: str = Field("Unemployed", json_schema_extra={"example": "Unemployed"})
    citizenship: str = Field("Indian", json_schema_extra={"example": "Indian"})

    class12_percentile: Optional[float] = Field(None, ge=0, le=100, json_schema_extra={"example": 88.5})
    attendance_percentage: Optional[float] = Field(None, ge=0, le=100, json_schema_extra={"example": 82.0})
    education_gap_years: float = Field(0.0, ge=0, json_schema_extra={"example": 0.0})
    course_type: Optional[str] = Field(None, json_schema_extra={"example": "Professional"})
    admission_through_cap: Optional[bool] = Field(None, json_schema_extra={"example": True})
    family_male_beneficiaries_count: float = Field(0.0, ge=0, json_schema_extra={"example": 1.0})
    receiving_other_scholarship: bool = Field(False, json_schema_extra={"example": False})
    pmis_exclusion_clearance: Optional[bool] = Field(None, json_schema_extra={"example": True})


class StudentProfileCreate(StudentProfileBase):
    pass


class StudentProfileUpdate(BaseModel):
    full_name: Optional[str] = Field(None, min_length=2, max_length=128)
    date_of_birth: Optional[date] = None
    gender: Optional[str] = None
    state: Optional[str] = None
    education_level: Optional[str] = None
    course_name: Optional[str] = None
    institution_name: Optional[str] = None
    institution_type: Optional[str] = None
    social_category: Optional[str] = None
    annual_family_income: Optional[float] = Field(None, ge=0)
    is_full_time_student: Optional[bool] = None
    employment_status: Optional[str] = None
    citizenship: Optional[str] = None
    class12_percentile: Optional[float] = Field(None, ge=0, le=100)
    attendance_percentage: Optional[float] = Field(None, ge=0, le=100)
    education_gap_years: Optional[float] = Field(None, ge=0)
    course_type: Optional[str] = None
    admission_through_cap: Optional[bool] = None
    family_male_beneficiaries_count: Optional[float] = Field(None, ge=0)
    receiving_other_scholarship: Optional[bool] = None
    pmis_exclusion_clearance: Optional[bool] = None


class StudentProfileResponse(StudentProfileBase):
    model_config = ConfigDict(from_attributes=True)

    id: str
    user_id: str
    age: int = 0
    age_as_of: str = "2026-08-07"

    @model_validator(mode="before")
    @classmethod
    def calculate_age_field(cls, data: any) -> any:
        if isinstance(data, dict):
            dob = data.get("date_of_birth")
        else:
            dob = getattr(data, "date_of_birth", None)

        if dob:
            if isinstance(dob, str):
                dob = date.fromisoformat(dob)
            ref = date.fromisoformat("2026-08-07")
            calculated_age = ref.year - dob.year - ((ref.month, ref.day) < (dob.month, dob.day))
            if isinstance(data, dict):
                data["age"] = calculated_age
            else:
                setattr(data, "age", calculated_age)
        return data
