from typing import Any, Dict, List, Optional
from pymongo.asynchronous.database import AsyncDatabase
from app.database.collections import get_questions_collection

PUBLIC_QUESTION_PROJECTION = {
    "correct_answer": 0,
    "recovery_practice_questions.answer_key": 0,
}


async def get_public_questions(
    db: AsyncDatabase,
    subject: Optional[str] = None,
    chapter_name: Optional[str] = None,
    concept_name: Optional[str] = None,
) -> List[Dict[str, Any]]:
    """Retrieves questions matching optional filters, strictly omitting correct_answer and recovery answer_key."""
    col = get_questions_collection(db)
    query: Dict[str, Any] = {}
    if subject:
        query["subject"] = subject.strip()
    if chapter_name:
        query["chapter_name"] = chapter_name.strip()
    if concept_name:
        query["concept_name"] = concept_name.strip()

    cursor = col.find(query, projection=PUBLIC_QUESTION_PROJECTION)
    return await cursor.to_list(length=None)


async def get_public_question_by_id(
    db: AsyncDatabase, question_id: str
) -> Optional[Dict[str, Any]]:
    """Retrieves a single question by question_id with answer keys strictly stripped."""
    col = get_questions_collection(db)
    return await col.find_one(
        {"_id": question_id.strip()},
        projection=PUBLIC_QUESTION_PROJECTION,
    )


async def get_question_internal(
    db: AsyncDatabase, question_id: str
) -> Optional[Dict[str, Any]]:
    """Backend-only getter returning the full question including correct_answer for grading."""
    col = get_questions_collection(db)
    return await col.find_one({"_id": question_id.strip()})


async def get_internal_questions_by_chapter(
    db: AsyncDatabase, subject: str, chapter_name: str
) -> List[Dict[str, Any]]:
    """Retrieves all questions for a chapter including probes and recovery questions for offline packs."""
    col = get_questions_collection(db)
    cursor = col.find(
        {
            "subject": subject.strip(),
            "chapter_name": chapter_name.strip(),
        }
    )
    return await cursor.to_list(length=None)


# Alias for explicit naming
get_question_by_id_internal = get_question_internal


async def upsert_question(db: AsyncDatabase, question_doc: Dict[str, Any]) -> None:
    """Idempotently upserts a question document into the questions collection."""
    col = get_questions_collection(db)
    qid = question_doc.get("_id") or question_doc.get("question_id")
    if not qid:
        raise ValueError("Question document must contain '_id' or 'question_id'")
    doc_to_save = dict(question_doc)
    doc_to_save["_id"] = qid
    doc_to_save["question_id"] = qid
    await col.update_one({"_id": qid}, {"$set": doc_to_save}, upsert=True)
