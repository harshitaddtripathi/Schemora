from datetime import date
import pytest
from pydantic import ValidationError
from app.schemas.profile import StudentProfileCreate, StudentProfileUpdate, StudentProfileResponse


def test_student_profile_create_schema_valid():
    payload = {
        "full_name": "Rohan Deshmukh",
        "date_of_birth": "2004-11-20",
        "gender": "Male",
        "state": "Maharashtra",
        "education_level": "Undergraduate",
        "course_name": "B.Com",
        "institution_name": "SP College Pune",
        "institution_type": "Regular",
        "social_category": "General",
        "annual_family_income": 250000.0,
        "is_full_time_student": True,
        "employment_status": "Unemployed",
        "citizenship": "Indian",
        "class12_percentile": 85.0,
        "attendance_percentage": 78.0,
    }
    schema = StudentProfileCreate(**payload)
    assert schema.full_name == "Rohan Deshmukh"
    assert schema.date_of_birth == date(2004, 11, 20)
    assert schema.annual_family_income == 250000.0


def test_student_profile_create_invalid_income():
    payload = {
        "full_name": "Rohan Deshmukh",
        "date_of_birth": "2004-11-20",
        "gender": "Male",
        "state": "Maharashtra",
        "education_level": "Undergraduate",
        "social_category": "General",
        "annual_family_income": -100.0,  # Invalid negative income
    }
    with pytest.raises(ValidationError):
        StudentProfileCreate(**payload)


def test_student_profile_response_age_calculation():
    payload = {
        "id": "prof-123",
        "user_id": "usr-456",
        "full_name": "Priya Patil",
        "date_of_birth": "2007-08-10",
        "gender": "Female",
        "state": "Maharashtra",
        "education_level": "Class12",
        "social_category": "SC",
    }
    response = StudentProfileResponse.model_validate(payload)
    # DOB: 2007-08-10, Age as of 2026-08-07: 18 years old (birthday on Aug 10, so 18)
    assert response.age == 18
