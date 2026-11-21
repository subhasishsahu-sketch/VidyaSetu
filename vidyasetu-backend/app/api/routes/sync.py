"""Sync routes for offline packs and edge SLM batch synchronization."""

from fastapi import APIRouter, Depends, status
from pymongo.asynchronous.database import AsyncDatabase
from app.database.mongodb import get_database
from app.schemas.sync_schema import (
    OfflinePackRequest,
    OfflinePackResponse,
    OfflineSyncBatchRequest,
    OfflineSyncBatchResponse,
)
from app.services import sync_service

router = APIRouter(tags=["Mobile Offline Sync"])


@router.post(
    "/offline-packs",
    response_model=OfflinePackResponse,
    status_code=status.HTTP_200_OK,
    summary="Download complete offline curriculum pack",
)
async def get_offline_pack(
    request: OfflinePackRequest,
    db: AsyncDatabase = Depends(get_database),
):
    """Bundles all chapter questions (with 5 diagnostic probes and recovery questions)

    and 768-dim RAG vector chunks for on-device edge SLM grading and offline study.
    """
    return await sync_service.create_offline_pack(db, request)


@router.post(
    "/sync/offline-analysis",
    response_model=OfflineSyncBatchResponse,
    status_code=status.HTTP_200_OK,
    summary="Batch sync offline diagnostic analysis events",
)
async def sync_offline_analysis(
    batch: OfflineSyncBatchRequest,
    db: AsyncDatabase = Depends(get_database),
):
    """Idempotently synchronizes queued offline diagnostic analysis events from mobile devices.

    Guarantees deduplication on analysis_id, isolates invalid events into failed_events,
    and updates mastery metrics only once per event.
    """
    return await sync_service.process_offline_sync_batch(db, batch)
