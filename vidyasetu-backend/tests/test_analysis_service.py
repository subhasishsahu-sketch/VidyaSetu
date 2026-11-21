"""Tests for deterministic 7-parameter behavioral analyzer and hypothesis ranker."""

import pytest
from app.services.analysis_service import (
    build_7parameter_snapshot,
    calculate_evidence_confidence,
    rank_hypotheses,
)


def test_build_7parameter_snapshot_clamping():
    snapshot = build_7parameter_snapshot(
        attempt_time_sec=-5.0,
        confidence_rating=150.0,
        answer_changes_count=-2,
        student_preferred_language="odia",
        concept_understanding=-10.0,
        previous_performance=110.0,
        english_comprehension=55.5,
    )
    assert snapshot["time_taken"] == "Low"
    assert snapshot["confidence_level"] == "High"
    assert snapshot["answer_changes"] == "None"
    assert snapshot["language_preference"] == "Odia"
    assert snapshot["concept_understanding"] == "Weak"
    assert snapshot["previous_performance"] == "Strong"
    assert snapshot["english_comprehension"] == "Weak"


def test_rank_hypotheses_careless_mistake():
    snapshot = {
        "time_taken": 15.0,
        "confidence_level": 85.0,
        "answer_changes": 0,
        "language_preference": "Odia",
        "concept_understanding": 70.0,
        "previous_performance": 75.0,
        "english_comprehension": 70.0,
    }
    hypotheses = rank_hypotheses(snapshot, expected_time_sec=60)
    assert len(hypotheses) == 5
    top = hypotheses[0]
    assert top.hypothesis == "careless_mistake"
    assert top.recommended_probe == "untimed_retry"
    assert top.score >= 0.75


def test_rank_hypotheses_language_barrier():
    snapshot = {
        "time_taken": 40.0,
        "confidence_level": 40.0,
        "answer_changes": 1,
        "language_preference": "Odia",
        "concept_understanding": 60.0,
        "previous_performance": 60.0,
        "english_comprehension": 35.0,
    }
    hypotheses = rank_hypotheses(snapshot, expected_time_sec=60)
    top = hypotheses[0]
    assert top.hypothesis == "language_barrier"
    assert top.recommended_probe == "language_probe"
    assert top.score >= 0.80


def test_rank_hypotheses_time_pressure():
    snapshot = {
        "time_taken": 95.0,
        "confidence_level": 35.0,
        "answer_changes": 3,
        "language_preference": "English",
        "concept_understanding": 65.0,
        "previous_performance": 65.0,
        "english_comprehension": 75.0,
    }
    hypotheses = rank_hypotheses(snapshot, expected_time_sec=60)
    top = hypotheses[0]
    assert top.hypothesis == "time_pressure"
    assert top.recommended_probe == "untimed_retry"
    assert top.score >= 0.70


def test_rank_hypotheses_prerequisite_gap():
    snapshot = {
        "time_taken": 45.0,
        "confidence_level": 50.0,
        "answer_changes": 1,
        "language_preference": "English",
        "concept_understanding": 60.0,
        "previous_performance": 30.0,
        "english_comprehension": 70.0,
    }
    hypotheses = rank_hypotheses(snapshot, expected_time_sec=60)
    top = hypotheses[0]
    assert top.hypothesis == "prerequisite_gap"
    assert top.recommended_probe == "prerequisite_probe"


def test_rank_hypotheses_conceptual_misunderstanding():
    snapshot = {
        "time_taken": 55.0,
        "confidence_level": 50.0,
        "answer_changes": 0,
        "language_preference": "English",
        "concept_understanding": 25.0,
        "previous_performance": 35.0,
        "english_comprehension": 70.0,
    }
    hypotheses = rank_hypotheses(snapshot, expected_time_sec=60)
    top = hypotheses[0]
    assert top.hypothesis == "conceptual_misunderstanding"
    assert top.recommended_probe == "transfer_probe"


def test_calculate_evidence_confidence_supported():
    # Successful language probe confirming language barrier
    conf = calculate_evidence_confidence(
        probe_type="language_probe",
        is_probe_successful=True,
        target_hypothesis="language_barrier",
        is_top_hypothesis=True,
        previous_performance=50.0,
        probe_time_sec=15.0,
        expected_probe_time_sec=30,
    )
    # 0.45 * 1.0 + 0.30 * 1.0 + 0.12 * 0.85 + 0.08 * 1.0 = 0.45 + 0.30 + 0.102 + 0.08 = 0.932 -> 0.93
    assert conf >= 0.75
    assert conf == pytest.approx(0.93, abs=0.02)


def test_calculate_evidence_confidence_unsupported():
    # Failed language probe refuting that language was the sole issue
    conf = calculate_evidence_confidence(
        probe_type="language_probe",
        is_probe_successful=False,
        target_hypothesis="language_barrier",
        is_top_hypothesis=False,
        previous_performance=70.0,
        probe_time_sec=50.0,
        expected_probe_time_sec=30,
    )
    # 0.45 * 0.25 + 0.30 * 0.65 + 0.12 * 0.60 + 0.08 * 0.333 < 0.75
    assert conf < 0.75
