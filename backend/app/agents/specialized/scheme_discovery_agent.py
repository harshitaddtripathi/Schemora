"""Scheme Discovery Agent for finding and filtering curated schemes via MCP tools."""

from typing import Dict, Any, Optional
from sqlalchemy.ext.asyncio import AsyncSession

from mcp_server.registry import mcp_tool_registry
from mcp_server.schemas.tool_schemas import UserContext
from app.core.agent_logger import AgentExecutionTrace


class SchemeDiscoveryAgent:
    """Specialized agent responsible for finding verified schemes matching user criteria."""

    def __init__(self, db: AsyncSession, trace: AgentExecutionTrace) -> None:
        self.db = db
        self.trace = trace

    async def execute(self, query: Optional[str] = None, context: Optional[UserContext] = None) -> Dict[str, Any]:
        """Discover schemes matching query and optional authenticated user profile."""
        state = None
        social_category = None

        # Fetch student profile via MCP user tool if context is available
        if context:
            try:
                prof_res = await mcp_tool_registry.execute_tool("get_student_profile", {}, db=self.db, context=context)
                if prof_res.success and prof_res.profile:
                    state = prof_res.profile.get("state")
                    social_category = prof_res.profile.get("social_category")
            except Exception:
                pass

        # Execute search_schemes MCP tool
        search_args = {
            "query": query,
            "state": state,
            "social_category": social_category,
            "limit": 10,
        }

        search_res = await mcp_tool_registry.execute_tool("search_schemes", search_args, db=self.db)
        
        found_schemes = []
        for s in search_res.schemes:
            found_schemes.append({
                "scheme_id": s.scheme_id,
                "title": s.title,
                "short_description": s.short_description,
                "provider": s.provider,
                "jurisdiction": s.jurisdiction,
                "state": s.state,
                "benefit_summary": s.benefit_summary,
                "application_deadline": s.application_deadline,
            })

        return {
            "agent": "scheme_discovery_agent",
            "status": "SUCCESS",
            "count": len(found_schemes),
            "schemes": found_schemes,
            "filtered_by_state": state,
            "filtered_by_category": social_category,
            "source_backed": True,
        }
