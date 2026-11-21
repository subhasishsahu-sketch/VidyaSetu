import pytest
from httpx import ASGITransport, AsyncClient
from app.database.mongodb import get_database
from app.database.seed import seed_database
from app.main import app
from app.repositories.questions_repository import get_question_internal
from tests.test_students_api import InMemoryAsyncDatabase


@pytest.fixture
def seeded_db():
    db = InMemoryAsyncDatabase()
    return db


@pytest.fixture
async def seeded_client(seeded_db):
    # Seed the questions into the in-memory db
    await seed_database(seeded_db)
    app.dependency_overrides[get_database] = lambda: seeded_db
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        yield c
    app.dependency_overrides.clear()


@pytest.mark.asyncio
async def test_questions_list_never_leaks_answers(seeded_client):
    response = await seeded_client.get("/api/v1/questions")
    assert response.status_code == 200
    questions = response.json()
    assert len(questions) == 5

    for q in questions:
        # 1. Zero answer leakage on top-level
        assert "correct_answer" not in q
        assert "correctAnswer" not in q

        # 2. All 5 canonical diagnostic probe branches must exist
        probes = q["diagnostic_probes"]
        assert "language_probe" in probes
        assert "untimed_retry" in probes
        assert "prerequisite_probe" in probes
        assert "transfer_probe" in probes
        assert "explain_back" in probes

        # 3. Language probe must have Odia Script prompt
        lang_probe = probes["language_probe"]
        assert "prompt_odia" in lang_probe

        # 4. Zero answer leakage in recovery questions
        recovery = q.get("recovery_practice_questions", [])
        for rec in recovery:
            assert "answer_key" not in rec
            assert "answerKey" not in rec
            assert "correct_answer" not in rec


@pytest.mark.asyncio
async def test_questions_filtering_by_subject_and_chapter(seeded_client):
    # Filter by History / India After Independence
    res_hist = await seeded_client.get(
        "/api/v1/questions?subject=History&chapter_name=India%20After%20Independence"
    )
    assert res_hist.status_code == 200
    hist_q = res_hist.json()
    assert len(hist_q) == 2
    for q in hist_q:
        assert q["subject"] == "History"
        assert q["chapter_name"] == "India After Independence"

    # Filter by Science
    res_sci = await seeded_client.get("/api/v1/questions?subject=Science")
    assert res_sci.status_code == 200
    sci_q = res_sci.json()
    assert len(sci_q) == 2
    for q in sci_q:
        assert q["subject"] == "Science"

    # Filter by non-existent chapter
    res_empty = await seeded_client.get("/api/v1/questions?chapter_name=NonExistent")
    assert res_empty.status_code == 200
    assert len(res_empty.json()) == 0


@pytest.mark.asyncio
async def test_single_question_by_id_and_404(seeded_client, seeded_db):
    # Get all questions
    res = await seeded_client.get("/api/v1/questions")
    first_q = res.json()[0]
    qid = first_q["question_id"]

    # Public fetch by ID
    single_res = await seeded_client.get(f"/api/v1/questions/{qid}")
    assert single_res.status_code == 200
    single_data = single_res.json()
    assert single_data["question_id"] == qid
    assert "correct_answer" not in single_data

    # 404 for unknown question
    missing = await seeded_client.get("/api/v1/questions/non-existent-uuid")
    assert missing.status_code == 404

    # Backend-only internal getter retains answers for grading
    internal_doc = await get_question_internal(seeded_db, qid)
    assert internal_doc is not None
    assert "correct_answer" in internal_doc
    assert internal_doc["correct_answer"] in ["A", "B", "C", "D"]
    assert internal_doc["recovery_practice_questions"][0]["answer_key"] is not None
