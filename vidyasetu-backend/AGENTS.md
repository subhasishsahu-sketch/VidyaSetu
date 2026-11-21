# VidyaSetu Mobile-Ready Backend Guidelines

## Stack & Database
- Python 3.11+, FastAPI, Pydantic v2, LangGraph, Google Gemini API.
- Use MongoDB with PyMongo's native `AsyncMongoClient` (`from pymongo import AsyncMongoClient`). NEVER use Motor (deprecated) and NEVER use SQLAlchemy/PostgreSQL.
- Use ONLY the 5 canonical collections: `students`, `student_progress`, `questions`, `diagnostic_analysis`, `rag_textbook_vectors`.

## Mobile & Offline Sync Contracts
- Use lowercase UUID v4 strings for all IDs (`_id`, `student_id`, `question_id`, `analysis_id`) so on-device SQLite/IndexedDB mirrors match MongoDB 1:1.
- Store UTC timestamps; keep `offline_created_at` separate from server `created_at`.
- Deduplicate offline sync events with a unique index on `analysis_id` and `$setOnInsert` upserts.
- Never return `correct_answer` or recovery `answer_key` in student-facing question routes.

## Language & Grounding
- Output Odia Unicode Script (`ଓଡ଼ିଆ ଲିପି`) with English technical terms inline. NEVER generate Romanised Odia.
- Always attach `grounded_reference` (`textbook_name`, `chapter_no`, `page_no`, `paragraph_no`) deterministically from `rag_textbook_vectors`—never let the LLM invent citations.

## Workflow Discipline
- Build ONLY the phase requested in the current prompt.
- Run pytest / startup verification before finishing each phase.