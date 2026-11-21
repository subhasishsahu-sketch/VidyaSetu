import pytest
from app.database.collections import (
    COLLECTION_QUESTIONS,
    COLLECTION_RAG_TEXTBOOK_VECTORS,
)
from app.database.seed import seed_database
from tests.test_students_api import InMemoryAsyncDatabase


@pytest.mark.asyncio
async def test_seed_database_idempotency_and_metadata():
    db = InMemoryAsyncDatabase()

    # First seed run
    res1 = await seed_database(db)
    assert res1["chunks"] == 61
    assert res1["questions"] == 5

    rag_col = db[COLLECTION_RAG_TEXTBOOK_VECTORS]
    q_col = db[COLLECTION_QUESTIONS]

    assert len(rag_col.docs) == 61
    assert len(q_col.docs) == 5

    # Second seed run (must be strictly idempotent)
    res2 = await seed_database(db)
    assert res2["chunks"] == 61
    assert res2["questions"] == 5

    # Document counts must remain identical (no duplication!)
    assert len(rag_col.docs) == 61
    assert len(q_col.docs) == 5

    # Verify all 61 chunks have 768-dim embeddings preserved
    for chunk in rag_col.docs:
        assert chunk["embedding_dim"] == 768
        assert len(chunk["embedding"]) == 768
        assert chunk["embedding_model"] == "intfloat/multilingual-e5-base"
        ref = chunk["grounded_reference"]
        assert "textbook_name" in ref
        assert "chapter_no" in ref
        assert "section_heading" in ref

        # Verify important_english_terms formatting and authentic Odia script
        terms = chunk.get("important_english_terms", [])
        assert isinstance(terms, list)
        for term_pair in terms:
            assert "english_term" in term_pair
            assert "odia_meaning" in term_pair
            odia_val = term_pair["odia_meaning"]
            if odia_val:
                # Must contain Odia Unicode script (\u0B00-\u0B7F) and never Romanised Odia
                import re
                assert bool(re.search(r"[\u0B00-\u0B7F]", odia_val)), f"Invalid Odia script in term: {term_pair}"

    # Verify specific technical terms have correct Odia meanings mapped
    all_mapped_pairs = {
        tp["english_term"].lower(): tp["odia_meaning"]
        for chunk in rag_col.docs
        for tp in chunk.get("important_english_terms", [])
    }
    assert all_mapped_pairs.get("planning commission") == "ଯୋଜନା ଆୟୋଗ"
    assert all_mapped_pairs.get("instrument of accession") == "ମିଶ୍ରଣ ଚୁକ୍ତିପତ୍ର"
    assert all_mapped_pairs.get("concave mirror") == "ଅବତଳ ଦର୍ପଣ"
    assert all_mapped_pairs.get("oasis") == "ମରୁଦ୍ଦ୍ୟାନ"

    # Verify all 5 seeded questions use exact subject and chapter_name strings
    allowed_chapters = {
        ("History", "India After Independence"),
        ("Science", "Light"),
        ("Geography", "Water Resources"),
    }
    for q in q_col.docs:
        pair = (q["subject"], q["chapter_name"])
        assert pair in allowed_chapters
        assert len(q["options"]) == 4
        assert q["correct_answer"] in ["A", "B", "C", "D"]
        assert len(q["diagnostic_probes"]) == 5
