import json
from typing import List, Dict, Any, Tuple
from app.models.student_profile import StudentProfile
from app.models.scheme import Scheme, SchemeRule


def parse_expected_value(raw: str) -> Any:
    try:
        return json.loads(raw)
    except Exception:
        return raw


def evaluate_rule_condition(rule: SchemeRule, profile: StudentProfile) -> str:
    """Evaluates a single rule condition against student profile.
    Returns: 'passed', 'failed', or 'unresolved'
    """
    field_name = rule.field_name
    val = getattr(profile, field_name, None)

    # Missing profile field => Unresolved
    if val is None:
        return "unresolved"

    operator = rule.operator
    expected = parse_expected_value(rule.expected_value)

    if expected is None and operator in ("lte", "gte", "eq"):
        return "unresolved"

    try:
        if operator == "eq":
            return "passed" if val == expected else "failed"
        elif operator == "neq":
            return "passed" if val != expected else "failed"
        elif operator == "gt":
            return "passed" if val > float(expected) else "failed"
        elif operator == "gte":
            return "passed" if val >= float(expected) else "failed"
        elif operator == "lt":
            return "passed" if val < float(expected) else "failed"
        elif operator == "lte":
            return "passed" if val <= float(expected) else "failed"
        elif operator == "in":
            return "passed" if val in expected else "failed"
        elif operator == "not_in":
            return "passed" if val not in expected else "failed"
        elif operator == "contains":
            return "passed" if expected in str(val) else "failed"
        elif operator == "exists":
            return "passed" if bool(val) else "failed"
        else:
            return "unresolved"
    except Exception:
        return "unresolved"


def evaluate_scheme_eligibility(scheme: Scheme, profile: StudentProfile) -> Dict[str, Any]:
    matched_rules = []
    failed_rules = []
    unresolved_rules = []
    unresolved_fields = set()

    for rule in scheme.rules:
        outcome = evaluate_rule_condition(rule, profile)
        rule_info = {
            "rule_id": rule.rule_id,
            "field_name": rule.field_name,
            "operator": rule.operator,
            "outcome": outcome,
            "failure_reason": rule.failure_reason,
        }

        if outcome == "passed":
            matched_rules.append(rule_info)
        elif outcome == "failed":
            failed_rules.append(rule_info)
        else:
            unresolved_rules.append(rule_info)
            unresolved_fields.add(rule.field_name)

    # Determine overall status
    if len(failed_rules) > 0:
        status = "NotMatched"
        confidence_score = 0.0
    elif len(unresolved_rules) > 0:
        status = "NeedsInformation"
        total_rules = max(1, len(scheme.rules))
        confidence_score = round(len(matched_rules) / total_rules, 2)
    else:
        status = "RuleMatched"
        confidence_score = 1.0

    return {
        "scheme_id": scheme.id,
        "scheme_title": scheme.title,
        "provider": scheme.provider,
        "jurisdiction": scheme.jurisdiction,
        "benefit_summary": scheme.benefit_summary,
        "status": status,
        "confidence_score": confidence_score,
        "matched_rules_count": len(matched_rules),
        "unresolved_rules_count": len(unresolved_rules),
        "failed_rules_count": len(failed_rules),
        "unresolved_fields": list(unresolved_fields),
        "matched_rules": matched_rules,
        "unresolved_rules": unresolved_rules,
        "failed_rules": failed_rules,
    }


def rank_and_select_top3(evaluations: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    # Exclude NotMatched
    eligible_candidates = [e for e in evaluations if e["status"] != "NotMatched"]

    status_weights = {
        "RuleMatched": 2.0,
        "NeedsInformation": 1.0,
        "NotMatched": 0.0,
    }

    eligible_candidates.sort(
        key=lambda x: (
            status_weights.get(x["status"], 0.0),
            x["confidence_score"],
            x["matched_rules_count"],
        ),
        reverse=True,
    )

    return eligible_candidates[:3]
