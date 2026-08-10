import uuid
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import structlog

from app.core.config import settings
from app.core.logging import setup_logging, logger
from app.core.database import engine
from app.db.base import Base
from app.api.v1.health import router as health_router
from app.api.v1.profile import router as profile_router
from app.api.v1.schemes import router as schemes_router
from app.api.v1.ai import router as ai_router
from app.api.v1.documents import router as documents_router
from app.api.v1.saved_schemes import router as saved_schemes_router
from app.api.v1.analytics import router as analytics_router
from app.api.v1.admin import router as admin_router
from app.schemas.common import ErrorResponse, ErrorDetail

setup_logging()


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Auto-create tables for development/testing if using SQLite
    if "sqlite" in settings.DATABASE_URL:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
    yield


app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.BACKEND_CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.middleware("http")
async def add_request_id_and_log(request: Request, call_next):
    request_id = str(uuid.uuid4())
    request.state.request_id = request_id
    structlog.contextvars.clear_contextvars()
    structlog.contextvars.bind_contextvars(
        request_id=request_id,
        path=request.url.path,
        method=request.method,
    )

    response = await call_next(request)
    response.headers["X-Request-ID"] = request_id
    return response


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.error("unhandled_exception", error=str(exc), exc_info=True)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content=ErrorResponse(
            message="Internal server error",
            errors=[ErrorDetail(code="INTERNAL_ERROR", message=str(exc))],
        ).model_dump(),
    )


# Mount Routers
app.include_router(health_router, prefix=settings.API_V1_STR, tags=["Health"])
app.include_router(profile_router, prefix=f"{settings.API_V1_STR}/profile", tags=["Student Profile"])
app.include_router(schemes_router, prefix=f"{settings.API_V1_STR}/schemes", tags=["Scheme Catalog & Recommendations"])
app.include_router(ai_router, prefix=f"{settings.API_V1_STR}/ai", tags=["AI Grounded Explanations & Scoped Assistant"])
app.include_router(documents_router, prefix=f"{settings.API_V1_STR}/documents", tags=["OCR Document Analysis & Application Checklist"])
app.include_router(saved_schemes_router, prefix=f"{settings.API_V1_STR}/saved-schemes", tags=["Saved Schemes & Status Tracker"])
app.include_router(analytics_router, prefix=f"{settings.API_V1_STR}/analytics", tags=["Privacy-Safe Analytics"])
app.include_router(admin_router, prefix=f"{settings.API_V1_STR}/admin", tags=["Admin Dashboard"])


@app.get("/")
async def root():
    return {
        "project": settings.PROJECT_NAME,
        "version": settings.VERSION,
        "docs": "/docs",
        "health": f"{settings.API_V1_STR}/health",
        "profile": f"{settings.API_V1_STR}/profile/me",
        "schemes": f"{settings.API_V1_STR}/schemes",
        "ai": f"{settings.API_V1_STR}/ai/chat",
        "documents": f"{settings.API_V1_STR}/documents/my-documents",
        "saved_schemes": f"{settings.API_V1_STR}/saved-schemes",
    }
