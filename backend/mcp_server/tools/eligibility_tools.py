"""Deterministic Eligibility Evaluation MCP Tool for Schemora."""

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from fastapi import HTTPException

from app.models.scheme import Scheme
from app.models.student_profile import StudentProfile
from app.services.eligibility_service import evaluate_scheme_eligibility
from mcp_server.schemas.tool_schemas import (
    EvaluateEligibilityInput, EvaluateEligibilityOutput,
    RuleEvaluationResultSchema, UserContext,
)
from mcp_server.security import verify_user_authorization


async def evaluate_eligibility_tool(
    db: AsyncSession,
    input_data: EvaluateEligibilityInput,
    context: UserContext,
) -> EvaluateEligibilityOutput:
    """Evaluate scheme eligibility using the deterministic eligibility engine.
    
    This tool invokes the underlying deterministic eligibility engine and returns
    RuleMatched, NeedsInformation, or NotMatched along with passed/failed/unresolved rules.
    """
    verify_user_authorization(context)

    # 1. Fetch user's student profile
    prof_res = await db.execute(select(StudentProfile).where(StudentProfile.user_id == context.user_id))
    profile = prof_res.scalar_one_or_none()

    if not profile:
        return EvaluateEligibilityOutput(
            success=False,
            scheme_id=input_data.scheme_id,
            overall_status="NeedsInformation",
            match_score=0.0,
            passed_rules=[],
            failed_rules=[],
            unresolved_rules=[],
            explanation="Student profile not found. Please complete profile first.",
        )

    # 2. Fetch scheme with rules
    scheme_res = await db.execute(
        select(Scheme).options(selectinload(Scheme.rules)).where(Scheme.id == input_data.scheme_id)
    )
    scheme = scheme_res.scalar_one_or_none()

    if not scheme:
        return EvaluateEligibilityOutput(
            success=False,
            scheme_id=input_data.scheme_id,
            overall_status="NotMatched",
            match_score=0.0,
            passed_rules=[],
            failed_rules=[],
            unresolved_rules=[],
            explanation=f"Scheme '{input_data.scheme_id}' not found.",
        )

    # 3. Call deterministic eligibility engine
    eval_res = evaluate_scheme_eligibility(scheme, profile)

    passed_items = [
        RuleEvaluationResultSchema(
            rule_id=r["rule_id"],
            field_name=r["field_name"],
            operator=r["operator"],
            expected_value=r.get("expected_value") or r.get("expected"),
            rule_type=r.get("rule_type", "mandatory"),
            status="passed",
            failure_reason="",
        )
        for r in eval_res.get("matched_rules", [])
    ]

    failed_items = [
        RuleEvaluationResultSchema(
            rule_id=r["rule_id"],
            field_name=r["field_name"],
            operator=r["operator"],
            expected_value=r.get("expected_value") or r.get("expected"),
            rule_type=r.get("rule_type", "mandatory"),
            status="failed",
            failure_reason=r.get("failure_reason", "Condition failed"),
        )
        for r in eval_res.get("failed_rules", [])
    ]

    unresolved_items = [
        RuleEvaluationResultSchema(
            rule_id=r["rule_id"],
            field_name=r["field_name"],
            operator=r["operator"],
            expected_value=r.get("expected_value") or r.get("expected"),
            rule_type=r.get("rule_type", "mandatory"),
            status="unresolved",
            failure_reason="Information required",
        )
        for r in eval_res.get("unresolved_rules", [])
    ]

    status = eval_res["status"]
    score = float(eval_res["confidence_score"])

    explanation = (
        f"Deterministic engine evaluated {scheme.title}: Status '{status}' with match score {score:.0%}. "
        f"Passed rules: {len(passed_items)}, Failed rules: {len(failed_items)}, Unresolved rules: {len(unresolved_items)}."
    )

    return EvaluateEligibilityOutput(
        success=True,
        scheme_id=scheme.id,
        overall_status=status,
        match_score=score,
        passed_rules=passed_items,
        failed_rules=failed_items,
        unresolved_rules=unresolved_items,
        explanation=explanation,
    )
