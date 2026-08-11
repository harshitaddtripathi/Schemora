"""Programmatic Tool Registry & Execution Dispatcher for Schemora MCP Server."""

from typing import Dict, Any, Callable, Awaitable, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel

from mcp_server.schemas.tool_schemas import (
    UserContext,
    SearchSchemesInput, GetSchemeInput, GetSchemeSourcesInput, EvaluateEligibilityInput,
    GetRequiredDocumentsInput, GetApplicationStepsInput, GetApplicationWindowsInput,
    GetApplicationStatusInput, UpdateApplicationStatusInput, AnalyzeDocumentInput,
    GetDocumentChecklistInput, SearchKnowledgeBaseInput, GetOfficialSourceInput, CreateReminderInput,
)
from mcp_server.tools.scheme_tools import (
    search_schemes_tool, get_scheme_tool, get_scheme_sources_tool, get_application_windows_tool,
)
from mcp_server.tools.eligibility_tools import evaluate_eligibility_tool
from mcp_server.tools.document_tools import (
    get_required_documents_tool, analyze_document_tool, get_document_checklist_tool,
)
from mcp_server.tools.rag_tools import search_knowledge_base_tool, get_official_source_tool
from mcp_server.tools.user_tools import (
    get_student_profile_tool, get_saved_schemes_tool, get_application_status_tool,
    update_application_status_tool, create_reminder_tool,
)
from mcp_server.tools.guidance_tools import get_application_steps_tool


class MCPToolRegistry:
    """Registry mapping tool names to input schema classes and execution handlers."""

    def __init__(self) -> None:
        self._tools: Dict[str, Dict[str, Any]] = {}
        self._register_default_tools()

    def _register_default_tools(self) -> None:
        self.register(
            name="search_schemes",
            description="Search curated schemes by query, state, and category",
            schema_cls=SearchSchemesInput,
            handler=search_schemes_tool,
            requires_context=False,
        )
        self.register(
            name="get_scheme",
            description="Retrieve scheme details & rule counts by scheme ID",
            schema_cls=GetSchemeInput,
            handler=get_scheme_tool,
            requires_context=False,
        )
        self.register(
            name="get_scheme_sources",
            description="Retrieve official source URLs for a scheme",
            schema_cls=GetSchemeSourcesInput,
            handler=get_scheme_sources_tool,
            requires_context=False,
        )
        self.register(
            name="evaluate_eligibility",
            description="Invoke deterministic eligibility engine for user profile against scheme",
            schema_cls=EvaluateEligibilityInput,
            handler=evaluate_eligibility_tool,
            requires_context=True,
        )
        self.register(
            name="get_required_documents",
            description="List required documents for a scheme",
            schema_cls=GetRequiredDocumentsInput,
            handler=get_required_documents_tool,
            requires_context=False,
        )
        self.register(
            name="get_application_steps",
            description="Retrieve step-by-step application instructions and portal URL",
            schema_cls=GetApplicationStepsInput,
            handler=get_application_steps_tool,
            requires_context=False,
        )
        self.register(
            name="get_application_windows",
            description="Retrieve application opening and closing window dates",
            schema_cls=GetApplicationWindowsInput,
            handler=get_application_windows_tool,
            requires_context=False,
        )
        self.register(
            name="get_student_profile",
            description="Fetch authenticated user's student profile",
            schema_cls=None,
            handler=get_student_profile_tool,
            requires_context=True,
        )
        self.register(
            name="get_saved_schemes",
            description="Fetch user's saved/bookmarked schemes",
            schema_cls=None,
            handler=get_saved_schemes_tool,
            requires_context=True,
        )
        self.register(
            name="get_application_status",
            description="Retrieve application tracking status for user's saved schemes",
            schema_cls=GetApplicationStatusInput,
            handler=get_application_status_tool,
            requires_context=True,
        )
        self.register(
            name="update_application_status",
            description="Update status of user's scheme application",
            schema_cls=UpdateApplicationStatusInput,
            handler=update_application_status_tool,
            requires_context=True,
        )
        self.register(
            name="analyze_document",
            description="Parse document content, mask sensitive PII, and cross-verify with profile",
            schema_cls=AnalyzeDocumentInput,
            handler=analyze_document_tool,
            requires_context=True,
        )
        self.register(
            name="get_document_checklist",
            description="Build readiness checklist & document status for scheme",
            schema_cls=GetDocumentChecklistInput,
            handler=get_document_checklist_tool,
            requires_context=True,
        )
        self.register(
            name="search_knowledge_base",
            description="Search verified knowledge base using RAG vector retrieval",
            schema_cls=SearchKnowledgeBaseInput,
            handler=search_knowledge_base_tool,
            requires_context=False,
        )
        self.register(
            name="get_official_source",
            description="Retrieve metadata for a specific official source ID",
            schema_cls=GetOfficialSourceInput,
            handler=get_official_source_tool,
            requires_context=False,
        )
        self.register(
            name="create_reminder",
            description="Create scheme application deadline reminder for authenticated user",
            schema_cls=CreateReminderInput,
            handler=create_reminder_tool,
            requires_context=True,
        )

    def register(
        self,
        name: str,
        description: str,
        schema_cls: Optional[type[BaseModel]],
        handler: Callable[..., Awaitable[Any]],
        requires_context: bool = False,
    ) -> None:
        self._tools[name] = {
            "name": name,
            "description": description,
            "schema_cls": schema_cls,
            "handler": handler,
            "requires_context": requires_context,
        }

    def list_tools(self) -> Dict[str, Dict[str, Any]]:
        return self._tools

    async def execute_tool(
        self,
        name: str,
        arguments: Dict[str, Any],
        db: AsyncSession,
        context: Optional[UserContext] = None,
    ) -> Any:
        """Execute tool by name with arguments, db session, and user context."""
        if name not in self._tools:
            raise KeyError(f"MCP Tool '{name}' is not registered.")

        tool_info = self._tools[name]
        handler = tool_info["handler"]
        schema_cls = tool_info["schema_cls"]
        requires_context = tool_info["requires_context"]

        # Parse & validate arguments
        parsed_input = None
        if schema_cls:
            parsed_input = schema_cls.model_validate(arguments or {})

        # Invoke handler
        if requires_context:
            if not context:
                raise PermissionError(f"Tool '{name}' requires authenticated UserContext.")
            if parsed_input is not None:
                return await handler(db=db, input_data=parsed_input, context=context)
            else:
                return await handler(db=db, context=context)
        else:
            if parsed_input is not None:
                return await handler(db=db, input_data=parsed_input)
            else:
                return await handler(db=db)


# Global Singleton Tool Registry
mcp_tool_registry = MCPToolRegistry()
