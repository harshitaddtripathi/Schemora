"""Document Agent for analyzing document readiness and verification status via MCP tools."""

from typing import Dict, Any, List, Optional
from sqlalchemy.ext.asyncio import AsyncSession

from mcp_server.registry import mcp_tool_registry
from mcp_server.schemas.tool_schemas import UserContext
from app.core.agent_logger import AgentExecutionTrace


class DocumentAgent:
    """Specialized agent responsible for document checklist verification and OCR matching."""

    def __init__(self, db: AsyncSession, trace: AgentExecutionTrace) -> None:
        self.db = db
        self.trace = trace

    async def execute(self, scheme_id: str, context: Optional[UserContext] = None) -> Dict[str, Any]:
        """Fetch document requirements and readiness checklist for a scheme."""
        # 1. Fetch static required documents via MCP tool
        req_docs_res = await mcp_tool_registry.execute_tool(
            "get_required_documents",
            {"scheme_id": scheme_id},
            db=self.db,
        )

        required_docs = [
            {
                "doc_type": d.doc_type,
                "title": d.title,
                "description": d.description,
                "is_mandatory": d.is_mandatory,
            }
            for d in req_docs_res.required_documents
        ]

        # 2. Build readiness checklist if authenticated
        checklist_items = []
        readiness_pct = 0.0

        if context:
            try:
                chk_res = await mcp_tool_registry.execute_tool(
                    "get_document_checklist",
                    {"scheme_id": scheme_id},
                    db=self.db,
                    context=context,
                )
                if chk_res.success:
                    readiness_pct = chk_res.readiness_percentage
                    checklist_items = [
                        {
                            "doc_type": it.doc_type,
                            "status": it.status,  # Available, Missing, VerificationRequired
                            "masked_identifier": it.masked_identifier,
                        }
                        for it in chk_res.items
                    ]
            except Exception:
                pass

        missing_docs = [d["doc_type"] for d in checklist_items if d["status"] == "Missing"]

        return {
            "agent": "document_agent",
            "status": "SUCCESS",
            "scheme_id": scheme_id,
            "readiness_percentage": readiness_pct,
            "required_documents": required_docs,
            "checklist_status": checklist_items,
            "missing_documents": missing_docs,
        }
