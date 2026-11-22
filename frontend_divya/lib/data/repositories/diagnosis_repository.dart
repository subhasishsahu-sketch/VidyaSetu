import '../../models/diagnostic_result.dart';
import '../../models/explanation.dart';
import '../../models/study_plan.dart';
import '../mock/mock_data.dart';

abstract class DiagnosisRepository {
  Future<DiagnosticResult> getDiagnosticResult(String questionId);
  Future<Explanation> getExplanation(String questionId);
  Future<StudyPlan> getStudyPlan(String studentId);
}

class MockDiagnosisRepository implements DiagnosisRepository {
  @override
  Future<DiagnosticResult> getDiagnosticResult(String questionId) =>
      MockDataStore.getDiagnosticResult(questionId);

  @override
  Future<Explanation> getExplanation(String questionId) =>
      MockDataStore.getExplanation(questionId);

  @override
  Future<StudyPlan> getStudyPlan(String studentId) =>
      MockDataStore.getStudyPlan();
}
