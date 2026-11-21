"""Tri-Lingual RAG Language Intelligence service using google-genai with offline fallback."""

import json
import logging
import re
from typing import Any, Dict, List, Optional
from google import genai
from google.genai import types
from app.core.config import settings
from app.schemas.diagnostic_schema import InterventionOutput, LanguageExplainResponse
from app.schemas.rag_schema import GroundedReference, KeyTermPair

logger = logging.getLogger(__name__)

SYSTEM_PROMPT = """You are VidyaSetu AI, an expert Odia-medium academic coach for Odisha state board students (BSE Odisha).
Your goal is to bridge the language divide for rural and Odia-medium students studying competitive science and state board syllabus.

STRICT RULES:
1. Always output authentic Odia Unicode Script (ଓଡ଼ିଆ ଲିପି) with English technical terms inline.
2. NEVER generate Romanised Odia (do NOT spell Odia words with English letters like 'Aloka pratiphalana'). Always use Odia script (e.g. 'ଆଲୋକ ପ୍ରତିଫଳନ (Reflection of Light)').
3. Ground the explanation strictly in the provided Odisha curriculum textbook context. NEVER fabricate facts or page numbers.
4. Output JSON strictly matching this schema:
{
  "bilingual_explanation_odia_english": "Clear explanation in Odia script with English technical terms inline",
  "pure_odia_explanation": "Pure Odia script explanation without English terms",
  "pure_english_explanation": "Formal standard English academic explanation",
  "english_terms_with_odia_meanings": [
    {"english_term": "...", "odia_meaning": "..."}
  ]
}
"""


def _clean_odia_text(raw_text: str) -> str:
    """Removes Latin characters from Odia text while preserving digits (e.g. 1951) and normalizing punctuation."""
    # Remove parentheticals containing English words (e.g. '(Reflection of Light)')
    cleaned = re.sub(r"\([A-Za-z\s,\-\./]+\)", "", raw_text)
    # Remove any stray remaining Latin characters
    cleaned = re.sub(r"[A-Za-z]+", "", cleaned)
    # Remove empty parentheses if left behind
    cleaned = re.sub(r"\(\s*\)", "", cleaned)
    # Clean space preceding punctuation marks and Odia danda
    cleaned = re.sub(r"\s+([,.:;?!|।\)])", r"\1", cleaned)
    # Normalize multiple whitespace
    cleaned = re.sub(r"\s+", " ", cleaned).strip()
    return cleaned


def _generate_fallback_intervention(
    chunk_text: str,
    important_english_terms: List[KeyTermPair],
    grounded_reference: GroundedReference,
    student_english_level: int,
    misconception: Optional[str] = None,
) -> InterventionOutput:
    """Deterministic, high-quality offline fallback synthesizing the 3-Way Language Bridge from MongoDB chunks."""
    sec_heading = grounded_reference.section_heading or "ମୁଖ୍ୟ ବିଷୟବସ୍ତୁ (Core Concept)"
    
    bilingual = (
        f"ଧାରଣା ବୁଝାମଣା ({sec_heading}):\n\n"
        f"{chunk_text}\n\n"
        f"ଶିକ୍ଷଣ ପରାମର୍ଶ (Learning Tip): ମନେରଖନ୍ତୁ, ପରୀକ୍ଷାରେ ଉଭୟ ଇଂରାଜୀ ବୈଷୟିକ ଶବ୍ଦ (English technical terms) "
        f"ଓ ଏହାର ଓଡ଼ିଆ ଅର୍ଥ ବୁଝିବା ନିହାତି ଜରୁରୀ।"
    )

    pure_odia = _clean_odia_text(chunk_text)
    if not pure_odia:
        pure_odia = "ଏହି ପାଠ୍ୟ ବିଷୟବସ୍ତୁର ମୂଳ ଧାରଣାକୁ ସଠିକ୍ ଭାବରେ ମନେରଖନ୍ତୁ ଏବଂ ଅଭ୍ୟାସ କରନ୍ତୁ।"

    terms_summary = ", ".join([f"{t.english_term} ({t.odia_meaning})" for t in important_english_terms[:4] if t.odia_meaning])
    pure_english = (
        f"According to {grounded_reference.textbook_name} (Chapter {grounded_reference.chapter_no}), "
        f"the topic '{sec_heading}' covers essential state curriculum concepts including {terms_summary or 'fundamental principles'}. "
        f"Mastering these definitions and laws ensures accurate exam recall."
    )

    return InterventionOutput(
        bilingual_explanation_odia_english=bilingual,
        pure_odia_explanation=pure_odia,
        pure_english_explanation=pure_english,
        english_terms_with_odia_meanings=important_english_terms,
        grounded_textbook_reference=grounded_reference,
        recorded_english_exposure_level=student_english_level,
    )


def generate_intervention(
    chunk_doc: Dict[str, Any],
    student_english_level: int = 1,
    misconception: Optional[str] = None,
    question_text: Optional[str] = None,
) -> InterventionOutput:
    """Generates the 3-Way Language Bridge intervention using Gemini API with deterministic offline fallback."""
    chunk_text = chunk_doc.get("chunk_text", "")
    terms_raw = chunk_doc.get("important_english_terms", [])
    terms = []
    for item in terms_raw:
        if isinstance(item, dict):
            terms.append(KeyTermPair(**item))
        elif isinstance(item, KeyTermPair):
            terms.append(item)

    ref_raw = chunk_doc.get("grounded_reference", {})
    if isinstance(ref_raw, dict):
        grounded_ref = GroundedReference(**ref_raw)
    elif isinstance(ref_raw, GroundedReference):
        grounded_ref = ref_raw
    else:
        grounded_ref = GroundedReference(textbook_name="BSE Odisha Science", chapter_no=1)

    # If Gemini API key is present, attempt live cloud generation
    if settings.GEMINI_API_KEY:
        try:
            client = genai.Client(api_key=settings.GEMINI_API_KEY)
            prompt = (
                f"Curriculum Textbook Chunk:\n{chunk_text}\n\n"
                f"Identified Student Misconception / Root Cause: {misconception or 'Conceptual gap'}\n"
                f"Question Context: {question_text or 'Class 10 State Syllabus Question'}\n"
                f"Student English Exposure Level (1=Bilingual, 4=Exam English): {student_english_level}\n\n"
                f"Generate the 3-way language bridge intervention strictly adhering to the JSON schema."
            )

            response = client.models.generate_content(
                model=settings.GEMINI_MODEL,
                contents=prompt,
                config=types.GenerateContentConfig(
                    system_instruction=SYSTEM_PROMPT,
                    response_mime_type="application/json",
                    temperature=0.2,
                ),
            )

            if response and response.text:
                data = json.loads(response.text)
                llm_terms = []
                for t in data.get("english_terms_with_odia_meanings", []):
                    if isinstance(t, dict) and t.get("english_term"):
                        llm_terms.append(KeyTermPair(
                            english_term=t.get("english_term", ""),
                            odia_meaning=t.get("odia_meaning", ""),
                        ))
                
                # Merge terms from LLM and chunk if needed
                merged_terms = llm_terms if llm_terms else terms

                return InterventionOutput(
                    bilingual_explanation_odia_english=data.get(
                        "bilingual_explanation_odia_english", chunk_text
                    ),
                    pure_odia_explanation=data.get(
                        "pure_odia_explanation", _clean_odia_text(chunk_text)
                    ),
                    pure_english_explanation=data.get(
                        "pure_english_explanation", "Explanation grounded in Odisha curriculum."
                    ),
                    english_terms_with_odia_meanings=merged_terms,
                    grounded_textbook_reference=grounded_ref,
                    recorded_english_exposure_level=student_english_level,
                )
        except Exception as exc:
            logger.warning("Gemini API call failed (%s); falling back to offline synthesizer.", exc)

    # Deterministic offline / demo fallback
    return _generate_fallback_intervention(
        chunk_text=chunk_text,
        important_english_terms=terms,
        grounded_reference=grounded_ref,
        student_english_level=student_english_level,
        misconception=misconception,
    )
