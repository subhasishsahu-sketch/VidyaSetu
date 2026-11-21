import pytest
from unittest.mock import MagicMock
from app.core.config import Settings
from app.database import collections


def test_settings_defaults():
    settings = Settings()
    assert settings.MONGODB_URI == "mongodb://localhost:27017"
    assert settings.MONGODB_DB_NAME == "vidyasetu"
    assert settings.HOST == "0.0.0.0"
    assert settings.PORT == 8000
    assert settings.CORS_ORIGINS == ["*"]


def test_cors_origins_parsing():
    s1 = Settings(CORS_ORIGINS='["http://localhost:3000", "http://10.0.2.2:8000"]')
    assert s1.CORS_ORIGINS == ["http://localhost:3000", "http://10.0.2.2:8000"]

    s2 = Settings(CORS_ORIGINS="http://localhost:3000, http://localhost:8000")
    assert s2.CORS_ORIGINS == ["http://localhost:3000", "http://localhost:8000"]

    s3 = Settings(CORS_ORIGINS=["https://vidyasetu.app"])
    assert s3.CORS_ORIGINS == ["https://vidyasetu.app"]


def test_collection_constants():
    assert collections.COLLECTION_STUDENTS == "students"
    assert collections.COLLECTION_STUDENT_PROGRESS == "student_progress"
    assert collections.COLLECTION_QUESTIONS == "questions"
    assert collections.COLLECTION_DIAGNOSTIC_ANALYSIS == "diagnostic_analysis"
    assert collections.COLLECTION_RAG_TEXTBOOK_VECTORS == "rag_textbook_vectors"

    assert len(collections.ALL_COLLECTIONS) == 5
    assert set(collections.ALL_COLLECTIONS) == {
        "students",
        "student_progress",
        "questions",
        "diagnostic_analysis",
        "rag_textbook_vectors",
    }


def test_typed_collection_getters():
    mock_db = MagicMock()
    mock_db.__getitem__.side_effect = lambda name: f"mock_col_{name}"

    assert collections.get_students_collection(mock_db) == "mock_col_students"
    assert collections.get_student_progress_collection(mock_db) == "mock_col_student_progress"
    assert collections.get_questions_collection(mock_db) == "mock_col_questions"
    assert collections.get_diagnostic_analysis_collection(mock_db) == "mock_col_diagnostic_analysis"
    assert collections.get_rag_textbook_vectors_collection(mock_db) == "mock_col_rag_textbook_vectors"
