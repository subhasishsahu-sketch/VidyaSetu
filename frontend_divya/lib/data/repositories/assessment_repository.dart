import '../../models/question.dart';
import '../mock/mock_data.dart';

class AttemptPayload {
  final String studentId;
  final String questionId;
  final String chapterName;
  final String concept;
  final String questionText;
  final String submittedAnswer;
  final bool isCorrect;
  final int timeTakenSeconds;
  final int expectedTimeSeconds;
  final String confidenceLevel;
  final int answerChanges;
  final String preferredLanguage;

  const AttemptPayload({
    required this.studentId,
    required this.questionId,
    required this.chapterName,
    required this.concept,
    required this.questionText,
    required this.submittedAnswer,
    required this.isCorrect,
    required this.timeTakenSeconds,
    required this.expectedTimeSeconds,
    required this.confidenceLevel,
    required this.answerChanges,
    required this.preferredLanguage,
  });

  Map<String, dynamic> toJson() => {
        'student_id': studentId,
        'question_id': questionId,
        'chapter_name': chapterName,
        'concept': concept,
        'question_text': questionText,
        'submitted_answer': submittedAnswer,
        'is_correct': isCorrect,
        'time_taken_seconds': timeTakenSeconds,
        'expected_time_seconds': expectedTimeSeconds,
        'confidence_level': confidenceLevel,
        'answer_changes': answerChanges,
        'preferred_language': preferredLanguage,
      };
}

abstract class AssessmentRepository {
  Future<List<Question>> getDiagnosticQuestions(String chapterId);
  Future<bool> recordAttempt(AttemptPayload payload);
}

class MockAssessmentRepository implements AssessmentRepository {
  @override
  Future<List<Question>> getDiagnosticQuestions(String chapterId) =>
      MockDataStore.getQuestions();

  @override
  Future<bool> recordAttempt(AttemptPayload payload) async {
    // In offline mode, attempt is registered into local telemetry queue
    return true;
  }
}
