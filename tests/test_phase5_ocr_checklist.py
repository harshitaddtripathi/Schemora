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

SAMPLE_AADHAAR_NUM = "9999_8888_1234"
SAMPLE_PAN_NUM = "ABCDE-1234-F"


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
async def test_document_upload_parse_and_masking():
    headers = {"Authorization": "Bearer test-token-citizen-phase5"}
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        # Create student profile
        profile_payload = {
            "full_name": "Rohan Mehta",
            "date_of_birth": "2005-08-20",
            "gender": "Male",
            "state": "Maharashtra",
            "education_level": "Undergraduate",
            "course_name": "B.Com Accounting",
            "institution_name": "R.A. Podar College",
            "institution_type": "Regular",
            "social_category": "General",
            "annual_family_income": 200000.0,
            "is_full_time_student": True,
            "employment_status": "Unemployed",
            "citizenship": "Indian",
            "class12_percentile": 89.0,
            "attendance_percentage": 88.0,
        }
        await client.post("/api/v1/profile", json=profile_payload, headers=headers)

        # Upload Aadhaar document
        aadhaar_req = {
            "doc_type": "Aadhaar",
            "file_name": "aadhaar_sample.json",
            "raw_content": f'{{"full_name": "Rohan Mehta", "date_of_birth": "2005-08-20", "aadhaar_number": "{SAMPLE_AADHAAR_NUM}"}}',
        }
        res = await client.post("/api/v1/documents/upload-parse", json=aadhaar_req, headers=headers)
        assert res.status_code == 200
        data = res.json()["data"]
        assert data["doc_type"] == "Aadhaar"
        assert data["masked_identifier"] == "XXXX-XXXX-1234"
        assert data["verification_status"] == "Verified"
        assert "not constitute a legally binding" in data["non_legal_disclaimer"]

        # Upload PAN document
        pan_req = {
            "doc_type": "PAN",
            "file_name": "pan_sample.json",
            "raw_content": f'{{"full_name": "Rohan Mehta", "date_of_birth": "2005-08-20", "pan_number": "{SAMPLE_PAN_NUM}"}}',
        }
        pan_res = await client.post("/api/v1/documents/upload-parse", json=pan_req, headers=headers)
        assert pan_res.status_code == 200
        assert pan_res.json()["data"]["masked_identifier"] == "XXXXX-1234-X"


@pytest.mark.asyncio
async def test_scheme_application_checklist():
    headers = {"Authorization": "Bearer test-token-citizen-phase5"}
    scheme_id = "sch-central-pmis-003"
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        res = await client.get(f"/api/v1/documents/checklist/{scheme_id}", headers=headers)
        assert res.status_code == 200
        data = res.json()["data"]
        assert data["scheme_id"] == scheme_id
        assert len(data["items"]) >= 2
        assert "application_steps" in data
        assert len(data["application_steps"]) == 4
