import asyncio
import pytest
from httpx import AsyncClient, ASGITransport
import sys
from pathlib import Path

backend_path = Path(__file__).resolve().parents[1] / "backend"
if str(backend_path) not in sys.path:
    sys.path.insert(0, str(backend_path))

from app.main import app
from app.core.database import engine
from app.db.base import Base


@pytest.fixture(autouse=True, scope="module")
def init_test_database():
    async def _init():
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
    asyncio.run(_init())


@pytest.mark.asyncio
async def test_unauthorized_profile_access():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get("/api/v1/profile/me")
        assert response.status_code == 401


@pytest.mark.asyncio
async def test_profile_lifecycle_and_age_derivation():
    headers = {"Authorization": "Bearer test-token-citizen-phase2"}
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        # 1. Profile initially not found (404)
        get_res = await client.get("/api/v1/profile/me", headers=headers)
        assert get_res.status_code == 404

        # 2. Create profile (POST 201)
        profile_payload = {
            "full_name": "Ananya Kulkarni",
            "date_of_birth": "2006-03-10",
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
        create_res = await client.post("/api/v1/profile", json=profile_payload, headers=headers)
        assert create_res.status_code == 201
        created_data = create_res.json()["data"]
        assert created_data["full_name"] == "Ananya Kulkarni"
        # Age derived as of 2026-08-07: 2026 - 2006 = 20 years old
        assert created_data["age"] == 20

        # 3. Retrieve created profile (GET 200)
        get_me_res = await client.get("/api/v1/profile/me", headers=headers)
        assert get_me_res.status_code == 200
        assert get_me_res.json()["data"]["annual_family_income"] == 180000.0

        # 4. Update profile (PUT 200)
        update_payload = {"annual_family_income": 190000.0, "class12_percentile": 94.0}
        put_res = await client.put("/api/v1/profile", json=update_payload, headers=headers)
        assert put_res.status_code == 200
        assert put_res.json()["data"]["annual_family_income"] == 190000.0
        assert put_res.json()["data"]["class12_percentile"] == 94.0

        # 5. Delete account and profile data (DELETE 200)
        delete_res = await client.delete("/api/v1/profile", headers=headers)
        assert delete_res.status_code == 200
        assert delete_res.json()["success"] is True

        # 6. Verify profile no longer exists
        get_after_delete = await client.get("/api/v1/profile/me", headers=headers)
        assert get_after_delete.status_code == 404
