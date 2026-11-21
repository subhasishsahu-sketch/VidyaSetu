from pymongo.asynchronous.collection import AsyncCollection
from pymongo.asynchronous.database import AsyncDatabase

# Canonical 5 collections required by AGENTS.md
COLLECTION_STUDENTS = "students"
COLLECTION_STUDENT_PROGRESS = "student_progress"
COLLECTION_QUESTIONS = "questions"
COLLECTION_DIAGNOSTIC_ANALYSIS = "diagnostic_analysis"
COLLECTION_RAG_TEXTBOOK_VECTORS = "rag_textbook_vectors"

ALL_COLLECTIONS = [
    COLLECTION_STUDENTS,
    COLLECTION_STUDENT_PROGRESS,
    COLLECTION_QUESTIONS,
    COLLECTION_DIAGNOSTIC_ANALYSIS,
    COLLECTION_RAG_TEXTBOOK_VECTORS,
]


def get_students_collection(db: AsyncDatabase) -> AsyncCollection:
    """Returns the typed students collection."""
    return db[COLLECTION_STUDENTS]


def get_student_progress_collection(db: AsyncDatabase) -> AsyncCollection:
    """Returns the typed student_progress collection."""
    return db[COLLECTION_STUDENT_PROGRESS]


def get_questions_collection(db: AsyncDatabase) -> AsyncCollection:
    """Returns the typed questions collection."""
    return db[COLLECTION_QUESTIONS]


def get_diagnostic_analysis_collection(db: AsyncDatabase) -> AsyncCollection:
    """Returns the typed diagnostic_analysis collection."""
    return db[COLLECTION_DIAGNOSTIC_ANALYSIS]


def get_rag_textbook_vectors_collection(db: AsyncDatabase) -> AsyncCollection:
    """Returns the typed rag_textbook_vectors collection."""
    return db[COLLECTION_RAG_TEXTBOOK_VECTORS]
