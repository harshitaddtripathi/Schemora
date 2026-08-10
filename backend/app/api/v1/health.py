import time
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from pydantic import BaseModel
from app.core.database import get_db
from app.core.config import settings
from app.schemas.common import APIResponse

router = APIRouter()


class HealthCheckData(BaseModel):
    status: str
    version: str
    environment: str
    database_connected: bool
    latency_ms: float


@router.get("/health", response_model=APIResponse[HealthCheckData], summary="Backend Health Check")
async def health_check(db: AsyncSession = Depends(get_db)):
    """Health check endpoint to verify backend service and database connectivity."""
    start_time = time.time()
    db_connected = False

    try:
        result = await db.execute(text("SELECT 1"))
        if result.scalar() == 1:
            db_connected = True
    except Exception:
        db_connected = False

    latency = round((time.time() - start_time) * 1000, 2)

    return APIResponse(
        success=True,
        message="Schemora backend operational",
        data=HealthCheckData(
            status="healthy" if db_connected else "degraded",
            version=settings.VERSION,
            environment=settings.APP_ENV,
            database_connected=db_connected,
            latency_ms=latency,
        ),
    )
