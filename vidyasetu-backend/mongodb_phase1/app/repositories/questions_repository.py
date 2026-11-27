import uuid

from app.database.mongodb import get_db
from app.validators.question_validators import PROBE_KEYS


def _col():
    return get_db()["questions"]


# Hide answers from anything sent to the student app
STUDENT_HIDE = {
    "correct_answer": 0,
    "recovery_practice_questions.answer_key": 0,
}


def _validate(data: dict):
    option_keys = {o["key"] for o in data["options"]}
    if data["correct_answer"] not in option_keys:
        raise ValueError("correct_answer must match one of the option keys")
    missing = [k for k in PROBE_KEYS if k not in data.get("diagnostic_probes", {})]
    if missing:
        raise ValueError(f"Missing diagnostic probes: {missing}")


async def create_question(data: dict) -> dict:
    _validate(data)
    doc = {
        "_id": str(uuid.uuid4()),
        "expected_time_sec": 60,
        "recovery_practice_questions": [],
        **data,
    }
    await _col().insert_one(doc)
    return doc


async def upsert_question(data: dict) -> dict:
    """Insert, or update if the same question already exists (safe to re-run)."""
    _validate(data)
    key = {k: data[k] for k in ("subject", "chapter_name", "concept_name", "question_text")}
    await _col().update_one(
        key,
        {"$set": data, "$setOnInsert": {"_id": str(uuid.uuid4())}},
        upsert=True,
    )
    return await _col().find_one(key)


async def get_question_full(question_id: str) -> dict | None:
    """Backend only. Includes the answers."""
    return await _col().find_one({"_id": question_id})


async def get_question_for_student(question_id: str) -> dict | None:
    return await _col().find_one({"_id": question_id}, STUDENT_HIDE)


async def list_questions_for_student(
    subject: str,
    chapter_name: str | None = None,
    concept_name: str | None = None,
    limit: int = 50,
) -> list[dict]:
    query = {"subject": subject}
    if chapter_name:
        query["chapter_name"] = chapter_name
    if concept_name:
        query["concept_name"] = concept_name
    return await _col().find(query, STUDENT_HIDE).to_list(length=limit)


async def get_probe(question_id: str, probe_name: str) -> dict | None:
    if probe_name not in PROBE_KEYS:
        raise ValueError(f"Unknown probe '{probe_name}'. Use one of {PROBE_KEYS}")
    doc = await _col().find_one(
        {"_id": question_id}, {f"diagnostic_probes.{probe_name}": 1}
    )
    return doc["diagnostic_probes"][probe_name] if doc else None


async def check_answer(question_id: str, selected_option: str) -> bool | None:
    doc = await _col().find_one({"_id": question_id}, {"correct_answer": 1})
    if doc is None:
        return None
    return selected_option == doc["correct_answer"]