import '../../models/student.dart';
import '../mock/mock_data.dart';

abstract class StudentRepository {
  Future<Student> getStudentProfile();
  Future<void> updateLanguagePreference(String language);
  Future<void> logStudySession(int minutes);
}

class MockStudentRepository implements StudentRepository {
  Student? _currentStudent;

  @override
  Future<Student> getStudentProfile() async {
    _currentStudent ??= await MockDataStore.getStudent();
    return _currentStudent!;
  }

  @override
  Future<void> updateLanguagePreference(String language) async {
    final s = await getStudentProfile();
    _currentStudent = Student(
      studentId: s.studentId,
      name: s.name,
      classGrade: s.classGrade,
      board: s.board,
      preferredLanguage: language,
      englishExposureLevel: s.englishExposureLevel,
      subject: s.subject,
      dailyGoalMinutes: s.dailyGoalMinutes,
      completedMinutes: s.completedMinutes,
      remainingMinutes: s.remainingMinutes,
      goalPercentage: s.goalPercentage,
      streakDays: s.streakDays,
      schoolMeshPeersSynced: s.schoolMeshPeersSynced,
      offlineSlmActive: s.offlineSlmActive,
      activeChapter: s.activeChapter,
    );
  }

  @override
  Future<void> logStudySession(int minutes) async {
    final s = await getStudentProfile();
    final newCompleted = s.completedMinutes + minutes;
    final newRemaining = (s.dailyGoalMinutes - newCompleted).clamp(0, s.dailyGoalMinutes);
    final newPercent = ((newCompleted / s.dailyGoalMinutes) * 100).toInt().clamp(0, 100);

    _currentStudent = Student(
      studentId: s.studentId,
      name: s.name,
      classGrade: s.classGrade,
      board: s.board,
      preferredLanguage: s.preferredLanguage,
      englishExposureLevel: s.englishExposureLevel,
      subject: s.subject,
      dailyGoalMinutes: s.dailyGoalMinutes,
      completedMinutes: newCompleted,
      remainingMinutes: newRemaining,
      goalPercentage: newPercent,
      streakDays: s.streakDays,
      schoolMeshPeersSynced: s.schoolMeshPeersSynced,
      offlineSlmActive: s.offlineSlmActive,
      activeChapter: s.activeChapter,
    );
  }
}
