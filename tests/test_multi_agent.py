"""Test suite for Schemora Multi-Agent System & Orchestration Pipeline."""

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
from app.services.rag_service import ingest_document

from mcp_server.schemas.tool_schemas import UserContext
from app.agents.orchestrator import SchemoraOrchestratorAgent
from app.agents.specialized.scheme_discovery_agent import SchemeDiscoveryAgent
from app.agents.specialized.eligibility_agent import EligibilityAgent
from app.agents.specialized.document_agent import DocumentAgent
from app.agents.specialized.rag_agent import ResearchRAGAgent
from app.agents.specialized.guidance_agent import ApplicationGuidanceAgent
from app.agents.specialized.reminder_agent import ReminderTrackingAgent
from app.core.agent_logger import AgentExecutionTrace

ROOT = Path(__file__).resolve().parents[1]


@pytest.fixture(autouse=True, scope="module")
def init_agent_database():
    async def _init():
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.drop_all)
            await conn.run_sync(Base.metadata.create_all)
        json_path = ROOT / "data" / "schemes" / "schemes.v1.json"
        async with AsyncSessionLocal() as db:
            await seed_scheme_dataset(db, json_path)

            # Ingest RAG document
            await ingest_document(
                db=db,
                title="CSSS Guideline Document",
                content="The Central Sector Scheme of Scholarship for College and University Students provides financial aid to meritorious students above 80th percentile in Class 12.",
                scheme_id="sch-central-csss-001",
                source_url="https://scholarships.gov.in/public/CSSS_guidelines.pdf",
            )

            # Seed benchmark user
            user = User(id="user-agent-1", firebase_uid="uid-agent-1", phone_number="9988776655", role="citizen")
            db.add(user)
            await db.flush()

            profile = StudentProfile(
                id="prof-agent-1",
                user_id="user-agent-1",
                full_name="Agent Benchmark User",
                date_of_birth=datetime.date(2005, 6, 1),
                gender="Female",
                state="Maharashtra",
                social_category="OBC",
                education_level="Undergraduate",
                annual_family_income=200000.0,
                class12_percentile=92.0,
            )
            db.add(profile)
            await db.commit()

        await engine.dispose()

    asyncio.run(_init())


@pytest.mark.asyncio
async def test_orchestrator_intent_analysis_and_routing():
    """Verify orchestrator selects relevant agents based on user query intent."""
    async with AsyncSessionLocal() as db:
        orchestrator = SchemoraOrchestratorAgent(db)

        # 1. Scheme & eligibility query
        agents_1 = orchestrator.analyze_intent("Which scholarships can I apply for and am I eligible?")
        assert "scheme_discovery_agent" in agents_1
        assert "eligibility_agent" in agents_1

        # 2. Document requirement query
        agents_2 = orchestrator.analyze_intent("What documents do I need for Maharashtra OBC scholarship?")
        assert "document_agent" in agents_1 or "document_agent" in agents_2

        # 3. Specific question requiring RAG
        agents_3 = orchestrator.analyze_intent("What is the deadline and source for CSSS scholarship?")
        assert "research_rag_agent" in agents_3


@pytest.mark.asyncio
async def test_eligibility_agent_cannot_override_deterministic_result():
    """Verify EligibilityAgent relies strictly on deterministic engine evaluation."""
    ctx = UserContext(user_id="user-agent-1", firebase_uid="uid-agent-1", role="citizen")
    trace = AgentExecutionTrace(user_id="user-agent-1")
    async with AsyncSessionLocal() as db:
        agent = EligibilityAgent(db, trace)
        res = await agent.execute(scheme_ids=["sch-central-csss-001"], context=ctx)
        assert res["status"] == "SUCCESS"
        eval_item = res["evaluations"][0]
        assert eval_item["deterministic_source_of_truth"] is True
        assert eval_item["status"] in ("RuleMatched", "NeedsInformation")
        assert "csss-r001-class12-percentile" in eval_item["passed_rule_ids"]


@pytest.mark.asyncio
async def test_rag_agent_citations_and_fallback():
    """Verify ResearchRAGAgent cites evidence sources and returns fallback if ungrounded."""
    trace = AgentExecutionTrace(user_id="user-agent-1")
    async with AsyncSessionLocal() as db:
        agent = ResearchRAGAgent(db, trace)

        # Grounded query with evidence
        grounded_res = await agent.execute(query="financial aid for meritorious students 80th percentile", scheme_id="sch-central-csss-001")
        assert grounded_res["evidence_found"] is True
        assert len(grounded_res["sources"]) >= 1
        assert grounded_res["sources"][0]["official_url"] is not None

        # Unknown query without evidence
        ungrounded_res = await agent.execute(query="xyz999 random unknown non-existent government policy", scheme_id="sch-central-csss-001")
        assert ungrounded_res["evidence_found"] is False
        assert "Information not available" in ungrounded_res["message"]


@pytest.mark.asyncio
async def test_end_to_end_multi_agent_flow():
    """Verify End-to-End Orchestrator flow from user query to structured recommendation."""
    ctx = UserContext(user_id="user-agent-1", firebase_uid="uid-agent-1", role="citizen")
    async with AsyncSessionLocal() as db:
        orchestrator = SchemoraOrchestratorAgent(db)
        user_query = "Find government schemes I may be eligible for and tell me what documents I need."

        res = await orchestrator.execute(query=user_query, context=ctx)

        assert res["orchestrator"] == "SchemoraOrchestratorAgent"
        assert res["user_query"] == user_query
        assert len(res["selected_agents"]) >= 2
        assert len(res["recommendations"]) >= 1

        rec = res["recommendations"][0]
        assert "scheme_name" in rec
        assert "eligibility_status" in rec
        assert "confidence" in rec
        assert "why_matched" in rec
        assert "unresolved_conditions" in rec
        assert "required_documents" in rec
        assert "official_source" in rec
        assert "last_verified_date" in rec
        assert "official_application_url" in rec
