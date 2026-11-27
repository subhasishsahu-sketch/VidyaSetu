import asyncio

from app.database.mongodb import get_db, get_client
from app.validators.diagnostic_validators import DIAGNOSTIC_VALIDATOR


async def setup_diagnostic(db=None):
    db = db if db is not None else get_db()
    existing = await db.list_collection_names()

    if "diagnostic_analysis" not in existing:
        await db.create_collection("diagnostic_analysis", validator=DIAGNOSTIC_VALIDATOR)
    else:
        await db.command("collMod", "diagnostic_analysis", validator=DIAGNOSTIC_VALIDATOR)

    col = db["diagnostic_analysis"]
    # Prevents the same offline event being stored twice
    await col.create_index([("analysis_id", 1)], unique=True)
    await col.create_index([("student_id", 1), ("created_at", -1)])
    await col.create_index([("question_id", 1), ("created_at", -1)])
    await col.create_index([("execution_source", 1), ("created_at", -1)])

    print("diagnostic_analysis collection, validator and indexes are ready.")


async def main():
    await setup_diagnostic()
    await get_client().close()


if __name__ == "__main__":
    asyncio.run(main())