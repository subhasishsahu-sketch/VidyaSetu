"""Weighted overall mastery.

TEMPORARY PLACEHOLDER: the project spec says overall_mastery is a *weighted* score
but does not define the weights. Equal weights are used below only so the code runs.
Get the real weights from the WHY Engine / backend owner, then edit MASTERY_WEIGHTS
(and document the formula).
"""
from __future__ import annotations

from typing import Mapping

from app.validators.student_progress import INPUT_SCORE_FIELDS

MASTERY_WEIGHTS: dict[str, float] = {field: 1.0 for field in INPUT_SCORE_FIELDS}  # TODO: confirm


def compute_overall_mastery(progress: Mapping[str, float]) -> float:
    total_weight = sum(MASTERY_WEIGHTS.values())
    weighted = sum(float(progress[f]) * w for f, w in MASTERY_WEIGHTS.items())
    return round(weighted / total_weight, 2)
