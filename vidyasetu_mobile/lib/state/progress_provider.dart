import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/progress_model.dart';
import '../data/repositories/vidyasetu_repository.dart';
import 'repository_provider.dart';

class ProgressState {
  final List<ProgressModel> chapters;
  final bool isLoading;
  final String? error;

  const ProgressState({
    this.chapters = const [],
    this.isLoading = false,
    this.error,
  });

  ProgressState copyWith({
    List<ProgressModel>? chapters,
    bool? isLoading,
    String? error,
  }) {
    return ProgressState(
      chapters: chapters ?? this.chapters,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  double get averageMastery {
    if (chapters.isEmpty) return 0.0;
    final sum = chapters.fold<double>(0.0, (s, c) => s + c.overallMastery);
    return sum / chapters.length;
  }

  int get completedChapterCount {
    return chapters.where((c) => c.overallMastery >= 75.0).length;
  }
}

class ProgressNotifier extends StateNotifier<ProgressState> {
  final VidyaSetuRepository _repo;
  final String _studentId;

  ProgressNotifier(this._repo, this._studentId)
      : super(const ProgressState(isLoading: true)) {
    loadProgress();
  }

  Future<void> loadProgress() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final list = await _repo.getProgressList(_studentId);
      state = state.copyWith(chapters: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<ProgressModel?> getChapterProgress(String chapterName) async {
    try {
      return await _repo.getChapterProgress(_studentId, chapterName);
    } catch (_) {
      return null;
    }
  }
}

final progressProvider =
    StateNotifierProvider.family<ProgressNotifier, ProgressState, String>(
  (ref, studentId) {
    final repo = ref.watch(vidyasetuRepositoryProvider);
    return ProgressNotifier(repo, studentId);
  },
);
