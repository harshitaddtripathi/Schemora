import pytest
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db, Base


@pytest.mark.asyncio
async def test_get_db_session():
    generator = get_db()
    session = await anext(generator)
    assert isinstance(session, AsyncSession)
    await session.close()


def test_base_declarative():
    assert hasattr(Base, "metadata")
