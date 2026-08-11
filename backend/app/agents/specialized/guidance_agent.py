"""Application Guidance Agent for step-by-step instructions via MCP tools."""

from typing import Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession

from mcp_server.registry import mcp_tool_registry
from app.core.agent_logger import AgentExecutionTrace


class ApplicationGuidanceAgent:
    """Specialized agent explaining portal guidance, step workflows, and official links."""

    def __init__(self, db: AsyncSession, trace: AgentExecutionTrace) -> None:
        self.db = db
        self.trace = trace

    async def execute(self, scheme_id: str) -> Dict[str, Any]:
        """Fetch application steps and portal details via MCP tool."""
        steps_res = await mcp_tool_registry.execute_tool(
            "get_application_steps",
            {"scheme_id": scheme_id},
            db=self.db,
        )

        steps_data = [
            {
                "step_number": s.step_number,
                "title": s.title,
                "instruction": s.instruction,
                "official_url": s.official_url,
            }
            for s in steps_res.steps
        ]

        return {
            "agent": "application_guidance_agent",
            "status": "SUCCESS",
            "scheme_id": scheme_id,
            "application_mode": steps_res.application_mode,
            "official_portal_url": steps_res.portal_url,
            "steps": steps_data,
            "can_auto_submit": False,  # Explicit safety flag: Never auto-submits applications
            "guidance_note": "Please review all instructions and apply on the official government portal.",
        }
