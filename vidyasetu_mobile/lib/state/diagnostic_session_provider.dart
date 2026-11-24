import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/telemetry_tracker.dart';
import '../data/mock/mock_data.dart';
import '../data/models/diagnostic_model.dart';
import '../data/models/question_model.dart';
import '../models/question.dart';
import '../models/diagnostic_result.dart';
import '../data/repositories/vidyasetu_repository.dart';
import 'repository_provider.dart';
import 'student_profile_provider.dart';

class DiagnosticSessionState {
  final List<Question> questions;
  final int currentQuestionIndex;
  final String? selectedOptionId;
  final bool isSubmitted;
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
  final String? error;

  const DiagnosticSessionState({
    this.questions = const [],
    this.currentQuestionIndex = 0,
    this.selectedOptionId,
    this.isSubmitted = false,
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
    String? error,
  }) {
    return DiagnosticSessionState(
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      selectedOptionId: selectedOptionId ?? this.selectedOptionId,
      isSubmitted: isSubmitted ?? this.isSubmitted,
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

  Future<void> loadSession() async {
    state = state.copyWith(isLoading: true);
    final qs = await MockDataStore.getQuestions();

    // Default to Question 3 (index 2) to showcase Question 3 diagnostic scenario
    final initialIndex = (qs.length >= 3) ? 2 : 0;

    state = state.copyWith(
      questions: qs,
      currentQuestionIndex: initialIndex,
      isLoading: false,
    );

    telemetry.startQuestion();

    if (qs.isNotEmpty && initialIndex < qs.length && qs[initialIndex].id == 'HIST_CH2_Q03') {
      selectOption('B');
      await submitAnswer();
    }
  }

  void selectOption(String optionId) {
    if (state.isSubmitted) return;
    telemetry.onOptionSelected(optionId);
    state = state.copyWith(selectedOptionId: optionId);
  }

  /// Step A: Submits Question Attempt Telemetry to trigger WHY Engine.
  Future<void> submitAnswer() async {
    final currentQ = state.currentQuestion;
    if (currentQ == null || state.selectedOptionId == null) return;

    final studentProfile = _ref.read(studentProfileProvider).student;
    final studentId = studentProfile?.studentId ?? '9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d';
    final questionId = currentQ.id;

    AttemptResponse? attemptRes;
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
    } catch (_) {}

    DiagnosticResult diag;
    try {
      diag = await MockDataStore.getDiagnosticResult(currentQ.id);
    } catch (_) {
      diag = const DiagnosticResult(
        questionId: 'HIST_CH2_Q03',
        diagnosisTitle: 'Careless Terminology Confusion',
        diagnosisTitleOr: 'ଅସାବଧାନତା ଜନିତ ଶବ୍ଦାବଳୀ ଭ୍ରାନ୍ତି',
        certaintyPercent: 94,
        sourceEngine: 'Causal Error Mapping • VidyaSetu Cognitive Engine',
        causalWhyTitle: 'କାହିଁକି ଏହି ଭୁଲ୍ ହେଲା? (Causal Why)',
        causalWhyEn: 'State Planning Board vs Odisha Planning Commission confusion.',
        causalWhyOr: 'ରାଜ୍ୟ ଯୋଜନା ବୋର୍ଡ ଭ୍ରାନ୍ତି।',
        citation: 'BSE Ch 2: Independent Odisha Pg. 43',
        dbStorageBadge: 'Diagnostics indexed locally in SQLite DB • Auto-saved',
      );
    }

    state = state.copyWith(
      isSubmitted: true,
      whyResult: diag,
      attemptResponse: attemptRes,
      activeProbe: attemptRes?.selectedProbe,
    );
  }

  /// Step B: Submits student response to a diagnostic probe.
  Future<void> submitProbeAnswer(String probeOption) async {
    final analysisId = state.attemptResponse?.analysisId;
    final probeType = state.activeProbe?['probe_type']?.toString() ?? 'terminology_distinction';

    state = state.copyWith(
      selectedProbeOption: probeOption,
      isSubmittingProbe: true,
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
        updatedWhy = DiagnosticResult(
          questionId: updatedWhy.questionId,
          diagnosisTitle: probeResult.confirmedHypothesis!,
          diagnosisTitleOr: updatedWhy.diagnosisTitleOr,
          certaintyPercent: ((probeResult.confidenceScore ?? 0.94) * 100).toInt(),
          sourceEngine: updatedWhy.sourceEngine,
          causalWhyTitle: updatedWhy.causalWhyTitle,
          causalWhyEn: probeResult.intervention?.pureEnglishExplanation ?? updatedWhy.causalWhyEn,
          causalWhyOr: probeResult.intervention?.pureOdiaExplanation ?? updatedWhy.causalWhyOr,
          citation: updatedWhy.citation,
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
      state = state.copyWith(isSubmittingProbe: false, error: e.toString());
    }
  }

  /// Step C: Submits student answer to immediate recovery practice question.
  Future<void> submitRecoveryAnswer(String recoveryOption) async {
    final analysisId = state.attemptResponse?.analysisId ?? state.probeResult?.analysisId;
    final recoveryQ = state.recoveryQuestion;

    state = state.copyWith(
      selectedRecoveryOption: recoveryOption,
      isSubmittingRecovery: true,
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
      state = state.copyWith(isSubmittingRecovery: false, error: e.toString());
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

  void nextQuestion() {
    if (state.currentQuestionIndex < state.questions.length - 1) {
      final nextIdx = state.currentQuestionIndex + 1;
      state = state.copyWith(
        currentQuestionIndex: nextIdx,
        selectedOptionId: null,
        isSubmitted: false,
        whyResult: null,
        attemptResponse: null,
        probeResult: null,
        recoveryResult: null,
        activeProbe: null,
        selectedProbeOption: null,
        recoveryQuestion: null,
        selectedRecoveryOption: null,
      );
      telemetry.startQuestion();
    }
  }
}

final diagnosticSessionProvider =
    StateNotifierProvider<DiagnosticSessionNotifier, DiagnosticSessionState>((ref) {
  final repo = ref.watch(vidyasetuRepositoryProvider);
  return DiagnosticSessionNotifier(repo, ref);
});
