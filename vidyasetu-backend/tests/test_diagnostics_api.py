"""End-to-end API tests for WHY Engine diagnostics and Language Intelligence."""

import re
import pytest
from httpx import ASGITransport, AsyncClient
from app.database.mongodb import get_database
from app.database.seed import seed_database
from app.main import app
from tests.test_students_api import InMemoryAsyncDatabase


@pytest.fixture
def test_db():
    return InMemoryAsyncDatabase()


@pytest.fixture
async def client(test_db):
    await seed_database(test_db)
    app.dependency_overrides[get_database] = lambda: test_db
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        yield c
    app.dependency_overrides.clear()


@pytest.fixture
async def registered_student_id(client):
    res = await client.post(
        "/api/v1/students",
        json={
            "name": "Subham Swain",
            "class_grade": 10,
            "preferred_language": "Odia",
            "english_exposure_level": 1,
            "subject": "History",
        },
    )
    assert res.status_code == 201
    return res.json()["student_id"]


@pytest.fixture
async def question_id(client):
    res = await client.get("/api/v1/questions?subject=History")
    assert res.status_code == 200
    questions = res.json()
    assert len(questions) > 0
    return questions[0]["question_id"]


@pytest.mark.asyncio
async def test_attempt_telemetry_aliases_and_correct_answer(client, registered_student_id, question_id):
    # Fetch internal question to find correct answer
    q_res = await client.get(f"/api/v1/questions/{question_id}")
    assert q_res.status_code == 200

    # Submit using mobile telemetry aliases: submitted_answer, time_taken_seconds, answer_changes, confidence_level
    # First question correct answer is "B" (Instrument of Accession)
    payload = {
        "student_id": registered_student_id,
        "question_id": question_id,
        "submitted_answer": "B",
        "time_taken_seconds": 24.5,
        "answer_changes": 1,
        "confidence_level": 85.0,
    }

    res = await client.post("/api/v1/diagnostics/attempt", json=payload)
    assert res.status_code == 200
    data = res.json()

    assert data["is_correct"] is True
    assert data["status"] == "passed"
    assert data["selected_probe"] is None
    assert len(data["candidate_hypotheses"]) == 0
    assert "analysis_id" in data


@pytest.mark.asyncio
async def test_full_why_engine_diagnostic_loop_and_recovery(client, registered_student_id, question_id):
    # Step A: Submit wrong answer (e.g. "A") with telemetry aliases
    attempt_payload = {
        "student_id": registered_student_id,
        "question_id": question_id,
        "submitted_answer": "A",
        "time_taken_seconds": 15.0,
        "answer_changes": 0,
        "confidence_level": 90.0,
    }

    res_a = await client.post("/api/v1/diagnostics/attempt", json=attempt_payload)
    assert res_a.status_code == 200
    data_a = res_a.json()

    assert data_a["is_correct"] is False
    assert data_a["status"] == "probe_required"
    assert len(data_a["candidate_hypotheses"]) == 5
    assert data_a["selected_probe"] is not None
    probe_type = data_a["selected_probe"]["probe_type"]
    analysis_id = data_a["analysis_id"]

    # Step B: Submit probe response with probe telemetry alias
    probe_payload = {
        "analysis_id": analysis_id,
        "probe_type": probe_type,
        "probe_submitted_answer": "B",
        "probe_time_taken_sec": 18.0,
    }

    res_b = await client.post("/api/v1/diagnostics/probe-response", json=probe_payload)
    assert res_b.status_code == 200
    data_b = res_b.json()

    assert data_b["status"] == "diagnosis_confirmed"
    assert data_b["confidence_score"] >= 0.75
    assert data_b["confirmed_hypothesis"] is not None

    # Verify 3-Way Language Bridge drawer payload
    intervention = data_b["intervention"]
    assert intervention is not None
    # Bilingual Odia script + English terms
    assert re.search(r"[\u0B00-\u0B7F]", intervention["bilingual_explanation_odia_english"])
    # Pure Odia (no English words)
    assert not re.search(r"[A-Za-z]", intervention["pure_odia_explanation"])
    assert re.search(r"[\u0B00-\u0B7F]", intervention["pure_odia_explanation"])
    # Pure English
    assert len(intervention["pure_english_explanation"]) > 10
    # Grounded Reference
    assert intervention["grounded_textbook_reference"]["chapter_no"] is not None

    # Verify Recovery Practice Question strictly omits answer_key
    rec_q = data_b["recovery_practice_question"]
    assert rec_q is not None
    assert "answer_key" not in rec_q
    practice_id = rec_q["practice_id"]

    # Step C: Submit Recovery Practice Answer
    recovery_payload = {
        "analysis_id": analysis_id,
        "practice_id": practice_id,
        "selected_option": "C",  # First Five Year plan commenced in 1951 ("C")
    }

    res_c = await client.post("/api/v1/diagnostics/recovery", json=recovery_payload)
    assert res_c.status_code == 200
    data_c = res_c.json()

    assert data_c["is_correct"] is True
    assert data_c["has_student_improved"] is True
    assert "concept_understanding" in data_c["updated_scores"]
    assert "confidence_level" in data_c["updated_scores"]
    assert "overall_mastery" in data_c["updated_scores"]
    assert "recommended_next_task" in data_c
    rec_task = data_c["recommended_next_task"]
    assert rec_task["subject"] == "History"
    assert rec_task["chapter_name"] == "India After Independence"
    assert "task_type" in rec_task
    assert "reason" in rec_task
    assert rec_task["recommended_for"] == registered_student_id

    # Verify student document in db was updated with recommended_next_task
    st_res = await client.get(f"/api/v1/students/{registered_student_id}")
    assert st_res.status_code == 200
    st_data = st_res.json()
    assert st_data["recommended_next_task"] is not None
    assert st_data["recommended_next_task"]["subject"] == "History"


@pytest.mark.asyncio
async def test_language_explain_endpoint(client):
    payload = {
        "text": "Explain reflection of light and incident ray for Class 10 state board.",
        "subject": "Science",
        "chapter_name": "Light",
        "target_level": 2,
    }
    res = await client.post("/api/v1/language/explain", json=payload)
    assert res.status_code == 200
    data = res.json()

    assert "bilingual_explanation_odia_english" in data
    assert re.search(r"[\u0B00-\u0B7F]", data["bilingual_explanation_odia_english"])
    assert "pure_odia_explanation" in data
    assert not re.search(r"[A-Za-z]", data["pure_odia_explanation"])
    assert "pure_english_explanation" in data
    assert data["recorded_english_exposure_level"] == 2


@pytest.mark.asyncio
async def test_language_progress_endpoint(client, registered_student_id):
    # Initialize some progress
    prog_res = await client.post(
        f"/api/v1/students/{registered_student_id}/progress",
        json={
            "chapter_name": "Light",
            "concept_understanding": 70.0,
            "language_understanding": 60.0,
            "previous_performance_score": 65.0,
        },
    )
    assert prog_res.status_code == 200

    res = await client.get(f"/api/v1/language/progress/{registered_student_id}")
    assert res.status_code == 200
    data = res.json()

    assert data["student_id"] == registered_student_id
    assert data["english_exposure_level"] in [1, 2, 3, 4]
    assert data["mean_english_comprehension"] == 60.0
    assert data["total_chapters_tracked"] == 1
    assert "Level" in data["language_proficiency_band"]
