import asyncio
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
backend_path = ROOT / "backend"
if str(backend_path) not in sys.path:
    sys.path.insert(0, str(backend_path))

from app.core.database import AsyncSessionLocal, engine
from app.db.base import Base
from app.services.seeder import seed_scheme_dataset


async def main():
    print("Initializing database tables...")
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    json_path = ROOT / "data" / "schemes" / "schemes.v1.json"
    print(f"Seeding schemes from {json_path}...")

    async with AsyncSessionLocal() as db:
        count = await seed_scheme_dataset(db, json_path)
        print(f"Successfully seeded {count} schemes into the database.")


if __name__ == "__main__":
    asyncio.run(main())
