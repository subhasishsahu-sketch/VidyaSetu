import copy
import uuid
from datetime import datetime, timezone
import pytest
from httpx import ASGITransport, AsyncClient
from app.database.mongodb import get_database
from app.main import app


class InMemoryAsyncCollection:
    def __init__(self, name: str):
        self.name = name
        self.docs = []

    def _apply_projection(self, doc, projection):
        if not projection:
            return copy.deepcopy(doc)
        res = copy.deepcopy(doc)
        for k, v in projection.items():
            if v == 0:
                if "." in k:
                    parent, child = k.split(".", 1)
                    if parent in res and isinstance(res[parent], list):
                        for item in res[parent]:
                            if isinstance(item, dict):
                                item.pop(child, None)
                else:
                    res.pop(k, None)
        return res

    async def insert_one(self, doc):
        self.docs.append(copy.deepcopy(doc))
        return type("InsertResult", (), {"inserted_id": doc["_id"]})()

    async def find_one(self, filter_dict, projection=None):
        for doc in self.docs:
            match = True
            for k, v in filter_dict.items():
                if doc.get(k) != v:
                    match = False
                    break
            if match:
                return self._apply_projection(doc, projection)
        return None

    def find(self, filter_dict, projection=None):
        matched = []
        for doc in self.docs:
            match = True
            for k, v in filter_dict.items():
                if doc.get(k) != v:
                    match = False
                    break
            if match:
                matched.append(self._apply_projection(doc, projection))

        class Cursor:
            def __init__(self, items):
                self.items = items

            def sort(self, key, direction):
                self.items.sort(
                    key=lambda x: x.get(key, 0), reverse=(direction == -1)
                )
                return self

            async def to_list(self, length=None):
                return copy.deepcopy(self.items)

        return Cursor(matched)

    async def update_one(self, filter_dict, update_dict, upsert=False):
        for doc in self.docs:
            match = True
            for k, v in filter_dict.items():
                if doc.get(k) != v:
                    match = False
                    break
            if match:
                if "$set" in update_dict:
                    doc.update(copy.deepcopy(update_dict["$set"]))
                return type("UpdateResult", (), {"matched_count": 1, "modified_count": 1})()
        if upsert:
            new_doc = copy.deepcopy(filter_dict)
            if "$setOnInsert" in update_dict:
                new_doc.update(copy.deepcopy(update_dict["$setOnInsert"]))
            if "$set" in update_dict:
                new_doc.update(copy.deepcopy(update_dict["$set"]))
            self.docs.append(new_doc)
            return type("UpdateResult", (), {"matched_count": 0, "upserted_id": new_doc.get("_id")})()
        return type("UpdateResult", (), {"matched_count": 0, "modified_count": 0})()

    async def find_one_and_update(self, filter_dict, update_dict, upsert=False, return_document=None):
        for doc in self.docs:
            match = True
            for k, v in filter_dict.items():
                if doc.get(k) != v:
                    match = False
                    break
            if match:
                if "$push" in update_dict:
                    for field, item in update_dict["$push"].items():
                        if field not in doc or not isinstance(doc[field], list):
                            doc[field] = []
                        doc[field].append(copy.deepcopy(item))
                if "$set" in update_dict:
                    doc.update(copy.deepcopy(update_dict["$set"]))
                return copy.deepcopy(doc)

        if upsert:
            new_doc = copy.deepcopy(filter_dict)
            if "$setOnInsert" in update_dict:
                new_doc.update(copy.deepcopy(update_dict["$setOnInsert"]))
            if "$set" in update_dict:
                new_doc.update(copy.deepcopy(update_dict["$set"]))
            self.docs.append(new_doc)
            return copy.deepcopy(new_doc)
        return None


class InMemoryAsyncDatabase:
    def __init__(self):
        self.collections = {}

    def __getitem__(self, name: str):
        if name not in self.collections:
            self.collections[name] = InMemoryAsyncCollection(name)
        return self.collections[name]


@pytest.fixture
def mock_db():
    return InMemoryAsyncDatabase()


@pytest.fixture
async def client(mock_db):
    app.dependency_overrides[get_database] = lambda: mock_db
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        yield c
    app.dependency_overrides.clear()


@pytest.mark.asyncio
async def test_register_student_success(client):
    payload = {
        "name": "Suhani Sahu",
        "class": 10,  # Tests alias "class" -> "class_grade"
        "preferred_language": "Odia",
        "subject": "History",
    }
    response = await client.post("/api/v1/students", json=payload)
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Suhani Sahu"
    assert data["class_grade"] == 10
    assert data["preferred_language"] == "Odia"
    assert data["english_exposure_level"] == 1
    assert data["completed_chapters"] == 0
    assert "student_id" in data
    # Validate UUID v4 format
    student_uuid = uuid.UUID(data["student_id"])
    assert student_uuid.version == 4


@pytest.mark.asyncio
async def test_register_student_pydantic_422_errors(client):
    # 1. Invalid class grade (must be 6-12)
    res1 = await client.post("/api/v1/students", json={"name": "A", "class": 4, "subject": "Math"})
    assert res1.status_code == 422

    # 2. Name too short (< 2 chars)
    res2 = await client.post("/api/v1/students", json={"name": "A", "class": 10, "subject": "Math"})
    assert res2.status_code == 422

    # 3. Invalid preferred language
    res3 = await client.post(
        "/api/v1/students",
        json={"name": "Valid Name", "class": 10, "preferred_language": "Hindi", "subject": "Math"},
    )
    assert res3.status_code == 422


@pytest.mark.asyncio
async def test_get_student_by_id(client):
    # Register student
    reg = await client.post(
        "/api/v1/students",
        json={"name": "Rohan Das", "class_grade": 9, "subject": "Science"},
    )
    student_id = reg.json()["student_id"]

    # Get student
    get_res = await client.get(f"/api/v1/students/{student_id}")
    assert get_res.status_code == 200
    assert get_res.json()["name"] == "Rohan Das"

    # 404 for unknown
    missing = await client.get("/api/v1/students/00000000-0000-0000-0000-000000000000")
    assert missing.status_code == 404


@pytest.mark.asyncio
async def test_progress_upsert_and_mastery_calculation(client):
    # Register student
    reg = await client.post(
        "/api/v1/students",
        json={"name": "Priya Mohanty", "class": 10, "subject": "History"},
    )
    student_id = reg.json()["student_id"]

    # Post progress using mobile aliases
    progress_payload = {
        "chapter_name": "  Planning Commission & Five Year Plans  ",  # tests whitespace stripping
        "concept_understanding": 80.0,
        "language_understanding": 60.0,  # Alias for english_comprehension
        "prerequisite_understanding": 70.0,
        "time_management": 65.0,
        "confidence_level": 70.0,
        "accuracy": 75.0,  # Alias for previous_performance_score
    }
    # Expected overall_mastery:
    # 0.30*80 (24.0) + 0.20*75 (15.0) + 0.15*70 (10.5) + 0.15*60 (9.0) + 0.10*65 (6.5) + 0.10*70 (7.0)
    # = 24.0 + 15.0 + 10.5 + 9.0 + 6.5 + 7.0 = 72.0
    res = await client.post(f"/api/v1/students/{student_id}/progress", json=progress_payload)
    assert res.status_code == 200
    prog_data = res.json()
    assert prog_data["chapter_name"] == "Planning Commission & Five Year Plans"
    assert prog_data["overall_mastery"] == 72.0
    assert prog_data["english_comprehension"] == 60.0
    # Must expose language_understanding for mobile chart widget
    assert prog_data["language_understanding"] == 60.0

    # Retrieve single chapter progress (also test path parameter whitespace strip)
    single_res = await client.get(
        f"/api/v1/students/{student_id}/progress/  Planning Commission & Five Year Plans  "
    )
    assert single_res.status_code == 200
    assert single_res.json()["overall_mastery"] == 72.0

    # Student completed_chapters should still be 0 (72.0 < 75.0)
    s_res = await client.get(f"/api/v1/students/{student_id}")
    assert s_res.json()["completed_chapters"] == 0
    # english_exposure_level for 60.0 is Level 2 (<= 65.0)
    assert s_res.json()["english_exposure_level"] == 2

    # Now update progress for another chapter with >= 75.0 mastery
    high_prog = {
        "chapter_name": "Chapter 2: Industrial Growth",
        "concept_understanding": 90.0,
        "english_comprehension": 85.0,
        "prerequisite_understanding": 85.0,
        "time_management": 80.0,
        "confidence_level": 80.0,
        "previous_performance_score": 85.0,
    }
    # 0.30*90 (27.0) + 0.20*85 (17.0) + 0.15*85 (12.75) + 0.15*85 (12.75) + 0.10*80 (8.0) + 0.10*80 (8.0)
    # = 27 + 17 + 12.75 + 12.75 + 8 + 8 = 85.5
    res2 = await client.post(f"/api/v1/students/{student_id}/progress", json=high_prog)
    assert res2.status_code == 200
    assert res2.json()["overall_mastery"] == 85.5

    # Check student aggregate sync: completed_chapters must now be 1!
    s_res2 = await client.get(f"/api/v1/students/{student_id}")
    s_data2 = s_res2.json()
    assert s_data2["completed_chapters"] == 1
    # Mean english: (60.0 + 85.0) / 2 = 72.5 -> Level 3 (<= 82.0)
    assert s_data2["english_exposure_level"] == 3


@pytest.mark.asyncio
async def test_progress_list_and_404s(client):
    # Non-existent student checks
    non_student = "00000000-0000-0000-0000-000000000000"
    res1 = await client.get(f"/api/v1/students/{non_student}/progress")
    assert res1.status_code == 404

    res2 = await client.post(f"/api/v1/students/{non_student}/progress", json={"chapter_name": "Ch 1"})
    assert res2.status_code == 404

    res3 = await client.get(f"/api/v1/students/{non_student}/progress/Ch 1")
    assert res3.status_code == 404

    # Register student
    reg = await client.post(
        "/api/v1/students",
        json={"name": "Test Student", "class": 8, "subject": "Geography"},
    )
    s_id = reg.json()["student_id"]

    # Query chapter not yet recorded
    res4 = await client.get(f"/api/v1/students/{s_id}/progress/NonExistentChapter")
    assert res4.status_code == 404
