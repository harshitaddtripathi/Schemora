"""RAG and Knowledge Base MCP tools for Schemora."""

from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.models.scheme import SchemeSource
from app.services.rag_service import retrieve_relevant_chunks
from mcp_server.schemas.tool_schemas import (
    SearchKnowledgeBaseInput, SearchKnowledgeBaseOutput, KnowledgeChunkSchema,
    GetOfficialSourceInput, GetOfficialSourceOutput,
)


async def search_knowledge_base_tool(
    db: AsyncSession,
    input_data: SearchKnowledgeBaseInput,
) -> SearchKnowledgeBaseOutput:
    """Search verified government scheme knowledge chunks using RAG retrieval.
    
    Returns structured chunks with source_id, official_url, content_snippet, and score.
    If no relevant knowledge is found, returns fallback message.
    """
    raw_chunks = await retrieve_relevant_chunks(
        db=db,
        query=input_data.query,
        scheme_id=input_data.scheme_id,
        top_k=input_data.limit,
    )

    # Filter out chunks with zero or negligible relevance
    relevant_chunks = [c for c in raw_chunks if c["similarity_score"] > 0.001]

    if not relevant_chunks:
        return SearchKnowledgeBaseOutput(
            success=True,
            query=input_data.query,
            results=[],
            fallback_message="Information not available in Schemora's verified knowledge base.",
        )

    results = []
    for idx, c in enumerate(relevant_chunks):
        src_id = f"src-rag-{c.get('scheme_id') or 'gen'}-{idx+1}"
        results.append(
            KnowledgeChunkSchema(
                chunk_id=c["chunk_id"],
                scheme_id=c.get("scheme_id") or "general",
                source_id=src_id,
                source_title=c.get("source_title", "Official Scheme Documentation"),
                official_url=c.get("source_url", "https://myscheme.gov.in"),
                content_snippet=c["content"],
                last_verified_at="2026-08-07",
                relevance_score=c["similarity_score"],
            )
        )

    return SearchKnowledgeBaseOutput(
        success=True,
        query=input_data.query,
        results=results,
        fallback_message=None,
    )


async def get_official_source_tool(
    db: AsyncSession,
    input_data: GetOfficialSourceInput,
) -> GetOfficialSourceOutput:
    """Retrieve metadata for a specific official source ID."""
    stmt = select(SchemeSource).where(SchemeSource.id == input_data.source_id)
    res = await db.execute(stmt)
    source = res.scalar_one_or_none()

    if not source:
        return GetOfficialSourceOutput(
            success=False,
            source_id=input_data.source_id,
            source_name="Unknown Source",
            url="https://myscheme.gov.in",
            source_type="OfficialPortal",
            last_verified_at="2026-08-07",
        )

    return GetOfficialSourceOutput(
        success=True,
        source_id=source.id,
        source_name=source.source_name,
        url=source.url,
        source_type=source.source_type,
        last_verified_at=source.last_verified_at,
    )
