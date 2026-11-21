import asyncio
import json
import logging
import uuid
from pathlib import Path
from typing import Any, Dict, List, Optional
from pymongo.asynchronous.database import AsyncDatabase
from app.database.collections import (
    COLLECTION_QUESTIONS,
    COLLECTION_RAG_TEXTBOOK_VECTORS,
)
from app.database.mongodb import (
    close_mongo_connection,
    connect_to_mongo,
    get_database,
)

logger = logging.getLogger(__name__)

# Deterministic UUID v5 namespace for VidyaSetu seeds
SEED_NAMESPACE = uuid.UUID("a3b8c9d0-1e2f-4a5b-8c7d-9e0f1a2b3c4d")

# 5 Realistic BSE Odisha Class 10 Questions
# Using exact subject and chapter_name from offline_curriculum.db
SEED_QUESTIONS: List[Dict[str, Any]] = [
    {
        "seed_key": "bse_c10_hist_planning_commission",
        "subject": "History",
        "chapter_name": "India After Independence",
        "concept_name": "Planning Commission & Five Year Plans",
        "question_text": "Which institution was established in March 1950 under the chairmanship of Prime Minister Jawaharlal Nehru to formulate Five Year Plans for India's economic development?",
        "options": [
            {"key": "A", "text": "Finance Commission"},
            {"key": "B", "text": "Planning Commission"},
            {"key": "C", "text": "National Development Council"},
            {"key": "D", "text": "Election Commission"},
        ],
        "correct_answer": "B",
        "expected_time_sec": 60,
        "diagnostic_probes": {
            "language_probe": {
                "prompt_odia": "୧୯୫୦ ମସିହା ମାର୍ଚ୍ଚ ମାସରେ ପ୍ରଧାନମନ୍ତ୍ରୀ ଜବାହରଲାଲ ନେହେରୁଙ୍କ ଅଧ୍ୟକ୍ଷତାରେ ଦେଶର economic development ପାଇଁ Five Year Plans ପ୍ରସ୍ତୁତ କରିବାକୁ କେଉଁ institution ଗଠନ କରାଯାଇଥିଲା?",
                "prompt_english": "Which institution was set up in March 1950 under PM Nehru to formulate Five Year Plans?",
                "options": [
                    {"key": "A", "text": "ଅର୍ଥ ଆୟୋଗ (Finance Commission)"},
                    {"key": "B", "text": "ଯୋଜନା ଆୟୋଗ (Planning Commission)"},
                    {"key": "C", "text": "ଜାତୀୟ ବିକାଶ ପରିଷଦ"},
                    {"key": "D", "text": "ନିର୍ବାଚନ ଆୟୋଗ"},
                ],
            },
            "untimed_retry": {
                "question_text": "In 1950, what was the name of the commission established to coordinate India's balanced economic growth through Five Year Plans?",
                "options": [
                    {"key": "A", "text": "Finance Commission"},
                    {"key": "B", "text": "Planning Commission"},
                    {"key": "C", "text": "Pay Commission"},
                    {"key": "D", "text": "NITI Aayog"},
                ],
            },
            "prerequisite_probe": {
                "question_text": "What type of economic model did post-independence India adopt where both public (government) and private sectors co-exist?",
                "options": [
                    {"key": "A", "text": "Capitalist Economy"},
                    {"key": "B", "text": "Mixed Economy (ମିଶ୍ରିତ ଅର୍ଥନୀତି)"},
                    {"key": "C", "text": "Pure Socialist Economy"},
                    {"key": "D", "text": "Feudal Economy"},
                ],
            },
            "transfer_probe": {
                "scenario": "During 1951-1956, multi-purpose river valley projects like Hirakud and Bhakra Nangal were constructed to boost agriculture and irrigation.",
                "question_text": "Under which specific Five Year Plan were these foundational irrigation and power projects launched?",
                "options": [
                    {"key": "A", "text": "First Five Year Plan (ପ୍ରଥମ ପଞ୍ଚବାର୍ଷିକ ଯୋଜନା)"},
                    {"key": "B", "text": "Second Five Year Plan"},
                    {"key": "C", "text": "Third Five Year Plan"},
                    {"key": "D", "text": "Fourth Five Year Plan"},
                ],
            },
            "explain_back": {
                "prompt": "Why did India's leadership establish the Planning Commission in 1950 instead of relying purely on free market forces?",
                "options": [
                    {"key": "A", "text": "To systematically assess national resources and ensure balanced socialist-mixed growth"},
                    {"key": "B", "text": "To nationalize and seize all private properties"},
                    {"key": "C", "text": "To collect higher customs duties on foreign goods"},
                    {"key": "D", "text": "To replace parliamentary elections with central planning"},
                ],
            },
        },
        "recovery_practice_questions": [
            {
                "practice_id": "REC-HIST-01",
                "question_text": "In which year did the First Five Year Plan (ପ୍ରଥମ ପଞ୍ଚବାର୍ଷିକ ଯୋଜନା) commence in India?",
                "options": [
                    {"key": "A", "text": "1947"},
                    {"key": "B", "text": "1950"},
                    {"key": "C", "text": "1951"},
                    {"key": "D", "text": "1956"},
                ],
                "answer_key": "C",
            }
        ],
    },
    {
        "seed_key": "bse_c10_hist_princely_states",
        "subject": "History",
        "chapter_name": "India After Independence",
        "concept_name": "Merger of Princely States (Garhjat)",
        "question_text": "Which historic agreement did Sardar Vallabhbhai Patel advise rulers of princely states to sign to formally accede to the Indian Union?",
        "options": [
            {"key": "A", "text": "Poona Pact"},
            {"key": "B", "text": "Instrument of Accession (ମିଶ୍ରଣ ଚୁକ୍ତିପତ୍ର)"},
            {"key": "C", "text": "Shimla Accord"},
            {"key": "D", "text": "Delhi Pact"},
        ],
        "correct_answer": "B",
        "expected_time_sec": 45,
        "diagnostic_probes": {
            "language_probe": {
                "prompt_odia": "ଦେଶୀୟ ରାଜ୍ୟମାନଙ୍କୁ ଭାରତୀୟ ସଂଘ (Indian Union) ସହିତ ଯୋଡ଼ିବା ପାଇଁ ସର୍ଦ୍ଦାର ପଟେଲ ରାଜାମାନଙ୍କୁ କେଉଁ ‘ଚୁକ୍ତିପତ୍ର’ ସ୍ଵାକ୍ଷର କରିବାକୁ ବୁଝାଇଥିଲେ?",
                "prompt_english": "Which legal agreement did Sardar Patel ask princely rulers to sign to join the Indian Union?",
                "options": [
                    {"key": "A", "text": "ପୁନା ଚୁକ୍ତି (Poona Pact)"},
                    {"key": "B", "text": "ମିଶ୍ରଣ ଚୁକ୍ତିପତ୍ର (Instrument of Accession)"},
                    {"key": "C", "text": "ସିମଲା ଚୁକ୍ତି"},
                    {"key": "D", "text": "ଦିଲ୍ଲୀ ଡ୍ରାଫ୍ଟ"},
                ],
            },
            "untimed_retry": {
                "question_text": "What official document did princely rulers sign to surrender defense, foreign affairs, and communications to the Indian Union?",
                "options": [
                    {"key": "A", "text": "Treaty of Versailles"},
                    {"key": "B", "text": "Instrument of Accession"},
                    {"key": "C", "text": "Government of India Act"},
                    {"key": "D", "text": "Indian Independence Act"},
                ],
            },
            "prerequisite_probe": {
                "question_text": "Who was the first Deputy Prime Minister and Home Minister of independent India responsible for integrating princely states?",
                "options": [
                    {"key": "A", "text": "Jawaharlal Nehru"},
                    {"key": "B", "text": "Sardar Vallabhbhai Patel"},
                    {"key": "C", "text": "Subhas Chandra Bose"},
                    {"key": "D", "text": "Harekrushna Mahatab"},
                ],
            },
            "transfer_probe": {
                "scenario": "In Odisha, 25 out of 26 Garhjat princely states merged with the state administration on January 1, 1948.",
                "question_text": "Which lone Garhjat state delayed its formal merger with Odisha until January 1, 1949?",
                "options": [
                    {"key": "A", "text": "Nilgiri"},
                    {"key": "B", "text": "Mayurbhanj"},
                    {"key": "C", "text": "Ranpur"},
                    {"key": "D", "text": "Dhenkanal"},
                ],
            },
            "explain_back": {
                "prompt": "What incentive was granted to princely rulers in exchange for surrendering their administrative sovereignty to India?",
                "options": [
                    {"key": "A", "text": "Annual privy purses (ବାର୍ଷିକ ବୃତ୍ତି) and retention of personal property"},
                    {"key": "B", "text": "Permanent cabinet ministries in New Delhi"},
                    {"key": "C", "text": "Exemption from all federal laws"},
                    {"key": "D", "text": "Ownership of all military equipment"},
                ],
            },
        },
        "recovery_practice_questions": [
            {
                "practice_id": "REC-HIST-02",
                "question_text": "How many princely states (ଦେଶୀୟ ରାଜ୍ୟ) existed in India at the time of independence in 1947?",
                "options": [
                    {"key": "A", "text": "Approximately 200"},
                    {"key": "B", "text": "Approximately 565"},
                    {"key": "C", "text": "Approximately 800"},
                    {"key": "D", "text": "Approximately 120"},
                ],
                "answer_key": "B",
            }
        ],
    },
    {
        "seed_key": "bse_c10_sci_spherical_mirrors",
        "subject": "Science",
        "chapter_name": "Light",
        "concept_name": "Reflection & Spherical Mirrors",
        "question_text": "Which type of spherical mirror is commonly installed as a rear-view mirror in automobiles because it always produces an erect, diminished image and gives a wider field of view?",
        "options": [
            {"key": "A", "text": "Concave Mirror (ଅବତଳ ଦର୍ପଣ)"},
            {"key": "B", "text": "Convex Mirror (ଉତ୍ତଳ ଦର୍ପଣ)"},
            {"key": "C", "text": "Plane Mirror (ସମତଳ ଦର୍ପଣ)"},
            {"key": "D", "text": "Parabolic Concave Mirror"},
        ],
        "correct_answer": "B",
        "expected_time_sec": 45,
        "diagnostic_probes": {
            "language_probe": {
                "prompt_odia": "ଗାଡ଼ିମାନଙ୍କରେ ପଛପଟ ଟ୍ରାଫିକ୍ ଦେଖିବା ପାଇଁ rear-view mirror ଭାବେ କେଉଁ spherical mirror ବ୍ୟବହାର ହୁଏ, ଯାହାକି ସର୍ବଦା erect (ସଳଖ) ଓ diminished (କ୍ଷୁଦ୍ର) image ଗଠନ କରି wider field of view ପ୍ରଦାନ କରେ?",
                "prompt_english": "Which mirror is used as a rear-view mirror because it forms erect, diminished images with a wider field of view?",
                "options": [
                    {"key": "A", "text": "ଅବତଳ ଦର୍ପଣ (Concave Mirror)"},
                    {"key": "B", "text": "ଉତ୍ତଳ ଦର୍ପଣ (Convex Mirror)"},
                    {"key": "C", "text": "ସମତଳ ଦର୍ପଣ (Plane Mirror)"},
                    {"key": "D", "text": "ଦ୍ୱି-ଅବତଳ ଲେନ୍ସ"},
                ],
            },
            "untimed_retry": {
                "question_text": "Why do convex mirrors provide drivers with a much wider field of view compared to plane mirrors?",
                "options": [
                    {"key": "A", "text": "Because they are curved outwards"},
                    {"key": "B", "text": "Because they absorb stray light"},
                    {"key": "C", "text": "Because they invert distant objects"},
                    {"key": "D", "text": "Because they have zero focal length"},
                ],
            },
            "prerequisite_probe": {
                "question_text": "According to the laws of reflection of light, what is the relationship between the angle of incidence (i) and the angle of reflection (r)?",
                "options": [
                    {"key": "A", "text": "Angle of incidence is greater than angle of reflection"},
                    {"key": "B", "text": "Angle of incidence is strictly equal to angle of reflection (∠i = ∠r)"},
                    {"key": "C", "text": "Angle of incidence is half of angle of reflection"},
                    {"key": "D", "text": "They are perpendicular to each other"},
                ],
            },
            "transfer_probe": {
                "scenario": "A dentist needs to inspect a decayed tooth cavity and requires a magnified, upright virtual image of the tooth.",
                "question_text": "Which type of mirror should the dentist use when holding it close to the patient's tooth?",
                "options": [
                    {"key": "A", "text": "Concave Mirror held within focal point (f)"},
                    {"key": "B", "text": "Convex Mirror"},
                    {"key": "C", "text": "Plane Mirror"},
                    {"key": "D", "text": "Cylindrical Mirror"},
                ],
            },
            "explain_back": {
                "prompt": "How does the nature of reflection change between smooth polished surfaces and rough unpolished walls?",
                "options": [
                    {"key": "A", "text": "Polished surfaces produce regular specular reflection, while rough walls cause diffused reflection"},
                    {"key": "B", "text": "Rough walls violate the law of reflection"},
                    {"key": "C", "text": "Specular reflection only occurs in vacuum"},
                    {"key": "D", "text": "Both surfaces absorb 100% of incident rays"},
                ],
            },
        },
        "recovery_practice_questions": [
            {
                "practice_id": "REC-SCI-01",
                "question_text": "Where is the center of curvature (C) located for a convex mirror?",
                "options": [
                    {"key": "A", "text": "In front of the reflecting surface"},
                    {"key": "B", "text": "Behind the reflecting surface"},
                    {"key": "C", "text": "At the optical pole (P)"},
                    {"key": "D", "text": "At infinity"},
                ],
                "answer_key": "B",
            }
        ],
    },
    {
        "seed_key": "bse_c10_sci_curvature_focal_length",
        "subject": "Science",
        "chapter_name": "Light",
        "concept_name": "Center of Curvature & Focal Length",
        "question_text": "For spherical mirrors having small apertures, what is the exact mathematical relationship between radius of curvature (R) and focal length (f)?",
        "options": [
            {"key": "A", "text": "R = f"},
            {"key": "B", "text": "R = 2f"},
            {"key": "C", "text": "R = f / 2"},
            {"key": "D", "text": "R = 3f"},
        ],
        "correct_answer": "B",
        "expected_time_sec": 40,
        "diagnostic_probes": {
            "language_probe": {
                "prompt_odia": "କ୍ଷୁଦ୍ର aperture ବିଶିଷ୍ଟ spherical mirror ପାଇଁ radius of curvature (ବକ୍ରତା ବ୍ୟାସାର୍ଦ୍ଧ R) ଏବଂ focal length (ଫୋକସ ଦୂରତା f) ମଧ୍ୟରେ ଗାଣିତିକ ସମ୍ପର୍କ କ'ଣ?",
                "prompt_english": "What is the relationship between radius of curvature (R) and focal length (f) for a spherical mirror?",
                "options": [
                    {"key": "A", "text": "R = f"},
                    {"key": "B", "text": "R = 2f (f = R/2)"},
                    {"key": "C", "text": "R = f / 2"},
                    {"key": "D", "text": "R = 4f"},
                ],
            },
            "untimed_retry": {
                "question_text": "If a concave mirror has a radius of curvature of 30 cm, what is its focal length?",
                "options": [
                    {"key": "A", "text": "30 cm"},
                    {"key": "B", "text": "15 cm"},
                    {"key": "C", "text": "60 cm"},
                    {"key": "D", "text": "7.5 cm"},
                ],
            },
            "prerequisite_probe": {
                "question_text": "What is the geometric center of the reflecting spherical surface called?",
                "options": [
                    {"key": "A", "text": "Principal Focus"},
                    {"key": "B", "text": "Pole (P)"},
                    {"key": "C", "text": "Center of Curvature"},
                    {"key": "D", "text": "Aperture"},
                ],
            },
            "transfer_probe": {
                "scenario": "A student measures the focal length of a convex shaving mirror to be 10 cm.",
                "question_text": "What is the radius of the sphere from which this mirror was cut?",
                "options": [
                    {"key": "A", "text": "5 cm"},
                    {"key": "B", "text": "20 cm"},
                    {"key": "C", "text": "10 cm"},
                    {"key": "D", "text": "40 cm"},
                ],
            },
            "explain_back": {
                "prompt": "Why do parallel rays close to the principal axis converge at exactly halfway between the pole and center of curvature?",
                "options": [
                    {"key": "A", "text": "Due to paraxial geometry where ∠i = ∠r bisects the radius to f = R/2"},
                    {"key": "B", "text": "Because light speed doubles inside the mirror"},
                    {"key": "C", "text": "Due to atmospheric refraction"},
                    {"key": "D", "text": "Because the focal point is defined arbitrarily"},
                ],
            },
        },
        "recovery_practice_questions": [
            {
                "practice_id": "REC-SCI-02",
                "question_text": "What is the focal length of a spherical mirror whose radius of curvature is 40 cm?",
                "options": [
                    {"key": "A", "text": "10 cm"},
                    {"key": "B", "text": "20 cm"},
                    {"key": "C", "text": "40 cm"},
                    {"key": "D", "text": "80 cm"},
                ],
                "answer_key": "B",
            }
        ],
    },
    {
        "seed_key": "bse_c10_geog_water_harvesting",
        "subject": "Geography",
        "chapter_name": "Water Resources",
        "concept_name": "Ancient Water Harvesting & Multipurpose River Projects",
        "question_text": "On which major river of Odisha was the multipurpose Hirakud Dam constructed to mitigate devastating floods and provide agricultural irrigation and hydropower?",
        "options": [
            {"key": "A", "text": "Brahmani River"},
            {"key": "B", "text": "Mahanadi River"},
            {"key": "C", "text": "Baitarani River"},
            {"key": "D", "text": "Subarnarekha River"},
        ],
        "correct_answer": "B",
        "expected_time_sec": 45,
        "diagnostic_probes": {
            "language_probe": {
                "prompt_odia": "ଓଡ଼ିଶାର ବନ୍ୟା ନିୟନ୍ତ୍ରଣ (flood control), ଜଳସେଚନ (irrigation) ଏବଂ hydroelectric power ଉତ୍ପାଦନ ପାଇଁ ଐତିହାସିକ Hirakud Dam କେଉଁ major river ଉପରେ ନିର୍ମିତ ହୋଇଛି?",
                "prompt_english": "On which major river in Odisha was Hirakud Dam built for flood control and irrigation?",
                "options": [
                    {"key": "A", "text": "ବ୍ରାହ୍ମଣୀ (Brahmani)"},
                    {"key": "B", "text": "ମହାନଦୀ (Mahanadi)"},
                    {"key": "C", "text": "ବୈତରଣୀ (Baitarani)"},
                    {"key": "D", "text": "ଋଷିକୁଲ୍ୟା (Rushikulya)"},
                ],
            },
            "untimed_retry": {
                "question_text": "Which is the longest major earthen dam in India built across the Mahanadi River near Sambalpur?",
                "options": [
                    {"key": "A", "text": "Bhakra Dam"},
                    {"key": "B", "text": "Hirakud Dam"},
                    {"key": "C", "text": "Tehri Dam"},
                    {"key": "D", "text": "Sardar Sarovar Dam"},
                ],
            },
            "prerequisite_probe": {
                "question_text": "What is the primary natural reason river valley projects are classified as 'multipurpose'?",
                "options": [
                    {"key": "A", "text": "They only generate nuclear power"},
                    {"key": "B", "text": "They integrate flood control, irrigation, power, and inland navigation together"},
                    {"key": "C", "text": "They stop rainfall completely"},
                    {"key": "D", "text": "They are exclusively used for industrial dumping"},
                ],
            },
            "transfer_probe": {
                "scenario": "In ancient Kalinga (historic Odisha), sophisticated water-management and canal-irrigation networks were recorded in epigraphical inscriptions.",
                "question_text": "Which ancient monarch's Hathigumpha inscription mentions opening a canal originally dug 300 years earlier by a Nanda king?",
                "options": [
                    {"key": "A", "text": "Emperor Ashoka"},
                    {"key": "B", "text": "King Kharavela (ଖାରବେଳ)"},
                    {"key": "C", "text": "Samudragupta"},
                    {"key": "D", "text": "Kapilendra Deva"},
                ],
            },
            "explain_back": {
                "prompt": "How did ancient Indian hydraulic engineers adapt water harvesting methods to regional topography?",
                "options": [
                    {"key": "A", "text": "By developing rooftop rainwater harvesting, inundation channels, and diversion bunds like 'guls' or 'kuls'"},
                    {"key": "B", "text": "By constructing steel water pipes connecting all rivers"},
                    {"key": "C", "text": "By importing fresh water from neighboring countries"},
                    {"key": "D", "text": "By drying out wetland ecosystems"},
                ],
            },
        },
        "recovery_practice_questions": [
            {
                "practice_id": "REC-GEOG-01",
                "question_text": "In which Indian state is the Hirakud Multipurpose Project located?",
                "options": [
                    {"key": "A", "text": "West Bengal"},
                    {"key": "B", "text": "Odisha"},
                    {"key": "C", "text": "Jharkhand"},
                    {"key": "D", "text": "Chhattisgarh"},
                ],
                "answer_key": "B",
            }
        ],
    },
]


# Curated BSE Odisha Class 10 STEM & Social Science Technical Glossary
ODIA_TECH_TERM_GLOSSARY: Dict[str, str] = {
    # History: India After Independence
    "instrument of accession": "ମିଶ୍ରଣ ଚୁକ୍ତିପତ୍ର",
    "privy purse": "ବାର୍ଷିକ ବୃତ୍ତି",
    "mixed economy": "ମିଶ୍ରିତ ଅର୍ଥନୀତି",
    "planning commission": "ଯୋଜନା ଆୟୋଗ",
    "five year plans": "ପଞ୍ଚବାର୍ଷିକ ଯୋଜନା",
    "green revolution": "ସବୁଜ ବିପ୍ଳବ",
    "lpg policy": "ନୂତନ ଅର୍ଥନୈତିକ ନୀତି",
    "liberalisation": "ଉଦାରୀକରଣ",
    "privatisation": "ଘରୋଇକରଣ",
    "globalisation": "ଜଗତୀକରଣ",
    "aec": "ପରମାଣୁ ଶକ୍ତି ଆୟୋଗ",
    "isro": "ଭାରତୀୟ ମହାକାଶ ଗବେଷଣା ସଂସ୍ଥା",
    "insat": "ଇନ୍‌ସାଟ୍ ଉପଗ୍ରହ",
    "irs": "ଆଇ.ଆର୍.ଏସ୍ ଉପଗ୍ରହ",
    "drdo": "ପ୍ରତିରକ୍ଷା ଗବେଷଣା ଓ ବିକାଶ ସଂଗଠନ",
    "igmdp": "ସମନ୍ୱିତ ନିୟନ୍ତ୍ରିତ କ୍ଷେପଣାସ୍ତ୍ର ବିକାଶ କାର୍ଯ୍ୟକ୍ରମ",
    "iit": "ଭାରତୀୟ ପ୍ରଯୁକ୍ତିବିଦ୍ୟା ଅନୁଷ୍ଠାନ",
    "aiims": "ଅଖିଳ ଭାରତୀୟ ଆୟୁର୍ବିଜ୍ଞାନ ସଂସ୍ଥାନ",
    "it": "ସୂଚନା ପ୍ରଯୁକ୍ତିବିଦ୍ୟା",
    # Science: Light
    "nature of light": "ଆଲୋକର ପ୍ରକୃତି",
    "shadow": "ଛାଇ",
    "ray of light": "ଆଲୋକ ରଶ୍ମି",
    "diffraction": "ବିବର୍ତ୍ତନ",
    "wave theory of light": "ଆଲୋକର ତରଙ୍ଗ ତତ୍ତ୍ୱ",
    "reflection of light": "ଆଲୋକର ପ୍ରତିଫଳନ",
    "spherical mirrors": "ଗୋଲକୀୟ ଦର୍ପଣ",
    "concave mirror": "ଅବତଳ ଦର୍ପଣ",
    "convex mirror": "ଉତ୍ତଳ ଦର୍ପଣ",
    "pole": "ମେରୁ",
    "center of curvature": "ବକ୍ରତା କେନ୍ଦ୍ର",
    "radius of curvature": "ବକ୍ରତା ବ୍ୟାସାର୍ଦ୍ଧ",
    "principal axis": "ମୁଖ୍ୟ ଅକ୍ଷ",
    "principal focus": "ମୁଖ୍ୟ ଫୋକସ୍",
    "focal length": "ଫୋକସ ଦୂରତା",
    "shaving mirror": "କ୍ଷୌର ଦର୍ପଣ",
    "rear-view mirror": "ପୃଷ୍ଠଦର୍ଶୀ ଦର୍ପଣ",
    "wider field of view": "ବ୍ୟାପକ ଦୃଷ୍ଟିକ୍ଷେତ୍ର",
    "new cartesian sign convention": "କାର୍ତ୍ତେସୀୟ ଚିହ୍ନ ପ୍ରଣାଳୀ",
    "mirror formula": "ଦର୍ପଣ ସୂତ୍ର",
    "magnification": "ବର୍ଦ୍ଧନ",
    "refraction of light": "ଆଲୋକର ପ୍ରତିସରଣ",
    "refractive index": "ପ୍ରତିସରଣାଙ୍କ",
    "absolute refractive index": "ପରମ ପ୍ରତିସରଣାଙ୍କ",
    "spherical lenses": "ଗୋଲକୀୟ ଲେନ୍ସ",
    "convex lens": "ଉତ୍ତଳ ଲେନ୍ସ",
    "converging lens": "ଅଭିସାରୀ ଲେନ୍ସ",
    "concave lens": "ଅବତଳ ଲେନ୍ସ",
    "diverging lens": "ଅପସାରୀ ଲେନ୍ସ",
    "optical center": "ଆଲୋକ କେନ୍ଦ୍ର",
    "lens formula": "ଲେନ୍ସ ସୂତ୍ର",
    "power of a lens": "ଲେନ୍ସର କ୍ଷମତା",
    "dioptre": "ଡାଇଅପ୍ଟର",
    # Geography: Water Resources
    "oasis": "ମରୁଦ୍ଦ୍ୟାନ",
    "water resources": "ଜଳ ସମ୍ପଦ",
    "water harvesting": "ଜଳ ଅମଳ",
    "rainwater harvesting": "ବର୍ଷାଜଳ ଅମଳ",
    "irrigation": "ଜଳସେଚନ",
    "multipurpose project": "ବହୁମୁଖୀ ନଦୀବନ୍ଧ ଯୋଜନା",
    "dam": "ନଦୀବନ୍ଧ",
    "flood control": "ବନ୍ୟା ନିୟନ୍ତ୍ରଣ",
    "hydroelectric power": "ଜଳବିଦ୍ୟୁତ୍ ଶକ୍ତି",
    "national water grid": "ଜାତୀୟ ଜଳ ଗ୍ରୀଡ୍",
    "river water dispute": "ନଦୀଜଳ ବିବାଦ",
    # Science: Metals and Non-Metals
    "acids, bases and salts": "ଅମ୍ଳ, କ୍ଷାରକ ଓ ଲବଣ",
    "acidity": "ଅମ୍ଳତା",
    "indicator": "ସୂଚକ",
    "synthetic indicators": "କୃତ୍ରିମ ସୂଚକ",
    "neutralisation": "ପ୍ରଶମନ",
    "alkali": "କ୍ଷାର",
    "corrosive": "କ୍ଷୟକାରୀ",
}


def parse_important_english_terms(
    raw_terms_str: Optional[str], chunk_text: str = ""
) -> List[Dict[str, str]]:
    """Parses raw comma-separated english_tech_terms into deduplicated key-term pairs.

    - Strips whitespace and deduplicates case-insensitively per chunk.
    - If a term has a verified Odia Unicode meaning in ODIA_TECH_TERM_GLOSSARY or chunk_text,
      it is attached.
    - If no verified Odia Unicode characters are found, odia_meaning is set to "" (never Romanised Odia).
    """
    if not raw_terms_str:
        return []

    seen = set()
    result = []
    for raw in raw_terms_str.split(","):
        cleaned = raw.strip()
        if not cleaned:
            continue
        lower = cleaned.lower()
        if lower in seen:
            continue
        seen.add(lower)

        # Check glossary first
        odia = ODIA_TECH_TERM_GLOSSARY.get(lower, "")

        # Dynamic search in chunk_text if not in glossary
        if not odia and chunk_text:
            import re
            m = re.search(
                rf"{re.escape(cleaned)}[^\(（]{{0,30}}[\(（]([\u0B00-\u0B7F\s]{{2,40}})[\)）]",
                chunk_text,
                re.IGNORECASE,
            )
            if m:
                cand = m.group(1).strip()
                if re.search(r"[\u0B00-\u0B7F]", cand):
                    odia = cand

        # Verify only authentic Odia Unicode characters (\u0B00-\u0B7F)
        import re
        if odia and not re.search(r"[\u0B00-\u0B7F]", odia):
            odia = ""

        result.append({"english_term": cleaned, "odia_meaning": odia})

    return result


async def import_offline_slm_chunks(db: AsyncDatabase) -> int:
    """Imports pre-computed chunks with full 768-dim embeddings into rag_textbook_vectors.

    Uses deterministic UUID v5 IDs and update_one(..., upsert=True) for strict idempotency.
    """
    col = db[COLLECTION_RAG_TEXTBOOK_VECTORS]
    seed_chunks_file = Path("app/database/seed_chunks.json")

    if not seed_chunks_file.exists():
        logger.warning(
            "seed_chunks.json not found at %s. Skipping textbook chunk import.",
            seed_chunks_file,
        )
        return 0

    with open(seed_chunks_file, "r", encoding="utf-8") as f:
        records = json.load(f)

    imported_count = 0
    for r in records:
        raw_id = r["chunk_id"]
        # Generate deterministic lowercase UUID v5
        doc_id = str(uuid.uuid5(SEED_NAMESPACE, f"chunk:{raw_id}")).lower()

        # Parse and map important English terms with Odia Unicode meanings
        existing_terms = r.get("important_english_terms") or []
        if existing_terms and isinstance(existing_terms, list) and isinstance(existing_terms[0], dict):
            raw_str = ", ".join(t.get("english_term", "") for t in existing_terms)
        else:
            raw_str = r.get("english_tech_terms") or ""

        parsed_terms = parse_important_english_terms(raw_str, r.get("chunk_text", ""))

        doc: Dict[str, Any] = {
            "_id": doc_id,
            "chunk_id": doc_id,
            "original_chunk_id": raw_id,
            "subject": r["subject"],
            "chapter_name": r["chapter_name"],
            "chunk_text": r["chunk_text"],
            "embedding": r["embedding"],
            "embedding_model": r.get("embedding_model", "intfloat/multilingual-e5-base"),
            "embedding_dim": len(r["embedding"]),
            "grounded_reference": r["grounded_reference"],
            "important_english_terms": parsed_terms,
        }

        await col.update_one({"_id": doc_id}, {"$set": doc}, upsert=True)
        imported_count += 1

    logger.info("Successfully imported %d textbook chunks idempotently.", imported_count)
    return imported_count


async def seed_questions(db: AsyncDatabase) -> int:
    """Seeds realistic BSE Odisha Class 10 questions into questions collection.

    Uses deterministic UUID v5 IDs and update_one(..., upsert=True) for strict idempotency.
    """
    col = db[COLLECTION_QUESTIONS]
    seeded_count = 0

    for q in SEED_QUESTIONS:
        seed_key = q["seed_key"]
        doc_id = str(uuid.uuid5(SEED_NAMESPACE, f"question:{seed_key}")).lower()

        doc: Dict[str, Any] = {
            "_id": doc_id,
            "question_id": doc_id,
            "seed_key": seed_key,
            "subject": q["subject"],
            "chapter_name": q["chapter_name"],
            "concept_name": q["concept_name"],
            "question_text": q["question_text"],
            "options": q["options"],
            "correct_answer": q["correct_answer"],
            "expected_time_sec": q["expected_time_sec"],
            "diagnostic_probes": q["diagnostic_probes"],
            "recovery_practice_questions": q["recovery_practice_questions"],
        }

        await col.update_one({"_id": doc_id}, {"$set": doc}, upsert=True)
        seeded_count += 1

    logger.info("Successfully seeded %d questions idempotently.", seeded_count)
    return seeded_count


async def seed_database(db: AsyncDatabase) -> Dict[str, int]:
    """Runs complete seed pipeline idempotently."""
    chunks = await import_offline_slm_chunks(db)
    questions = await seed_questions(db)
    return {"chunks": chunks, "questions": questions}


async def main():
    logging.basicConfig(level=logging.INFO)
    logger.info("Starting VidyaSetu database seed execution...")
    try:
        await connect_to_mongo()
        db = await get_database()
        results = await seed_database(db)
        logger.info(
            "Seed completed: %d textbook chunks, %d questions.",
            results["chunks"],
            results["questions"],
        )
    except Exception as exc:
        logger.error("Database seed failed or MongoDB is not running: %s", exc)
    finally:
        await close_mongo_connection()


if __name__ == "__main__":
    asyncio.run(main())
