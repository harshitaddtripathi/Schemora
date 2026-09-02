import asyncio
import sys
from app.core.database import AsyncSessionLocal
from app.models.scheme import Scheme
from sqlalchemy import select

sys.stdout.reconfigure(encoding='utf-8')

async def main():
    async with AsyncSessionLocal() as db:
        res = await db.execute(select(Scheme))
        schemes = res.scalars().all()
        print(f"Total schemes in DB: {len(schemes)}")
        for s in schemes:
            print(f"- {s.title} | Category: {s.benefit_type} | Gender: {s.gender_eligibility}")

if __name__ == "__main__":
    asyncio.run(main())
