import uuid
from datetime import datetime, timezone

from pymongo.errors import DuplicateKeyError

from app.database.mongodb import get_db

REQUIRED_FIELDS = ["student_id", "question_id", "attempt_data"]

OPTIONAL_FIELDS = [
    "probe_loop_evidence",
    "student_parameters_snapshot",
    "intervention_and_language_output",
    "recovery_assessment",
]


def _col():
    return get_db()["diagnostic_analysis"]


def _to_datetime(value):
    """Turns '2026-11-19T08:45:00Z' text from a phone into a real date."""
    if value is None:
        return None
    if isinstance(value, datetime):
        return value if value.tzinfo else value.replace(tzinfo=timezone.utc)
    return datetime.fromisoformat(str(value).replace("Z", "+00:00"))


async def save_analysis(event: dict) -> dict:
    """
    Saves one diagnostic event. Safe to call twice with the same analysis_id:
    the second call changes nothing and returns inserted=False.
    """
    missing = [f for f in REQUIRED_FIELDS if f not in event]
    if missing:
        raise ValueError(f"Missing required fields: {missing}")

    analysis_id = event.get("analysis_id") or str(uuid.uuid4())

    doc = {
        "student_id": event["student_id"],
        "question_id": event["question_id"],
        "attempt_data": event["attempt_data"],
        "execution_source": event.get("execution_source", "cloud_gemini"),
        "created_at": datetime.now(timezone.utc),
    }
    for field in OPTIONAL_FIELDS:
        if event.get(field) is not None:
            doc[field] = event[field]

    offline_at = _to_datetime(event.get("offline_created_at"))
    if offline_at is not None:
        doc["offline_created_at"] = offline_at  # when it really happened offline

    try:
        result = await _col().update_one(
            {"analysis_id": analysis_id},
            {"$setOnInsert": {"_id": analysis_id, **doc}},
            upsert=True,
        )
    except DuplicateKeyError:
        # Two uploads arrived at the same moment; the other one won.
        return {"analysis_id": analysis_id, "inserted": False}

    return {"analysis_id": analysis_id, "inserted": result.upserted_id is not None}


async def get_analysis(analysis_id: str) -> dict | None:
    return await _col().find_one({"analysis_id": analysis_id})


async def list_for_student(student_id: str, limit: int = 20) -> list[dict]:
    cursor = _col().find({"student_id": student_id}).sort("created_at", -1).limit(limit)
    return await cursor.to_list(length=limit)


async def list_for_question(question_id: str, limit: int = 50) -> list[dict]:
    cursor = _col().find({"question_id": question_id}).sort("created_at", -1).limit(limit)
    return await cursor.to_list(length=limit)


async def set_recovery_assessment(analysis_id: str, recovery: dict) -> bool:
    """Adds the recovery result after the student does the practice question."""
    result = await _col().update_one(
        {"analysis_id": analysis_id},
        {"$set": {"recovery_assessment": recovery}},
    )
    return result.matched_count == 1