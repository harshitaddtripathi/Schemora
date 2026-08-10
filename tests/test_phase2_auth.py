import asyncio
import pytest
from fastapi import HTTPException
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
async def test_auth_missing_header_rejection():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        res = await client.get("/api/v1/profile/me")
        assert res.status_code == 401
        assert "detail" in res.json()


@pytest.mark.asyncio
async def test_citizen_and_admin_role_creation():
    citizen_headers = {"Authorization": "Bearer test-citizen-token-001"}
    admin_headers = {"Authorization": "Bearer test-admin-token-001"}

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        # Citizen profile initial 404
        c_res = await client.get("/api/v1/profile/me", headers=citizen_headers)
        assert c_res.status_code == 404

        # Admin profile initial 404
        a_res = await client.get("/api/v1/profile/me", headers=admin_headers)
        assert a_res.status_code == 404
