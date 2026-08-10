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
async def test_scheme_catalog_search_and_pagination():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        # Search all schemes
        res = await client.get("/api/v1/schemes")
        assert res.status_code == 200
        data = res.json()
        assert data["success"] is True
        assert len(data["data"]) >= 3
        assert "meta" in data

        # Search by query
        search_res = await client.get("/api/v1/schemes?q=internship")
        assert search_res.status_code == 200
        assert len(search_res.json()["data"]) >= 1
        assert "Internship" in search_res.json()["data"][0]["title"]


@pytest.mark.asyncio
async def test_scheme_details_with_rules_and_sources():
    scheme_id = "sch-central-csss-001"
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        res = await client.get(f"/api/v1/schemes/{scheme_id}")
        assert res.status_code == 200
        scheme_data = res.json()["data"]
        assert scheme_data["id"] == scheme_id
        assert len(scheme_data["rules"]) > 0
        assert len(scheme_data["sources"]) > 0


@pytest.mark.asyncio
async def test_top3_recommendations_calculation():
    headers = {"Authorization": "Bearer test-token-citizen-phase3"}
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        # Create student profile first
        profile_payload = {
            "full_name": "Aarav Sharma",
            "date_of_birth": "2005-06-15",
            "gender": "Male",
            "state": "Maharashtra",
            "education_level": "Undergraduate",
            "course_name": "B.Tech Computer Engineering",
            "institution_name": "COEP Technological University",
            "institution_type": "Regular",
            "social_category": "OBC",
            "annual_family_income": 200000.0,
            "is_full_time_student": True,
            "employment_status": "Unemployed",
            "citizenship": "Indian",
            "class12_percentile": 88.5,
            "attendance_percentage": 82.0,
        }
        await client.post("/api/v1/profile", json=profile_payload, headers=headers)

        # Request recommendations
        rec_res = await client.post("/api/v1/schemes/recommendations", headers=headers)
        assert rec_res.status_code == 200
        rec_data = rec_res.json()["data"]
        assert "top3_recommendations" in rec_data
        top3 = rec_data["top3_recommendations"]
        assert len(top3) <= 3

        # Verify that Top 3 excludes NotMatched schemes
        for item in top3:
            assert item["status"] != "NotMatched"
            assert item["confidence_score"] > 0.0
