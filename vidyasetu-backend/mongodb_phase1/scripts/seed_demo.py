"""Smoke test / demo data.  Run:  cd backend && python -m scripts.seed_demo"""
import asyncio
import pprint

from app.database.init_db import init_db
from app.database.mongodb import close_client, get_db
from app.repositories import progress_repository as progress
from app.repositories import students_repository as students


async def main() -> None:
    db = get_db()
    try:
        await init_db(db)
        s = await students.create_student(
            db, name="Sunita", class_grade=9, subject="Science", preferred_language="Odia"
        )
        await progress.upsert_progress(
            db, s["_id"], "Force and Laws of Motion",
            {
                "concept_understanding": 45, "english_comprehension": 30,
                "prerequisite_understanding": 60, "time_management": 55,
                "confidence_level": 40, "previous_performance_score": 50,
            },
        )
        await students.set_recommended_next_task(
            db, s["_id"], subject="Science", chapter_name="Force and Laws of Motion",
            task_type="concept_repair", reason="English comprehension needs support",
        )
        pprint.pprint(await progress.get_student_with_progress(db, s["_id"]))
    finally:
        await close_client()


if __name__ == "__main__":
    asyncio.run(main())
