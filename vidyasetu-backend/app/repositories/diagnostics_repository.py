"""Diagnostics repository for the diagnostic_analysis collection."""

from typing import Any, Dict, Optional
from pymongo import ReturnDocument
from app.database.collections import COLLECTION_DIAGNOSTIC_ANALYSIS
from app.schemas.diagnostic_schema import DiagnosticAnalysisDocument


async def create_diagnostic_record(
    db: Any, doc: DiagnosticAnalysisDocument
) -> DiagnosticAnalysisDocument:
    """Inserts a diagnostic analysis record deduplicated via $setOnInsert upsert on analysis_id."""
    collection = db[COLLECTION_DIAGNOSTIC_ANALYSIS]

    insert_payload = {
        "_id": doc.analysis_id,
        "analysis_id": doc.analysis_id,
        "student_id": doc.student_id,
        "question_id": doc.question_id,
        "attempt_data": doc.attempt_data,
        "probe_loop_evidence": doc.probe_loop_evidence,
        "student_parameters_snapshot": doc.student_parameters_snapshot,
        "intervention_and_language_output": doc.intervention_and_language_output,
        "recovery_assessment": doc.recovery_assessment,
        "execution_source": doc.execution_source,
        "created_at": doc.created_at,
        "offline_created_at": doc.offline_created_at,
    }

    result = await collection.find_one_and_update(
        {"analysis_id": doc.analysis_id},
        {"$setOnInsert": insert_payload},
        upsert=True,
        return_document=ReturnDocument.AFTER,
    )
    return DiagnosticAnalysisDocument(**result)


async def get_diagnostic_record(db: Any, analysis_id: str) -> Optional[Dict[str, Any]]:
    """Retrieves a diagnostic analysis document by its analysis_id."""
    collection = db[COLLECTION_DIAGNOSTIC_ANALYSIS]
    return await collection.find_one({"analysis_id": analysis_id})


async def update_diagnostic_record(
    db: Any, analysis_id: str, update_fields: Dict[str, Any]
) -> Optional[Dict[str, Any]]:
    """Updates fields on an existing diagnostic analysis record."""
    collection = db[COLLECTION_DIAGNOSTIC_ANALYSIS]
    return await collection.find_one_and_update(
        {"analysis_id": analysis_id},
        {"$set": update_fields},
        return_document=ReturnDocument.AFTER,
    )


async def append_probe_evidence(
    db: Any,
    analysis_id: str,
    evidence_item: Dict[str, Any],
    additional_updates: Optional[Dict[str, Any]] = None,
) -> Optional[Dict[str, Any]]:
    """Pushes a new probe attempt into probe_loop_evidence and sets additional fields."""
    collection = db[COLLECTION_DIAGNOSTIC_ANALYSIS]
    update_op: Dict[str, Any] = {"$push": {"probe_loop_evidence": evidence_item}}
    if additional_updates:
        update_op["$set"] = additional_updates
    return await collection.find_one_and_update(
        {"analysis_id": analysis_id},
        update_op,
        return_document=ReturnDocument.AFTER,
    )
