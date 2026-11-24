import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/telemetry_tracker.dart';
import '../data/mock/mock_data.dart';
import '../data/models/diagnostic_model.dart';
import '../data/models/question_model.dart';
import '../models/question.dart';
import '../models/diagnostic_result.dart';
import '../data/repositories/vidyasetu_repository.dart';
import 'locale_provider.dart';
import 'repository_provider.dart';
import 'student_profile_provider.dart';

class DiagnosticSessionState {
  final List<Question> questions;
  final int currentQuestionIndex;
  final String? selectedOptionId;
  final bool isSubmitted;
  final bool? isCorrect;
  final DiagnosticResult? whyResult;
  final AttemptResponse? attemptResponse;
  final ProbeResponseResult? probeResult;
  final RecoverySubmitResponse? recoveryResult;
  final Map<String, dynamic>? activeProbe;
  final String? selectedProbeOption;
  final RecoveryPracticeQuestionModel? recoveryQuestion;
  final String? selectedRecoveryOption;
  final Set<String> revisionQuestionIds;
  final bool isLoading;
  final bool isSubmittingProbe;
  final bool isSubmittingRecovery;
  final bool isSessionCompleted;
  final int correctAnswersCount;
  final String? currentChapterId;
  final String? error;

  const DiagnosticSessionState({
    this.questions = const [],
    this.currentQuestionIndex = 0,
    this.selectedOptionId,
    this.isSubmitted = false,
    this.isCorrect,
    this.whyResult,
    this.attemptResponse,
    this.probeResult,
    this.recoveryResult,
    this.activeProbe,
    this.selectedProbeOption,
    this.recoveryQuestion,
    this.selectedRecoveryOption,
    this.revisionQuestionIds = const {},
    this.isLoading = false,
    this.isSubmittingProbe = false,
    this.isSubmittingRecovery = false,
    this.isSessionCompleted = false,
    this.correctAnswersCount = 0,
    this.currentChapterId,
    this.error,
  });

  Question? get currentQuestion =>
      questions.isNotEmpty && currentQuestionIndex < questions.length
          ? questions[currentQuestionIndex]
          : null;

  DiagnosticSessionState copyWith({
    List<Question>? questions,
    int? currentQuestionIndex,
    String? selectedOptionId,
    bool? isSubmitted,
    bool? isCorrect,
    DiagnosticResult? whyResult,
    AttemptResponse? attemptResponse,
    ProbeResponseResult? probeResult,
    RecoverySubmitResponse? recoveryResult,
    Map<String, dynamic>? activeProbe,
    String? selectedProbeOption,
    RecoveryPracticeQuestionModel? recoveryQuestion,
    String? selectedRecoveryOption,
    Set<String>? revisionQuestionIds,
    bool? isLoading,
    bool? isSubmittingProbe,
    bool? isSubmittingRecovery,
    bool? isSessionCompleted,
    int? correctAnswersCount,
    String? currentChapterId,
    String? error,
  }) {
    return DiagnosticSessionState(
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      selectedOptionId: selectedOptionId ?? this.selectedOptionId,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      isCorrect: isCorrect ?? this.isCorrect,
      whyResult: whyResult ?? this.whyResult,
      attemptResponse: attemptResponse ?? this.attemptResponse,
      probeResult: probeResult ?? this.probeResult,
      recoveryResult: recoveryResult ?? this.recoveryResult,
      activeProbe: activeProbe ?? this.activeProbe,
      selectedProbeOption: selectedProbeOption ?? this.selectedProbeOption,
      recoveryQuestion: recoveryQuestion ?? this.recoveryQuestion,
      selectedRecoveryOption: selectedRecoveryOption ?? this.selectedRecoveryOption,
      revisionQuestionIds: revisionQuestionIds ?? this.revisionQuestionIds,
      isLoading: isLoading ?? this.isLoading,
      isSubmittingProbe: isSubmittingProbe ?? this.isSubmittingProbe,
      isSubmittingRecovery: isSubmittingRecovery ?? this.isSubmittingRecovery,
      isSessionCompleted: isSessionCompleted ?? this.isSessionCompleted,
      correctAnswersCount: correctAnswersCount ?? this.correctAnswersCount,
      currentChapterId: currentChapterId ?? this.currentChapterId,
      error: error,
    );
  }
}

class DiagnosticSessionNotifier extends StateNotifier<DiagnosticSessionState> {
  final VidyaSetuRepository _repository;
  final Ref _ref;
  final AttemptTelemetryTracker telemetry = AttemptTelemetryTracker();

  DiagnosticSessionNotifier(this._repository, this._ref)
      : super(const DiagnosticSessionState(isLoading: true)) {
    loadSession();
  }

  /// Loads the question series for the specified chapter, mapping repository models
  /// to UI question cards and defaulting gracefully to cached/mock questions.
  Future<void> loadSession({String? chapterId}) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      currentChapterId: chapterId,
      currentQuestionIndex: 0,
      selectedOptionId: null,
      isSubmitted: false,
      isCorrect: null,
      whyResult: null,
      attemptResponse: null,
      probeResult: null,
      recoveryResult: null,
      activeProbe: null,
      selectedProbeOption: null,
      recoveryQuestion: null,
      selectedRecoveryOption: null,
      isSessionCompleted: false,
      correctAnswersCount: 0,
    );

    List<Question> loadedQuestions = [];
    try {
      String? subjectFilter;
      String? chapterFilter;

      if (chapterId != null) {
        if (chapterId.startsWith('HIST')) {
          subjectFilter = 'History';
        } else if (chapterId.startsWith('PHYS') || chapterId.startsWith('BIO') || chapterId.startsWith('SCI')) {
          subjectFilter = 'Science';
        } else if (chapterId.startsWith('MATH')) {
          subjectFilter = 'Math';
        } else if (chapterId.startsWith('GEOG')) {
          subjectFilter = 'Geography';
        }
      }

      final repoQuestions = await _repository.getQuestions(
        subject: subjectFilter,
        chapterName: chapterFilter,
      );

      if (repoQuestions.isNotEmpty) {
        loadedQuestions = repoQuestions.asMap().entries.map((entry) {
          return Question.fromQuestionModel(
            entry.value,
            stepNumber: entry.key + 1,
            totalSteps: repoQuestions.length,
          );
        }).toList();
      }
    } catch (_) {}

    // Fallback to structured multi-question series if repository returns empty
    if (loadedQuestions.isEmpty) {
      final mockQs = await MockDataStore.getQuestions();
      loadedQuestions = mockQs;
    }

    state = state.copyWith(
      questions: loadedQuestions,
      currentQuestionIndex: 0,
      isLoading: false,
    );

    telemetry.startQuestion();
  }

  void selectOption(String optionId) {
    if (state.isSubmitted) return;
    telemetry.onOptionSelected(optionId);
    state = state.copyWith(selectedOptionId: optionId);
  }

  /// Step 1: Submits Question Attempt Telemetry to trigger WHY Engine.
  Future<void> submitAnswer() async {
    final currentQ = state.currentQuestion;
    if (currentQ == null || state.selectedOptionId == null) return;

    final studentProfile = _ref.read(studentProfileProvider).student;
    final studentId = studentProfile?.studentId ?? '9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d';
    final questionId = currentQ.id;

    final lang = _ref.read(localeProvider);
    final langPref = lang == AppLanguage.odia ? 'Odia' : 'English';

    AttemptResponse? attemptRes;
    String? submitError;
    try {
      attemptRes = await _repository.submitAttempt(
        AttemptRequest(
          studentId: studentId,
          questionId: questionId,
          selectedOption: state.selectedOptionId!,
          timeTakenSec: telemetry.elapsedSeconds.toDouble().clamp(5.0, 300.0),
          answerChangesCount: telemetry.optionChangeCount,
          confidenceRating: telemetry.inferredConfidence == 'low' ? 30.0 : 85.0,
        ),
      );
    } catch (e) {
      submitError = e.toString();
    }

    final isCorrect = attemptRes?.isCorrect ??
        (currentQ.correctOptionId.isNotEmpty &&
            state.selectedOptionId == currentQ.correctOptionId);

    if (isCorrect) {
      // Correct attempt: celebrate and allow advancing to next question without WHY drawer
      state = state.copyWith(
        isSubmitted: true,
        isCorrect: true,
        whyResult: null,
        attemptResponse: attemptRes,
        correctAnswersCount: state.correctAnswersCount + 1,
        error: submitError,
      );
      return;
    }

    // Incorrect attempt: Trigger WHY Engine loop
    final topHypo = (attemptRes != null && attemptRes.candidateHypotheses.isNotEmpty)
        ? attemptRes.candidateHypotheses.first
        : null;

    DiagnosticResult diag;
    if (topHypo != null) {
      diag = DiagnosticResult(
        questionId: questionId,
        diagnosisTitle: _formatHypothesisTitle(topHypo.hypothesis),
        diagnosisTitleOr: _formatHypothesisTitleOr(topHypo.hypothesis),
        certaintyPercent: (topHypo.score * 100).toInt(),
        sourceEngine: 'Causal Error Mapping • VidyaSetu Cognitive Engine',
        causalWhyTitle: 'କାହିଁକି ଏହି ଭୁଲ୍ ହେଲା? (Causal Why)',
        causalWhyEn: topHypo.reason,
        causalWhyOr: topHypo.reason,
        citation: 'BSE Odisha Curriculum Citation',
        dbStorageBadge: 'Diagnostics indexed locally in SQLite DB • Auto-saved',
      );
    } else {
      try {
        diag = await MockDataStore.getDiagnosticResult(questionId);
      } catch (_) {
        diag = const DiagnosticResult(
          questionId: 'DIAG_Q',
          diagnosisTitle: 'Conceptual Misunderstanding',
          diagnosisTitleOr: 'ଧାରଣାଗତ ଭ୍ରାନ୍ତି',
          certaintyPercent: 90,
          sourceEngine: 'Causal Error Mapping • VidyaSetu Cognitive Engine',
          causalWhyTitle: 'କାହିଁକି ଏହି ଭୁଲ୍ ହେଲା? (Causal Why)',
          causalWhyEn: 'Conceptual discrepancy detected in option selection.',
          causalWhyOr: 'ନିର୍ବାଚିତ ବିକଳ୍ପରେ ଧାରଣାଗତ ତ୍ରୁଟି ଦେଖାଦେଇଛି।',
          citation: 'BSE Odisha Standards Pg. 43',
          dbStorageBadge: 'Diagnostics indexed locally in SQLite DB • Auto-saved',
        );
      }
    }

    state = state.copyWith(
      isSubmitted: true,
      isCorrect: false,
      whyResult: diag,
      attemptResponse: attemptRes,
      activeProbe: attemptRes?.selectedProbe,
      error: submitError,
    );
  }

  /// Step 2: Submits student response to the active diagnostic probe.
  Future<void> submitProbeAnswer(String probeOption) async {
    final analysisId = state.attemptResponse?.analysisId;
    final probeType = state.activeProbe?['probe_type']?.toString() ?? 'terminology_distinction';

    state = state.copyWith(
      selectedProbeOption: probeOption,
      isSubmittingProbe: true,
      error: null,
    );

    if (analysisId == null) {
      state = state.copyWith(isSubmittingProbe: false);
      return;
    }

    try {
      final probeResult = await _repository.submitProbeResponse(
        ProbeResponseRequest(
          analysisId: analysisId,
          probeType: probeType,
          submittedAnswer: probeOption,
          timeTakenSec: 15.0,
        ),
      );

      DiagnosticResult? updatedWhy = state.whyResult;
      if (probeResult.confirmedHypothesis != null && updatedWhy != null) {
        final intervention = probeResult.intervention;
        final citationStr = intervention != null
            ? intervention.textbookCitation
            : updatedWhy.citation;

        updatedWhy = DiagnosticResult(
          questionId: updatedWhy.questionId,
          diagnosisTitle: _formatHypothesisTitle(probeResult.confirmedHypothesis!),
          diagnosisTitleOr: _formatHypothesisTitleOr(probeResult.confirmedHypothesis!),
          certaintyPercent: ((probeResult.confidenceScore ?? 0.94) * 100).toInt(),
          sourceEngine: updatedWhy.sourceEngine,
          causalWhyTitle: updatedWhy.causalWhyTitle,
          causalWhyEn: intervention?.pureEnglishExplanation ?? updatedWhy.causalWhyEn,
          causalWhyOr: intervention?.pureOdiaExplanation ?? updatedWhy.causalWhyOr,
          citation: citationStr,
          dbStorageBadge: updatedWhy.dbStorageBadge,
        );
      }

      state = state.copyWith(
        probeResult: probeResult,
        whyResult: updatedWhy,
        activeProbe: probeResult.selectedProbe,
        recoveryQuestion: probeResult.recoveryPracticeQuestion,
        isSubmittingProbe: false,
      );
    } catch (e) {
      state = state.copyWith(isSubmittingProbe: false, error: 'Probe submission failed: $e');
    }
  }

  /// Step 3: Submits student answer to immediate recovery practice question.
  Future<void> submitRecoveryAnswer(String recoveryOption) async {
    final analysisId = state.attemptResponse?.analysisId ?? state.probeResult?.analysisId;
    final recoveryQ = state.recoveryQuestion;

    state = state.copyWith(
      selectedRecoveryOption: recoveryOption,
      isSubmittingRecovery: true,
      error: null,
    );

    if (analysisId == null || recoveryQ == null) {
      state = state.copyWith(isSubmittingRecovery: false);
      return;
    }

    try {
      final recoveryRes = await _repository.submitRecovery(
        RecoverySubmitRequest(
          analysisId: analysisId,
          practiceId: recoveryQ.practiceId,
          submittedAnswer: recoveryOption,
        ),
      );

      // Refresh student progress profile
      _ref.read(studentProfileProvider.notifier).loadProfile();

      state = state.copyWith(
        recoveryResult: recoveryRes,
        isSubmittingRecovery: false,
      );
    } catch (e) {
      state = state.copyWith(isSubmittingRecovery: false, error: 'Recovery submission failed: $e');
    }
  }

  void toggleRevision(String questionId) {
    final set = Set<String>.from(state.revisionQuestionIds);
    if (set.contains(questionId)) {
      set.remove(questionId);
    } else {
      set.add(questionId);
    }
    state = state.copyWith(revisionQuestionIds: set);
  }

  /// Advances to next question in sequence, or sets session completed if at the end.
  void nextQuestion() {
    if (state.currentQuestionIndex < state.questions.length - 1) {
      final nextIdx = state.currentQuestionIndex + 1;
      state = state.copyWith(
        currentQuestionIndex: nextIdx,
        selectedOptionId: null,
        isSubmitted: false,
        isCorrect: null,
        whyResult: null,
        attemptResponse: null,
        probeResult: null,
        recoveryResult: null,
        activeProbe: null,
        selectedProbeOption: null,
        recoveryQuestion: null,
        selectedRecoveryOption: null,
        error: null,
      );
      telemetry.startQuestion();
    } else {
      state = state.copyWith(isSessionCompleted: true);
    }
  }

  void restartSession() {
    loadSession(chapterId: state.currentChapterId);
  }

  String _formatHypothesisTitle(String raw) {
    switch (raw.toLowerCase()) {
      case 'careless_mistake':
        return 'Careless Terminology Confusion';
      case 'time_pressure':
        return 'Time Pressure & Pacing Rush';
      case 'language_barrier':
        return 'Language Comprehension Barrier';
      case 'prerequisite_gap':
        return 'Prerequisite Foundation Gap';
      case 'conceptual_misunderstanding':
      default:
        return 'Conceptual Misunderstanding';
    }
  }

  String _formatHypothesisTitleOr(String raw) {
    switch (raw.toLowerCase()) {
      case 'careless_mistake':
        return 'ଅସାବଧାନତା ଜନିତ ଶବ୍ଦାବଳୀ ଭ୍ରାନ୍ତି';
      case 'time_pressure':
        return 'ସମୟ ଚାପ ଓ ବ୍ୟସ୍ତତା';
      case 'language_barrier':
        return 'ଭାଷାଗତ ବୁଝାମଣା ପ୍ରତିବନ୍ଧକ';
      case 'prerequisite_gap':
        return 'ପୂର୍ବ ଧାରଣାର ଅଭାବ';
      case 'conceptual_misunderstanding':
      default:
        return 'ଧାରଣାଗତ ଭ୍ରାନ୍ତି';
    }
  }
}

final diagnosticSessionProvider =
    StateNotifierProvider<DiagnosticSessionNotifier, DiagnosticSessionState>((ref) {
  final repo = ref.watch(vidyasetuRepositoryProvider);
  return DiagnosticSessionNotifier(repo, ref);
});
