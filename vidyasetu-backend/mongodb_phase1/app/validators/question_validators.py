PROBE_KEYS = [
    "language_probe",
    "untimed_retry",
    "prerequisite_probe",
    "transfer_probe",
    "explain_back",
]

QUESTION_VALIDATORS = {
    "$jsonSchema": {
        "bsonType": "object",
        "required": [
            "_id", "subject", "chapter_name", "concept_name",
            "question_text", "options", "correct_answer",
            "expected_time_sec", "diagnostic_probes",
        ],
        "properties": {
            "_id": {"bsonType": "string"},
            "subject": {"bsonType": "string", "minLength": 1},
            "chapter_name": {"bsonType": "string", "minLength": 1},
            "concept_name": {"bsonType": "string", "minLength": 1},
            "question_text": {"bsonType": "string", "minLength": 1},
            "options": {
                "bsonType": "array",
                "minItems": 2,
                "items": {
                    "bsonType": "object",
                    "required": ["key", "text"],
                    "properties": {
                        "key": {"bsonType": "string"},
                        "text": {"bsonType": "string"},
                    },
                },
            },
            "correct_answer": {"bsonType": "string", "minLength": 1},
            "expected_time_sec": {"bsonType": "int", "minimum": 1},
            "diagnostic_probes": {
                "bsonType": "object",
                "required": PROBE_KEYS,
                "properties": {k: {"bsonType": "object"} for k in PROBE_KEYS},
            },
            "recovery_practice_questions": {
                "bsonType": "array",
                "items": {
                    "bsonType": "object",
                    "required": ["practice_id", "question_text", "answer_key"],
                    "properties": {
                        "practice_id": {"bsonType": "string"},
                        "question_text": {"bsonType": "string"},
                        "answer_key": {"bsonType": "string"},
                    },
                },
            },
        },
    }
}