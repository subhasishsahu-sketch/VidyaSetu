from typing import Any, Dict, List
from pydantic import AliasChoices, BaseModel, ConfigDict, Field, model_validator


class QuestionOption(BaseModel):
    """Multiple-choice option."""

    key: str = Field(description="Option letter, e.g. 'A', 'B', 'C', 'D'")
    text: str = Field(description="Option text")

    model_config = ConfigDict(populate_by_name=True)


class DiagnosticProbes(BaseModel):
    """The 5 canonical diagnostic probe branches."""

    language_probe: Dict[str, Any] = Field(
        description="Probe in Odia Script (ଓଡ଼ିଆ) + English technical terms"
    )
    untimed_retry: Dict[str, Any] = Field(
        description="Pacing probe removing countdown pressure"
    )
    prerequisite_probe: Dict[str, Any] = Field(
        description="Foundational concept check from earlier syllabus"
    )
    transfer_probe: Dict[str, Any] = Field(
        description="Novel scenario testing principle transfer beyond rote memory"
    )
    explain_back: Dict[str, Any] = Field(
        description="Explanation/reasoning prompt in Odia or English"
    )

    model_config = ConfigDict(populate_by_name=True)


class RecoveryPracticeQuestionInternal(BaseModel):
    """Internal recovery practice question including answer key for grading."""

    practice_id: str
    question_text: str
    options: List[QuestionOption]
    answer_key: str

    model_config = ConfigDict(populate_by_name=True)


class RecoveryPracticeQuestionPublic(BaseModel):
    """Public recovery practice question omitting the answer key for student safety."""

    practice_id: str
    question_text: str
    options: List[QuestionOption]

    model_config = ConfigDict(populate_by_name=True)


class QuestionInternal(BaseModel):
    """Full question document stored in MongoDB, containing correct answers."""

    question_id: str = Field(validation_alias=AliasChoices("question_id", "_id"))
    subject: str
    chapter_name: str
    concept_name: str
    question_text: str
    options: List[QuestionOption]
    correct_answer: str
    expected_time_sec: int = Field(default=60, gt=0)
    diagnostic_probes: DiagnosticProbes
    recovery_practice_questions: List[RecoveryPracticeQuestionInternal] = Field(
        default_factory=list
    )

    model_config = ConfigDict(populate_by_name=True)


class QuestionPublicResponse(BaseModel):
    """Student-safe question delivery schema strictly omitting correct answers."""

    question_id: str = Field(validation_alias=AliasChoices("question_id", "_id"))
    subject: str
    chapter_name: str
    concept_name: str
    question_text: str
    options: List[QuestionOption]
    expected_time_sec: int = Field(default=60, gt=0)
    diagnostic_probes: DiagnosticProbes
    recovery_practice_questions: List[RecoveryPracticeQuestionPublic] = Field(
        default_factory=list
    )

    @model_validator(mode="before")
    @classmethod
    def strip_secret_keys(cls, data: Any) -> Any:
        if isinstance(data, dict):
            # Ensure correct_answer is never present in public response
            data.pop("correct_answer", None)
            rec = data.get("recovery_practice_questions")
            if isinstance(rec, list):
                sanitized = []
                for item in rec:
                    if isinstance(item, dict):
                        item_copy = dict(item)
                        item_copy.pop("answer_key", None)
                        sanitized.append(item_copy)
                    elif hasattr(item, "model_dump"):
                        dumped = item.model_dump()
                        dumped.pop("answer_key", None)
                        sanitized.append(dumped)
                    else:
                        sanitized.append(item)
                data["recovery_practice_questions"] = sanitized
        return data

    model_config = ConfigDict(populate_by_name=True)
