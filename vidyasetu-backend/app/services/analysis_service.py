"""Deterministic 7-parameter behavioral analyzer and hypothesis ranker."""

from typing import Any, Dict, List, Optional
from app.schemas.diagnostic_schema import CandidateHypothesis
from app.services.mastery_service import clamp_score


def build_7parameter_snapshot(
    attempt_time_sec: float,
    confidence_rating: float,
    answer_changes_count: int,
    student_preferred_language: str = "Odia",
    concept_understanding: float = 50.0,
    previous_performance: float = 50.0,
    english_comprehension: float = 50.0,
    expected_time_sec: int = 60,
) -> Dict[str, str]:
    """Builds a deterministic 7-parameter behavioral snapshot with exact blueprint categorical labels."""
    exp = max(10, expected_time_sec)
    time_sec = max(0.0, float(attempt_time_sec))
    time_ratio = time_sec / exp

    if time_ratio > 1.2:
        time_cat = "High"
    elif time_ratio < 0.6:
        time_cat = "Low"
    else:
        time_cat = "Normal"

    conf = clamp_score(confidence_rating)
    if conf >= 70.0:
        conf_cat = "High"
    elif conf <= 45.0:
        conf_cat = "Low"
    else:
        conf_cat = "Normal"

    changes = max(0, int(answer_changes_count))
    if changes >= 2:
        changes_cat = "Frequent"
    elif changes == 1:
        changes_cat = "Occasional"
    else:
        changes_cat = "None"

    lang_pref = "English" if str(student_preferred_language).strip().lower() == "english" else "Odia"
    concept_cat = "Understood" if clamp_score(concept_understanding) >= 60.0 else "Weak"
    prev_cat = "Strong" if clamp_score(previous_performance) >= 60.0 else "Weak"
    eng_cat = "Strong" if clamp_score(english_comprehension) >= 60.0 else "Weak"

    return {
        "time_taken": time_cat,
        "confidence_level": conf_cat,
        "answer_changes": changes_cat,
        "language_preference": lang_pref,
        "concept_understanding": concept_cat,
        "previous_performance": prev_cat,
        "english_comprehension": eng_cat,
    }


def rank_hypotheses(
    snapshot: Any,
    expected_time_sec: int = 60,
) -> List[CandidateHypothesis]:
    """Ranks 5 root-cause hypotheses deterministically based on the 7-parameter categorical snapshot.

    Hypotheses evaluated:
      1. careless_mistake -> untimed_retry
      2. time_pressure -> untimed_retry
      3. language_barrier -> language_probe
      4. prerequisite_gap -> prerequisite_probe
      5. conceptual_misunderstanding -> transfer_probe
    """
    if hasattr(snapshot, "model_dump"):
        snap_dict = snapshot.model_dump()
    elif isinstance(snapshot, dict):
        snap_dict = snapshot
    else:
        snap_dict = dict(snapshot) if snapshot else {}

    raw_time = snap_dict.get("time_taken", "Normal")
    if isinstance(raw_time, (int, float)):
        time_ratio = float(raw_time) / max(10, expected_time_sec)
        time_cat = "High" if time_ratio > 1.2 else ("Low" if time_ratio < 0.6 else "Normal")
    else:
        time_cat = str(raw_time).strip().capitalize()

    raw_conf = snap_dict.get("confidence_level", "Normal")
    if isinstance(raw_conf, (int, float)):
        conf_cat = "High" if float(raw_conf) >= 70.0 else ("Low" if float(raw_conf) <= 45.0 else "Normal")
    else:
        conf_cat = str(raw_conf).strip().capitalize()

    raw_changes = snap_dict.get("answer_changes", "None")
    if isinstance(raw_changes, (int, float)):
        changes_cat = "Frequent" if int(raw_changes) >= 2 else ("Occasional" if int(raw_changes) == 1 else "None")
    else:
        changes_cat = str(raw_changes).strip().capitalize()

    lang_pref = "English" if str(snap_dict.get("language_preference", "Odia")).strip().lower() == "english" else "Odia"

    raw_concept = snap_dict.get("concept_understanding", "Understood")
    if isinstance(raw_concept, (int, float)):
        concept_cat = "Understood" if float(raw_concept) >= 60.0 else "Weak"
    else:
        concept_cat = str(raw_concept).strip().capitalize()

    raw_prev = snap_dict.get("previous_performance", "Strong")
    if isinstance(raw_prev, (int, float)):
        prev_cat = "Strong" if float(raw_prev) >= 60.0 else "Weak"
    else:
        prev_cat = str(raw_prev).strip().capitalize()

    raw_eng = snap_dict.get("english_comprehension", "Strong")
    if isinstance(raw_eng, (int, float)):
        eng_cat = "Strong" if float(raw_eng) >= 60.0 else "Weak"
    else:
        eng_cat = str(raw_eng).strip().capitalize()

    # 1. Careless Mistake
    careless_score = 0.10
    if time_cat == "Low" and conf_cat == "High" and changes_cat in ("None", "Occasional"):
        careless_score = 0.88
    elif time_cat == "Low" and conf_cat == "Normal":
        careless_score = 0.65

    # 2. Time Pressure
    time_pressure_score = 0.10
    if time_cat == "High" or changes_cat == "Frequent":
        time_pressure_score = 0.80 if conf_cat == "Low" else 0.70
    elif changes_cat == "Occasional" and conf_cat == "Low":
        time_pressure_score = 0.55

    # 3. Language Barrier
    language_barrier_score = 0.10
    if eng_cat == "Weak" and lang_pref == "Odia":
        language_barrier_score = 0.85
    elif eng_cat == "Weak":
        language_barrier_score = 0.65

    # 4. Prerequisite Gap
    prereq_score = 0.15
    if prev_cat == "Weak" and concept_cat == "Understood":
        prereq_score = 0.80
    elif prev_cat == "Weak":
        prereq_score = 0.60

    # 5. Conceptual Misunderstanding
    concept_score = 0.20
    if concept_cat == "Weak":
        concept_score = 0.85 if prev_cat == "Weak" else 0.78
    elif prev_cat == "Weak":
        concept_score = 0.50

    candidates = [
        CandidateHypothesis(
            hypothesis="careless_mistake",
            score=round(max(0.0, min(1.0, careless_score)), 3),
            reason=f"Fast completion ({time_cat} time) with {conf_cat} confidence suggests oversight.",
            recommended_probe="untimed_retry",
        ),
        CandidateHypothesis(
            hypothesis="time_pressure",
            score=round(max(0.0, min(1.0, time_pressure_score)), 3),
            reason=f"Pacing strain detected ({time_cat} time, {changes_cat} answer changes) under test timing.",
            recommended_probe="untimed_retry",
        ),
        CandidateHypothesis(
            hypothesis="language_barrier",
            score=round(max(0.0, min(1.0, language_barrier_score)), 3),
            reason=f"English comprehension level ({eng_cat}) with {lang_pref} preference indicates struggle with English terms.",
            recommended_probe="language_probe",
        ),
        CandidateHypothesis(
            hypothesis="prerequisite_gap",
            score=round(max(0.0, min(1.0, prereq_score)), 3),
            reason=f"Historical performance ({prev_cat}) points to underlying prerequisite concept gaps.",
            recommended_probe="prerequisite_probe",
        ),
        CandidateHypothesis(
            hypothesis="conceptual_misunderstanding",
            score=round(max(0.0, min(1.0, concept_score)), 3),
            reason=f"Concept grasp ({concept_cat}) suggests a core misconception in this chapter.",
            recommended_probe="transfer_probe",
        ),
    ]

    candidates.sort(key=lambda h: (-h.score, h.hypothesis))
    return candidates


def calculate_evidence_confidence(
    probe_type: str,
    is_probe_successful: bool,
    target_hypothesis: str,
    is_top_hypothesis: bool,
    previous_performance: float = 50.0,
    probe_time_sec: float = 20.0,
    expected_probe_time_sec: int = 30,
) -> float:
    """Calculates deterministic evidence confidence from student's probe response.

    Formula:
      confidence = (0.45 * base) + (0.30 * match) + (0.12 * history) + (0.08 * speed)
      diagnosis supported if confidence >= 0.75.
    """
    # 1. Base Score (0.45 weight): does probe outcome confirm or refute hypothesis?
    # - language_probe: success confirms the student understands once language is simplified
    # - untimed_retry: success confirms time pressure / careless mistake
    # - prerequisite_probe: failure confirms a prerequisite gap; success refutes it
    # - transfer_probe: failure confirms core concept gap; success refutes it
    # - explain_back: success/failure directly reflects grasp
    if probe_type == "language_probe":
        base = 1.0 if is_probe_successful else 0.25
    elif probe_type == "untimed_retry":
        base = 1.0 if is_probe_successful else 0.20
    elif probe_type == "prerequisite_probe":
        # If student fails the prerequisite probe, it confirms prerequisite gap!
        base = 1.0 if not is_probe_successful else 0.20
    elif probe_type == "transfer_probe":
        # If student fails the transfer probe, it confirms conceptual misunderstanding!
        base = 0.95 if not is_probe_successful else 0.25
    else:  # explain_back or general
        base = 0.90 if is_probe_successful else 0.40

    # 2. Match Score (0.30 weight): probe aligns with top-ranked hypothesis
    match = 1.0 if is_top_hypothesis else 0.65

    # 3. History Score (0.12 weight): historical performance alignment
    if isinstance(previous_performance, str):
        history = 0.85 if previous_performance.strip().lower() == "weak" else 0.60
    else:
        p = clamp_score(previous_performance)
        history = 0.85 if p < 60.0 else 0.60

    # 4. Speed Score (0.08 weight): response pace within expectations
    exp = max(10, expected_probe_time_sec)
    if probe_time_sec <= exp:
        speed = 1.0
    else:
        speed = max(0.20, 1.0 - ((probe_time_sec - exp) / exp))

    raw_conf = (0.45 * base) + (0.30 * match) + (0.12 * history) + (0.08 * speed)
    return round(max(0.0, min(1.0, raw_conf)), 2)
