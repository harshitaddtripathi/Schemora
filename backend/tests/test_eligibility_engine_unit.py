from datetime import date
import pytest

from app.models.student_profile import StudentProfile
from app.models.scheme import Scheme, SchemeRule
from app.services.eligibility_service import (
    evaluate_rule_condition,
    evaluate_scheme_eligibility,
    rank_and_select_top3,
)


@pytest.fixture
def sample_profile():
    return StudentProfile(
        id="prof-unit-1",
        user_id="user-unit-1",
        full_name="Vikram Salunkhe",
        date_of_birth=date(2005, 5, 15),
        gender="Male",
        state="Maharashtra",
        education_level="Undergraduate",
        social_category="OBC",
        annual_family_income=200000.0,
        class12_percentile=85.0,
        attendance_percentage=80.0,
        is_full_time_student=True,
        employment_status="Unemployed",
        citizenship="Indian",
    )


def test_evaluate_rule_condition_operators(sample_profile):
    # Operator: eq (passed)
    r_eq = SchemeRule(field_name="state", operator="eq", expected_value='"Maharashtra"')
    assert evaluate_rule_condition(r_eq, sample_profile) == "passed"

    # Operator: eq (failed)
    r_eq_fail = SchemeRule(field_name="state", operator="eq", expected_value='"Karnataka"')
    assert evaluate_rule_condition(r_eq_fail, sample_profile) == "failed"

    # Operator: gte (passed)
    r_gte = SchemeRule(field_name="class12_percentile", operator="gte", expected_value="80")
    assert evaluate_rule_condition(r_gte, sample_profile) == "passed"

    # Operator: lte (passed)
    r_lte = SchemeRule(field_name="annual_family_income", operator="lte", expected_value="250000")
    assert evaluate_rule_condition(r_lte, sample_profile) == "passed"

    # Operator: in (passed)
    r_in = SchemeRule(field_name="social_category", operator="in", expected_value='["OBC", "SC", "ST"]')
    assert evaluate_rule_condition(r_in, sample_profile) == "passed"


def test_evaluate_rule_condition_missing_field():
    incomplete_profile = StudentProfile(
        id="prof-inc-1",
        user_id="user-inc-1",
        full_name="Test User",
        date_of_birth=date(2005, 5, 15),
        gender="Male",
        state="Maharashtra",
        education_level="Undergraduate",
        social_category="General",
        annual_family_income=None,  # Missing income
    )
    r_income = SchemeRule(field_name="annual_family_income", operator="lte", expected_value="250000")
    assert evaluate_rule_condition(r_income, incomplete_profile) == "unresolved"


def test_evaluate_scheme_eligibility_status_matched(sample_profile):
    scheme = Scheme(
        id="sch-unit-1",
        title="Sample Scholarship",
        provider="Dept of Education",
        jurisdiction="State",
        benefit_summary="Financial Support",
        rules=[
            SchemeRule(rule_id="r1", field_name="state", operator="eq", expected_value='"Maharashtra"'),
            SchemeRule(rule_id="r2", field_name="social_category", operator="eq", expected_value='"OBC"'),
        ],
    )
    eval_res = evaluate_scheme_eligibility(scheme, sample_profile)
    assert eval_res["status"] == "RuleMatched"
    assert eval_res["confidence_score"] == 1.0
    assert eval_res["matched_rules_count"] == 2


def test_evaluate_scheme_eligibility_status_needs_information():
    incomplete_profile = StudentProfile(
        id="prof-inc-2",
        user_id="user-inc-2",
        full_name="Test User 2",
        date_of_birth=date(2005, 5, 15),
        gender="Female",
        state="Maharashtra",
        education_level="Undergraduate",
        social_category="OBC",
        annual_family_income=None,
    )
    scheme = Scheme(
        id="sch-unit-2",
        title="Sample Scholarship 2",
        provider="Dept of Education",
        jurisdiction="State",
        benefit_summary="Financial Support",
        rules=[
            SchemeRule(rule_id="r1", field_name="state", operator="eq", expected_value='"Maharashtra"'),
            SchemeRule(rule_id="r2", field_name="annual_family_income", operator="lte", expected_value="250000"),
        ],
    )
    eval_res = evaluate_scheme_eligibility(scheme, incomplete_profile)
    assert eval_res["status"] == "NeedsInformation"
    assert 0.0 < eval_res["confidence_score"] < 1.0
    assert "annual_family_income" in eval_res["unresolved_fields"]


def test_rank_and_select_top3():
    items = [
        {"scheme_id": "s1", "status": "NotMatched", "confidence_score": 0.0, "matched_rules_count": 0},
        {"scheme_id": "s2", "status": "NeedsInformation", "confidence_score": 0.5, "matched_rules_count": 1},
        {"scheme_id": "s3", "status": "RuleMatched", "confidence_score": 1.0, "matched_rules_count": 3},
        {"scheme_id": "s4", "status": "RuleMatched", "confidence_score": 1.0, "matched_rules_count": 4},
    ]

    top3 = rank_and_select_top3(items)

    assert len(top3) == 3
    # Top 1 should be s4 (highest matched rules count among RuleMatched)
    assert top3[0]["scheme_id"] == "s4"
    # s1 (NotMatched) should be excluded
    assert not any(i["scheme_id"] == "s1" for i in top3)
