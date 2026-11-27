import asyncio

from app.database.mongodb import get_client
from app.repositories import questions_repository as qr


async def main():
    # fetch the questions 
    questions = await qr.list_questions_for_student("History", "Nationalism in India")
    print("Questions found:", len(questions))
    if not questions:
        print("No questions found. Run: python -m scripts.seed_questions")
        await get_client().close()
        return

    q = questions[0]
    qid = q["_id"]
    print("Concept:", q["concept_name"])

    #  the student view must not contain the answers
    print("\nStudent view has correct_answer?", "correct_answer" in q)  # expect False
    recovery = q.get("recovery_practice_questions", [])
    leaked = any("answer_key" in r for r in recovery)
    print("Student view has recovery answer_key?", leaked)  # expect False

    #the backend checking the answer
    print("\nAnswer B correct?", await qr.check_answer(qid, "B"))
    print("Answer A correct?", await qr.check_answer(qid, "A"))

    # choosing one probe
    print("\nLanguage probe:", await qr.get_probe(qid, "language_probe"))

    #  wrong probe name should be rejected
    try:
        await qr.get_probe(qid, "fake_probe")
    except ValueError as e:
        print("\nBad probe name rejected:", e)

    # the backend view does contain the answer
    full = await qr.get_question_full(qid)
    print("\nBackend view has correct_answer?", "correct_answer" in full)  # expect True

    await get_client().close()


if __name__ == "__main__":
    asyncio.run(main())