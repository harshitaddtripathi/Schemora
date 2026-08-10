from app.core.config import Settings


def test_default_settings():
    settings = Settings()
    assert settings.PROJECT_NAME == "Schemora API"
    assert settings.VERSION == "0.1.0"
    assert settings.API_V1_STR == "/api/v1"
    assert "sqlite" in settings.DATABASE_URL
    assert isinstance(settings.BACKEND_CORS_ORIGINS, list)
    assert len(settings.BACKEND_CORS_ORIGINS) > 0


def test_cors_origins_configuration():
    settings = Settings(BACKEND_CORS_ORIGINS=["http://localhost:3000", "https://schemora.app"])
    assert "http://localhost:3000" in settings.BACKEND_CORS_ORIGINS
    assert "https://schemora.app" in settings.BACKEND_CORS_ORIGINS
