"""Research and RAG Agent for retrieving evidence-backed knowledge via MCP tools."""

from typing import Dict, Any, Optional
from sqlalchemy.ext.asyncio import AsyncSession

from mcp_server.registry import mcp_tool_registry
from app.core.agent_logger import AgentExecutionTrace


class ResearchRAGAgent:
    """Specialized agent responsible for searching verified knowledge chunks and official sources."""

    def __init__(self, db: AsyncSession, trace: AgentExecutionTrace) -> None:
        self.db = db
        self.trace = trace

    async def execute(self, query: str, scheme_id: Optional[str] = None) -> Dict[str, Any]:
        """Retrieve verified knowledge chunks and sources matching query."""
        kb_res = await mcp_tool_registry.execute_tool(
            "search_knowledge_base",
            {"query": query, "scheme_id": scheme_id, "limit": 5},
            db=self.db,
        )

        if not kb_res.results or kb_res.fallback_message:
            return {
                "agent": "research_rag_agent",
                "status": "NO_EVIDENCE",
                "query": query,
                "evidence_found": False,
                "message": "Information not available in Schemora's verified knowledge base.",
                "sources": [],
                "source_ids": [],
            }

        sources = []
        source_ids = []
        evidence_snippets = []

        for r in kb_res.results:
            sources.append({
                "source_id": r.source_id,
                "source_title": r.source_title,
                "official_url": r.official_url,
                "last_verified_at": r.last_verified_at,
                "relevance_score": r.relevance_score,
            })
            source_ids.append(r.source_id)
            evidence_snippets.append(r.content_snippet)

        return {
            "agent": "research_rag_agent",
            "status": "SUCCESS",
            "query": query,
            "evidence_found": True,
            "message": "Found evidence in Schemora's verified knowledge base.",
            "evidence_snippets": evidence_snippets,
            "sources": sources,
            "source_ids": source_ids,
        }
