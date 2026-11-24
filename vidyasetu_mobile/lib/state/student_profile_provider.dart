import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/offline/local_database.dart';
import '../data/models/student_model.dart';
import '../data/models/progress_model.dart';
import '../data/repositories/vidyasetu_repository.dart';
import 'repository_provider.dart';

class StudentProfileState {
  final StudentModel? student;
  final List<ProgressModel> progressList;
  final bool isLoading;
  final String? error;

  const StudentProfileState({
    this.student,
    this.progressList = const [],
    this.isLoading = false,
    this.error,
  });

  StudentProfileState copyWith({
    StudentModel? student,
    List<ProgressModel>? progressList,
    bool? isLoading,
    String? error,
  }) {
    return StudentProfileState(
      student: student ?? this.student,
      progressList: progressList ?? this.progressList,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Calculates average overall mastery from all chapter progress records,
  /// falling back to student's goalPercentage or 0 when no progress records exist.
  int get goalPercentage {
    if (progressList.isEmpty) return student?.goalPercentage ?? 0;
    final sum = progressList.fold<double>(0.0, (s, c) => s + c.overallMastery);
    return (sum / progressList.length).round();
  }
}

class StudentProfileNotifier extends StateNotifier<StudentProfileState> {
  final VidyaSetuRepository _repo;
  final LocalDatabase _localDb;

  StudentProfileNotifier(this._repo, this._localDb)
      : super(const StudentProfileState(isLoading: true)) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // 1. Check local database for any persisted student profile
      StudentModel? student = _localDb.getAnyStudent();

      if (student != null) {
        try {
          student = await _repo.getStudent(student.studentId);
          _localDb.saveStudent(student);
        } catch (_) {
          // If offline or network timeout, retain locally saved student
        }
      }

      // 2. If none exists or getStudent returned 404/null, auto-bootstrap
      if (student == null) {
        student = await _repo.registerStudent(
          const StudentCreateRequest(
            name: 'Sunita',
            classGrade: 10,
            preferredLanguage: 'Odia',
            englishExposureLevel: 1,
            subject: 'History',
          ),
        );
        _localDb.saveStudent(student);
      }

      // 3. Load student progress records to derive accurate goal percentage
      List<ProgressModel> progressList = const [];
      try {
        progressList = await _repo.getProgressList(student.studentId);
      } catch (_) {
        // If offline or network timeout, retain empty progress list
      }

      state = state.copyWith(
        student: student,
        progressList: progressList,
        isLoading: false,
      );
    } catch (e) {
      // In case of any transient error, fallback to demo model so app never fails
      final fallbackStudent = StudentModel(
        studentId: '9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d',
        name: 'Sunita',
        classGrade: 10,
        preferredLanguage: 'Odia',
        englishExposureLevel: 1,
        subject: 'History',
        completedChapters: 1,
        createdAt: DateTime.now().toUtc(),
        goalPercentage: 65,
        completedMinutes: 10,
        remainingMinutes: 5,
        dailyGoalMinutes: 15,
      );
      state = state.copyWith(student: fallbackStudent, isLoading: false);
    }
  }

  Future<void> addStudyTime(int minutes) async {
    await loadProfile();
  }
}

final studentProfileProvider =
    StateNotifierProvider<StudentProfileNotifier, StudentProfileState>((ref) {
  final repo = ref.watch(vidyasetuRepositoryProvider);
  final localDb = ref.watch(localDatabaseProvider);
  return StudentProfileNotifier(repo, localDb);
});
