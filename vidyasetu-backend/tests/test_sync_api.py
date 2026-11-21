"""Automated tests for Mobile Offline Packs and Idempotent Offline Batch Synchronization."""

import uuid
from datetime import datetime, timezone
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
            "name": "Priyanka Jena",
            "class_grade": 10,
            "preferred_language": "Odia",
            "english_exposure_level": 1,
            "subject": "History",
        },
    )
    assert res.status_code == 201
    return res.json()["student_id"]


@pytest.fixture
async def history_question(client):
    res = await client.get("/api/v1/questions?subject=History")
    assert res.status_code == 200
    questions = res.json()
    assert len(questions) > 0
    return questions[0]


@pytest.mark.asyncio
async def test_offline_pack_download_success(client):
    # Test downloading offline pack for Science / Light
    req_payload = {
        "subject": "Science  ",
        "chapter_name": "  Light ",
    }
    res = await client.post("/api/v1/offline-packs", json=req_payload)
    assert res.status_code == 200
    data = res.json()

    assert data["subject"] == "Science"
    assert data["chapter_name"] == "Light"
    assert "pack_id" in data
    assert "cached_at" in data

    # 1. Questions must include full 5 diagnostic probes and recovery questions
    cached_q = data["cached_questions"]
    assert len(cached_q) > 0
    q = cached_q[0]
    assert "diagnostic_probes" in q
    assert "language_probe" in q["diagnostic_probes"]
    assert "recovery_practice_questions" in q

    # 2. Local RAG vectors must contain 768-dim embeddings and grounded reference
    local_vectors = data["local_rag_vectors"]
    assert len(local_vectors) > 0
    vec = local_vectors[0]
    assert len(vec["embedding"]) == 768
    assert vec["embedding_dim"] == 768
    assert "grounded_reference" in vec
    assert vec["grounded_reference"]["chapter_no"] is not None


@pytest.mark.asyncio
async def test_offline_pack_404_when_subject_chapter_not_found(client):
    res = await client.post(
        "/api/v1/offline-packs",
        json={"subject": "NonExistent", "chapter_name": "UnknownChapter"},
    )
    assert res.status_code == 404
    assert "No curriculum content found" in res.json()["detail"]


@pytest.mark.asyncio
async def test_offline_sync_batch_idempotency_and_cause_specific_boost(
    client, registered_student_id, history_question
):
    analysis_id = str(uuid.uuid4()).lower()
    now_iso = datetime.now(timezone.utc).isoformat()

    event = {
        "analysis_id": analysis_id,
        "student_id": registered_student_id,
        "question_id": history_question["question_id"],
        "attempt_data": {
            "selected_option": "A",
            "time_taken_sec": 45.0,
            "answer_changes_count": 0,
            "confidence_rating": 80.0,
            "is_correct": False,
        },
        "probe_loop_evidence": [
            {
                "probe_type": "language_probe",
                "submitted_answer": "B",
                "time_taken_sec": 15.0,
                "is_correct": True,
                "confidence_score": 0.88,
            }
        ],
        "student_parameters_snapshot": {
            "time_taken": "Normal",
            "confidence_level": "High",
            "answer_changes": "None",
            "language_preference": "Odia",
            "concept_understanding": "Weak",
            "previous_performance": "Strong",
            "english_comprehension": "Weak",
        },
        "intervention_and_language_output": {
            "misconception": "language_barrier",
            "bilingual_explanation_odia_english": "ବିସ୍ତୃତ ବୁଝାମଣା",
            "pure_odia_explanation": "ଶୁଦ୍ଧ ଓଡ଼ିଆ ବୁଝାମଣା",
            "pure_english_explanation": "Pure English explanation",
        },
        "recovery_assessment": {
            "practice_id": "REC-HIST-01",
            "submitted_answer": "C",
            "is_correct": True,
            "has_student_improved": True,
        },
        "execution_source": "edge_slm_offline_sync",
        "offline_created_at": now_iso,
    }

    batch_payload = {
        "student_id": registered_student_id,
        "batch_timestamp": now_iso,
        "events": [event],
    }

    # 1. First sync call: event must be in synced_ids
    res_1 = await client.post("/api/v1/sync/offline-analysis", json=batch_payload)
    assert res_1.status_code == 200
    data_1 = res_1.json()
    assert analysis_id in data_1["synced_ids"]
    assert data_1["duplicate_ids"] == []
    assert data_1["failed_events"] == []

    # Verify student progress was updated with cause-specific boost for language_barrier (english_comprehension)
    prog_res = await client.get(
        f"/api/v1/students/{registered_student_id}/progress/{history_question['chapter_name']}"
    )
    assert prog_res.status_code == 200
    prog_data = prog_res.json()
    # Baseline was 50.0; language_barrier boost adds +8.0 -> 58.0
    assert prog_data["english_comprehension"] == 58.0
    # Confidence level baseline was 50.0; boost adds +5.0 -> 55.0
    assert prog_data["confidence_level"] == 55.0
    first_mastery = prog_data["overall_mastery"]

    # Verify student profile recommended_next_task was updated with structured planner dict
    st_res = await client.get(f"/api/v1/students/{registered_student_id}")
    assert st_res.status_code == 200
    rec_task = st_res.json()["recommended_next_task"]
    assert rec_task is not None
    assert rec_task["subject"] == history_question["subject"]
    assert rec_task["chapter_name"] == history_question["chapter_name"]
    assert rec_task["recommended_for"] == registered_student_id

    # 2. Second sync call with exact same batch: must be recognized as DUPLICATE and NOT boost again
    res_2 = await client.post("/api/v1/sync/offline-analysis", json=batch_payload)
    assert res_2.status_code == 200
    data_2 = res_2.json()
    assert analysis_id in data_2["duplicate_ids"]
    assert data_2["synced_ids"] == []
    assert data_2["failed_events"] == []

    # Verify progress was NOT boosted a second time
    prog_res_2 = await client.get(
        f"/api/v1/students/{registered_student_id}/progress/{history_question['chapter_name']}"
    )
    assert prog_res_2.status_code == 200
    assert prog_res_2.json()["overall_mastery"] == first_mastery
    assert prog_res_2.json()["english_comprehension"] == 58.0


@pytest.mark.asyncio
async def test_offline_sync_batch_partial_failure(
    client, registered_student_id, history_question
):
    valid_id = str(uuid.uuid4()).lower()
    invalid_q_id = str(uuid.uuid4()).lower()
    bad_event_id = str(uuid.uuid4()).lower()
    now_iso = datetime.now(timezone.utc).isoformat()

    valid_event = {
        "analysis_id": valid_id,
        "student_id": registered_student_id,
        "question_id": history_question["question_id"],
        "attempt_data": {"selected_option": "B", "is_correct": True},
        "execution_source": "edge_slm_offline_sync",
        "offline_created_at": now_iso,
    }

    invalid_event = {
        "analysis_id": bad_event_id,
        "student_id": registered_student_id,
        "question_id": invalid_q_id,  # Non-existent question
        "attempt_data": {"selected_option": "A", "is_correct": False},
        "execution_source": "edge_slm_offline_sync",
        "offline_created_at": now_iso,
    }

    batch_payload = {
        "student_id": registered_student_id,
        "batch_timestamp": now_iso,
        "events": [invalid_event, valid_event],
    }

    res = await client.post("/api/v1/sync/offline-analysis", json=batch_payload)
    assert res.status_code == 200
    data = res.json()

    # Valid event is acknowledged
    assert valid_id in data["synced_ids"]

    # Invalid event is isolated in failed_events without aborting the batch
    assert len(data["failed_events"]) == 1
    assert data["failed_events"][0]["analysis_id"] == bad_event_id
    assert "not found" in data["failed_events"][0]["reason"]


@pytest.mark.asyncio
async def test_offline_sync_student_not_found_404(client, history_question):
    fake_student_id = str(uuid.uuid4()).lower()
    batch_payload = {
        "student_id": fake_student_id,
        "batch_timestamp": datetime.now(timezone.utc).isoformat(),
        "events": [],
    }
    res = await client.post("/api/v1/sync/offline-analysis", json=batch_payload)
    assert res.status_code == 404
    assert f"Student {fake_student_id} not found" in res.json()["detail"]
