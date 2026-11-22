import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/student_repository.dart';
import '../models/student.dart';

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  return MockStudentRepository();
});

class StudentProfileState {
  final Student? student;
  final bool isLoading;
  final String? error;

  const StudentProfileState({
    this.student,
    this.isLoading = false,
    this.error,
  });

  StudentProfileState copyWith({
    Student? student,
    bool? isLoading,
    String? error,
  }) {
    return StudentProfileState(
      student: student ?? this.student,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class StudentProfileNotifier extends StateNotifier<StudentProfileState> {
  final StudentRepository _repository;

  StudentProfileNotifier(this._repository) : super(const StudentProfileState(isLoading: true)) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true);
    try {
      final s = await _repository.getStudentProfile();
      state = state.copyWith(student: s, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> addStudyTime(int minutes) async {
    await _repository.logStudySession(minutes);
    await loadProfile();
  }
}

final studentProfileProvider =
    StateNotifierProvider<StudentProfileNotifier, StudentProfileState>((ref) {
  final repo = ref.watch(studentRepositoryProvider);
  return StudentProfileNotifier(repo);
});
