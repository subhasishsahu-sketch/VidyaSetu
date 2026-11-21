from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from pymongo.asynchronous.database import AsyncDatabase
from app.database.mongodb import get_database
from app.repositories.progress_repository import (
    get_chapter_progress,
    get_student_progress_list,
    sync_student_aggregates,
    upsert_progress,
)
from app.repositories.students_repository import (
    create_student,
    get_student_by_id,
)
from app.schemas.progress_schema import ProgressResponse, ProgressUpdateRequest
from app.schemas.student_schema import StudentCreateRequest, StudentResponse

router = APIRouter(prefix="/students", tags=["Students & Progress"])


@router.post(
    "",
    response_model=StudentResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Register a new student",
)
async def register_student(
    student_in: StudentCreateRequest,
    db: AsyncDatabase = Depends(get_database),
):
    """Registers a new student with a unique lowercase UUID v4 identifier."""
    doc = await create_student(db, student_in)
    return doc


@router.get(
    "/{student_id}",
    response_model=StudentResponse,
    summary="Get student profile",
)
async def get_student(
    student_id: str,
    db: AsyncDatabase = Depends(get_database),
):
    """Retrieves student profile by student_id."""
    student = await get_student_by_id(db, student_id)
    if not student:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Student with id '{student_id}' not found",
        )
    return student


@router.post(
    "/{student_id}/progress",
    response_model=ProgressResponse,
    summary="Add or update chapter progress",
)
async def update_progress(
    student_id: str,
    progress_in: ProgressUpdateRequest,
    db: AsyncDatabase = Depends(get_database),
):
    """Upserts chapter progress scores, recalculates overall_mastery, and syncs student aggregates."""
    student = await get_student_by_id(db, student_id)
    if not student:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Student with id '{student_id}' not found",
        )

    updated_progress = await upsert_progress(db, student_id, progress_in)
    await sync_student_aggregates(db, student_id)
    return updated_progress


@router.get(
    "/{student_id}/progress",
    response_model=List[ProgressResponse],
    summary="Get all chapter progress records",
)
async def get_progress_list(
    student_id: str,
    db: AsyncDatabase = Depends(get_database),
):
    """Retrieves all chapter progress records for a student sorted by last_updated DESC."""
    student = await get_student_by_id(db, student_id)
    if not student:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Student with id '{student_id}' not found",
        )

    return await get_student_progress_list(db, student_id)


@router.get(
    "/{student_id}/progress/{chapter_name}",
    response_model=ProgressResponse,
    summary="Get progress for a specific chapter",
)
async def get_single_chapter_progress(
    student_id: str,
    chapter_name: str,
    db: AsyncDatabase = Depends(get_database),
):
    """Retrieves progress for a specific chapter."""
    student = await get_student_by_id(db, student_id)
    if not student:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Student with id '{student_id}' not found",
        )

    clean_chapter = chapter_name.strip()
    progress = await get_chapter_progress(db, student_id, clean_chapter)
    if not progress:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Progress record for chapter '{clean_chapter}' not found",
        )

    return progress
