import pytest
from app.services.mastery_service import (
    clamp_score,
    compute_overall_mastery,
    is_chapter_completed,
    map_english_exposure_level,
)


def test_clamp_score():
    assert clamp_score(-10.5) == 0.0
    assert clamp_score(0.0) == 0.0
    assert clamp_score(55.5) == 55.5
    assert clamp_score(100.0) == 100.0
    assert clamp_score(125.0) == 100.0


def test_compute_overall_mastery():
    # 0.30 * 80 + 0.20 * 70 + 0.15 * 60 + 0.15 * 50 + 0.10 * 40 + 0.10 * 30
    # = 24.0 + 14.0 + 9.0 + 7.5 + 4.0 + 3.0 = 61.5
    mastery = compute_overall_mastery(
        concept_understanding=80.0,
        previous_performance_score=70.0,
        prerequisite_understanding=60.0,
        english_comprehension=50.0,
        time_management=40.0,
        confidence_level=30.0,
    )
    assert mastery == 61.5

    # Out of bounds clamping check
    max_mastery = compute_overall_mastery(
        concept_understanding=150.0,
        previous_performance_score=150.0,
        prerequisite_understanding=150.0,
        english_comprehension=150.0,
        time_management=150.0,
        confidence_level=150.0,
    )
    assert max_mastery == 100.0

    min_mastery = compute_overall_mastery(-10, -20, -30, -40, -50, -60)
    assert min_mastery == 0.0


def test_map_english_exposure_level_continuous():
    # Continuous <= thresholds:
    # <= 45.0 -> 1
    assert map_english_exposure_level(-5.0) == 1
    assert map_english_exposure_level(0.0) == 1
    assert map_english_exposure_level(45.0) == 1

    # <= 65.0 -> 2 (including edge floats like 45.05)
    assert map_english_exposure_level(45.05) == 2
    assert map_english_exposure_level(50.0) == 2
    assert map_english_exposure_level(65.0) == 2

    # <= 82.0 -> 3 (including 65.01)
    assert map_english_exposure_level(65.01) == 3
    assert map_english_exposure_level(75.0) == 3
    assert map_english_exposure_level(82.0) == 3

    # > 82.0 -> 4
    assert map_english_exposure_level(82.01) == 4
    assert map_english_exposure_level(90.0) == 4
    assert map_english_exposure_level(100.0) == 4
    assert map_english_exposure_level(110.0) == 4


def test_is_chapter_completed():
    assert is_chapter_completed(74.99) is False
    assert is_chapter_completed(75.0) is True
    assert is_chapter_completed(85.5) is True
    assert is_chapter_completed(100.0) is True
