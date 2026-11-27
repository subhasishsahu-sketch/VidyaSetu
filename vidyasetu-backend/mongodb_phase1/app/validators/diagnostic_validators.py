from app.validators.question_validators import PROBE_KEYS

EXECUTION_SOURCES = ["cloud_gemini", "edge_slm_offline_sync"]

_num = ["int", "long", "double"]

DIAGNOSTIC_VALIDATOR = {
    "$jsonSchema": {
        "bsonType": "object",
        "required": [
            "_id", "analysis_id", "student_id", "question_id",
            "attempt_data", "execution_source", "created_at",
        ],
        "properties": {
            "_id": {"bsonType": "string"},
            "analysis_id": {"bsonType": "string"},
            "student_id": {"bsonType": "string"},
            "question_id": {"bsonType": "string"},

            "attempt_data": {
                "bsonType": "object",
                "required": ["selected_option", "is_correct", "time_taken_sec"],
                "properties": {
                    "selected_option": {"bsonType": "string"},
                    "is_correct": {"bsonType": "bool"},
                    "time_taken_sec": {"bsonType": _num, "minimum": 0},
                    "confidence_rating": {"bsonType": "string"},
                    "answer_changes_count": {"bsonType": "int", "minimum": 0},
                },
            },

            "probe_loop_evidence": {
                "bsonType": "object",
                "properties": {
                    "possible_causes": {"bsonType": "array", "items": {"bsonType": "string"}},
                    "probes_triggered": {"bsonType": "array", "items": {"enum": PROBE_KEYS}},
                    "student_probe_responses": {"bsonType": "array"},
                    "is_diagnosis_supported": {"bsonType": "bool"},
                    "final_diagnosis": {"bsonType": "string"},
                    "confidence_score": {"bsonType": ["double", "int"], "minimum": 0, "maximum": 1},
                },
            },

            "student_parameters_snapshot": {
                "bsonType": "object",
                "properties": {
                    "time_taken": {"enum": ["High", "Low"]},
                    "confidence_level": {"enum": ["High", "Low"]},
                    "answer_changes": {"enum": ["Frequent", "None"]},
                    "language_preference": {"enum": ["Odia", "English"]},
                    "concept_understanding": {"enum": ["Understood", "Not Understood"]},
                    "previous_performance": {"enum": ["Strong", "Weak"]},
                    "english_comprehension": {"enum": ["Strong", "Weak"]},
                },
            },

            "intervention_and_language_output": {
                "bsonType": "object",
                "properties": {
                    "bilingual_explanation_odia_english": {"bsonType": "string"},
                    "english_terms_with_odia_meanings": {
                        "bsonType": "array",
                        "items": {
                            "bsonType": "object",
                            "required": ["english_term", "odia_meaning"],
                            "properties": {
                                "english_term": {"bsonType": "string"},
                                "odia_meaning": {"bsonType": "string"},
                            },
                        },
                    },
                    "grounded_textbook_reference": {"bsonType": "object"},
                    "recorded_english_exposure_level": {"bsonType": "int", "minimum": 1, "maximum": 4},
                },
            },

            "recovery_assessment": {
                "bsonType": "object",
                "properties": {
                    "practice_question_attempted": {"bsonType": "string"},
                    "is_recovery_correct": {"bsonType": "bool"},
                    "has_student_improved": {"bsonType": "bool"},
                },
            },

            "execution_source": {"enum": EXECUTION_SOURCES},
            "offline_created_at": {"bsonType": "date"},
            "created_at": {"bsonType": "date"},
        },
    }
}