"""Stateful LangGraph WHY Engine orchestrating the 3 diagnostic steps."""

import logging
import uuid
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from typing_extensions import TypedDict
from langgraph.graph import END, StateGraph

from app.repositories import (
    diagnostics_repository,
    progress_repository,
    questions_repository,
    rag_repository,
    students_repository,
)
from app.schemas.diagnostic_schema import (
    AttemptRequest,
    AttemptResponse,
    CandidateHypothesis,
    DiagnosticAnalysisDocument,
    ProbeResponseRequest,
    ProbeResponseResult,
    RecoverySubmitRequest,
    RecoverySubmitResponse,
)
from app.schemas.question_schema import QuestionInternal, RecoveryPracticeQuestionPublic
from app.services import analysis_service, language_service, mastery_service

logger = logging.getLogger(__name__)


class WhyEngineState(TypedDict, total=False):
    """Unified state schema for the LangGraph WHY Engine."""

    step: str  # "attempt" | "probe_response" | "recovery"
    db: Any

    # Input requests
    attempt_request: Optional[AttemptRequest]
    probe_request: Optional[ProbeResponseRequest]
    recovery_request: Optional[RecoverySubmitRequest]

    # Output responses
    attempt_result: Optional[AttemptResponse]
    probe_result: Optional[ProbeResponseResult]
    recovery_result: Optional[RecoverySubmitResponse]


async def node_attempt(state: WhyEngineState) -> Dict[str, Any]:
    """Step A: Grades initial answer, builds 7-parameter snapshot, ranks hypotheses, selects probe."""
    db = state["db"]
    req = state["attempt_request"]
    if not req:
        raise ValueError("attempt_request missing in state")

    analysis_id = str(uuid.uuid4()).lower()

    # 1. Load internal question document
    question_doc = await questions_repository.get_question_by_id_internal(db, req.question_id)
    if not question_doc:
        raise ValueError(f"Question {req.question_id} not found")
    question = QuestionInternal(**question_doc)

    # 2. Check if initial attempt is correct
    is_correct = (req.selected_option.strip().upper() == question.correct_answer.strip().upper())

    attempt_data = {
        "selected_option": req.selected_option,
        "time_taken_sec": req.time_taken_sec,
        "answer_changes_count": req.answer_changes_count,
        "confidence_rating": req.confidence_rating,
        "is_correct": is_correct,
    }

    if is_correct:
        # Student answered correctly - no diagnostic intervention needed
        doc = DiagnosticAnalysisDocument(
            _id=analysis_id,
            analysis_id=analysis_id,
            student_id=req.student_id,
            question_id=req.question_id,
            attempt_data=attempt_data,
            probe_loop_evidence=[],
            student_parameters_snapshot={},
            execution_source="cloud_gemini",
            created_at=datetime.now(timezone.utc),
            offline_created_at=req.offline_created_at,
        )
        await diagnostics_repository.create_diagnostic_record(db, doc)

        res = AttemptResponse(
            analysis_id=analysis_id,
            is_correct=True,
            status="passed",
            candidate_hypotheses=[],
            selected_probe=None,
        )
        return {"attempt_result": res}

    # 3. Student answered incorrectly - load profile and chapter progress
    student_doc = await students_repository.get_student_by_id(db, req.student_id)
    progress_doc = await progress_repository.get_chapter_progress(
        db, req.student_id, question.chapter_name
    )

    lang_pref = student_doc.get("preferred_language", "Odia") if student_doc else "Odia"
    concept = float(progress_doc.get("concept_understanding", 50.0)) if progress_doc else 50.0
    prev_perf = float(progress_doc.get("previous_performance_score", 50.0)) if progress_doc else 50.0
    english = float(progress_doc.get("english_comprehension", 50.0)) if progress_doc else 50.0

    # 4. Build deterministic 7-parameter snapshot
    snapshot = analysis_service.build_7parameter_snapshot(
        attempt_time_sec=req.time_taken_sec,
        confidence_rating=req.confidence_rating,
        answer_changes_count=req.answer_changes_count,
        student_preferred_language=lang_pref,
        concept_understanding=concept,
        previous_performance=prev_perf,
        english_comprehension=english,
    )

    # 5. Rank root-cause hypotheses
    ranked_hypotheses = analysis_service.rank_hypotheses(
        snapshot, expected_time_sec=question.expected_time_sec
    )
    top_hypothesis = ranked_hypotheses[0]

    # 6. Select diagnostic probe matching top hypothesis
    probes_dict = question.diagnostic_probes.model_dump()
    probe_key = top_hypothesis.recommended_probe
    probe_content = probes_dict.get(probe_key) or probes_dict.get("untimed_retry") or {}
    selected_probe = {"probe_type": probe_key, **probe_content}

    # 7. Persist initial diagnostic event document in MongoDB
    doc = DiagnosticAnalysisDocument(
        _id=analysis_id,
        analysis_id=analysis_id,
        student_id=req.student_id,
        question_id=req.question_id,
        attempt_data=attempt_data,
        probe_loop_evidence=[],
        student_parameters_snapshot=snapshot,
        execution_source="cloud_gemini",
        created_at=datetime.now(timezone.utc),
        offline_created_at=req.offline_created_at,
    )
    await diagnostics_repository.create_diagnostic_record(db, doc)

    res = AttemptResponse(
        analysis_id=analysis_id,
        is_correct=False,
        status="probe_required",
        candidate_hypotheses=ranked_hypotheses,
        selected_probe=selected_probe,
    )
    return {"attempt_result": res}


async def node_probe_response(state: WhyEngineState) -> Dict[str, Any]:
    """Step B: Evaluates probe response, calculates confidence, routes to next probe or generates intervention."""
    db = state["db"]
    req = state["probe_request"]
    if not req:
        raise ValueError("probe_request missing in state")

    record = await diagnostics_repository.get_diagnostic_record(db, req.analysis_id)
    if not record:
        raise ValueError(f"Diagnostic record {req.analysis_id} not found")

    question_doc = await questions_repository.get_question_by_id_internal(db, record["question_id"])
    if not question_doc:
        raise ValueError(f"Question {record['question_id']} not found")
    question = QuestionInternal(**question_doc)

    probes_dict = question.diagnostic_probes.model_dump()
    probe_data = probes_dict.get(req.probe_type, {})

    # 1. Determine if probe answer was successful
    probe_correct_key = (
        probe_data.get("correct_answer")
        or probe_data.get("answer_key")
        or question.correct_answer
    )
    is_probe_successful = (
        req.submitted_answer.strip().upper() == str(probe_correct_key).strip().upper()
    )

    # 2. Check alignment with top candidate hypothesis
    raw_snapshot = record.get("student_parameters_snapshot", {})
    if hasattr(raw_snapshot, "model_dump"):
        snapshot = raw_snapshot.model_dump()
    elif isinstance(raw_snapshot, dict):
        snapshot = raw_snapshot
    else:
        snapshot = dict(raw_snapshot) if raw_snapshot else {}

    ranked_hypotheses = analysis_service.rank_hypotheses(snapshot, question.expected_time_sec)
    top_hypo = ranked_hypotheses[0] if ranked_hypotheses else None
    is_top = (top_hypo and top_hypo.recommended_probe == req.probe_type)

    # 3. Calculate evidence confidence
    prev_perf = snapshot.get("previous_performance", 50.0)
    confidence = analysis_service.calculate_evidence_confidence(
        probe_type=req.probe_type,
        is_probe_successful=is_probe_successful,
        target_hypothesis=top_hypo.hypothesis if top_hypo else "conceptual_misunderstanding",
        is_top_hypothesis=bool(is_top),
        previous_performance=prev_perf,
        probe_time_sec=req.time_taken_sec,
        expected_probe_time_sec=30,
    )

    evidence_item = {
        "probe_type": req.probe_type,
        "submitted_answer": req.submitted_answer,
        "time_taken_sec": req.time_taken_sec,
        "is_correct": is_probe_successful,
        "confidence_score": confidence,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }

    prior_evidence = record.get("probe_loop_evidence", [])
    total_probes_tried = len(prior_evidence) + 1
    is_diagnosis_supported = (confidence >= 0.75)
    should_conclude = is_diagnosis_supported or (total_probes_tried >= 2)

    if not should_conclude:
        # Choose next probe from remaining hypotheses
        probes_tried = {item.get("probe_type") for item in prior_evidence} | {req.probe_type}
        next_probe_content = None
        for hypo in ranked_hypotheses:
            if hypo.recommended_probe not in probes_tried and hypo.recommended_probe in probes_dict:
                next_probe_content = {
                    "probe_type": hypo.recommended_probe,
                    **probes_dict[hypo.recommended_probe],
                }
                break

        if not next_probe_content:
            next_probe_content = {
                "probe_type": "explain_back",
                **probes_dict.get("explain_back", {}),
            }

        await diagnostics_repository.append_probe_evidence(db, req.analysis_id, evidence_item)

        res = ProbeResponseResult(
            analysis_id=req.analysis_id,
            status="probe_required",
            confirmed_hypothesis=None,
            confidence_score=confidence,
            selected_probe=next_probe_content,
            intervention=None,
            recovery_practice_question=None,
        )
        return {"probe_result": res}

    # Diagnosis confirmed!
    confirmed_hypo_name = top_hypo.hypothesis if top_hypo else "conceptual_misunderstanding"
    if not is_diagnosis_supported and not is_probe_successful:
        confirmed_hypo_name = "conceptual_misunderstanding"

    # Retrieve grounded textbook chunk from rag_textbook_vectors
    chunks = await rag_repository.get_chunks_by_chapter(
        db, question.subject, question.chapter_name
    )
    if not chunks:
        chunks = await rag_repository.get_chunks_by_subject(db, question.subject)

    chunk_doc = chunks[0] if chunks else {
        "chunk_text": question.question_text,
        "important_english_terms": [],
        "grounded_reference": {
            "textbook_name": "BSE Odisha Curriculum",
            "chapter_no": 1,
            "section_heading": question.concept_name,
        },
    }

    # Calibrate student English exposure level
    student_doc = await students_repository.get_student_by_id(db, record["student_id"])
    exposure_level = int(student_doc.get("english_exposure_level", 1)) if student_doc else 1

    # Generate 3-Way Language Bridge intervention
    intervention = language_service.generate_intervention(
        chunk_doc=chunk_doc,
        student_english_level=exposure_level,
        misconception=confirmed_hypo_name,
        question_text=question.question_text,
    )

    # Attach 1st recovery practice question strictly omitting answer_key
    recovery_public = None
    if question.recovery_practice_questions:
        rec_internal = question.recovery_practice_questions[0]
        recovery_public = RecoveryPracticeQuestionPublic(
            practice_id=rec_internal.practice_id,
            question_text=rec_internal.question_text,
            options=rec_internal.options,
        )

    # Persist intervention and updated status in MongoDB
    updates = {
        "intervention_and_language_output": intervention.model_dump(),
        "confirmed_hypothesis": confirmed_hypo_name,
        "confidence_score": confidence,
    }
    await diagnostics_repository.append_probe_evidence(
        db, req.analysis_id, evidence_item, additional_updates=updates
    )

    res = ProbeResponseResult(
        analysis_id=req.analysis_id,
        status="diagnosis_confirmed",
        confirmed_hypothesis=confirmed_hypo_name,
        confidence_score=confidence,
        selected_probe=None,
        intervention=intervention,
        recovery_practice_question=recovery_public,
    )
    return {"probe_result": res}


async def node_recovery(state: WhyEngineState) -> Dict[str, Any]:
    """Step C: Grades recovery check against answer key, boosts mastery, syncs student progress."""
    db = state["db"]
    req = state["recovery_request"]
    if not req:
        raise ValueError("recovery_request missing in state")

    record = await diagnostics_repository.get_diagnostic_record(db, req.analysis_id)
    if not record:
        raise ValueError(f"Diagnostic record {req.analysis_id} not found")

    question_doc = await questions_repository.get_question_by_id_internal(db, record["question_id"])
    if not question_doc:
        raise ValueError(f"Question {record['question_id']} not found")
    question = QuestionInternal(**question_doc)

    # Locate matching recovery question
    target_rec = None
    for rec in question.recovery_practice_questions:
        if rec.practice_id == req.practice_id:
            target_rec = rec
            break

    if not target_rec:
        raise ValueError(
            f"Recovery question {req.practice_id} not found on question {question.question_id}"
        )

    is_correct = (req.submitted_answer.strip().upper() == target_rec.answer_key.strip().upper())
    has_improved = is_correct

    # Load chapter progress
    student_id = record["student_id"]
    progress_doc = await progress_repository.get_chapter_progress(
        db, student_id, question.chapter_name
    )

    curr_concept = float(progress_doc.get("concept_understanding", 50.0)) if progress_doc else 50.0
    curr_prev = float(progress_doc.get("previous_performance_score", 50.0)) if progress_doc else 50.0
    curr_prereq = float(progress_doc.get("prerequisite_understanding", 50.0)) if progress_doc else 50.0
    curr_eng = float(progress_doc.get("english_comprehension", 50.0)) if progress_doc else 50.0
    curr_time = float(progress_doc.get("time_management", 50.0)) if progress_doc else 50.0
    curr_conf = float(progress_doc.get("confidence_level", 50.0)) if progress_doc else 50.0

    root_cause = record.get("confirmed_hypothesis") or "conceptual_misunderstanding"

    if has_improved:
        boosted = mastery_service.apply_recovery_boost(
            curr_concept=curr_concept,
            curr_prev=curr_prev,
            curr_prereq=curr_prereq,
            curr_eng=curr_eng,
            curr_time=curr_time,
            curr_conf=curr_conf,
            root_cause=root_cause,
        )
    else:
        boosted = {
            "concept_understanding": curr_concept,
            "previous_performance_score": curr_prev,
            "prerequisite_understanding": curr_prereq,
            "english_comprehension": curr_eng,
            "time_management": curr_time,
            "confidence_level": curr_conf,
        }

    new_mastery = mastery_service.compute_overall_mastery(
        concept_understanding=boosted["concept_understanding"],
        previous_performance_score=boosted["previous_performance_score"],
        prerequisite_understanding=boosted["prerequisite_understanding"],
        english_comprehension=boosted["english_comprehension"],
        time_management=boosted["time_management"],
        confidence_level=boosted["confidence_level"],
    )

    # Persist updated chapter progress
    from app.schemas.progress_schema import ProgressUpdateRequest

    update_dto = ProgressUpdateRequest(
        chapter_name=question.chapter_name,
        concept_understanding=boosted["concept_understanding"],
        previous_performance_score=boosted["previous_performance_score"],
        prerequisite_understanding=boosted["prerequisite_understanding"],
        english_comprehension=boosted["english_comprehension"],
        time_management=boosted["time_management"],
        confidence_level=boosted["confidence_level"],
    )
    await progress_repository.upsert_progress(db, student_id, update_dto)
    await progress_repository.sync_student_aggregates(db, student_id)

    # Formulate next recommended task using shared builder
    recommended_task = mastery_service.build_recommended_next_task(
        student_id=student_id,
        subject=question.subject,
        chapter_name=question.chapter_name,
        concept_name=question.concept_name,
        root_cause=root_cause,
        overall_mastery=new_mastery,
    )
    await students_repository.update_student_profile(
        db, student_id, {"recommended_next_task": recommended_task}
    )

    # Record assessment in MongoDB
    recovery_assessment = {
        "practice_id": req.practice_id,
        "submitted_answer": req.submitted_answer,
        "is_correct": is_correct,
        "has_student_improved": has_improved,
        "recorded_at": datetime.now(timezone.utc).isoformat(),
    }
    await diagnostics_repository.update_diagnostic_record(
        db, req.analysis_id, {"recovery_assessment": recovery_assessment}
    )

    res = RecoverySubmitResponse(
        analysis_id=req.analysis_id,
        is_correct=is_correct,
        has_student_improved=has_improved,
        updated_scores={
            "concept_understanding": boosted["concept_understanding"],
            "english_comprehension": boosted["english_comprehension"],
            "time_management": boosted["time_management"],
            "prerequisite_understanding": boosted["prerequisite_understanding"],
            "confidence_level": boosted["confidence_level"],
            "overall_mastery": new_mastery,
        },
        recommended_next_task=recommended_task,
    )
    return {"recovery_result": res}


# Build LangGraph StateGraph
workflow = StateGraph(WhyEngineState)
workflow.add_node("attempt", node_attempt)
workflow.add_node("probe_response", node_probe_response)
workflow.add_node("recovery", node_recovery)

workflow.set_conditional_entry_point(
    lambda state: state["step"],
    {
        "attempt": "attempt",
        "probe_response": "probe_response",
        "recovery": "recovery",
    },
)
workflow.add_edge("attempt", END)
workflow.add_edge("probe_response", END)
workflow.add_edge("recovery", END)

why_engine_graph = workflow.compile()


async def run_why_engine_attempt(db: Any, req: AttemptRequest) -> AttemptResponse:
    """Executes Step A of the WHY Engine."""
    init_state: WhyEngineState = {
        "step": "attempt",
        "db": db,
        "attempt_request": req,
    }
    result_state = await why_engine_graph.ainvoke(init_state)
    return result_state["attempt_result"]


async def run_why_engine_probe_response(
    db: Any, req: ProbeResponseRequest
) -> ProbeResponseResult:
    """Executes Step B of the WHY Engine."""
    init_state: WhyEngineState = {
        "step": "probe_response",
        "db": db,
        "probe_request": req,
    }
    result_state = await why_engine_graph.ainvoke(init_state)
    return result_state["probe_result"]


async def run_why_engine_recovery(
    db: Any, req: RecoverySubmitRequest
) -> RecoverySubmitResponse:
    """Executes Step C of the WHY Engine."""
    init_state: WhyEngineState = {
        "step": "recovery",
        "db": db,
        "recovery_request": req,
    }
    result_state = await why_engine_graph.ainvoke(init_state)
    return result_state["recovery_result"]
