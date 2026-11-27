import asyncio

from app.database.mongodb import get_db, get_client
from app.repositories.diagnostics_repository import save_analysis

# Fixed IDs, so running this script twice cannot create copies
CLOUD_EVENT_ID = "a1b2c3d4-0001-4000-8000-000000000001"
OFFLINE_EVENT_ID = "a1b2c3d4-0002-4000-8000-000000000002"


async def main():
    db = get_db()

    # Use a real student and a real question already in the database
    student = await db.students.find_one({})
    question = await db.questions.find_one({"concept_name": "Non-Cooperation Movement"})

    if student is None or question is None:
        print("Need data first. Run seed_more (students) and seed_questions (questions).")
        await get_client().close()
        return

    student_id = student["_id"]
    question_id = question["_id"]

    # EVENT 1: a normal online run (cloud)
    cloud_event = {
        "analysis_id": CLOUD_EVENT_ID,
        "student_id": student_id,
        "question_id": question_id,
        "attempt_data": {
            "selected_option": "A",
            "is_correct": False,
            "time_taken_sec": 68,
            "confidence_rating": "low",
            "answer_changes_count": 2,
        },
        "probe_loop_evidence": {
            "possible_causes": ["language_barrier", "careless_mistake"],
            "probes_triggered": ["language_probe", "untimed_retry"],
            "student_probe_responses": ["Option B"],
            "is_diagnosis_supported": True,
            "final_diagnosis": "language_barrier",
            "confidence_score": 0.84,
        },
        "student_parameters_snapshot": {
            "time_taken": "High",
            "confidence_level": "Low",
            "answer_changes": "Frequent",
            "language_preference": "Odia",
            "concept_understanding": "Understood",
            "previous_performance": "Strong",
            "english_comprehension": "Weak",
        },
        "intervention_and_language_output": {
            "bilingual_explanation_odia_english": (
                "The Non-Cooperation Movement (ଅସହଯୋଗ ଆନ୍ଦୋଳନ) was started by "
                "Mahatma Gandhi in 1920."
            ),
            "english_terms_with_odia_meanings": [
                {"english_term": "Non-Cooperation", "odia_meaning": "ଅସହଯୋଗ"},
                {"english_term": "Movement", "odia_meaning": "ଆନ୍ଦୋଳନ"},
            ],
            "grounded_textbook_reference": {
                "textbook_name": "BSE Odisha Class 10 History",
                "chapter_no": 2,
                "page_no": 58,
                "paragraph_no": 3,
            },
            "recorded_english_exposure_level": 1,
        },
        "recovery_assessment": {
            "practice_question_attempted": "REC-001",
            "is_recovery_correct": True,
            "has_student_improved": True,
        },
        "execution_source": "cloud_gemini",
    }

    # EVENT 2: done on a phone with no internet, uploaded later
    offline_event = {
        "analysis_id": OFFLINE_EVENT_ID,
        "student_id": student_id,
        "question_id": question_id,
        "attempt_data": {
            "selected_option": "C",
            "is_correct": False,
            "time_taken_sec": 30,
            "confidence_rating": "high",
            "answer_changes_count": 0,
        },
        "probe_loop_evidence": {
            "possible_causes": ["prerequisite_gap"],
            "probes_triggered": ["prerequisite_probe"],
            "student_probe_responses": ["Not sure"],
            "is_diagnosis_supported": True,
            "final_diagnosis": "prerequisite_gap",
            "confidence_score": 0.7,
        },
        "student_parameters_snapshot": {
            "time_taken": "Low",
            "confidence_level": "High",
            "answer_changes": "None",
            "language_preference": "Odia",
            "concept_understanding": "Not Understood",
            "previous_performance": "Weak",
            "english_comprehension": "Strong",
        },
        "execution_source": "edge_slm_offline_sync",
        "offline_created_at": "2026-11-23T08:45:00Z",
    }

    for name, event in [("cloud", cloud_event), ("offline", offline_event)]:
        result = await save_analysis(event)
        status = "saved (new)" if result["inserted"] else "already existed, skipped"
        print(f"{name}: {status} -> {result['analysis_id']}")

    await get_client().close()


if __name__ == "__main__":
    asyncio.run(main())