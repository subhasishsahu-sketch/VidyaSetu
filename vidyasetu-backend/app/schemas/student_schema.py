from datetime import datetime
from typing import Any, Dict, Literal, Optional
from pydantic import AliasChoices, BaseModel, ConfigDict, Field


class StudentCreateRequest(BaseModel):
    """Schema for registering a new student."""

    name: str = Field(min_length=2, max_length=100, description="Full name of student")
    class_grade: int = Field(
        ge=6,
        le=12,
        validation_alias=AliasChoices("class_grade", "class"),
        description="Class grade (6-12)",
    )
    preferred_language: Literal["Odia", "English"] = Field(
        default="Odia", description="Preferred instruction language"
    )
    english_exposure_level: int = Field(
        default=1, ge=1, le=4, description="Calibrated English level (1-4)"
    )
    subject: str = Field(min_length=1, max_length=100, description="Primary subject")

    model_config = ConfigDict(populate_by_name=True)


class StudentResponse(BaseModel):
    """Schema for student profile responses."""

    student_id: str = Field(validation_alias=AliasChoices("student_id", "_id"))
    name: str
    class_grade: int
    preferred_language: Literal["Odia", "English"]
    english_exposure_level: int
    subject: str
    completed_chapters: int = 0
    recommended_next_task: Optional[Dict[str, Any]] = None
    created_at: datetime

    model_config = ConfigDict(populate_by_name=True)
