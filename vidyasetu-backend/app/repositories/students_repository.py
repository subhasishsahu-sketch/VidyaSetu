import uuid
from datetime import datetime, timezone
from typing import Any, Dict, Optional
from pymongo.asynchronous.database import AsyncDatabase
from app.database.collections import get_students_collection
from app.schemas.student_schema import StudentCreateRequest


async def create_student(
    db: AsyncDatabase, student_in: StudentCreateRequest
) -> Dict[str, Any]:
    """Creates a new student document with a lowercase UUID v4 primary key."""
    students_col = get_students_collection(db)
    student_id = str(uuid.uuid4()).lower()
    now = datetime.now(timezone.utc)

    doc: Dict[str, Any] = {
        "_id": student_id,
        "student_id": student_id,
        "name": student_in.name,
        "class_grade": student_in.class_grade,
        "preferred_language": student_in.preferred_language,
        "english_exposure_level": student_in.english_exposure_level,
        "subject": student_in.subject,
        "completed_chapters": 0,
        "recommended_next_task": None,
        "created_at": now,
    }

    await students_col.insert_one(doc)
    return doc


async def get_student_by_id(
    db: AsyncDatabase, student_id: str
) -> Optional[Dict[str, Any]]:
    """Retrieves a student document by its UUID v4 _id."""
    students_col = get_students_collection(db)
    return await students_col.find_one({"_id": student_id.lower().strip()})


async def update_student_profile(
    db: AsyncDatabase, student_id: str, update_dict: Dict[str, Any]
) -> None:
    """Updates fields on an existing student profile."""
    students_col = get_students_collection(db)
    await students_col.update_one(
        {"_id": student_id.lower().strip()},
        {"$set": update_dict},
    )
