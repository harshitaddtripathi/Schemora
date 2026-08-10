import pytest
from scripts.validate_phase0 import Phase0Validator

validator = Phase0Validator(skip_manifest=True)


def test_operator_evaluation():
    # eq / neq
    assert validator.evaluate_operator("Maharashtra", "eq", "Maharashtra") is True
    assert validator.evaluate_operator("Delhi", "eq", "Maharashtra") is False
    assert validator.evaluate_operator("General", "neq", "OBC") is True

    # gt / gte / lt / lte
    assert validator.evaluate_operator(85, "gte", 80) is True
    assert validator.evaluate_operator(80, "gte", 80) is True
    assert validator.evaluate_operator(79, "gte", 80) is False
    assert validator.evaluate_operator(200000, "lte", 250000) is True

    # in / not_in
    assert validator.evaluate_operator("Undergraduate", "in", ["Undergraduate", "Class12"]) is True
    assert validator.evaluate_operator("Postgraduate", "in", ["Undergraduate", "Class12"]) is False
    assert validator.evaluate_operator("FullTime", "not_in", ["Unemployed", "PartTime"]) is True

    # contains / exists
    assert validator.evaluate_operator(["OBC", "SC"], "contains", "OBC") is True
    assert validator.evaluate_operator("Valid Value", "exists", None) is True
    assert validator.evaluate_operator(None, "exists", None) is False


def test_missing_value_handling():
    assert validator.is_missing(None) is True
    assert validator.is_missing("unknown") is True
    assert validator.is_missing(0) is False
    assert validator.is_missing(False) is False
    assert validator.is_missing("") is False


def test_unresolved_rule_evaluation():
    node = {
        "rule_id": "test-unresolved",
        "type": "condition",
        "field": "annual_family_income",
        "operator": "lte",
        "value": 250000,
        "verification_status": "VerificationRequired",
    }
    outcomes = {}
    profile = {"annual_family_income": 200000}
    res = validator.evaluate_rule(node, profile, outcomes)
    assert res == "unresolved"
    assert outcomes["test-unresolved"] == "unresolved"


def test_and_group_logic():
    pass_condition = {
        "rule_id": "r1",
        "type": "condition",
        "field": "state",
        "operator": "eq",
        "value": "Maharashtra",
        "verification_status": "Verified",
    }
    fail_condition = {
        "rule_id": "r2",
        "type": "condition",
        "field": "annual_family_income",
        "operator": "lte",
        "value": 250000,
        "verification_status": "Verified",
    }

    group_and = {
        "rule_id": "g1",
        "type": "and",
        "conditions": [pass_condition, fail_condition],
    }

    # Case 1: Both pass
    profile1 = {"state": "Maharashtra", "annual_family_income": 200000}
    outcomes1 = {}
    assert validator.evaluate_rule(group_and, profile1, outcomes1) == "passed"

    # Case 2: One fails -> AND group fails
    profile2 = {"state": "Maharashtra", "annual_family_income": 300000}
    outcomes2 = {}
    assert validator.evaluate_rule(group_and, profile2, outcomes2) == "failed"


def test_or_group_logic():
    cond1 = {
        "rule_id": "r1",
        "type": "condition",
        "field": "gender",
        "operator": "eq",
        "value": "Female",
        "verification_status": "Verified",
    }
    cond2 = {
        "rule_id": "r2",
        "type": "condition",
        "field": "family_male_beneficiaries_count",
        "operator": "lte",
        "value": 2,
        "verification_status": "Verified",
    }

    group_or = {
        "rule_id": "g_or",
        "type": "or",
        "conditions": [cond1, cond2],
    }

    # Female applicant passes cond1 -> OR group passes
    profile1 = {"gender": "Female", "family_male_beneficiaries_count": 5}
    outcomes1 = {}
    assert validator.evaluate_rule(group_or, profile1, outcomes1) == "passed"

    # Male applicant with 1 male beneficiary passes cond2 -> OR group passes
    profile2 = {"gender": "Male", "family_male_beneficiaries_count": 1}
    outcomes2 = {}
    assert validator.evaluate_rule(group_or, profile2, outcomes2) == "passed"

    # Male applicant with 3 male beneficiaries fails both -> OR group fails
    profile3 = {"gender": "Male", "family_male_beneficiaries_count": 3}
    outcomes3 = {}
    assert validator.evaluate_rule(group_or, profile3, outcomes3) == "failed"
