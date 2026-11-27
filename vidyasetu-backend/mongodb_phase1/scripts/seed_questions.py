import asyncio

from app.database.mongodb import get_client
from app.repositories.questions_repository import upsert_question

SUBJECT = "History"
CHAPTER = "Nationalism in India"  

QUESTIONS = [
    {
        "subject": SUBJECT,
        "chapter_name": CHAPTER,
        "concept_name": "Non-Cooperation Movement",
        "question_text": "Who launched the Non-Cooperation Movement in 1920?",
        "options": [
            {"key": "A", "text": "Jawaharlal Nehru"},
            {"key": "B", "text": "Mahatma Gandhi"},
            {"key": "C", "text": "Subhas Chandra Bose"},
            {"key": "D", "text": "Bal Gangadhar Tilak"},
        ],
        "correct_answer": "B",
        "expected_time_sec": 45,
        "diagnostic_probes": {
            "language_probe": {
                "prompt_odia": "ଏହି ପ୍ରଶ୍ନକୁ ଓଡ଼ିଆରେ ପଢ଼ି ଉତ୍ତର ଦିଅନ୍ତୁ: ୧୯୨୦ ମସିହାରେ ଅସହଯୋଗ ଆନ୍ଦୋଳନ କିଏ ଆରମ୍ଭ କରିଥିଲେ?",
                "prompt_english": "Read the question again in simple English: Which leader started the Non-Cooperation Movement in 1920?",
            },
            "untimed_retry": {
                "question_text": "Take your time. Who started the Non-Cooperation Movement in 1920?"
            },
            "prerequisite_probe": {
                "prompt": "What does 'non-cooperation' mean when people use it against a government?"
            },
            "transfer_probe": {
                "prompt": "A village peacefully refuses to pay an unfair tax and boycotts a company's goods. Which idea from the Non-Cooperation Movement does this show?",
                "scenario": "Peaceful refusal to cooperate with an unfair authority",
            },
            "explain_back": {
                "prompt": "In your own words, explain why the Non-Cooperation Movement was a peaceful form of protest."
            },
        },
        "recovery_practice_questions": [
            {
                "practice_id": "REC-001",
                "question_text": "Which movement began in 1930 with Gandhi's march to Dandi?",
                "answer_key": "Civil Disobedience Movement (Salt March)",
            }
        ],
    },
    {
        "subject": SUBJECT,
        "chapter_name": CHAPTER,
        "concept_name": "Jallianwala Bagh massacre",
        "question_text": "In which Indian city did the Jallianwala Bagh massacre take place in 1919?",
        "options": [
            {"key": "A", "text": "Delhi"},
            {"key": "B", "text": "Amritsar"},
            {"key": "C", "text": "Lahore"},
            {"key": "D", "text": "Kolkata"},
        ],
        "correct_answer": "B",
        "expected_time_sec": 45,
        "diagnostic_probes": {
            "language_probe": {
                "prompt_odia": "ଏହି ପ୍ରଶ୍ନକୁ ସରଳ ଓଡ଼ିଆରେ ପଢ଼ି ପୁଣି ଉତ୍ତର ଦିଅନ୍ତୁ।",
                "prompt_english": "Read the question again slowly: Where did the Jallianwala Bagh massacre happen?",
            },
            "untimed_retry": {
                "question_text": "Take your time. Which city was the site of the Jallianwala Bagh massacre?"
            },
            "prerequisite_probe": {
                "prompt": "Who ruled India in 1919: the Mughals or the British?"
            },
            "transfer_probe": {
                "prompt": "Soldiers fire on a peaceful public meeting. How might ordinary citizens react, based on what followed Jallianwala Bagh?",
                "scenario": "Force used against a peaceful gathering",
            },
            "explain_back": {
                "prompt": "In your own words, explain why the Jallianwala Bagh massacre increased anger against British rule."
            },
        },
        "recovery_practice_questions": [
            {
                "practice_id": "REC-002",
                "question_text": "In which state is Amritsar located?",
                "answer_key": "Punjab",
            }
        ],
    },
]


async def main():
    for q in QUESTIONS:
        doc = await upsert_question(q)
        print("Saved:", doc["concept_name"], "->", doc["_id"])
    await get_client().close()


if __name__ == "__main__":
    asyncio.run(main())