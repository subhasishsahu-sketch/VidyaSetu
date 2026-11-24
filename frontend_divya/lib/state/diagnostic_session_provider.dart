import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/telemetry_tracker.dart';
import '../data/repositories/assessment_repository.dart';
import '../data/repositories/diagnosis_repository.dart';
import '../models/question.dart';
import '../models/diagnostic_result.dart';

final assessmentRepositoryProvider = Provider<AssessmentRepository>((ref) {
  return MockAssessmentRepository();
});

final diagnosisRepositoryProvider = Provider<DiagnosisRepository>((ref) {
  return MockDiagnosisRepository();
});

class DiagnosticSessionState {
  final List<Question> questions;
  final int currentQuestionIndex;
  final String? selectedOptionId;
  final bool isSubmitted;
  final DiagnosticResult? whyResult;
  final Set<String> revisionQuestionIds;
  final bool isLoading;

  const DiagnosticSessionState({
    this.questions = const [],
    this.currentQuestionIndex = 0,
    this.selectedOptionId,
    this.isSubmitted = false,
    this.whyResult,
    this.revisionQuestionIds = const {},
    this.isLoading = false,
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
    Set<String>? revisionQuestionIds,
    bool? isLoading,
  }) {
    return DiagnosticSessionState(
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      selectedOptionId: selectedOptionId ?? this.selectedOptionId,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      whyResult: whyResult,
      revisionQuestionIds: revisionQuestionIds ?? this.revisionQuestionIds,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class DiagnosticSessionNotifier extends StateNotifier<DiagnosticSessionState> {
  final AssessmentRepository _assessmentRepo;
  final DiagnosisRepository _diagnosisRepo;
  final AttemptTelemetryTracker telemetry = AttemptTelemetryTracker();

  DiagnosticSessionNotifier(this._assessmentRepo, this._diagnosisRepo)
      : super(const DiagnosticSessionState(isLoading: true)) {
    loadSession();
  }

  Future<void> loadSession() async {
    state = state.copyWith(isLoading: true);
    final qs = await _assessmentRepo.getDiagnosticQuestions('HIST_CH2');
    
    // Jump straight to Question 3 (index 2) to match reference screenshot state
    // with 'B' selected wrong and 'C' correct
    final initialIndex = (qs.length >= 3) ? 2 : 0;
    
    state = state.copyWith(
      questions: qs,
      currentQuestionIndex: initialIndex,
      isLoading: false,
    );
    
    telemetry.startQuestion();
    
    // Automatically pre-load Question 3 diagnostic scenario for showcase fidelity
    if (qs.isNotEmpty && initialIndex < qs.length && qs[initialIndex].id == 'HIST_CH2_Q03') {
      selectOption('B');
      await submitAnswer();
    }
  }

  void selectOption(String optionId) {
    if (state.isSubmitted) return; // Prevent changing after submission
    telemetry.onOptionSelected(optionId);
    state = state.copyWith(selectedOptionId: optionId);
  }

  Future<void> submitAnswer() async {
    final currentQ = state.currentQuestion;
    if (currentQ == null || state.selectedOptionId == null) return;

    final isCorrect = state.selectedOptionId == currentQ.correctOptionId;

    // Telemetry capture
    final attempt = AttemptPayload(
      studentId: '9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d',
      questionId: currentQ.id,
      chapterName: currentQ.topic,
      concept: 'Central vs State Jurisdiction',
      questionText: currentQ.questionTextEn,
      submittedAnswer: state.selectedOptionId!,
      isCorrect: isCorrect,
      timeTakenSeconds: telemetry.elapsedSeconds,
      expectedTimeSeconds: 45,
      confidenceLevel: telemetry.inferredConfidence,
      answerChanges: telemetry.optionChangeCount,
      preferredLanguage: 'Odia',
    );

    await _assessmentRepo.recordAttempt(attempt);

    // Fetch WHY engine diagnosis
    final diag = await _diagnosisRepo.getDiagnosticResult(currentQ.id);

    state = state.copyWith(
      isSubmitted: true,
      whyResult: diag,
    );
  }

  void toggleRevision(String questionId) {
    final set = Set<String>.from(state.revisionQuestionIds);
    if (set.contains(questionId)) {
      set.remove(questionId);
    } else {
      set.add(questionId);
    }
    state = state.copyWith(
      revisionQuestionIds: set,
      whyResult: state.whyResult,
      isSubmitted: state.isSubmitted,
      selectedOptionId: state.selectedOptionId,
    );
  }

  void nextQuestion() {
    if (state.currentQuestionIndex < state.questions.length - 1) {
      final nextIdx = state.currentQuestionIndex + 1;
      state = state.copyWith(
        currentQuestionIndex: nextIdx,
        selectedOptionId: null,
        isSubmitted: false,
        whyResult: null,
      );
      telemetry.startQuestion();
    }
  }
}

final diagnosticSessionProvider =
    StateNotifierProvider<DiagnosticSessionNotifier, DiagnosticSessionState>((ref) {
  final aRepo = ref.watch(assessmentRepositoryProvider);
  final dRepo = ref.watch(diagnosisRepositoryProvider);
  return DiagnosticSessionNotifier(aRepo, dRepo);
});
