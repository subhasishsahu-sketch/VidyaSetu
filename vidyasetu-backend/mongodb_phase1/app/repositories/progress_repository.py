"""Data access for `student_progress` (Table 2: mastery per student per chapter)."""
from __future__ import annotations

import uuid
from typing import Any, Mapping, Optional

from app.database.collections import STUDENT_PROGRESS, STUDENTS
from app.repositories.errors import NotFoundError
from app.repositories.students_repository import require_student
from app.services.mastery_service import compute_overall_mastery
from app.validators.student_progress import ALL_SCORE_FIELDS


def _validate_score(field: str, value: Any) -> float:
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        raise ValueError(f"{field} must be a number")
    if not 0 <= value <= 100:
        raise ValueError(f"{field} must be between 0 and 100")
    return float(value)


async def upsert_progress(
    db, student_id: str, chapter_name: str, scores: Mapping[str, float]
) -> dict[str, Any]:
    """Create or update one progress document (also used by offline sync).

    Only the scores passed in are changed. If `overall_mastery` is not passed,
    it is recalculated from the stored scores.
    """
    unknown = set(scores) - set(ALL_SCORE_FIELDS)
    if unknown:
        raise ValueError(f"unknown score fields: {sorted(unknown)}")
    if not chapter_name.strip():
        raise ValueError("chapter_name is required")

    await require_student(db, student_id)  # no foreign keys in MongoDB: check here

    clean = {field: _validate_score(field, v) for field, v in scores.items()}
    # Fields not supplied start at 0 when the document is first created.
    defaults = {f: 0.0 for f in ALL_SCORE_FIELDS if f not in clean}

    update: dict[str, Any] = {
        "$setOnInsert": {"_id": str(uuid.uuid4()), **defaults},
        "$currentDate": {"last_updated": True},
    }
    if clean:
        update["$set"] = clean

    await db[STUDENT_PROGRESS].update_one(
        {"student_id": student_id, "chapter_name": chapter_name}, update, upsert=True
    )

    if "overall_mastery" not in clean:
        return await recalculate_overall_mastery(db, student_id, chapter_name)
    return await get_progress(db, student_id, chapter_name)


async def recalculate_overall_mastery(db, student_id: str, chapter_name: str) -> dict[str, Any]:
    doc = await get_progress(db, student_id, chapter_name)
    if doc is None:
        raise NotFoundError(f"no progress for student {student_id}, chapter {chapter_name}")
    overall = compute_overall_mastery(doc)
    await db[STUDENT_PROGRESS].update_one(
        {"_id": doc["_id"]},
        {"$set": {"overall_mastery": overall}, "$currentDate": {"last_updated": True}},
    )
    doc["overall_mastery"] = overall
    return doc


async def get_progress(db, student_id: str, chapter_name: str) -> Optional[dict[str, Any]]:
    return await db[STUDENT_PROGRESS].find_one(
        {"student_id": student_id, "chapter_name": chapter_name}
    )


async def list_progress(db, student_id: str, limit: int = 50) -> list[dict[str, Any]]:
    cursor = (
        db[STUDENT_PROGRESS].find({"student_id": student_id}).sort("last_updated", -1).limit(limit)
    )
    return await cursor.to_list()


async def get_student_with_progress(db, student_id: str) -> Optional[dict[str, Any]]:
    """'Retrieve Student Learning Profile' in one query (profile + all progress)."""
    cursor = await db[STUDENTS].aggregate(
        [
            {"$match": {"_id": student_id}},
            {
                "$lookup": {
                    "from": STUDENT_PROGRESS,
                    "localField": "_id",
                    "foreignField": "student_id",
                    "as": "progress",
                }
            },
        ]
    )
    docs = await cursor.to_list(length=1)
    return docs[0] if docs else None
