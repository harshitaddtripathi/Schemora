"""Application step guidance MCP tools for Schemora."""

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.models.scheme import Scheme, SchemeSource
from mcp_server.schemas.tool_schemas import (
    GetApplicationStepsInput, GetApplicationStepsOutput, StepSchema,
)


async def get_application_steps_tool(
    db: AsyncSession,
    input_data: GetApplicationStepsInput,
) -> GetApplicationStepsOutput:
    """Retrieve official step-by-step application guidance and portal links for a scheme."""
    stmt = select(Scheme).where(Scheme.id == input_data.scheme_id)
    res = await db.execute(stmt)
    scheme = res.scalar_one_or_none()

    portal_url = f"https://scholarships.gov.in/schemes/{input_data.scheme_id}"
    if scheme:
        src_res = await db.execute(select(SchemeSource).where(SchemeSource.scheme_id == scheme.id))
        source = src_res.scalars().first()
        if source and source.url:
            portal_url = source.url

    steps = [
        StepSchema(
            step_number=1,
            title="Registration & Profile Setup",
            instruction="Register on the official portal using your Aadhaar-linked mobile number and verify student details.",
            official_url=portal_url,
        ),
        StepSchema(
            step_number=2,
            title="Document Upload & Verification",
            instruction="Upload verified copies of Income Certificate, Class 12 Marksheet, and Category Certificate.",
            official_url=portal_url,
        ),
        StepSchema(
            step_number=3,
            title="Institutional Verification",
            instruction="Submit application to your institute nodal officer for online verification.",
            official_url=portal_url,
        ),
        StepSchema(
            step_number=4,
            title="Final Submission & Tracking",
            instruction="Review details, click Final Submit, and save the generated Application ID for tracking.",
            official_url=portal_url,
        ),
    ]

    return GetApplicationStepsOutput(
        success=True,
        scheme_id=input_data.scheme_id,
        application_mode="Online",
        portal_url=portal_url,
        steps=steps,
    )
