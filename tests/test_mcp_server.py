"""Test suite for Schemora FastMCP Server, MCP Tools, Authorization, and Isolation."""

import asyncio
import pytest
from pathlib import Path
import sys

backend_path = Path(__file__).resolve().parents[1] / "backend"
if str(backend_path) not in sys.path:
    sys.path.insert(0, str(backend_path))

import datetime
from app.core.database import engine, AsyncSessionLocal
from app.db.base import Base
from app.services.seeder import seed_scheme_dataset
from app.models.user import User
from app.models.student_profile import StudentProfile

from mcp_server.registry import mcp_tool_registry
from mcp_server.schemas.tool_schemas import UserContext, SearchSchemesInput, EvaluateEligibilityInput
from mcp_server.security import BLOCKED_SENSITIVE_KEYS

ROOT = Path(__file__).resolve().parents[1]


@pytest.fixture(autouse=True, scope="module")
def init_mcp_database():
    async def _init():
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.drop_all)
            await conn.run_sync(Base.metadata.create_all)
        json_path = ROOT / "data" / "schemes" / "schemes.v1.json"
        async with AsyncSessionLocal() as db:
            await seed_scheme_dataset(db, json_path)
            
            # Seed test users
            user_a = User(id="user-mcp-a", firebase_uid="uid-mcp-a", phone_number="9876543210", role="citizen")
            user_b = User(id="user-mcp-b", firebase_uid="uid-mcp-b", phone_number="9876543211", role="citizen")
            db.add_all([user_a, user_b])
            await db.flush()

            profile_a = StudentProfile(
                id="prof-mcp-a",
                user_id="user-mcp-a",
                full_name="User A MCP Test",
                date_of_birth=datetime.date(2005, 1, 1),
                gender="Female",
                state="Maharashtra",
                social_category="OBC",
                education_level="Undergraduate",
                annual_family_income=250000.0,
                class12_percentile=85.0,
            )
            db.add(profile_a)
            await db.commit()

        await engine.dispose()

    asyncio.run(_init())


@pytest.mark.asyncio
async def test_mcp_registry_inventory():
    """Verify all 16 MCP tools are registered in MCPToolRegistry."""
    tools = mcp_tool_registry.list_tools()
    assert len(tools) == 16
    expected_tools = [
        "search_schemes", "get_scheme", "get_scheme_sources", "evaluate_eligibility",
        "get_required_documents", "get_application_steps", "get_application_windows",
        "get_student_profile", "get_saved_schemes", "get_application_status",
        "update_application_status", "analyze_document", "get_document_checklist",
        "search_knowledge_base", "get_official_source", "create_reminder"
    ]
    for t in expected_tools:
        assert t in tools, f"Missing MCP tool: {t}"


@pytest.mark.asyncio
async def test_mcp_search_schemes_tool():
    """Test search_schemes tool returns source-backed results."""
    async with AsyncSessionLocal() as db:
        res = await mcp_tool_registry.execute_tool("search_schemes", {"query": "Central", "limit": 5}, db=db)
        assert res.success is True
        assert res.count >= 1
        assert any(s.scheme_id == "sch-central-csss-001" for s in res.schemes)


@pytest.mark.asyncio
async def test_mcp_evaluate_eligibility_tool_deterministic():
    """Test evaluate_eligibility tool invokes deterministic engine."""
    ctx_a = UserContext(user_id="user-mcp-a", firebase_uid="uid-mcp-a", role="citizen")
    async with AsyncSessionLocal() as db:
        res = await mcp_tool_registry.execute_tool(
            "evaluate_eligibility",
            {"scheme_id": "sch-central-csss-001"},
            db=db,
            context=ctx_a,
        )
        assert res.success is True
        assert res.scheme_id == "sch-central-csss-001"
        assert res.overall_status in ("RuleMatched", "NeedsInformation")
        assert len(res.passed_rules) >= 1
        assert "Deterministic engine" in res.explanation


@pytest.mark.asyncio
async def test_mcp_authorization_and_data_isolation():
    """Verify authenticated User Context is required and User A cannot access User B data."""
    ctx_a = UserContext(user_id="user-mcp-a", firebase_uid="uid-mcp-a", role="citizen")
    ctx_b = UserContext(user_id="user-mcp-b", firebase_uid="uid-mcp-b", role="citizen")

    async with AsyncSessionLocal() as db:
        # User A profile access succeeds
        res_a = await mcp_tool_registry.execute_tool("get_student_profile", {}, db=db, context=ctx_a)
        assert res_a.success is True
        assert res_a.profile["full_name"] == "User A MCP Test"

        # User B profile access returns not found (isolated)
        res_b = await mcp_tool_registry.execute_tool("get_student_profile", {}, db=db, context=ctx_b)
        assert res_b.success is False
        assert "not found" in res_b.error.lower()

        # Unauthenticated execution on context-required tool raises PermissionError
        with pytest.raises(PermissionError):
            await mcp_tool_registry.execute_tool("get_student_profile", {}, db=db, context=None)


@pytest.mark.asyncio
async def test_mcp_no_sensitive_secrets_exposed():
    """Verify tool outputs do not leak passwords, API keys, or raw secrets."""
    ctx_a = UserContext(user_id="user-mcp-a", firebase_uid="uid-mcp-a", role="citizen")
    async with AsyncSessionLocal() as db:
        res = await mcp_tool_registry.execute_tool("get_student_profile", {}, db=db, context=ctx_a)
        data_str = str(res.profile)
        for key in BLOCKED_SENSITIVE_KEYS:
            assert f"'{key}'" not in data_str


@pytest.mark.asyncio
async def test_mcp_invalid_tool_error_handling():
    """Verify invalid tool names and malformed inputs are handled gracefully."""
    async with AsyncSessionLocal() as db:
        with pytest.raises(KeyError):
            await mcp_tool_registry.execute_tool("non_existent_tool", {}, db=db)
