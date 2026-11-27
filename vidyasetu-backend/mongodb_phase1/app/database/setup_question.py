import asyncio

from app.database.mongodb import get_db, get_client
from app.validators.question_validators import QUESTION_VALIDATORS


async def setup_questions(db=None):
    db = db if db is not None else get_db()
    existing = await db.list_collection_names()

    if "questions" not in existing:
        await db.create_collection("questions", validator=QUESTION_VALIDATORS)
    else:
        await db.command("collMod", "questions", validator=QUESTION_VALIDATORS)

    await db["questions"].create_index(
        [("subject", 1), ("chapter_name", 1), ("concept_name", 1)]
    )
    print("questions collection, validator and index are ready.")


async def main():
    await setup_questions()
    await get_client().close()


if __name__ == "__main__":
    asyncio.run(main())