"""Eligibility Agent for evaluating scheme rules via deterministic engine MCP tools."""

from typing import Dict, Any, List
from sqlalchemy.ext.asyncio import AsyncSession

from mcp_server.registry import mcp_tool_registry
from mcp_server.schemas.tool_schemas import UserContext
from app.core.agent_logger import AgentExecutionTrace


class EligibilityAgent:
    """Specialized agent responsible for delegating rule evaluation strictly to deterministic engine."""

    def __init__(self, db: AsyncSession, trace: AgentExecutionTrace) -> None:
        self.db = db
        self.trace = trace

    async def execute(self, scheme_ids: List[str], context: UserContext) -> Dict[str, Any]:
        """Evaluate deterministic eligibility for given scheme IDs using MCP tool."""
        evaluations = []

        for sid in scheme_ids:
            # Call evaluate_eligibility MCP tool
            eval_res = await mcp_tool_registry.execute_tool(
                "evaluate_eligibility",
                {"scheme_id": sid},
                db=self.db,
                context=context
            )

            passed_ids = [r.rule_id for r in eval_res.passed_rules]
            failed_ids = [r.rule_id for r in eval_res.failed_rules]
            unresolved_ids = [r.rule_id for r in eval_res.unresolved_rules]

            evaluations.append({
                "agent": "eligibility_agent",
                "scheme_id": sid,
                "status": eval_res.overall_status,  # RuleMatched, NeedsInformation, NotMatched
                "confidence_score": eval_res.match_score,
                "passed_rule_ids": passed_ids,
                "failed_rule_ids": failed_ids,
                "unresolved_rule_ids": unresolved_ids,
                "passed_rules_detail": [r.model_dump() for r in eval_res.passed_rules],
                "failed_rules_detail": [r.model_dump() for r in eval_res.failed_rules],
                "unresolved_rules_detail": [r.model_dump() for r in eval_res.unresolved_rules],
                "explanation": eval_res.explanation,
                "deterministic_source_of_truth": True,
            })

        return {
            "agent": "eligibility_agent",
            "status": "SUCCESS",
            "count": len(evaluations),
            "evaluations": evaluations,
        }
