"""Data access for `students` (Table 1: profile + Autonomous Study Planner output)."""
from __future__ import annotations

import uuid
from datetime import datetime, timezone
from typing import Any, Optional

from app.database.collections import STUDENT_PROGRESS, STUDENTS
from app.repositories.errors import NotFoundError
from app.validators.students import LANGUAGES


def _now() -> datetime:
    return datetime.now(timezone.utc)


async def create_student(
    db,
    *,
    name: str,
    class_grade: int,
    subject: str,
    preferred_language: str = "Odia",
    english_exposure_level: int = 1,
    completed_chapters: int = 0,
) -> dict[str, Any]:
    # MongoDB has no column defaults, so defaults live here.
    name = name.strip()
    if not name:
        raise ValueError("name is required")
    if not 1 <= class_grade <= 12:
        raise ValueError("class_grade must be between 1 and 12")
    if preferred_language not in LANGUAGES:
        raise ValueError(f"preferred_language must be one of {LANGUAGES}")
    if not 1 <= english_exposure_level <= 4:
        raise ValueError("english_exposure_level must be between 1 and 4")
    if completed_chapters < 0:
        raise ValueError("completed_chapters must be >= 0")

    doc = {
        "_id": str(uuid.uuid4()),
        "name": name,
        "class_grade": class_grade,
        "preferred_language": preferred_language,
        "english_exposure_level": english_exposure_level,
        "subject": subject,
        "completed_chapters": completed_chapters,
        "recommended_next_task": None,
        "created_at": _now(),
    }
    await db[STUDENTS].insert_one(doc)
    return doc


async def get_student(db, student_id: str) -> Optional[dict[str, Any]]:
    return await db[STUDENTS].find_one({"_id": student_id})


async def require_student(db, student_id: str) -> dict[str, Any]:
    student = await get_student(db, student_id)
    if student is None:
        raise NotFoundError(f"student {student_id} not found")
    return student


async def update_english_exposure_level(db, student_id: str, level: int) -> None:
    """'Record English Exposure Level' (written from the Language Intelligence Module)."""
    if not 1 <= level <= 4:
        raise ValueError("english_exposure_level must be between 1 and 4")
    result = await db[STUDENTS].update_one(
        {"_id": student_id}, {"$set": {"english_exposure_level": level}}
    )
    if result.matched_count == 0:
        raise NotFoundError(f"student {student_id} not found")


async def increment_completed_chapters(db, student_id: str, by: int = 1) -> None:
    result = await db[STUDENTS].update_one(
        {"_id": student_id}, {"$inc": {"completed_chapters": by}}
    )
    if result.matched_count == 0:
        raise NotFoundError(f"student {student_id} not found")


async def set_recommended_next_task(
    db,
    student_id: str,
    *,
    subject: str,
    chapter_name: str,
    task_type: str,
    reason: str,
    recommended_for: Optional[datetime] = None,
) -> dict[str, Any]:
    """Autonomous Study Planner -> 'Recommend Next Learning Task'."""
    task = {
        "subject": subject,
        "chapter_name": chapter_name,
        "task_type": task_type,
        "reason": reason,
        "recommended_for": recommended_for or _now(),
    }
    result = await db[STUDENTS].update_one(
        {"_id": student_id}, {"$set": {"recommended_next_task": task}}
    )
    if result.matched_count == 0:
        raise NotFoundError(f"student {student_id} not found")
    return task


async def delete_student(db, student_id: str) -> bool:
    """MongoDB has no ON DELETE CASCADE, so progress is deleted here explicitly."""
    await db[STUDENT_PROGRESS].delete_many({"student_id": student_id})
    result = await db[STUDENTS].delete_one({"_id": student_id})
    return result.deleted_count == 1
