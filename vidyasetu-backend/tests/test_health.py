import pytest
from httpx import AsyncClient, ASGITransport
from unittest.mock import AsyncMock, MagicMock
from app.main import app, allow_credentials
from app.database.mongodb import mongodb_manager


@pytest.mark.asyncio
async def test_health_check_disconnected():
    # Ensure client is None
    mongodb_manager.client = None
    mongodb_manager.db = None

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "degraded"
        assert data["database"] == "disconnected"

        # Also test /api/v1/health route
        v1_response = await client.get("/api/v1/health")
        assert v1_response.status_code == 200
        assert v1_response.json() == data


@pytest.mark.asyncio
async def test_health_check_connected():
    # Mock connected client with successful ping
    mock_client = MagicMock()
    mock_client.admin.command = AsyncMock(return_value={"ok": 1})
    mongodb_manager.client = mock_client

    try:
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            response = await client.get("/health")
            assert response.status_code == 200
            data = response.json()
            assert data["status"] == "healthy"
            assert data["database"] == "connected"
    finally:
        mongodb_manager.client = None
        mongodb_manager.db = None


def test_cors_credentials_rule():
    # Per rule 3: allow_credentials=False when CORS_ORIGINS contains "*"
    assert allow_credentials is False


@pytest.mark.asyncio
async def test_gzip_middleware_response():
    # Add a temporary large endpoint to test GZipMiddleware
    @app.get("/test-large")
    async def large_payload():
        return {"data": "x" * 600}

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/test-large", headers={"Accept-Encoding": "gzip"})
        assert response.status_code == 200
        assert response.headers.get("content-encoding") == "gzip"
