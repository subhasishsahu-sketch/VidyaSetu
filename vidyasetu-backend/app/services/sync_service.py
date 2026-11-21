"""Sync service for Mobile Offline Packs and Idempotent Offline Batch Synchronization."""

import logging
from datetime import datetime, timezone
from typing import Any, Dict, List
from fastapi import HTTPException, status
from pymongo.asynchronous.database import AsyncDatabase
from pymongo.errors import DuplicateKeyError

from app.database.collections import COLLECTION_DIAGNOSTIC_ANALYSIS
from app.repositories import (
    progress_repository,
    questions_repository,
    rag_repository,
    students_repository,
)
from app.schemas.progress_schema import ProgressUpdateRequest
from app.schemas.rag_schema import RagTextbookVector
from app.schemas.sync_schema import (
    OfflinePackRequest,
    OfflinePackResponse,
    OfflineSyncBatchRequest,
    OfflineSyncBatchResponse,
    OfflineSyncFailedEvent,
)
from app.services import mastery_service

logger = logging.getLogger(__name__)


async def create_offline_pack(
    db: AsyncDatabase, req: OfflinePackRequest
) -> OfflinePackResponse:
    """Creates a self-contained mobile offline pack bundling chapter questions and RAG vectors."""
    clean_subject = req.subject.strip()
    clean_chapter = req.chapter_name.strip()

    # 1. Fetch full chapter questions including diagnostic probes and recovery questions
    cached_questions = await questions_repository.get_internal_questions_by_chapter(
        db, clean_subject, clean_chapter
    )

    # 2. Fetch local RAG vectors
    chunk_docs = await rag_repository.get_chunks_by_chapter(
        db, clean_subject, clean_chapter
    )

    # 3. If both questions and vectors are empty, raise 404
    if not cached_questions and not chunk_docs:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"No curriculum content found for subject '{clean_subject}' and chapter '{clean_chapter}'",
        )

    # 4. Serialize RAG vector chunks
    local_rag_vectors = [RagTextbookVector(**c) for c in chunk_docs]

    pack_id = f"pack_{clean_subject.lower()}_{clean_chapter.lower().replace(' ', '_')}"

    return OfflinePackResponse(
        pack_id=pack_id,
        subject=clean_subject,
        chapter_name=clean_chapter,
        cached_questions=cached_questions,
        local_rag_vectors=local_rag_vectors,
        cached_at=datetime.now(timezone.utc),
    )


async def process_offline_sync_batch(
    db: AsyncDatabase, batch: OfflineSyncBatchRequest
) -> OfflineSyncBatchResponse:
    """Processes an offline synchronization batch idempotently with per-event fault isolation."""
    # 1. Validate student existence
    student = await students_repository.get_student_by_id(db, batch.student_id)
    if not student:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Student {batch.student_id} not found",
        )

    # 2. Sort events by offline_created_at ascending before processing
    sorted_events = sorted(batch.events, key=lambda ev: ev.offline_created_at)

    synced_ids: List[str] = []
    duplicate_ids: List[str] = []
    failed_events: List[OfflineSyncFailedEvent] = []

    col = db[COLLECTION_DIAGNOSTIC_ANALYSIS]

    for event in sorted_events:
        # Verify event student_id matches batch student_id
        if event.student_id != batch.student_id:
            failed_events.append(
                OfflineSyncFailedEvent(
                    analysis_id=event.analysis_id,
                    reason=f"Event student_id '{event.student_id}' does not match batch student_id '{batch.student_id}'",
                )
            )
            continue

        # Verify question exists
        q_doc = await questions_repository.get_question_internal(db, event.question_id)
        if not q_doc:
            failed_events.append(
                OfflineSyncFailedEvent(
                    analysis_id=event.analysis_id,
                    reason=f"Question {event.question_id} not found",
                )
            )
            continue

        # Prepare payload for $setOnInsert
        now_utc = datetime.now(timezone.utc)
        snapshot_dict = (
            event.student_parameters_snapshot.model_dump()
            if hasattr(event.student_parameters_snapshot, "model_dump")
            else dict(event.student_parameters_snapshot)
        )

        insert_payload = {
            "_id": event.analysis_id,
            "analysis_id": event.analysis_id,
            "student_id": event.student_id,
            "question_id": event.question_id,
            "attempt_data": event.attempt_data,
            "probe_loop_evidence": event.probe_loop_evidence,
            "student_parameters_snapshot": snapshot_dict,
            "intervention_and_language_output": event.intervention_and_language_output,
            "recovery_assessment": event.recovery_assessment,
            "execution_source": "edge_slm_offline_sync",
            "created_at": now_utc,
            "offline_created_at": event.offline_created_at,
        }

        # Idempotent write with DuplicateKeyError guard
        try:
            result = await col.update_one(
                {"analysis_id": event.analysis_id},
                {"$setOnInsert": insert_payload},
                upsert=True,
            )
            is_new = (getattr(result, "upserted_id", None) is not None)
        except DuplicateKeyError:
            is_new = False

        if not is_new:
            duplicate_ids.append(event.analysis_id)
            continue

        # New event successfully ingested
        synced_ids.append(event.analysis_id)

        # Check recovery assessment for metric boost
        rec_assessment = event.recovery_assessment or {}
        if rec_assessment.get("has_student_improved") is True:
            chapter_name = q_doc.get("chapter_name", "")
            progress_doc = await progress_repository.get_chapter_progress(
                db, batch.student_id, chapter_name
            )

            # Initialize default 50.0 component scores if progress doc does not exist
            curr_concept = float(progress_doc.get("concept_understanding", 50.0)) if progress_doc else 50.0
            curr_prev = float(progress_doc.get("previous_performance_score", 50.0)) if progress_doc else 50.0
            curr_prereq = float(progress_doc.get("prerequisite_understanding", 50.0)) if progress_doc else 50.0
            curr_eng = float(progress_doc.get("english_comprehension", 50.0)) if progress_doc else 50.0
            curr_time = float(progress_doc.get("time_management", 50.0)) if progress_doc else 50.0
            curr_conf = float(progress_doc.get("confidence_level", 50.0)) if progress_doc else 50.0

            # Determine diagnosed root cause
            root_cause = "conceptual_misunderstanding"
            if event.intervention_and_language_output:
                root_cause = event.intervention_and_language_output.get("misconception") or root_cause
            elif isinstance(event.attempt_data, dict) and event.attempt_data.get("confirmed_hypothesis"):
                root_cause = event.attempt_data.get("confirmed_hypothesis")

            # Apply recovery boost using shared helper
            boosted = mastery_service.apply_recovery_boost(
                curr_concept=curr_concept,
                curr_prev=curr_prev,
                curr_prereq=curr_prereq,
                curr_eng=curr_eng,
                curr_time=curr_time,
                curr_conf=curr_conf,
                root_cause=root_cause,
            )

            # Recompute overall mastery
            new_mastery = mastery_service.compute_overall_mastery(
                concept_understanding=boosted["concept_understanding"],
                previous_performance_score=boosted["previous_performance_score"],
                prerequisite_understanding=boosted["prerequisite_understanding"],
                english_comprehension=boosted["english_comprehension"],
                time_management=boosted["time_management"],
                confidence_level=boosted["confidence_level"],
            )

            # Upsert chapter progress
            update_dto = ProgressUpdateRequest(
                chapter_name=chapter_name,
                concept_understanding=boosted["concept_understanding"],
                previous_performance_score=boosted["previous_performance_score"],
                prerequisite_understanding=boosted["prerequisite_understanding"],
                english_comprehension=boosted["english_comprehension"],
                time_management=boosted["time_management"],
                confidence_level=boosted["confidence_level"],
            )
            await progress_repository.upsert_progress(db, batch.student_id, update_dto)
            await progress_repository.sync_student_aggregates(db, batch.student_id)

            # Build recommended next task and update student profile
            recommended_task = mastery_service.build_recommended_next_task(
                student_id=batch.student_id,
                subject=q_doc.get("subject", ""),
                chapter_name=chapter_name,
                concept_name=q_doc.get("concept_name", ""),
                root_cause=root_cause,
                overall_mastery=new_mastery,
            )
            await students_repository.update_student_profile(
                db, batch.student_id, {"recommended_next_task": recommended_task}
            )

    return OfflineSyncBatchResponse(
        synced_ids=synced_ids,
        duplicate_ids=duplicate_ids,
        failed_events=failed_events,
    )
