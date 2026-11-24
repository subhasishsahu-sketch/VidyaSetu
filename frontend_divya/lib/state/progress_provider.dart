import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../data/models/progress_model.dart';
import 'health_provider.dart';

/// State holding chapter progress list for a student.
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

  /// Derives overall mastery average across all tracked chapters.
  double get averageMastery {
    if (chapters.isEmpty) return 0.0;
    final sum = chapters.fold<double>(0.0, (s, c) => s + c.overallMastery);
    return sum / chapters.length;
  }

  /// Number of chapters where overall_mastery >= 75.0.
  int get completedChapterCount {
    return chapters.where((c) => c.overallMastery >= 75.0).length;
  }
}

class ProgressNotifier extends StateNotifier<ProgressState> {
  final ApiClient _apiClient;
  final String _studentId;

  ProgressNotifier(this._apiClient, this._studentId) : super(const ProgressState(isLoading: true)) {
    loadProgress();
  }

  Future<void> loadProgress() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final list = await _apiClient.getList('/students/$_studentId/progress');
      final chapters = list
          .map((e) => ProgressModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      state = state.copyWith(chapters: chapters, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// Gets progress for a specific chapter.
  Future<ProgressModel?> getChapterProgress(String chapterName) async {
    try {
      final json = await _apiClient.get('/students/$_studentId/progress/$chapterName');
      return ProgressModel.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}

/// Provider family keyed by studentId.
final progressProvider =
    StateNotifierProvider.family<ProgressNotifier, ProgressState, String>(
  (ref, studentId) {
    final apiClient = ref.watch(apiClientProvider);
    return ProgressNotifier(apiClient, studentId);
  },
);
