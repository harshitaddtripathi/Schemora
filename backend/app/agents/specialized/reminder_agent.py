"""Reminder and Tracking Agent for managing saved schemes, status, and deadlines via MCP tools."""

from typing import Dict, Any, Optional
from sqlalchemy.ext.asyncio import AsyncSession

from mcp_server.registry import mcp_tool_registry
from mcp_server.schemas.tool_schemas import UserContext
from app.core.agent_logger import AgentExecutionTrace


class ReminderTrackingAgent:
    """Specialized agent tracking user application status and setting deadline reminders."""

    def __init__(self, db: AsyncSession, trace: AgentExecutionTrace) -> None:
        self.db = db
        self.trace = trace

    async def execute(
        self,
        action: str = "get_status",
        scheme_id: Optional[str] = None,
        new_status: Optional[str] = None,
        reminder_date: Optional[str] = None,
        context: Optional[UserContext] = None,
    ) -> Dict[str, Any]:
        """Perform application tracking or reminder operations via MCP tools."""
        if not context:
            return {
                "agent": "reminder_tracking_agent",
                "status": "UNAUTHENTICATED",
                "message": "User context required for tracking and reminders.",
            }

        if action == "create_reminder" and scheme_id and reminder_date:
            rem_res = await mcp_tool_registry.execute_tool(
                "create_reminder",
                {
                    "scheme_id": scheme_id,
                    "reminder_date": reminder_date,
                    "title": f"Deadline Reminder for {scheme_id}",
                    "notes": "Automated deadline alert set by Schemora Reminder Agent",
                },
                db=self.db,
                context=context,
            )
            return {
                "agent": "reminder_tracking_agent",
                "status": "SUCCESS",
                "action": "create_reminder",
                "reminder_id": rem_res.reminder_id,
                "scheme_id": rem_res.scheme_id,
                "reminder_date": rem_res.reminder_date,
            }

        if action == "update_status" and scheme_id and new_status:
            upd_res = await mcp_tool_registry.execute_tool(
                "update_application_status",
                {"scheme_id": scheme_id, "status": new_status, "notes": "Updated by Reminder Agent"},
                db=self.db,
                context=context,
            )
            return {
                "agent": "reminder_tracking_agent",
                "status": "SUCCESS",
                "action": "update_status",
                "scheme_id": upd_res.scheme_id,
                "new_status": upd_res.status,
                "updated_at": upd_res.updated_at,
            }

        # Default action: get saved schemes & application status
        saved_res = await mcp_tool_registry.execute_tool("get_saved_schemes", {}, db=self.db, context=context)
        status_res = await mcp_tool_registry.execute_tool("get_application_status", {"scheme_id": scheme_id}, db=self.db, context=context)

        saved_list = [s.model_dump() for s in saved_res.saved_schemes]
        apps_list = [a.model_dump() for a in status_res.applications]

        return {
            "agent": "reminder_tracking_agent",
            "status": "SUCCESS",
            "action": "get_status",
            "saved_schemes_count": len(saved_list),
            "saved_schemes": saved_list,
            "application_statuses": apps_list,
        }
