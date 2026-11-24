import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from app.api.routes.diagnostics import router as diagnostics_router
from app.api.routes.language import router as language_router
from app.api.routes.questions import router as questions_router
from app.api.routes.students import router as students_router
from app.api.routes.sync import router as sync_router
from app.api.routes.voice import router as voice_router
from app.core.config import settings
from app.database.mongodb import (
    connect_to_mongo,
    close_mongo_connection,
    mongodb_manager,
)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifespan context manager for startup and shutdown events."""
    try:
        await connect_to_mongo()
    except Exception as exc:
        logger.warning("MongoDB connection could not be established at startup: %s", exc)
    yield
    await close_mongo_connection()


app = FastAPI(
    title=settings.PROJECT_NAME,
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
)

# GZip Response Compression for 2G/3G Rural Networks (minimum_size=500)
app.add_middleware(GZipMiddleware, minimum_size=500)

# Dual CORS + Mobile Header Support
# Set allow_credentials=False when CORS_ORIGINS contains wildcard '*'
allow_credentials = False if "*" in settings.CORS_ORIGINS else True

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=allow_credentials,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health", tags=["Health"])
@app.get("/api/v1/health", tags=["Health"])
async def health_check():
    """Health check endpoint verifying API and MongoDB connectivity."""
    db_status = "disconnected"
    if mongodb_manager.client is not None:
        try:
            await mongodb_manager.client.admin.command("ping")
            db_status = "connected"
        except Exception:
            db_status = "disconnected"

    return {
        "status": "healthy" if db_status == "connected" else "degraded",
        "database": db_status,
    }


# Include API routes under /api/v1
app.include_router(students_router, prefix=settings.API_V1_PREFIX)
app.include_router(questions_router, prefix=settings.API_V1_PREFIX)
app.include_router(diagnostics_router, prefix=settings.API_V1_PREFIX)
app.include_router(language_router, prefix=settings.API_V1_PREFIX)
app.include_router(sync_router, prefix=settings.API_V1_PREFIX)
app.include_router(voice_router, prefix=settings.API_V1_PREFIX)


