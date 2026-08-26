import json
from typing import List, Dict, Any, Tuple, Optional
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

    # Check category/title mismatch (e.g. Student profile evaluating non-student target schemes)
    scheme_text = f"{scheme.title} {scheme.scheme_category or ''} {scheme.short_description or ''}".lower()

    if any(kw in scheme_text for kw in ["kisan", "fasal", "farmer", "agriculture", "agri", "crop", "landholding"]):
        failed_rules.append({
            "rule_id": "rule_profile_mismatch_farmer",
            "field_name": "occupation",
            "operator": "eq",
            "outcome": "failed",
            "failure_reason": "Ineligible: Active profile is 'Student', whereas this scheme is designed for 'Farmers' with agricultural landholding or farming occupation.",
        })
    elif any(kw in scheme_text for kw in ["mudra", "svanidhi", "pmegp", "business", "enterprise", "msme"]):
        failed_rules.append({
            "rule_id": "rule_profile_mismatch_entrepreneur",
            "field_name": "occupation",
            "operator": "eq",
            "outcome": "failed",
            "failure_reason": "Ineligible: Active profile is 'Student', whereas this scheme requires an active micro-enterprise or business registration.",
        })
    elif any(kw in scheme_text for kw in ["pension", "apy", "ignoaps", "senior", "scss", "old age"]):
        failed_rules.append({
            "rule_id": "rule_profile_mismatch_senior",
            "field_name": "age",
            "operator": "gte",
            "outcome": "failed",
            "failure_reason": "Ineligible: Active profile is 'Student' (Age ~20), whereas senior citizen schemes require age 60+ or retired pension status.",
        })
    elif any(kw in scheme_text for kw in ["ladki", "bahin", "gruha", "lakshmi", "sumangala", "sukanya", "matru", "women", "female"]):
        failed_rules.append({
            "rule_id": "rule_profile_mismatch_women",
            "field_name": "gender",
            "operator": "eq",
            "outcome": "failed",
            "failure_reason": "Ineligible: Active profile is 'Student / Learner', whereas women/family schemes are restricted to female heads of household or women beneficiaries.",
        })

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


def evaluate_user_against_scheme_dict(user: Dict[str, Any], scheme: Dict[str, Any]) -> Dict[str, Any]:
    """Deterministic eligibility evaluation of a user profile dict against a normalized scheme dict.
    
    Returns:
        {
          "scheme_id": "...",
          "scheme_name": "...",
          "eligibility": "eligible" | "not_eligible" | "needs_review",
          "matched_rules": [],
          "failed_rules": [],
          "unknown_rules": []
        }
    """
    matched = []
    failed = []
    unknown = []

    elig = scheme.get("eligibility", {})
    if not isinstance(elig, dict):
        elig = {}

    # 1. Age check
    age_req = elig.get("age", {})
    user_age = user.get("age")
    if user_age is not None:
        try:
            u_age = float(user_age)
            min_a = age_req.get("min")
            max_a = age_req.get("max")
            if min_a is not None and u_age < min_a:
                failed.append("age_min")
            elif max_a is not None and u_age > max_a:
                failed.append("age_max")
            elif min_a is not None or max_a is not None:
                matched.append("age")
        except Exception:
            unknown.append("age")
    elif age_req.get("min") is not None or age_req.get("max") is not None:
        unknown.append("age")

    # 2. Gender check
    gender_req = elig.get("gender", [])
    user_gender = user.get("gender")
    if user_gender:
        u_gen = str(user_gender).lower()
        g_req_lower = [str(g).lower() for g in gender_req]
        if "all" in g_req_lower or not g_req_lower:
            matched.append("gender")
        elif u_gen in g_req_lower:
            matched.append("gender")
        else:
            failed.append("gender")
    elif gender_req and "all" not in [str(g).lower() for g in gender_req]:
        unknown.append("gender")

    # 3. Income check
    income_req = elig.get("income", {})
    max_income = income_req.get("maximum") if isinstance(income_req, dict) else None
    user_income = user.get("annual_income") or user.get("family_income")
    if user_income is not None and max_income is not None:
        try:
            if float(user_income) <= float(max_income):
                matched.append("income")
            else:
                failed.append("income")
        except Exception:
            unknown.append("income")
    elif max_income is not None:
        unknown.append("income")

    # 4. State / Domicile check
    scheme_govt_level = scheme.get("government_level", "central").lower()
    scheme_state = scheme.get("state")
    user_state = user.get("state")

    if scheme_govt_level == "state" or scheme_state:
        if user_state:
            if scheme_state and user_state.strip().lower() == scheme_state.strip().lower():
                matched.append("state")
            elif not scheme_state:
                matched.append("state")
            else:
                failed.append("state")
        else:
            unknown.append("state")

    # 5. Social Category check
    soc_req = elig.get("social_category", [])
    user_soc = user.get("social_category")
    if user_soc and soc_req:
        soc_req_upper = [s.upper() for s in soc_req]
        if user_soc.strip().upper() in soc_req_upper or "ALL" in soc_req_upper:
            matched.append("social_category")
        else:
            failed.append("social_category")
    elif soc_req:
        unknown.append("social_category")

    # 6. Occupation check
    occ_req = elig.get("occupation", [])
    user_occ = str(user.get("occupation") or user.get("profile_type") or "student").lower()
    scheme_title = (scheme.get("scheme_name") or scheme.get("title") or "").lower()

    if user_occ in ["student", "learner", "unemployed"]:
        if any(kw in scheme_title for kw in ["kisan", "fasal", "farmer", "agri", "crop"]):
            failed.append("occupation_mismatch_student_vs_farmer")
        elif any(kw in scheme_title for kw in ["mudra", "svanidhi", "pmegp", "business", "msme"]):
            failed.append("occupation_mismatch_student_vs_entrepreneur")
        elif any(kw in scheme_title for kw in ["pension", "apy", "ignoaps", "senior", "scss"]):
            failed.append("age_mismatch_student_vs_senior")
        elif any(kw in scheme_title for kw in ["ladki", "bahin", "gruha", "lakshmi", "sumangala", "women"]):
            failed.append("profile_mismatch_student_vs_women")
    elif user_occ and occ_req:
        occ_req_lower = [o.lower() for o in occ_req]
        if user_occ.strip().lower() in occ_req_lower or "all" in occ_req_lower:
            matched.append("occupation")
        else:
            failed.append("occupation")
    elif occ_req:
        unknown.append("occupation")

    # 7. Education check
    edu_req = elig.get("education", [])
    user_edu = user.get("education")
    if user_edu and edu_req:
        edu_req_lower = [e.lower() for e in edu_req]
        if user_edu.strip().lower() in edu_req_lower or "all" in edu_req_lower:
            matched.append("education")
        else:
            failed.append("education")
    elif edu_req:
        unknown.append("education")

    # 8. Disability check
    disability_req = elig.get("disability")
    user_disability = user.get("disability")
    if disability_req is not None:
        if user_disability is not None:
            if bool(user_disability) == bool(disability_req):
                matched.append("disability")
            else:
                failed.append("disability")
        else:
            unknown.append("disability")

    # Final status evaluation
    if len(failed) > 0:
        overall_status = "not_eligible"
    elif len(unknown) > 0:
        overall_status = "needs_review"
    else:
        overall_status = "eligible"

    return {
        "scheme_id": scheme.get("scheme_id") or scheme.get("id"),
        "scheme_name": scheme.get("scheme_name") or scheme.get("title"),
        "eligibility": overall_status,
        "matched_rules": matched,
        "failed_rules": failed,
        "unknown_rules": unknown,
    }
