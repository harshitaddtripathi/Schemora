from datetime import date
import pytest

from app.models.student_profile import StudentProfile
from app.services.document_service import (
    mask_aadhaar_number,
    mask_pan_number,
    parse_document_content,
    compare_document_with_profile,
    NON_LEGAL_DISCLAIMER,
)
from app.services.checklist_service import generate_scheme_checklist
from app.schemas.document import DocumentUploadRequest, DocumentResponse, ChecklistItem, SchemeChecklistResponse


@pytest.fixture
def sample_profile():
    return StudentProfile(
        id="prof-doc-1",
        user_id="user-doc-1",
        full_name="Aarav Sharma",
        date_of_birth=date(2005, 6, 15),
        gender="Male",
        state="Maharashtra",
        education_level="Undergraduate",
        annual_family_income=200000.0,
    )


def test_mask_aadhaar_number():
    assert mask_aadhaar_number("9999_8888_1234") == "XXXX-XXXX-1234"
    assert mask_aadhaar_number("1234_5678_9012") == "XXXX-XXXX-9012"
    assert mask_aadhaar_number("12") == "XXXX-XXXX-XXXX"


def test_mask_pan_number():
    assert mask_pan_number("ABCDE_1234_F") == "XXXXX-1234-X"
    assert mask_pan_number("SHORT") == "XXXXX-0000-X"


def test_parse_document_content():
    content = '{"full_name": "Aarav Sharma", "date_of_birth": "2005-06-15", "aadhaar_number": "9999_8888_1234"}'
    parsed = parse_document_content("Aadhaar", content)
    assert parsed["full_name"] == "Aarav Sharma"
    assert parsed["masked_identifier"] == "XXXX-XXXX-1234"


def test_compare_document_with_profile_verified(sample_profile):
    extracted = {"full_name": "Aarav Sharma", "date_of_birth": "2005-06-15"}
    status, notes = compare_document_with_profile("Aadhaar", extracted, sample_profile)
    assert status == "Verified"
    assert "match student profile perfectly" in notes


def test_compare_document_with_profile_correction_required(sample_profile):
    extracted = {"full_name": "Different Name", "date_of_birth": "1990-01-01"}
    status, notes = compare_document_with_profile("Aadhaar", extracted, sample_profile)
    assert status == "CorrectionRequired"
    assert "Name mismatch" in notes
    assert "Date of Birth mismatch" in notes


def test_generate_scheme_checklist_missing_docs():
    class DummySource:
        url = "https://scholarships.gov.in"

    class DummyScheme:
        id = "sch-central-csss-001"
        title = "Central Sector Scheme"
        sources = [DummySource()]

    checklist = generate_scheme_checklist(DummyScheme(), user_docs=[])
    assert checklist["scheme_id"] == "sch-central-csss-001"
    assert checklist["readiness_percentage"] == 0.0
    assert checklist["is_ready_for_application"] is False
    assert len(checklist["items"]) == 2
    assert checklist["items"][0]["status"] == "Missing"
