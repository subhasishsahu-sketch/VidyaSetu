import logging
from typing import Optional
from pymongo import AsyncMongoClient, ASCENDING, DESCENDING
from pymongo.asynchronous.database import AsyncDatabase
from app.core.config import settings
from app.database.collections import (
    COLLECTION_STUDENTS,
    COLLECTION_STUDENT_PROGRESS,
    COLLECTION_QUESTIONS,
    COLLECTION_DIAGNOSTIC_ANALYSIS,
    COLLECTION_RAG_TEXTBOOK_VECTORS,
)

logger = logging.getLogger(__name__)


class MongoDBManager:
    client: Optional[AsyncMongoClient] = None
    db: Optional[AsyncDatabase] = None


mongodb_manager = MongoDBManager()


async def connect_to_mongo() -> None:
    """Initialize AsyncMongoClient, verify connection with ping, and ensure indexes.

    Do not assign mongodb_manager.db until ping and ensure_indexes() succeed.
    On failure, close client and reset state to None.
    """
    logger.info("Connecting to MongoDB at %s...", settings.MONGODB_URI)
    client: Optional[AsyncMongoClient] = None
    try:
        client = AsyncMongoClient(
            settings.MONGODB_URI,
            serverSelectionTimeoutMS=5000,
        )
        # Verify connectivity via admin ping
        await client.admin.command("ping")
        logger.info("MongoDB ping successful.")

        db_instance = client[settings.MONGODB_DB_NAME]
        await ensure_indexes(db_instance)

        # Successful connection and index creation: assign to manager
        mongodb_manager.client = client
        mongodb_manager.db = db_instance
        logger.info("MongoDB initialized and indexes ensured for database '%s'.", settings.MONGODB_DB_NAME)

    except Exception as exc:
        logger.warning("MongoDB connection / initialization failed: %s", exc)
        if client is not None:
            try:
                await client.close()
            except Exception:
                pass
        mongodb_manager.client = None
        mongodb_manager.db = None
        raise exc


async def close_mongo_connection() -> None:
    """Close MongoDB connection pool cleanly."""
    if mongodb_manager.client is not None:
        logger.info("Closing MongoDB connection...")
        try:
            await mongodb_manager.client.close()
        except Exception as exc:
            logger.warning("Error closing MongoDB client: %s", exc)
        finally:
            mongodb_manager.client = None
            mongodb_manager.db = None
        logger.info("MongoDB connection closed.")


async def get_database() -> AsyncDatabase:
    """FastAPI dependency to inject AsyncDatabase."""
    if mongodb_manager.db is None:
        raise RuntimeError("Database connection has not been initialized.")
    return mongodb_manager.db


async def ensure_indexes(db: AsyncDatabase) -> None:
    """Create required unique and compound query indexes across all 5 canonical collections."""
    logger.info("Ensuring canonical MongoDB indexes across collections...")

    # Collection 1: students
    await db[COLLECTION_STUDENTS].create_index(
        [("class_grade", ASCENDING), ("subject", ASCENDING)],
        name="idx_students_class_subject",
    )

    # Collection 2: student_progress
    await db[COLLECTION_STUDENT_PROGRESS].create_index(
        [("student_id", ASCENDING), ("chapter_name", ASCENDING)],
        unique=True,
        name="uq_student_chapter",
    )
    await db[COLLECTION_STUDENT_PROGRESS].create_index(
        [("student_id", ASCENDING), ("last_updated", DESCENDING)],
        name="idx_student_last_updated",
    )

    # Collection 3: questions
    await db[COLLECTION_QUESTIONS].create_index(
        [("subject", ASCENDING), ("chapter_name", ASCENDING), ("concept_name", ASCENDING)],
        name="idx_questions_lookup",
    )

    # Collection 4: diagnostic_analysis
    await db[COLLECTION_DIAGNOSTIC_ANALYSIS].create_index(
        [("analysis_id", ASCENDING)],
        unique=True,
        name="uq_analysis_id",
    )
    await db[COLLECTION_DIAGNOSTIC_ANALYSIS].create_index(
        [("student_id", ASCENDING), ("created_at", DESCENDING)],
        name="idx_diag_student_created",
    )
    await db[COLLECTION_DIAGNOSTIC_ANALYSIS].create_index(
        [("question_id", ASCENDING), ("created_at", DESCENDING)],
        name="idx_diag_question_created",
    )
    await db[COLLECTION_DIAGNOSTIC_ANALYSIS].create_index(
        [("execution_source", ASCENDING), ("created_at", DESCENDING)],
        name="idx_diag_execution_source",
    )

    # Collection 5: rag_textbook_vectors
    await db[COLLECTION_RAG_TEXTBOOK_VECTORS].create_index(
        [("subject", ASCENDING), ("chapter_name", ASCENDING)],
        name="idx_rag_subject_chapter",
    )

    logger.info("All canonical MongoDB indexes ensured successfully.")
