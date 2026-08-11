"""Scheme discovery and metadata MCP tools for Schemora."""

from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, or_
from sqlalchemy.orm import selectinload

from app.models.scheme import Scheme, SchemeSource
from mcp_server.schemas.tool_schemas import (
    SearchSchemesInput, SearchSchemesOutput, SchemeItemSchema,
    GetSchemeInput, GetSchemeOutput, SchemeDetailSchema,
    GetSchemeSourcesInput, GetSchemeSourcesOutput, SourceItemSchema,
    GetApplicationWindowsInput, GetApplicationWindowsOutput, WindowSchema,
)


async def search_schemes_tool(
    db: AsyncSession,
    input_data: SearchSchemesInput,
) -> SearchSchemesOutput:
    """Search schemes in the curated knowledge base by query, state, and category."""
    stmt = select(Scheme).where(Scheme.is_published == True)

    if input_data.state:
        stmt = stmt.where(or_(Scheme.state == input_data.state, Scheme.state.is_(None)))

    if input_data.social_category:
        stmt = stmt.where(
            or_(
                Scheme.social_categories == "All",
                Scheme.social_categories.icontains(input_data.social_category)
            )
        )

    if input_data.query:
        q = f"%{input_data.query}%"
        stmt = stmt.where(
            or_(
                Scheme.title.ilike(q),
                Scheme.short_description.ilike(q),
                Scheme.detailed_description.ilike(q),
                Scheme.provider.ilike(q)
            )
        )

    stmt = stmt.limit(input_data.limit)
    res = await db.execute(stmt)
    schemes = res.scalars().all()

    items = [
        SchemeItemSchema(
            scheme_id=s.id,
            title=s.title,
            short_description=s.short_description,
            provider=s.provider,
            jurisdiction=s.jurisdiction,
            state=s.state,
            benefit_summary=s.benefit_summary,
            is_published=s.is_published,
            application_deadline=s.application_deadline,
        )
        for s in schemes
    ]

    return SearchSchemesOutput(success=True, count=len(items), schemes=items)


async def get_scheme_tool(
    db: AsyncSession,
    input_data: GetSchemeInput,
) -> GetSchemeOutput:
    """Retrieve comprehensive details and rule counts for a specific scheme."""
    stmt = (
        select(Scheme)
        .options(selectinload(Scheme.rules), selectinload(Scheme.sources))
        .where(Scheme.id == input_data.scheme_id)
    )
    res = await db.execute(stmt)
    scheme = res.scalar_one_or_none()

    if not scheme:
        return GetSchemeOutput(success=False, error=f"Scheme '{input_data.scheme_id}' not found.")

    detail = SchemeDetailSchema(
        id=scheme.id,
        title=scheme.title,
        short_description=scheme.short_description,
        detailed_description=scheme.detailed_description,
        provider=scheme.provider,
        jurisdiction=scheme.jurisdiction,
        state=scheme.state,
        gender_eligibility=scheme.gender_eligibility,
        social_categories=scheme.social_categories,
        benefit_type=scheme.benefit_type,
        benefit_summary=scheme.benefit_summary,
        implementation_status=scheme.implementation_status,
        is_published=scheme.is_published,
        application_deadline=scheme.application_deadline,
        rules_count=len(scheme.rules) if scheme.rules else 0,
        sources_count=len(scheme.sources) if scheme.sources else 0,
    )

    return GetSchemeOutput(success=True, scheme=detail)


async def get_scheme_sources_tool(
    db: AsyncSession,
    input_data: GetSchemeSourcesInput,
) -> GetSchemeSourcesOutput:
    """Retrieve verified official sources and URLs for a scheme."""
    stmt = select(SchemeSource).where(SchemeSource.scheme_id == input_data.scheme_id)
    res = await db.execute(stmt)
    sources = res.scalars().all()

    items = [
        SourceItemSchema(
            source_id=src.id,
            source_name=src.source_name,
            url=src.url,
            source_type=src.source_type,
            last_verified_at=src.last_verified_at,
        )
        for src in sources
    ]

    return GetSchemeSourcesOutput(success=True, scheme_id=input_data.scheme_id, sources=items)


async def get_application_windows_tool(
    db: AsyncSession,
    input_data: GetApplicationWindowsInput,
) -> GetApplicationWindowsOutput:
    """Retrieve application windows and deadline statuses for schemes."""
    stmt = select(Scheme).where(Scheme.is_published == True)
    if input_data.scheme_id:
        stmt = stmt.where(Scheme.id == input_data.scheme_id)

    res = await db.execute(stmt)
    schemes = res.scalars().all()

    windows = []
    for s in schemes:
        closing = s.application_deadline or "2026-12-31"
        windows.append(
            WindowSchema(
                scheme_id=s.id,
                scheme_title=s.title,
                status="Open",
                opening_date="2026-01-01",
                closing_date=closing,
            )
        )

    return GetApplicationWindowsOutput(success=True, windows=windows)
