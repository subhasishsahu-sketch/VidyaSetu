"""Language Intelligence routes for Tri-Lingual RAG and student language progression."""

from fastapi import APIRouter, Depends, HTTPException, status
from app.database.mongodb import get_database
from app.repositories import progress_repository, rag_repository, students_repository
from app.schemas.diagnostic_schema import (
    LanguageExplainRequest,
    LanguageExplainResponse,
    LanguageProgressResponse,
)
from app.schemas.rag_schema import GroundedReference
from app.services import language_service, mastery_service

router = APIRouter(prefix="/language", tags=["Language Intelligence"])

PROFICIENCY_BANDS = {
    1: "Level 1: Full Bilingual Support (ସମ୍ପୂର୍ଣ୍ଣ ଦ୍ୱିଭାଷୀ ସହାୟତା)",
    2: "Level 2: English Term Emphasis (ଇଂରାଜୀ ବୈଷୟିକ ଶବ୍ଦ ଗୁରୁତ୍ୱ)",
    3: "Level 3: English with Odia Hints (ଓଡ଼ିଆ ସଙ୍କେତ ସହିତ ଇଂରାଜୀ)",
    4: "Level 4: Exam English (ପରୀକ୍ଷା ଇଂରାଜୀ)",
}


@router.post(
    "/explain",
    response_model=LanguageExplainResponse,
    status_code=status.HTTP_200_OK,
    summary="Explain concept via 3-Way Language Bridge",
)
async def explain_concept(
    request: LanguageExplainRequest,
    db=Depends(get_database),
):
    """Provides a 3-Way Language Bridge explanation for any academic topic or text snippet.

    Grounded in Odisha state textbook vectors, returning bilingual (Odia + English terms),
    pure Odia, and pure English explanations with vocabulary definitions.
    """
    target_level = request.target_level
    if not target_level and request.student_id:
        student = await students_repository.get_student_by_id(db, request.student_id)
        if student:
            target_level = int(student.get("english_exposure_level", 1))
    if not target_level:
        target_level = 1

    chunk_doc = None
    if request.subject and request.chapter_name:
        chunks = await rag_repository.get_chunks_by_chapter(
            db, request.subject, request.chapter_name
        )
        if chunks:
            chunk_doc = chunks[0]
    elif request.subject:
        chunks = await rag_repository.get_chunks_by_subject(db, request.subject)
        if chunks:
            chunk_doc = chunks[0]

    if not chunk_doc:
        chunk_doc = {
            "chunk_text": request.text,
            "important_english_terms": [],
            "grounded_reference": {
                "textbook_name": "BSE Odisha Board Curriculum",
                "chapter_no": 1,
                "section_heading": request.chapter_name or "General Concept",
            },
        }

    intervention = language_service.generate_intervention(
        chunk_doc=chunk_doc,
        student_english_level=target_level,
        misconception="General student inquiry",
        question_text=request.text,
    )

    return LanguageExplainResponse(
        bilingual_explanation_odia_english=intervention.bilingual_explanation_odia_english,
        pure_odia_explanation=intervention.pure_odia_explanation,
        pure_english_explanation=intervention.pure_english_explanation,
        english_terms_with_odia_meanings=intervention.english_terms_with_odia_meanings,
        grounded_textbook_reference=intervention.grounded_textbook_reference,
        recorded_english_exposure_level=target_level,
    )


@router.get(
    "/progress/{student_id}",
    response_model=LanguageProgressResponse,
    status_code=status.HTTP_200_OK,
    summary="Get student language progression metrics",
)
async def get_student_language_progress(
    student_id: str,
    db=Depends(get_database),
):
    """Returns student's English exposure calibration, average English comprehension, and band."""
    student = await students_repository.get_student_by_id(db, student_id)
    if not student:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Student {student_id} not found",
        )

    all_progress = await progress_repository.get_student_progress_list(db, student_id)
    if all_progress:
        mean_eng = sum(
            float(p.get("english_comprehension", 50.0)) for p in all_progress
        ) / len(all_progress)
        level = mastery_service.map_english_exposure_level(mean_eng)
        total_chapters = len(all_progress)
    else:
        mean_eng = 50.0
        level = int(student.get("english_exposure_level", 1))
        total_chapters = 0

    band = PROFICIENCY_BANDS.get(level, PROFICIENCY_BANDS[1])

    return LanguageProgressResponse(
        student_id=student_id,
        english_exposure_level=level,
        mean_english_comprehension=round(mean_eng, 2),
        total_chapters_tracked=total_chapters,
        language_proficiency_band=band,
    )
