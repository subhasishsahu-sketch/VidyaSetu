import asyncio
import uuid

from pymongo.errors import WriteError

from app.database.mongodb import get_db, get_client
from app.repositories import diagnostics_repository as dr

# The same IDs used by seed_diagnostics.py
CLOUD_EVENT_ID = "a1b2c3d4-0001-4000-8000-000000000001"
OFFLINE_EVENT_ID = "a1b2c3d4-0002-4000-8000-000000000002"


async def main():
    db = get_db()

    cloud = await dr.get_analysis(CLOUD_EVENT_ID)
    if cloud is None:
        print("Seed data missing. Run: python -m scripts.seed_diagnostics")
        await get_client().close()
        return

    # test 1: the same event sent twice must be stored only once 
    test_id = str(uuid.uuid4())
    event = {
        "analysis_id": test_id,
        "student_id": cloud["student_id"],
        "question_id": cloud["question_id"],
        "attempt_data": {
            "selected_option": "D",
            "is_correct": False,
            "time_taken_sec": 20,
            "confidence_rating": "low",
            "answer_changes_count": 1,
        },
        "execution_source": "edge_slm_offline_sync",
        "offline_created_at": "2026-11-23T09:00:00Z",
    }
    first = await dr.save_analysis(event)
    second = await dr.save_analysis(event)
    copies = await db.diagnostic_analysis.count_documents({"analysis_id": test_id})
    print("TEST 1: duplicate protection")
    print("  first upload inserted? ", first["inserted"])    # expect True
    print("  second upload inserted?", second["inserted"])   # expect False
    print("  copies in database:    ", copies)               # expect 1

    # test 2: offline time is kept separate from cloud time 
    saved = await dr.get_analysis(test_id)
    print("\nTEST 2: timestamps")
    print("  happened offline at:", saved["offline_created_at"])
    print("  stored in cloud at: ", saved["created_at"])

    await db.diagnostic_analysis.delete_one({"analysis_id": test_id})  # clean up

    # test3: a student's history 
    history = await dr.list_for_student(cloud["student_id"])
    print("\nTEST 3: student history")
    print("  records for this student:", len(history))
    for h in history:
        print("   -", h["execution_source"], "|", h["analysis_id"])

    # test 4: the diagnosis is stored inside the record 
    print("\nTEST 4: stored diagnosis")
    print("  final_diagnosis:", cloud["probe_loop_evidence"]["final_diagnosis"])
    print("  probes used:    ", cloud["probe_loop_evidence"]["probes_triggered"])

    # test 5: add the recovery result later 
    ok = await dr.set_recovery_assessment(OFFLINE_EVENT_ID, {
        "practice_question_attempted": "REC-001",
        "is_recovery_correct": True,
        "has_student_improved": True,
    })
    updated = await dr.get_analysis(OFFLINE_EVENT_ID)
    print("\nTEST 5: recovery update")
    print("  update worked?", ok)  # expect True
    print("  has_student_improved:", updated["recovery_assessment"]["has_student_improved"])

    # test 6: bad data is rejected by the validator 
    bad = dict(event)
    bad["analysis_id"] = str(uuid.uuid4())
    bad["execution_source"] = "banana"  # not an allowed value
    print("\nTEST 6: validator")
    try:
        await dr.save_analysis(bad)
        print("  PROBLEM: bad data was saved")
    except WriteError:
        print("  bad execution_source rejected (good)")

    # test 7: a missing required field is rejected 
    try:
        await dr.save_analysis({"student_id": "x"})
        print("  PROBLEM: incomplete event was saved")
    except ValueError as e:
        print("  incomplete event rejected (good):", e)

    await get_client().close()


if __name__ == "__main__":
    asyncio.run(main())