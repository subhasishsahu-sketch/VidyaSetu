from datetime import datetime
from pydantic import (
    AliasChoices,
    BaseModel,
    ConfigDict,
    Field,
    computed_field,
    field_validator,
)


class ProgressUpdateRequest(BaseModel):
    """Schema for updating or initializing chapter progress."""

    chapter_name: str = Field(min_length=1, description="Chapter title")
    concept_understanding: float = Field(
        default=50.0, ge=0.0, le=100.0, description="Concept grasp (0-100)"
    )
    english_comprehension: float = Field(
        default=50.0,
        ge=0.0,
        le=100.0,
        validation_alias=AliasChoices("english_comprehension", "language_understanding"),
        description="English comfort (0-100)",
    )
    prerequisite_understanding: float = Field(
        default=50.0, ge=0.0, le=100.0, description="Prerequisite grasp (0-100)"
    )
    time_management: float = Field(
        default=50.0, ge=0.0, le=100.0, description="Pacing under timing (0-100)"
    )
    confidence_level: float = Field(
        default=50.0, ge=0.0, le=100.0, description="Confidence metric (0-100)"
    )
    previous_performance_score: float = Field(
        default=50.0,
        ge=0.0,
        le=100.0,
        validation_alias=AliasChoices("previous_performance_score", "accuracy"),
        description="Previous accuracy score (0-100)",
    )

    @field_validator("chapter_name", mode="before")
    @classmethod
    def strip_whitespace(cls, v: str) -> str:
        if isinstance(v, str):
            v = v.strip()
            if not v:
                raise ValueError("chapter_name cannot be empty or whitespace only")
        return v

    model_config = ConfigDict(populate_by_name=True)


class ProgressResponse(BaseModel):
    """Schema for chapter progress response, exposing both english_comprehension and language_understanding."""

    progress_id: str = Field(validation_alias=AliasChoices("progress_id", "_id"))
    student_id: str
    chapter_name: str
    concept_understanding: float
    english_comprehension: float
    prerequisite_understanding: float
    time_management: float
    confidence_level: float
    previous_performance_score: float
    overall_mastery: float
    last_updated: datetime

    @computed_field
    def language_understanding(self) -> float:
        """Alias for english_comprehension required by Flutter chart widgets."""
        return self.english_comprehension

    model_config = ConfigDict(populate_by_name=True)
