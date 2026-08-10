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
from app.schemas.saved_scheme import VALID_STATUSES

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
async def test_saved_schemes_and_7_status_transitions():
    headers = {"Authorization": "Bearer test-token-citizen-phase6"}
    scheme_id = "sch-central-csss-001"
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        # Create profile
        profile_payload = {
            "full_name": "Siddharth Verma",
            "date_of_birth": "2005-04-10",
            "gender": "Male",
            "state": "Maharashtra",
            "education_level": "Undergraduate",
            "annual_family_income": 220000.0,
        }
        await client.post("/api/v1/profile", json=profile_payload, headers=headers)

        # Save scheme (may already exist from prior run; accept any valid status)
        save_res = await client.post(f"/api/v1/saved-schemes/{scheme_id}/toggle-save", headers=headers)
        assert save_res.status_code == 200
        assert save_res.json()["data"]["status"] in VALID_STATUSES

        # Verify list saved schemes
        list_res = await client.get("/api/v1/saved-schemes", headers=headers)
        assert list_res.status_code == 200
        assert len(list_res.json()["data"]) >= 1

        # Test all 7 manual status updates
        for target_status in VALID_STATUSES:
            update_res = await client.put(
                f"/api/v1/saved-schemes/{scheme_id}/status",
                json={"status": target_status, "notes": f"Transitioned to {target_status}"},
                headers=headers,
            )
            assert update_res.status_code == 200
            assert update_res.json()["data"]["status"] == target_status


@pytest.mark.asyncio
async def test_deadline_reminders_and_analytics_event():
    headers = {"Authorization": "Bearer test-token-citizen-phase6"}
    scheme_id = "sch-maharashtra-obc-postmatric-002"
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        # Create reminder
        rem_req = {
            "title": "Submit Post-Matric Application",
            "reminder_date": "2026-10-25T09:00:00Z",
        }
        rem_res = await client.post(f"/api/v1/saved-schemes/{scheme_id}/reminders", json=rem_req, headers=headers)
        assert rem_res.status_code == 200
        assert rem_res.json()["data"]["title"] == rem_req["title"]

        # Log analytics event
        event_req = {
            "event_type": "OfficialPortalOpened",
            "scheme_id": scheme_id,
            "metadata": {"source_url": "https://mahadbt.maharashtra.gov.in"},
        }
        event_res = await client.post("/api/v1/analytics/event", json=event_req, headers=headers)
        assert event_res.status_code == 200
        assert event_res.json()["data"]["event_type"] == "OfficialPortalOpened"
