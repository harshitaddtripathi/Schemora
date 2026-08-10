import asyncio
import pytest
from httpx import AsyncClient, ASGITransport
import sys
from pathlib import Path

backend_path = Path(__file__).resolve().parents[1] / "backend"
if str(backend_path) not in sys.path:
    sys.path.insert(0, str(backend_path))

from app.main import app
from app.core.database import engine, AsyncSessionLocal
from app.db.base import Base
from app.services.seeder import seed_scheme_dataset

ROOT = Path(__file__).resolve().parents[1]


@pytest.fixture(autouse=True, scope="module")
def init_and_seed_database():
    async def _init():
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
        json_path = ROOT / "data" / "schemes" / "schemes.v1.json"
        async with AsyncSessionLocal() as db:
            await seed_scheme_dataset(db, json_path)

    asyncio.run(_init())


@pytest.mark.asyncio
async def test_ai_explain_recommendation():
    headers = {"Authorization": "Bearer test-token-citizen-phase4"}
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        # Create student profile
        profile_payload = {
            "full_name": "Kavya Joshi",
            "date_of_birth": "2006-01-15",
            "gender": "Female",
            "state": "Maharashtra",
            "education_level": "Undergraduate",
            "course_name": "B.Sc Biotechnology",
            "institution_name": "University of Mumbai",
            "institution_type": "Regular",
            "social_category": "OBC",
            "annual_family_income": 180000.0,
            "is_full_time_student": True,
            "employment_status": "Unemployed",
            "citizenship": "Indian",
            "class12_percentile": 92.5,
            "attendance_percentage": 85.0,
        }
        await client.post("/api/v1/profile", json=profile_payload, headers=headers)

        # Request AI explanation for CSSS scheme
        req_payload = {
            "scheme_id": "sch-central-csss-001",
            "language": "en",
        }
        res = await client.post("/api/v1/ai/explain-recommendation", json=req_payload, headers=headers)
        assert res.status_code == 200
        data = res.json()["data"]
        assert data["scheme_id"] == "sch-central-csss-001"
        assert "explanation" in data
        assert len(data["citations"]) > 0


@pytest.mark.asyncio
async def test_ai_chat_scoped_question_and_citations():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        chat_req = {
            "question": "What is the attendance requirement for Maharashtra OBC scholarship?",
            "scheme_id": "sch-maharashtra-obc-postmatric-002",
            "language": "en",
        }
        res = await client.post("/api/v1/ai/chat", json=chat_req)
        assert res.status_code == 200
        data = res.json()["data"]
        assert data["is_grounded"] is True
        assert "answer" in data
        assert len(data["citations"]) > 0


@pytest.mark.asyncio
async def test_ai_chat_out_of_scope_fallback():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        out_of_scope_req = {
            "question": "Who won the cricket match yesterday?",
            "language": "en",
        }
        res = await client.post("/api/v1/ai/chat", json=out_of_scope_req)
        assert res.status_code == 200
        data = res.json()["data"]
        assert data["is_grounded"] is False
        assert "Academic Scheme Assistant" in data["answer"]
