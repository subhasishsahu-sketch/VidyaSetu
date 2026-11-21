"""Mastery calculation service implementing locked VidyaSetu formulas."""


def clamp_score(score: float) -> float:
    """Clamps float score strictly between 0.0 and 100.0."""
    return max(0.0, min(100.0, float(score)))


def compute_overall_mastery(
    concept_understanding: float,
    previous_performance_score: float,
    prerequisite_understanding: float,
    english_comprehension: float,
    time_management: float,
    confidence_level: float,
) -> float:
    """Computes deterministic overall mastery from the 6 locked parameters.

    Weights:
      - concept_understanding: 0.30
      - previous_performance_score: 0.20
      - prerequisite_understanding: 0.15
      - english_comprehension: 0.15
      - time_management: 0.10
      - confidence_level: 0.10

    Returns overall mastery clamped to [0.0, 100.0] and rounded to 2 decimal places.
    """
    c = clamp_score(concept_understanding)
    p = clamp_score(previous_performance_score)
    pr = clamp_score(prerequisite_understanding)
    e = clamp_score(english_comprehension)
    t = clamp_score(time_management)
    conf = clamp_score(confidence_level)

    raw_mastery = (
        (0.30 * c)
        + (0.20 * p)
        + (0.15 * pr)
        + (0.15 * e)
        + (0.10 * t)
        + (0.10 * conf)
    )
    return round(clamp_score(raw_mastery), 2)


def map_english_exposure_level(score: float) -> int:
    """Maps english_comprehension score to english_exposure_level (1..4).

    Clamps score to [0.0, 100.0] and uses continuous <= thresholds:
      - score <= 45.0  -> Level 1 (Full Bilingual Support)
      - score <= 65.0  -> Level 2 (English Term Emphasis)
      - score <= 82.0  -> Level 3 (English with Odia Hints)
      - score > 82.0   -> Level 4 (Exam English)
    """
    clamped = clamp_score(score)
    if clamped <= 45.0:
        return 1
    elif clamped <= 65.0:
        return 2
    elif clamped <= 82.0:
        return 3
    else:
        return 4


def is_chapter_completed(overall_mastery: float) -> bool:
    """Returns True if chapter overall_mastery meets or exceeds completion threshold (>= 75.0)."""
    return clamp_score(overall_mastery) >= 75.0


def apply_recovery_boost(
    curr_concept: float,
    curr_prev: float,
    curr_prereq: float,
    curr_eng: float,
    curr_time: float,
    curr_conf: float,
    root_cause: str,
) -> dict:
    """Applies cause-specific +8.0 boost and +5.0 confidence boost upon successful recovery check.

    Mapping:
      - 'language_barrier' -> english_comprehension += 8.0
      - 'time_pressure' -> time_management += 8.0
      - 'prerequisite_gap' -> prerequisite_understanding += 8.0
      - 'conceptual_misunderstanding' / 'careless_mistake' -> concept_understanding += 8.0
      - confidence_level += 5.0
    All metrics clamped strictly to [0.0, 100.0].
    """
    cause = str(root_cause).lower().strip()
    upd_concept = curr_concept
    upd_prev = curr_prev
    upd_prereq = curr_prereq
    upd_eng = curr_eng
    upd_time = curr_time

    if cause == "language_barrier":
        upd_eng = clamp_score(curr_eng + 8.0)
    elif cause == "time_pressure":
        upd_time = clamp_score(curr_time + 8.0)
    elif cause == "prerequisite_gap":
        upd_prereq = clamp_score(curr_prereq + 8.0)
    else:  # conceptual_misunderstanding, careless_mistake, or default
        upd_concept = clamp_score(curr_concept + 8.0)

    upd_conf = clamp_score(curr_conf + 5.0)

    return {
        "concept_understanding": upd_concept,
        "previous_performance_score": upd_prev,
        "prerequisite_understanding": upd_prereq,
        "english_comprehension": upd_eng,
        "time_management": upd_time,
        "confidence_level": upd_conf,
    }


def build_recommended_next_task(
    student_id: str,
    subject: str,
    chapter_name: str,
    concept_name: str,
    root_cause: str,
    overall_mastery: float,
) -> dict:
    """Builds a structured planner dictionary for students.recommended_next_task."""
    cause_label = str(root_cause).replace("_", " ").title()
    if overall_mastery >= 75.0:
        return {
            "subject": subject,
            "chapter_name": chapter_name,
            "task_type": "chapter_mastery",
            "reason": f"Mastery target achieved ({overall_mastery:.1f}% >= 75%). Ready for next syllabus chapter.",
            "recommended_for": student_id,
        }
    return {
        "subject": subject,
        "chapter_name": chapter_name,
        "task_type": "practice_reinforcement",
        "reason": f"Recovered from {cause_label}. Complete 1 more practice question on {concept_name} to solidify mastery.",
        "recommended_for": student_id,
    }
