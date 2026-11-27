"""Create collections, validators and indexes. Safe to run repeatedly.

Run:  cd backend && python -m app.database.init_db
"""
from __future__ import annotations

import asyncio

from app.database.collections import STUDENT_PROGRESS, STUDENTS
from app.database.mongodb import close_client, get_db
from app.validators.student_progress import STUDENT_PROGRESS_VALIDATOR
from app.validators.students import STUDENTS_VALIDATOR


async def _apply_validator(db, name: str, validator: dict) -> None:
    existing = await db.list_collection_names()
    options = {"validator": validator, "validationLevel": "strict", "validationAction": "error"}
    if name in existing:
        await db.command({"collMod": name, **options})  # update validator in place
    else:
        await db.create_collection(name, **options)


async def init_db(db) -> None:
    await _apply_validator(db, STUDENTS, STUDENTS_VALIDATOR)
    await _apply_validator(db, STUDENT_PROGRESS, STUDENT_PROGRESS_VALIDATOR)

    # students: cohort filtering by grade + subject
    await db[STUDENTS].create_index(
        [("class_grade", 1), ("subject", 1)], name="idx_students_grade_subject"
    )
    # student_progress: one document per student per chapter
    await db[STUDENT_PROGRESS].create_index(
        [("student_id", 1), ("chapter_name", 1)], unique=True, name="uq_student_chapter"
    )
    # student_progress: most recent progress for a student
    await db[STUDENT_PROGRESS].create_index(
        [("student_id", 1), ("last_updated", -1)], name="idx_progress_student_recent"
    )


async def _main() -> None:
    try:
        await init_db(get_db())
        print("Phase 1 collections, validators and indexes are ready.")
    finally:
        await close_client()


if __name__ == "__main__":
    asyncio.run(_main())
