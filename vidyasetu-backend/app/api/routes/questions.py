from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from pymongo.asynchronous.database import AsyncDatabase
from app.database.mongodb import get_database
from app.repositories.questions_repository import (
    get_public_question_by_id,
    get_public_questions,
)
from app.schemas.question_schema import QuestionPublicResponse

router = APIRouter(prefix="/questions", tags=["Questions & Assessment"])


@router.get(
    "",
    response_model=List[QuestionPublicResponse],
    summary="Get question bank with student-safe projection",
)
async def list_questions(
    subject: Optional[str] = Query(None, description="Filter by subject"),
    chapter_name: Optional[str] = Query(None, description="Filter by chapter name"),
    concept_name: Optional[str] = Query(None, description="Filter by concept name"),
    db: AsyncDatabase = Depends(get_database),
):
    """Retrieves questions matching optional filters.

    Strictly omits 'correct_answer' and recovery 'answer_key' to prevent answer leakage.
    """
    questions = await get_public_questions(
        db,
        subject=subject,
        chapter_name=chapter_name,
        concept_name=concept_name,
    )
    return questions


@router.get(
    "/{question_id}",
    response_model=QuestionPublicResponse,
    summary="Get single question by ID",
)
async def get_question(
    question_id: str,
    db: AsyncDatabase = Depends(get_database),
):
    """Retrieves a single question by question_id with answers stripped."""
    question = await get_public_question_by_id(db, question_id)
    if not question:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Question with id '{question_id}' not found",
        )
    return question
