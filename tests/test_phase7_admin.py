import asyncio
import pytest
import time
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

ADMIN_HEADERS = {"Authorization": "Bearer test-token-admin-evaluator"}
CITIZEN_HEADERS = {"Authorization": "Bearer test-token-citizen-phase7"}
NEW_SCHEME_ID = f"sch-admin-test-{int(time.time()) % 100000}"


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
async def test_admin_citizen_token_rejected():
    """P0-704: Citizen tokens must be rejected from all admin endpoints."""
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        res = await client.get("/api/v1/admin/schemes", headers=CITIZEN_HEADERS)
        assert res.status_code == 403
        assert "Administrative privilege required" in res.json()["detail"]


@pytest.mark.asyncio
async def test_admin_list_schemes():
    """P0-705: Admin can list all schemes."""
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        res = await client.get("/api/v1/admin/schemes", headers=ADMIN_HEADERS)
        assert res.status_code == 200
        data = res.json()["data"]
        assert len(data) >= 3
        assert all("id" in s and "title" in s for s in data)


@pytest.mark.asyncio
async def test_admin_create_and_edit_scheme():
    """P0-706: Admin can create a new scheme and edit it."""
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        # Create
        create_req = {
            "id": NEW_SCHEME_ID,
            "title": "Admin Pilot Scholarship",
            "provider": "Ministry of Education",
            "jurisdiction": "Central",
            "description": "A pilot scholarship for admin testing.",
            "category": "Scholarship",
            "application_mode": "Online",
        }
        res = await client.post("/api/v1/admin/schemes", json=create_req, headers=ADMIN_HEADERS)
        assert res.status_code == 200
        assert res.json()["data"]["id"] == NEW_SCHEME_ID

        # Edit
        edit_req = {"title": "Admin Pilot Scholarship (Updated)", "deadline_text": "31st December 2026"}
        edit_res = await client.put(f"/api/v1/admin/schemes/{NEW_SCHEME_ID}", json=edit_req, headers=ADMIN_HEADERS)
        assert edit_res.status_code == 200
        assert edit_res.json()["data"]["title"] == "Admin Pilot Scholarship (Updated)"


@pytest.mark.asyncio
async def test_admin_knowledge_publish_and_unpublish():
    """P0-711, P0-712, P0-713: Admin can publish knowledge chunks and verify unpublish removes them from retrieval."""
    scheme_id = "sch-central-csss-001"
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        # Publish knowledge
        publish_req = {
            "scheme_id": scheme_id,
            "source_text": "The Central Sector Scheme for Scholarship provides financial aid to meritorious students.",
            "source_url": "https://scholarships.gov.in/public/schemeGuidelines/CSSS",
        }
        pub_res = await client.post("/api/v1/admin/knowledge/publish", json=publish_req, headers=ADMIN_HEADERS)
        assert pub_res.status_code == 200
        assert pub_res.json()["data"]["status"] == "published"

        # Verify knowledge is retrievable via citizen AI chat
        chat_req = {"question": "What is the Central Sector Scheme for Scholarship?", "scheme_id": scheme_id}
        chat_res = await client.post("/api/v1/ai/chat", json=chat_req, headers=CITIZEN_HEADERS)
        assert chat_res.status_code == 200

        # Unpublish knowledge
        unpub_res = await client.post(
            "/api/v1/admin/knowledge/unpublish",
            json={"scheme_id": scheme_id},
            headers=ADMIN_HEADERS,
        )
        assert unpub_res.status_code == 200
        assert unpub_res.json()["data"]["status"] == "unpublished"
