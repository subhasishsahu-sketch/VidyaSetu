from datetime import datetime, timezone
from typing import Any, Dict, List, Literal, Optional, Union
from pydantic import (
    BaseModel,
    ConfigDict,
    Field,
    field_validator,
)
from app.schemas.diagnostic_schema import StudentParametersSnapshot
from app.schemas.rag_schema import RagTextbookVector


class OfflinePackRequest(BaseModel):
    """Request payload for downloading an offline pack for a subject chapter."""

    subject: str = Field(min_length=1, description="Subject name (e.g. Science, History)")
    chapter_name: str = Field(min_length=1, description="Chapter title")

    @field_validator("subject", "chapter_name", mode="before")
    @classmethod
    def strip_whitespace(cls, v: str) -> str:
        if isinstance(v, str):
            cleaned = v.strip()
            if not cleaned:
                raise ValueError("Field cannot be empty or whitespace only")
            return cleaned
        return v

    model_config = ConfigDict(populate_by_name=True)


class OfflinePackResponse(BaseModel):
    """Offline pack containing cached curriculum questions and local vector embeddings."""

    pack_id: str = Field(description="Deterministic offline pack ID")
    subject: str
    chapter_name: str
    cached_questions: List[Dict[str, Any]] = Field(
        default_factory=list,
        description="Complete chapter questions including 5 diagnostic probes and recovery questions",
    )
    local_rag_vectors: List[RagTextbookVector] = Field(
        default_factory=list,
        description="Local textbook vector chunks with 768-dim embeddings and grounded citations",
    )
    cached_at: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc),
        description="Timestamp when the offline pack was assembled",
    )

    model_config = ConfigDict(populate_by_name=True)


class OfflineSyncEvent(BaseModel):
    """Single diagnostic analysis event generated on-device by mobile edge SLM."""

    analysis_id: str = Field(min_length=1, description="Lowercase UUID v4 generated on-device")
    student_id: str = Field(min_length=1, description="Student UUID v4")
    question_id: str = Field(min_length=1, description="Question UUID v4")
    attempt_data: Dict[str, Any] = Field(description="Initial attempt telemetry")
    probe_loop_evidence: List[Dict[str, Any]] = Field(
        default_factory=list, description="Diagnostic probes evaluated offline"
    )
    student_parameters_snapshot: Union[StudentParametersSnapshot, Dict[str, Any]] = Field(
        default_factory=dict, description="Categorical 7-parameter behavioral snapshot"
    )
    intervention_and_language_output: Optional[Dict[str, Any]] = Field(
        default=None, description="3-Way Language Bridge drawer output shown offline"
    )
    recovery_assessment: Optional[Dict[str, Any]] = Field(
        default=None, description="Offline recovery check result"
    )
    execution_source: Literal["edge_slm_offline_sync"] = Field(
        default="edge_slm_offline_sync", description="Source flag"
    )
    offline_created_at: datetime = Field(
        description="Timestamp recorded by mobile device during offline mode"
    )

    model_config = ConfigDict(populate_by_name=True)


class OfflineSyncFailedEvent(BaseModel):
    """Details of an event that failed validation during batch synchronization."""

    analysis_id: str
    reason: str

    model_config = ConfigDict(populate_by_name=True)


class OfflineSyncBatchRequest(BaseModel):
    """Batch payload containing offline events queued on mobile device."""

    student_id: str = Field(min_length=1, description="Student UUID v4 string")
    batch_timestamp: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc),
        description="Device batch dispatch timestamp",
    )
    events: List[OfflineSyncEvent] = Field(
        default_factory=list, description="List of offline diagnostic analysis events"
    )

    model_config = ConfigDict(populate_by_name=True)


class OfflineSyncBatchResponse(BaseModel):
    """Response returned after processing offline batch synchronization."""

    synced_ids: List[str] = Field(
        default_factory=list, description="IDs of newly ingested and acknowledged events"
    )
    duplicate_ids: List[str] = Field(
        default_factory=list, description="IDs of previously synced events (idempotently skipped)"
    )
    failed_events: List[OfflineSyncFailedEvent] = Field(
        default_factory=list, description="Events that failed validation with reasons"
    )

    model_config = ConfigDict(populate_by_name=True)
