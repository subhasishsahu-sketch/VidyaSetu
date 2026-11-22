import 'dart:async';
import 'package:uuid/uuid.dart';

import '../models/student_model.dart';
import '../models/progress_model.dart';
import '../models/question_model.dart';
import '../models/diagnostic_model.dart';
import '../models/language_model.dart';
import '../models/offline_pack_model.dart';
import '../models/sync_batch_model.dart';
import '../../core/offline/local_database.dart';
import '../../core/offline/mastery_calculator.dart';
import '../../core/offline/behavioral_analyzer.dart';
import '../../core/offline/local_slm_engine.dart';
import 'vidyasetu_repository.dart';

/// Pure offline repository executing the Mark-Loss Autopsy on-device.
/// Persists local progress and enqueues lowercase UUID v4 sync events into pending_sync_queue.
class OfflineVidyaSetuRepository implements VidyaSetuRepository {
  final LocalDatabase localDb;
  final LocalSlmEngine slmEngine;
  final Uuid uuid;

  // In-memory active diagnostic sessions: analysisId -> active state
  final Map<String, _OfflineDiagnosticSession> _sessions = {};

  OfflineVidyaSetuRepository({
    required this.localDb,
    LocalSlmEngine? slmEngine,
    Uuid? uuid,
  })  : slmEngine = slmEngine ?? const GroundedFallbackSlmEngine(),
        uuid = uuid ?? const Uuid();

  @override
  Future<Map<String, dynamic>> checkHealth() async {
    return {
      'status': 'offline',
      'database': 'local_sqlite',
      'queue_count': localDb.getPendingQueueCount(),
    };
  }

  @override
  Future<StudentModel> registerStudent(StudentCreateRequest request) async {
    final studentId = uuid.v4().toLowerCase();
    final student = StudentModel(
      studentId: studentId,
      name: request.name,
      classGrade: request.classGrade,
      preferredLanguage: request.preferredLanguage,
      englishExposureLevel: request.englishExposureLevel,
      subject: request.subject,
      completedChapters: 0,
      createdAt: DateTime.now().toUtc(),
    );
    localDb.saveStudent(student);
    return student;
  }

  @override
  Future<StudentModel> getStudent(String studentId) async {
    final student = localDb.getStudent(studentId);
    if (student == null) {
      throw StateError('Student $studentId not found in local database');
    }
    return student;
  }

  @override
  Future<ProgressModel> updateProgress(
      String studentId, ProgressUpdateRequest request) async {
    final mastery = MasteryCalculator.computeOverallMastery(
      conceptUnderstanding: request.conceptUnderstanding,
      previousPerformanceScore: request.previousPerformanceScore,
      prerequisiteUnderstanding: request.prerequisiteUnderstanding,
      englishComprehension: request.englishComprehension,
      timeManagement: request.timeManagement,
      confidenceLevel: request.confidenceLevel,
    );

    final progress = ProgressModel(
      progressId: uuid.v4().toLowerCase(),
      studentId: studentId.toLowerCase(),
      chapterName: request.chapterName,
      conceptUnderstanding: request.conceptUnderstanding,
      englishComprehension: request.englishComprehension,
      prerequisiteUnderstanding: request.prerequisiteUnderstanding,
      timeManagement: request.timeManagement,
      confidenceLevel: request.confidenceLevel,
      previousPerformanceScore: request.previousPerformanceScore,
      overallMastery: mastery,
      lastUpdated: DateTime.now().toUtc(),
    );

    localDb.upsertProgress(progress);
    return progress;
  }

  @override
  Future<ProgressModel> getChapterProgress(
      String studentId, String chapterName) async {
    final progress = localDb.getChapterProgress(studentId, chapterName);
    if (progress == null) {
      throw StateError('Progress for chapter $chapterName not found locally');
    }
    return progress;
  }

  @override
  Future<List<ProgressModel>> getProgressList(String studentId) async {
    return localDb.getProgressList(studentId);
  }

  @override
  Future<List<QuestionModel>> getQuestions({
    String? subject,
    String? chapterName,
    String? conceptName,
  }) async {
    return localDb.getCachedQuestions(
      subject: subject,
      chapterName: chapterName,
      conceptName: conceptName,
    );
  }

  @override
  Future<QuestionModel> getQuestion(String questionId) async {
    final questions = localDb.getCachedQuestions();
    for (final q in questions) {
      if (q.questionId.toLowerCase() == questionId.trim().toLowerCase()) {
        return q;
      }
    }
    throw StateError('Question $questionId not found in local offline cache');
  }

  @override
  Future<AttemptResponse> submitAttempt(AttemptRequest request) async {
    final analysisId = uuid.v4().toLowerCase();
    final question = await getQuestion(request.questionId);

    final isCorrect = request.selectedOption.trim().toUpperCase() ==
        (question.correctAnswer ?? '').trim().toUpperCase();

    final attemptData = {
      'selected_option': request.selectedOption,
      'time_taken_sec': request.timeTakenSec,
      'answer_changes_count': request.answerChangesCount,
      'confidence_rating': request.confidenceRating,
      'is_correct': isCorrect,
    };

    final offlineCreatedAt = request.offlineCreatedAt ?? DateTime.now().toUtc();

    if (isCorrect) {
      // Correct attempt: record event and pass
      final event = OfflineSyncEvent(
        analysisId: analysisId,
        studentId: request.studentId,
        questionId: request.questionId,
        attemptData: attemptData,
        probeLoopEvidence: const [],
        studentParametersSnapshot: const StudentParametersSnapshot(),
        executionSource: 'edge_slm_offline_sync',
        offlineCreatedAt: offlineCreatedAt,
      );
      localDb.enqueueSyncEvent(event);

      return AttemptResponse(
        analysisId: analysisId,
        isCorrect: true,
        status: 'passed',
        candidateHypotheses: const [],
        selectedProbe: null,
      );
    }

    // Student answered incorrectly: start diagnostic session
    final student = localDb.getStudent(request.studentId);
    final progress = localDb.getChapterProgress(request.studentId, question.chapterName);

    final langPref = student?.preferredLanguage ?? 'Odia';
    final concept = progress?.conceptUnderstanding ?? 50.0;
    final prevPerf = progress?.previousPerformanceScore ?? 50.0;
    final eng = progress?.englishComprehension ?? 50.0;

    final snapshot = BehavioralAnalyzer.build7ParameterSnapshot(
      attemptTimeSec: request.timeTakenSec,
      confidenceRating: request.confidenceRating,
      answerChangesCount: request.answerChangesCount,
      studentPreferredLanguage: langPref,
      conceptUnderstanding: concept,
      previousPerformance: prevPerf,
      englishComprehension: eng,
      expectedTimeSec: question.expectedTimeSec,
    );

    final ranked = BehavioralAnalyzer.rankHypotheses(
      snapshot: snapshot,
      expectedTimeSec: question.expectedTimeSec,
    );

    final topHypo = ranked.first;
    final probesDict = question.diagnosticProbes.toJson();
    final probeKey = topHypo.recommendedProbe;
    final probeContent = (probesDict[probeKey] as Map<String, dynamic>?) ??
        (probesDict['untimed_retry'] as Map<String, dynamic>?) ??
        {};

    final selectedProbe = {'probe_type': probeKey, ...probeContent};

    // Save session in memory
    _sessions[analysisId] = _OfflineDiagnosticSession(
      analysisId: analysisId,
      studentId: request.studentId,
      question: question,
      attemptData: attemptData,
      snapshot: snapshot,
      rankedHypotheses: ranked,
      probeLoopEvidence: [],
      offlineCreatedAt: offlineCreatedAt,
    );

    return AttemptResponse(
      analysisId: analysisId,
      isCorrect: false,
      status: 'probe_required',
      candidateHypotheses: ranked,
      selectedProbe: selectedProbe,
    );
  }

  @override
  Future<ProbeResponseResult> submitProbeResponse(
      ProbeResponseRequest request) async {
    final session = _sessions[request.analysisId];
    if (session == null) {
      throw StateError('Active diagnostic session ${request.analysisId} not found');
    }

    final question = session.question;
    final probesDict = question.diagnosticProbes.toJson();
    final probeData = (probesDict[request.probeType] as Map<String, dynamic>?) ?? {};

    final probeCorrectKey = probeData['correct_answer'] ??
        probeData['answer_key'] ??
        question.correctAnswer ??
        '';

    final isSuccess = request.submittedAnswer.trim().toUpperCase() ==
        probeCorrectKey.toString().trim().toUpperCase();

    final topHypo = session.rankedHypotheses.first;
    final isTop = topHypo.recommendedProbe == request.probeType;

    final confidence = BehavioralAnalyzer.calculateEvidenceConfidence(
      probeType: request.probeType,
      isProbeSuccessful: isSuccess,
      targetHypothesis: topHypo.hypothesis,
      isTopHypothesis: isTop,
      previousPerformance: session.snapshot.previousPerformance,
      probeTimeSec: request.timeTakenSec,
      expectedProbeTimeSec: 30,
    );

    final evidenceItem = {
      'probe_type': request.probeType,
      'submitted_answer': request.submittedAnswer,
      'time_taken_sec': request.timeTakenSec,
      'is_correct': isSuccess,
      'confidence_score': confidence,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };
    session.probeLoopEvidence.add(evidenceItem);

    final totalProbes = session.probeLoopEvidence.length;
    final isSupported = confidence >= 0.75;
    final shouldConclude = isSupported || totalProbes >= 2;

    if (!shouldConclude) {
      // Pick next probe from remaining hypotheses
      final probesTried = session.probeLoopEvidence.map((e) => e['probe_type']).toSet();
      Map<String, dynamic>? nextProbe;
      for (final hypo in session.rankedHypotheses) {
        if (!probesTried.contains(hypo.recommendedProbe) && probesDict.containsKey(hypo.recommendedProbe)) {
          nextProbe = {
            'probe_type': hypo.recommendedProbe,
            ...(probesDict[hypo.recommendedProbe] as Map<String, dynamic>),
          };
          break;
        }
      }
      nextProbe ??= {
        'probe_type': 'explain_back',
        ...(probesDict['explain_back'] as Map<String, dynamic>? ?? {}),
      };

      return ProbeResponseResult(
        analysisId: request.analysisId,
        status: 'probe_required',
        confidenceScore: confidence,
        selectedProbe: nextProbe,
      );
    }

    // Diagnosis confirmed!
    var confirmedHypo = isSupported ? topHypo.hypothesis : 'conceptual_misunderstanding';
    session.confirmedHypothesis = confirmedHypo;
    session.confidenceScore = confidence;

    // Search textbook chunk via FTS5 or fallback
    final ftsChunk = localDb.queryOfflineFtsChunk(
      question.questionText,
      subject: question.subject,
      chapterName: question.chapterName,
    );

    final chunkText = ftsChunk != null
        ? (ftsChunk['chunk_text'] ?? question.questionText).toString()
        : question.questionText;

    final student = localDb.getStudent(session.studentId);
    final exposureLevel = student?.englishExposureLevel ?? 1;

    final intervention = await slmEngine.generateIntervention(
      chunkText: chunkText,
      importantEnglishTerms: const [],
      groundedReference: GroundedReference(
        textbookName: 'BSE Odisha Curriculum',
        chapterNo: 1,
        sectionHeading: question.conceptName.toString(),
      ),
      studentEnglishLevel: exposureLevel,
      misconception: confirmedHypo,
      questionText: question.questionText,
    );
    session.intervention = intervention;

    RecoveryPracticeQuestionModel? recoveryPublic;
    if (question.recoveryPracticeQuestions.isNotEmpty) {
      final rec = question.recoveryPracticeQuestions.first;
      recoveryPublic = RecoveryPracticeQuestionModel(
        practiceId: rec.practiceId,
        questionText: rec.questionText,
        options: rec.options,
        // answerKey strictly omitted
      );
    }

    // Enqueue offline sync event into pending_sync_queue
    final syncEvent = OfflineSyncEvent(
      analysisId: session.analysisId,
      studentId: session.studentId,
      questionId: question.questionId,
      attemptData: session.attemptData,
      probeLoopEvidence: session.probeLoopEvidence,
      studentParametersSnapshot: session.snapshot,
      interventionAndLanguageOutput: intervention.toJson(),
      recoveryAssessment: null,
      executionSource: 'edge_slm_offline_sync',
      offlineCreatedAt: session.offlineCreatedAt,
    );
    localDb.enqueueSyncEvent(syncEvent);

    return ProbeResponseResult(
      analysisId: session.analysisId,
      status: 'diagnosis_confirmed',
      confirmedHypothesis: confirmedHypo,
      confidenceScore: confidence,
      intervention: intervention,
      recoveryPracticeQuestion: recoveryPublic,
    );
  }

  @override
  Future<RecoverySubmitResponse> submitRecovery(
      RecoverySubmitRequest request) async {
    final session = _sessions[request.analysisId];
    if (session == null) {
      throw StateError('Active diagnostic session ${request.analysisId} not found');
    }

    final question = session.question;
    RecoveryPracticeQuestionModel? targetRec;
    for (final rec in question.recoveryPracticeQuestions) {
      if (rec.practiceId == request.practiceId) {
        targetRec = rec;
        break;
      }
    }

    if (targetRec == null) {
      throw StateError('Recovery question ${request.practiceId} not found');
    }

    final isCorrect = request.submittedAnswer.trim().toUpperCase() ==
        (targetRec.answerKey ?? '').trim().toUpperCase();

    // Load current progress
    final currentProgress = localDb.getChapterProgress(
          session.studentId,
          question.chapterName,
        ) ??
        ProgressModel(
          progressId: uuid.v4().toLowerCase(),
          studentId: session.studentId,
          chapterName: question.chapterName,
          conceptUnderstanding: 50.0,
          englishComprehension: 50.0,
          prerequisiteUnderstanding: 50.0,
          timeManagement: 50.0,
          confidenceLevel: 50.0,
          previousPerformanceScore: 50.0,
          overallMastery: 50.0,
          lastUpdated: DateTime.now().toUtc(),
        );

    final rootCause = session.confirmedHypothesis ?? 'conceptual_misunderstanding';

    Map<String, double> boosted;
    if (isCorrect) {
      boosted = MasteryCalculator.applyRecoveryBoost(
        currConcept: currentProgress.conceptUnderstanding,
        currPrev: currentProgress.previousPerformanceScore,
        currPrereq: currentProgress.prerequisiteUnderstanding,
        currEng: currentProgress.englishComprehension,
        currTime: currentProgress.timeManagement,
        currConf: currentProgress.confidenceLevel,
        rootCause: rootCause,
      );
    } else {
      boosted = {
        'concept_understanding': currentProgress.conceptUnderstanding,
        'previous_performance_score': currentProgress.previousPerformanceScore,
        'prerequisite_understanding': currentProgress.prerequisiteUnderstanding,
        'english_comprehension': currentProgress.englishComprehension,
        'time_management': currentProgress.timeManagement,
        'confidence_level': currentProgress.confidenceLevel,
      };
    }

    final newMastery = MasteryCalculator.computeOverallMastery(
      conceptUnderstanding: boosted['concept_understanding']!,
      previousPerformanceScore: boosted['previous_performance_score']!,
      prerequisiteUnderstanding: boosted['prerequisite_understanding']!,
      englishComprehension: boosted['english_comprehension']!,
      timeManagement: boosted['time_management']!,
      confidenceLevel: boosted['confidence_level']!,
    );

    final updatedProgress = currentProgress.copyWith(
      conceptUnderstanding: boosted['concept_understanding'],
      previousPerformanceScore: boosted['previous_performance_score'],
      prerequisiteUnderstanding: boosted['prerequisite_understanding'],
      englishComprehension: boosted['english_comprehension'],
      timeManagement: boosted['time_management'],
      confidenceLevel: boosted['confidence_level'],
      overallMastery: newMastery,
      lastUpdated: DateTime.now().toUtc(),
    );
    localDb.upsertProgress(updatedProgress);

    final nextTask = MasteryCalculator.buildRecommendedNextTask(
      studentId: session.studentId,
      subject: question.subject,
      chapterName: question.chapterName,
      conceptName: question.conceptName.toString(),
      rootCause: rootCause,
      overallMastery: newMastery,
    );

    final student = localDb.getStudent(session.studentId);
    if (student != null) {
      localDb.saveStudent(student.copyWith(recommendedNextTask: nextTask));
    }

    // Update queued sync event with recovery assessment
    final recoveryAssessment = {
      'practice_id': request.practiceId,
      'submitted_answer': request.submittedAnswer,
      'is_correct': isCorrect,
      'has_student_improved': isCorrect,
      'recorded_at': DateTime.now().toUtc().toIso8601String(),
    };

    final finalSyncEvent = OfflineSyncEvent(
      analysisId: session.analysisId,
      studentId: session.studentId,
      questionId: question.questionId,
      attemptData: session.attemptData,
      probeLoopEvidence: session.probeLoopEvidence,
      studentParametersSnapshot: session.snapshot,
      interventionAndLanguageOutput: session.intervention?.toJson(),
      recoveryAssessment: recoveryAssessment,
      executionSource: 'edge_slm_offline_sync',
      offlineCreatedAt: session.offlineCreatedAt,
    );
    localDb.enqueueSyncEvent(finalSyncEvent);

    return RecoverySubmitResponse(
      analysisId: session.analysisId,
      isCorrect: isCorrect,
      hasStudentImproved: isCorrect,
      updatedScores: {
        'concept_understanding': boosted['concept_understanding']!,
        'english_comprehension': boosted['english_comprehension']!,
        'time_management': boosted['time_management']!,
        'prerequisite_understanding': boosted['prerequisite_understanding']!,
        'confidence_level': boosted['confidence_level']!,
        'overall_mastery': newMastery,
      },
      recommendedNextTask: nextTask,
    );
  }

  @override
  Future<LanguageExplainResponse> explainConcept(
      LanguageExplainRequest request) async {
    final intervention = await slmEngine.generateIntervention(
      chunkText: request.text,
      importantEnglishTerms: const [],
      groundedReference: GroundedReference(
        textbookName: 'BSE Odisha Curriculum',
        chapterNo: 1,
        sectionHeading: request.chapterName ?? 'Core Concept',
      ),
      studentEnglishLevel: request.targetLevel ?? 1,
      misconception: 'General Inquiry',
      questionText: request.text,
    );

    return LanguageExplainResponse(
      bilingualExplanationOdiaEnglish: intervention.bilingualExplanationOdiaEnglish,
      pureOdiaExplanation: intervention.pureOdiaExplanation,
      pureEnglishExplanation: intervention.pureEnglishExplanation,
      englishTermsWithOdiaMeanings: intervention.englishTermsWithOdiaMeanings,
      groundedTextbookReference: intervention.groundedTextbookReference,
      recordedEnglishExposureLevel: intervention.recordedEnglishExposureLevel,
    );
  }

  @override
  Future<LanguageProgressResponse> getLanguageProgress(String studentId) async {
    final student = localDb.getStudent(studentId);
    final allProg = localDb.getProgressList(studentId);

    double meanEng = 50.0;
    int level = student?.englishExposureLevel ?? 1;
    if (allProg.isNotEmpty) {
      meanEng = allProg.map((p) => p.englishComprehension).reduce((a, b) => a + b) / allProg.length;
      level = MasteryCalculator.mapEnglishExposureLevel(meanEng);
    }

    return LanguageProgressResponse(
      studentId: studentId,
      englishExposureLevel: level,
      meanEnglishComprehension: double.parse(meanEng.toStringAsFixed(2)),
      totalChaptersTracked: allProg.length,
      languageProficiencyBand: 'Level $level: Odia-Medium Support',
    );
  }

  @override
  Future<OfflinePackModel> downloadOfflinePack(
      OfflinePackRequest request) async {
    final cached = localDb.getCachedOfflinePack(request.subject, request.chapterName);
    if (cached != null) return cached;
    throw StateError('Offline pack for ${request.subject} / ${request.chapterName} not found');
  }

  @override
  Future<OfflineSyncBatchResponse> syncPendingOfflineEvents({String? studentId}) async {
    // In offline mode, no sync occurs
    return const OfflineSyncBatchResponse();
  }
}

class _OfflineDiagnosticSession {
  final String analysisId;
  final String studentId;
  final QuestionModel question;
  final Map<String, dynamic> attemptData;
  final StudentParametersSnapshot snapshot;
  final List<CandidateHypothesis> rankedHypotheses;
  final List<Map<String, dynamic>> probeLoopEvidence;
  final DateTime offlineCreatedAt;

  String? confirmedHypothesis;
  double? confidenceScore;
  InterventionOutput? intervention;

  _OfflineDiagnosticSession({
    required this.analysisId,
    required this.studentId,
    required this.question,
    required this.attemptData,
    required this.snapshot,
    required this.rankedHypotheses,
    required this.probeLoopEvidence,
    required this.offlineCreatedAt,
  });
}
