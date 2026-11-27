"""JSON Schema validator for the `student_progress` collection (Table 2)."""

# The six inputs to the weighted mastery score.
INPUT_SCORE_FIELDS = (
    "concept_understanding",
    "english_comprehension",
    "prerequisite_understanding",
    "time_management",
    "confidence_level",
    "previous_performance_score",
)
ALL_SCORE_FIELDS = INPUT_SCORE_FIELDS + ("overall_mastery",)

_score = {"bsonType": ["double", "int", "long"], "minimum": 0, "maximum": 100}

STUDENT_PROGRESS_VALIDATOR = {
    "$jsonSchema": {
        "bsonType": "object",
        "required": ["_id", "student_id", "chapter_name", *ALL_SCORE_FIELDS, "last_updated"],
        "properties": {
            "_id": {"bsonType": "string", "description": "progress_id (UUID string)"},
            "student_id": {"bsonType": "string", "description": "Reference to students._id"},
            "chapter_name": {"bsonType": "string", "minLength": 1},
            **{field: _score for field in ALL_SCORE_FIELDS},
            "last_updated": {"bsonType": "date"},
        },
    }
}
