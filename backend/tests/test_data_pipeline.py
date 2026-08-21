import pytest
from app.services.data_pipeline.cleaner import (
    normalize_state,
    normalize_gender,
    normalize_social_category,
    parse_income_amount,
    parse_age_range,
    normalize_url,
    normalize_string,
    calculate_content_hash,
)
from app.services.data_pipeline.source_adapters import LocalRawFileSource
from app.services.eligibility_service import evaluate_user_against_scheme_dict
from scripts.clean_schemes import clean_raw_records


def test_income_normalization():
    assert parse_income_amount("₹2 Lakh") == 200000.0
    assert parse_income_amount("200000") == 200000.0
    assert parse_income_amount("2,00,000") == 200000.0
    assert parse_income_amount("Rs 2.5 Lakhs") == 250000.0
    assert parse_income_amount(None) is None


def test_age_normalization():
    min_a, max_a = parse_age_range("18 to 60 years")
    assert min_a == 18.0
    assert max_a == 60.0

    min_b, max_b = parse_age_range({"min": 20, "max": 40})
    assert min_b == 20.0
    assert max_b == 40.0


def test_state_normalization():
    assert normalize_state("MH") == "Maharashtra"
    assert normalize_state("maharashtra") == "Maharashtra"
    assert normalize_state("UP") == "Uttar Pradesh"
    assert normalize_state("DL") == "Delhi"


def test_gender_normalization():
    assert normalize_gender("female") == ["female"]
    assert normalize_gender("All") == ["all"]
    assert set(normalize_gender(["Male", "Female"])) == {"male", "female"}


def test_duplicate_detection_in_cleaning():
    raw_input = [
        {
            "source": "myScheme",
            "source_id": "SRC-001",
            "raw_data": {"scheme_name": "Scheme Alpha", "ministry": "Agri", "state": "MH"},
        },
        {
            "source": "myScheme",
            "source_id": "SRC-001",  # Duplicate Source ID
            "raw_data": {"scheme_name": "Scheme Alpha Duplicate", "ministry": "Agri", "state": "MH"},
        },
        {
            "source": "myScheme",
            "source_id": "SRC-002",
            "raw_data": {"scheme_name": "Scheme Alpha", "ministry": "Agri", "state": "MH"},  # Duplicate Name+State+Ministry combo
        },
    ]

    cleaned = clean_raw_records(raw_input)
    assert len(cleaned) == 1
    assert cleaned[0]["scheme_name"] == "Scheme Alpha"


def test_deterministic_eligibility_engine():
    scheme = {
        "scheme_id": "sch-001",
        "scheme_name": "Farmer Support Scheme",
        "government_level": "state",
        "state": "Maharashtra",
        "eligibility": {
            "age": {"min": 18, "max": 60},
            "gender": ["all"],
            "income": {"maximum": 200000},
            "social_category": ["OBC", "SC", "ST"],
            "states": ["Maharashtra"],
            "occupation": ["student", "farmer"],
        },
    }

    # 1. Eligible User
    user_eligible = {
        "age": 24,
        "gender": "female",
        "annual_income": 180000,
        "state": "Maharashtra",
        "occupation": "student",
        "social_category": "OBC",
    }
    res_eligible = evaluate_user_against_scheme_dict(user_eligible, scheme)
    assert res_eligible["eligibility"] == "eligible"
    assert "income" in res_eligible["matched_rules"]
    assert len(res_eligible["failed_rules"]) == 0

    # 2. Income too high
    user_high_income = dict(user_eligible, annual_income=300000)
    res_high_income = evaluate_user_against_scheme_dict(user_high_income, scheme)
    assert res_high_income["eligibility"] == "not_eligible"
    assert "income" in res_high_income["failed_rules"]

    # 3. Wrong State
    user_wrong_state = dict(user_eligible, state="Gujarat")
    res_wrong_state = evaluate_user_against_scheme_dict(user_wrong_state, scheme)
    assert res_wrong_state["eligibility"] == "not_eligible"
    assert "state" in res_wrong_state["failed_rules"]

    # 4. Missing Information -> Needs Review
    user_missing_income = {
        "age": 24,
        "gender": "female",
        "state": "Maharashtra",
    }
    res_missing = evaluate_user_against_scheme_dict(user_missing_income, scheme)
    assert res_missing["eligibility"] == "needs_review"
    assert "income" in res_missing["unknown_rules"]
