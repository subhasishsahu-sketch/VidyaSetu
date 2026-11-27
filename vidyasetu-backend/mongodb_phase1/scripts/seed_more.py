import asyncio
import uuid
from datetime import datetime, timezone

from app.database.mongodb import get_db, get_client

STUDENTS = [
    ("Ananya Das", 10, "Odia", "History"),
    ("Rohit Sahu", 10, "English", "History"),
    ("Priya Nayak", 12, "Odia", "Geography"),
    ("Sourav Behera", 10, "Odia", "Science"),
]

CHAPTERS = ["Resistance and Resilience", "Nationalism in India"]


async def main():
    db = get_db()
    now = datetime.now(timezone.utc)

    for i, (name, grade, lang, subject) in enumerate(STUDENTS):
        student_id = str(uuid.uuid4())

        await db.students.insert_one({
            "_id": student_id,
            "name": name,
            "class_grade": grade,
            "preferred_language": lang,
            "english_exposure_level": 1 + (i % 4),
            "subject": subject,
            "completed_chapters": i,
            "recommended_next_task": None,
            "created_at": now,
        })

        for j, chapter in enumerate(CHAPTERS):
            concept = 55.0 + i * 8 + j * 5
            english = 40.0 + i * 10 + j * 5
            await db.student_progress.insert_one({
                "_id": str(uuid.uuid4()),
                "student_id": student_id,
                "chapter_name": chapter,
                "concept_understanding": concept,
                "english_comprehension": english,
                "prerequisite_understanding": 70.0,
                "time_management": 60.0,
                "confidence_level": 50.0 + i * 5,
                "previous_performance_score": 65.0,
                "overall_mastery": round((concept + english + 70 + 60) / 4, 1),
                "last_updated": now,
            })

        print("Added:", name)

    await get_client().close()


asyncio.run(main())