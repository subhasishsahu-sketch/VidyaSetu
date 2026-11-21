import pytest
from pydantic import ValidationError
from app.repositories.rag_repository import (
    compute_cosine_similarity,
    retrieve_top_k_chunks,
    upsert_rag_chunk,
)
from app.schemas.rag_schema import (
    GroundedReference,
    KeyTermPair,
    RagTextbookVector,
)
from tests.test_students_api import InMemoryAsyncDatabase


def test_rag_schema_validation_768_and_384():
    # 1. 768-dim vector
    vec768 = [0.1] * 768
    item768 = RagTextbookVector(
        chunk_id="chunk-test-768",
        subject="History",
        chapter_name="India After Independence",
        chunk_text="Test paragraph",
        embedding=vec768,
        embedding_model="intfloat/multilingual-e5-base",
        embedding_dim=768,
        grounded_reference=GroundedReference(
            textbook_name="BSE Odisha History",
            chapter_no=1,
            section_heading="Introduction",
            page_no=None,
            paragraph_no=1,
        ),
        important_english_terms=[KeyTermPair(english_term="Planning Commission", odia_meaning="ଯୋଜନା ଆୟୋଗ")],
    )
    assert item768.embedding_dim == 768
    assert len(item768.embedding) == 768

    # 2. 384-dim vector
    vec384 = [0.2] * 384
    item384 = RagTextbookVector(
        chunk_id="chunk-test-384",
        subject="Science",
        chapter_name="Light",
        chunk_text="Light reflection paragraph",
        embedding=vec384,
        embedding_model="intfloat/multilingual-e5-small",
        embedding_dim=384,
        grounded_reference=GroundedReference(
            textbook_name="BSE Odisha Science",
            chapter_no=1,
            section_heading="Spherical Mirrors",
        ),
    )
    assert item384.embedding_dim == 384

    # 3. Dimension mismatch raises error
    with pytest.raises(ValidationError):
        RagTextbookVector(
            chunk_id="invalid-dim",
            subject="History",
            chapter_name="Test",
            chunk_text="Mismatch",
            embedding=[0.1] * 100,  # 100 floats but embedding_dim=768
            embedding_dim=768,
            grounded_reference=GroundedReference(textbook_name="Test", chapter_no=1),
        )


def test_compute_cosine_similarity():
    # Identical vectors
    v1 = [1.0, 0.0, 1.0]
    assert compute_cosine_similarity(v1, v1) == pytest.approx(1.0)

    # Orthogonal vectors
    v2 = [0.0, 1.0, 0.0]
    v3 = [1.0, 0.0, 0.0]
    assert compute_cosine_similarity(v2, v3) == 0.0

    # Negative / opposite vectors
    v4 = [1.0, 2.0]
    v5 = [-1.0, -2.0]
    assert round(compute_cosine_similarity(v4, v5), 4) == -1.0


@pytest.mark.asyncio
async def test_retrieve_top_k_chunks():
    db = InMemoryAsyncDatabase()

    # Insert two chunks in same chapter
    c1 = {
        "_id": "chunk-1",
        "chunk_id": "chunk-1",
        "subject": "History",
        "chapter_name": "India After Independence",
        "chunk_text": "Chunk about Five Year Plans",
        "embedding": [1.0, 0.0, 0.0, 0.0],
        "grounded_reference": {
            "textbook_name": "BSE Odisha History",
            "chapter_no": 1,
            "section_heading": "Economy",
            "page_no": 58,
            "paragraph_no": 2,
        },
    }
    c2 = {
        "_id": "chunk-2",
        "chunk_id": "chunk-2",
        "subject": "History",
        "chapter_name": "India After Independence",
        "chunk_text": "Chunk about princely states",
        "embedding": [0.0, 1.0, 0.0, 0.0],
        "grounded_reference": {
            "textbook_name": "BSE Odisha History",
            "chapter_no": 1,
            "section_heading": "Princely States",
            "page_no": 45,
            "paragraph_no": 1,
        },
    }
    await upsert_rag_chunk(db, c1)
    await upsert_rag_chunk(db, c2)

    # Query vector close to c1 [0.9, 0.1, 0.0, 0.0]
    query_vec = [0.9, 0.1, 0.0, 0.0]
    top_chunks = await retrieve_top_k_chunks(
        db, query_vec, subject="History", chapter_name="India After Independence", k=2
    )
    assert len(top_chunks) == 2
    # c1 must be ranked first
    assert top_chunks[0]["chunk_id"] == "chunk-1"
    assert top_chunks[0]["similarity_score"] > top_chunks[1]["similarity_score"]
    # Citation is intact
    assert top_chunks[0]["grounded_reference"]["section_heading"] == "Economy"
    assert top_chunks[0]["grounded_reference"]["page_no"] == 58
