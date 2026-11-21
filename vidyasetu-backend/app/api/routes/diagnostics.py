"""Diagnostic endpoints orchestrating the WHY Engine."""

from fastapi import APIRouter, Depends, HTTPException, status
from app.agents.why_engine import (
    run_why_engine_attempt,
    run_why_engine_probe_response,
    run_why_engine_recovery,
)
from app.database.mongodb import get_database
from app.schemas.diagnostic_schema import (
    AttemptRequest,
    AttemptResponse,
    ProbeResponseRequest,
    ProbeResponseResult,
    RecoverySubmitRequest,
    RecoverySubmitResponse,
)

router = APIRouter(prefix="/diagnostics", tags=["WHY Engine Diagnostics"])


@router.post(
    "/attempt",
    response_model=AttemptResponse,
    status_code=status.HTTP_200_OK,
    summary="Submit question attempt telemetry",
)
async def submit_attempt(
    request: AttemptRequest,
    db=Depends(get_database),
):
    """Submits student question telemetry.

    If correct, marks attempt passed. If incorrect, triggers the deterministic 7-parameter
    analyzer, ranks hypotheses, and delivers the first targeted diagnostic probe.
    """
    try:
        return await run_why_engine_attempt(db, request)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc))
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Diagnostic attempt evaluation error: {str(exc)}",
        )


@router.post(
    "/probe-response",
    response_model=ProbeResponseResult,
    status_code=status.HTTP_200_OK,
    summary="Submit diagnostic probe response",
)
async def submit_probe_response(
    request: ProbeResponseRequest,
    db=Depends(get_database),
):
    """Submits student response to a diagnostic probe.

    Calculates evidence confidence. If diagnosis is confirmed (or 2 probes tried),
    returns the grounded 3-Way Language Bridge intervention and immediate recovery practice question.
    """
    try:
        return await run_why_engine_probe_response(db, request)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc))
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Diagnostic probe evaluation error: {str(exc)}",
        )


@router.post(
    "/recovery",
    response_model=RecoverySubmitResponse,
    status_code=status.HTTP_200_OK,
    summary="Submit recovery practice question answer",
)
async def submit_recovery(
    request: RecoverySubmitRequest,
    db=Depends(get_database),
):
    """Grades the immediate recovery practice attempt against the answer key.

    If successful, awards mastery metric boosts (+8.0 concept, +5.0 confidence),
    recalculates overall mastery, updates student progress, and recommends the next task.
    """
    try:
        return await run_why_engine_recovery(db, request)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc))
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Recovery evaluation error: {str(exc)}",
        )
