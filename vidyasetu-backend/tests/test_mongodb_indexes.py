import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from pymongo import ASCENDING, DESCENDING
from app.database.mongodb import (
    ensure_indexes,
    connect_to_mongo,
    close_mongo_connection,
    get_database,
    mongodb_manager,
)
from app.database.collections import (
    COLLECTION_STUDENTS,
    COLLECTION_STUDENT_PROGRESS,
    COLLECTION_QUESTIONS,
    COLLECTION_DIAGNOSTIC_ANALYSIS,
    COLLECTION_RAG_TEXTBOOK_VECTORS,
)


@pytest.mark.asyncio
async def test_ensure_indexes_calls():
    # Setup mock collections and database
    mock_db = MagicMock()
    collections = {}

    def get_collection(name):
        if name not in collections:
            col = MagicMock()
            col.create_index = AsyncMock()
            collections[name] = col
        return collections[name]

    mock_db.__getitem__.side_effect = get_collection

    await ensure_indexes(mock_db)

    # 1. students indexes
    students_col = collections[COLLECTION_STUDENTS]
    students_col.create_index.assert_called_once_with(
        [("class_grade", ASCENDING), ("subject", ASCENDING)],
        name="idx_students_class_subject",
    )

    # 2. student_progress indexes
    prog_col = collections[COLLECTION_STUDENT_PROGRESS]
    assert prog_col.create_index.call_count == 2
    prog_col.create_index.assert_any_call(
        [("student_id", ASCENDING), ("chapter_name", ASCENDING)],
        unique=True,
        name="uq_student_chapter",
    )
    prog_col.create_index.assert_any_call(
        [("student_id", ASCENDING), ("last_updated", DESCENDING)],
        name="idx_student_last_updated",
    )

    # 3. questions indexes
    q_col = collections[COLLECTION_QUESTIONS]
    q_col.create_index.assert_called_once_with(
        [("subject", ASCENDING), ("chapter_name", ASCENDING), ("concept_name", ASCENDING)],
        name="idx_questions_lookup",
    )

    # 4. diagnostic_analysis indexes
    diag_col = collections[COLLECTION_DIAGNOSTIC_ANALYSIS]
    assert diag_col.create_index.call_count == 4
    diag_col.create_index.assert_any_call(
        [("analysis_id", ASCENDING)],
        unique=True,
        name="uq_analysis_id",
    )
    diag_col.create_index.assert_any_call(
        [("student_id", ASCENDING), ("created_at", DESCENDING)],
        name="idx_diag_student_created",
    )
    diag_col.create_index.assert_any_call(
        [("question_id", ASCENDING), ("created_at", DESCENDING)],
        name="idx_diag_question_created",
    )
    diag_col.create_index.assert_any_call(
        [("execution_source", ASCENDING), ("created_at", DESCENDING)],
        name="idx_diag_execution_source",
    )

    # 5. rag_textbook_vectors indexes
    rag_col = collections[COLLECTION_RAG_TEXTBOOK_VECTORS]
    rag_col.create_index.assert_called_once_with(
        [("subject", ASCENDING), ("chapter_name", ASCENDING)],
        name="idx_rag_subject_chapter",
    )


@pytest.mark.asyncio
async def test_connect_to_mongo_failure_resets_manager():
    # Simulate failed connection
    with patch("app.database.mongodb.AsyncMongoClient") as mock_client_cls:
        instance = MagicMock()
        instance.admin.command = AsyncMock(side_effect=ConnectionError("Could not reach MongoDB"))
        instance.close = AsyncMock()
        mock_client_cls.return_value = instance

        with pytest.raises(ConnectionError):
            await connect_to_mongo()

        # Manager state must be None
        assert mongodb_manager.client is None
        assert mongodb_manager.db is None
        instance.close.assert_called_once()


@pytest.mark.asyncio
async def test_get_database_dependency():
    mongodb_manager.db = None
    with pytest.raises(RuntimeError, match="Database connection has not been initialized"):
        await get_database()

    mock_db = MagicMock()
    mongodb_manager.db = mock_db
    try:
        db = await get_database()
        assert db == mock_db
    finally:
        mongodb_manager.db = None
