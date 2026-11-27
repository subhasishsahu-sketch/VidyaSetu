"""JSON Schema validator for the `students` collection (Table 1)."""

LANGUAGES = ("Odia", "English")

STUDENTS_VALIDATOR = {
    "$jsonSchema": {
        "bsonType": "object",
        "required": [
            "_id", "name", "class_grade", "preferred_language",
            "english_exposure_level", "subject", "completed_chapters", "created_at",
        ],
        "properties": {
            "_id": {"bsonType": "string", "description": "student_id (UUID string)"},
            "name": {"bsonType": "string", "minLength": 1, "maxLength": 100},
            "class_grade": {"bsonType": ["int", "long"], "minimum": 1, "maximum": 12},
            "preferred_language": {"enum": list(LANGUAGES)},
            "english_exposure_level": {"bsonType": ["int", "long"], "minimum": 1, "maximum": 4},
            "subject": {"bsonType": "string", "minLength": 1},
            "completed_chapters": {"bsonType": ["int", "long"], "minimum": 0},
            # Written by the Autonomous Study Planner. May be null until first planned.
            "recommended_next_task": {
                "bsonType": ["object", "null"],
                "properties": {
                    "subject": {"bsonType": "string"},
                    "chapter_name": {"bsonType": "string"},
                    "task_type": {"bsonType": "string"},
                    "reason": {"bsonType": "string"},
                    "recommended_for": {"bsonType": "date"},
                },
            },
            "created_at": {"bsonType": "date"},
        },
    }
}
