import uuid
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from pymongo import ReturnDocument
from pymongo.asynchronous.database import AsyncDatabase
from app.database.collections import get_student_progress_collection
from app.repositories.students_repository import update_student_profile
from app.schemas.progress_schema import ProgressUpdateRequest
from app.services.mastery_service import (
    compute_overall_mastery,
    is_chapter_completed,
    map_english_exposure_level,
)


async def upsert_progress(
    db: AsyncDatabase, student_id: str, progress_in: ProgressUpdateRequest
) -> Dict[str, Any]:
    """Atomically upserts chapter progress using find_one_and_update with ReturnDocument.AFTER.

    Maintains unique (student_id, chapter_name) and generates a lowercase UUID v4 for _id and progress_id.
    """
    progress_col = get_student_progress_collection(db)
    clean_student_id = student_id.lower().strip()
    clean_chapter_name = progress_in.chapter_name.strip()

    overall_mastery = compute_overall_mastery(
        concept_understanding=progress_in.concept_understanding,
        previous_performance_score=progress_in.previous_performance_score,
        prerequisite_understanding=progress_in.prerequisite_understanding,
        english_comprehension=progress_in.english_comprehension,
        time_management=progress_in.time_management,
        confidence_level=progress_in.confidence_level,
    )

    new_id = str(uuid.uuid4()).lower()
    now = datetime.now(timezone.utc)

    updated_doc = await progress_col.find_one_and_update(
        {"student_id": clean_student_id, "chapter_name": clean_chapter_name},
        {
            "$setOnInsert": {
                "_id": new_id,
                "progress_id": new_id,
                "student_id": clean_student_id,
                "chapter_name": clean_chapter_name,
            },
            "$set": {
                "concept_understanding": progress_in.concept_understanding,
                "english_comprehension": progress_in.english_comprehension,
                "prerequisite_understanding": progress_in.prerequisite_understanding,
                "time_management": progress_in.time_management,
                "confidence_level": progress_in.confidence_level,
                "previous_performance_score": progress_in.previous_performance_score,
                "overall_mastery": overall_mastery,
                "last_updated": now,
            },
        },
        upsert=True,
        return_document=ReturnDocument.AFTER,
    )
    return updated_doc


async def get_student_progress_list(
    db: AsyncDatabase, student_id: str
) -> List[Dict[str, Any]]:
    """Retrieves all chapter progress records for a student sorted by last_updated DESC."""
    progress_col = get_student_progress_collection(db)
    cursor = progress_col.find({"student_id": student_id.lower().strip()}).sort(
        "last_updated", -1
    )
    return await cursor.to_list(length=None)


async def get_chapter_progress(
    db: AsyncDatabase, student_id: str, chapter_name: str
) -> Optional[Dict[str, Any]]:
    """Retrieves a single chapter progress record by student_id and chapter_name."""
    progress_col = get_student_progress_collection(db)
    return await progress_col.find_one(
        {
            "student_id": student_id.lower().strip(),
            "chapter_name": chapter_name.strip(),
        }
    )


async def sync_student_aggregates(db: AsyncDatabase, student_id: str) -> None:
    """Computes aggregates from all progress records and updates the student document.

    - completed_chapters: count of records where overall_mastery >= 75.0
    - english_exposure_level: mapped from the mean english_comprehension across all chapters
    """
    clean_student_id = student_id.lower().strip()
    progress_list = await get_student_progress_list(db, clean_student_id)

    if not progress_list:
        await update_student_profile(
            db,
            clean_student_id,
            {"completed_chapters": 0, "english_exposure_level": 1},
        )
        return

    completed_count = sum(
        1 for p in progress_list if is_chapter_completed(p.get("overall_mastery", 0.0))
    )

    mean_english = sum(
        float(p.get("english_comprehension", 50.0)) for p in progress_list
    ) / len(progress_list)

    exposure_level = map_english_exposure_level(mean_english)

    await update_student_profile(
        db,
        clean_student_id,
        {
            "completed_chapters": completed_count,
            "english_exposure_level": exposure_level,
        },
    )


# Aliases for explicit naming across services
get_progress_by_chapter = get_chapter_progress
get_all_progress_by_student = get_student_progress_list
