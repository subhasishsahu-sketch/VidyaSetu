"""Tests for Tri-Lingual RAG Language Intelligence service."""

import re
from app.schemas.rag_schema import GroundedReference, KeyTermPair
from app.services.language_service import _clean_odia_text, generate_intervention


def test_clean_odia_text_strips_english_terms():
    sample = "ଆଲୋକର ପ୍ରତିଫଳନ (Reflection of Light) ନିୟମ ଅନୁସାରେ ଆପତନ କୋଣ ସର୍ବଦା ପ୍ରତିଫଳନ କୋଣ ସହ ସମାନ।"
    cleaned = _clean_odia_text(sample)
    # Check that no ASCII letters remain in pure Odia text
    assert not re.search(r"[A-Za-z]", cleaned)
    # Check that Odia characters are preserved
    assert re.search(r"[\u0B00-\u0B7F]", cleaned)


def test_clean_odia_text_preserves_digits_and_normalizes_punctuation():
    sample = "୧୯୫୧ (1951) ମସିହାରେ ପ୍ରଥମ ପଞ୍ଚବାର୍ଷିକ ଯୋଜନା (First Five Year Plan) ଆରମ୍ଭ ହୋଇଥିଲା।"
    cleaned = _clean_odia_text(sample)
    assert "1951" in cleaned
    assert "୧୯୫୧" in cleaned
    assert not re.search(r"[A-Za-z]", cleaned)
    assert "First" not in cleaned
    assert "Plan" not in cleaned


def test_generate_intervention_offline_fallback():
    chunk_doc = {
        "chunk_text": "ଆଲୋକର ପ୍ରତିଫଳନ (Reflection of Light) ନିୟମ ଅନୁସାରେ ଆପତନ କୋଣ ଏବଂ ପ୍ରତିଫଳନ କୋଣ ପରସ୍ପର ସମାନ।",
        "important_english_terms": [
            {"english_term": "Reflection of Light", "odia_meaning": "ଆଲୋକର ପ୍ରତିଫଳନ"},
            {"english_term": "Angle of Incidence", "odia_meaning": "ଆପତନ କୋଣ"},
        ],
        "grounded_reference": {
            "textbook_name": "ଭୌତିକ ବିଜ୍ଞାନ (Physical Science) Class 10",
            "chapter_no": 10,
            "section_heading": "ଆଲୋକର ପ୍ରତିଫଳନ (Reflection of Light)",
            "page_no": 161,
            "paragraph_no": 2,
        },
    }

    intervention = generate_intervention(
        chunk_doc=chunk_doc,
        student_english_level=2,
        misconception="language_barrier",
        question_text="What is the relation between angle of incidence and reflection?",
    )

    # 1. Bilingual contains Odia script AND English technical terms
    assert re.search(r"[\u0B00-\u0B7F]", intervention.bilingual_explanation_odia_english)
    assert "Reflection of Light" in intervention.bilingual_explanation_odia_english

    # 2. Pure Odia contains NO English alphabet characters
    assert not re.search(r"[A-Za-z]", intervention.pure_odia_explanation)
    assert re.search(r"[\u0B00-\u0B7F]", intervention.pure_odia_explanation)

    # 3. Pure English contains valid explanation
    assert len(intervention.pure_english_explanation) > 20
    assert "Physical Science" in intervention.pure_english_explanation or "Chapter 10" in intervention.pure_english_explanation

    # 4. Grounded reference matches accurately
    assert intervention.grounded_textbook_reference.chapter_no == 10
    assert intervention.grounded_textbook_reference.page_no == 161

    # 5. English terms with Odia meanings
    assert len(intervention.english_terms_with_odia_meanings) >= 2
    assert intervention.english_terms_with_odia_meanings[0].english_term == "Reflection of Light"
    assert intervention.english_terms_with_odia_meanings[0].odia_meaning == "ଆଲୋକର ପ୍ରତିଫଳନ"
