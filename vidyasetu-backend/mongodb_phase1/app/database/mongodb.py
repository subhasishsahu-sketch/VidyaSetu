"""MongoDB connection using the PyMongo async API (works with FastAPI)."""
from __future__ import annotations

import os

from pymongo import AsyncMongoClient
from pymongo.asynchronous.database import AsyncDatabase

_client: AsyncMongoClient | None = None


def get_client() -> AsyncMongoClient:
    global _client
    if _client is None:
        _client = AsyncMongoClient(
            os.getenv("MONGODB_URI", "mongodb://localhost:27017"),
            tz_aware=True,  # datetimes come back timezone-aware (UTC)
        )
    return _client


def get_db() -> AsyncDatabase:
    return get_client()[os.getenv("MONGODB_DB", "vidyasetu")]


async def close_client() -> None:
    global _client
    if _client is not None:
        await _client.close()
        _client = None
