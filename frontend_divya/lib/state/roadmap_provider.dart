import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/roadmap_repository.dart';
import '../models/subject.dart';

final roadmapRepositoryProvider = Provider<RoadmapRepository>((ref) {
  return MockRoadmapRepository();
});

class RoadmapState {
  final List<Subject> subjects;
  final String selectedSubjectId;
  final ChapterMilestoneData? currentRoadmap;
  final bool isLoading;
  final Set<String> expandedChapterIds;

  const RoadmapState({
    this.subjects = const [],
    this.selectedSubjectId = 'hist',
    this.currentRoadmap,
    this.isLoading = false,
    this.expandedChapterIds = const {'HIST_CH1'},
  });

  RoadmapState copyWith({
    List<Subject>? subjects,
    String? selectedSubjectId,
    ChapterMilestoneData? currentRoadmap,
    bool? isLoading,
    Set<String>? expandedChapterIds,
  }) {
    return RoadmapState(
      subjects: subjects ?? this.subjects,
      selectedSubjectId: selectedSubjectId ?? this.selectedSubjectId,
      currentRoadmap: currentRoadmap ?? this.currentRoadmap,
      isLoading: isLoading ?? this.isLoading,
      expandedChapterIds: expandedChapterIds ?? this.expandedChapterIds,
    );
  }
}

class RoadmapNotifier extends StateNotifier<RoadmapState> {
  final RoadmapRepository _repository;

  RoadmapNotifier(this._repository) : super(const RoadmapState(isLoading: true)) {
    loadRoadmap();
  }

  Future<void> loadRoadmap() async {
    state = state.copyWith(isLoading: true);
    try {
      final subjects = await _repository.getSubjects();
      final roadmap = await _repository.getSubjectRoadmap(state.selectedSubjectId);
      state = state.copyWith(
        subjects: subjects,
        currentRoadmap: roadmap,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> selectSubject(String subjectId) async {
    if (state.selectedSubjectId == subjectId) return;
    state = state.copyWith(selectedSubjectId: subjectId, isLoading: true);
    final roadmap = await _repository.getSubjectRoadmap(subjectId);
    state = state.copyWith(currentRoadmap: roadmap, isLoading: false);
  }

  void toggleChapterExpanded(String chapterId) {
    final updated = Set<String>.from(state.expandedChapterIds);
    if (updated.contains(chapterId)) {
      updated.remove(chapterId);
    } else {
      updated.add(chapterId);
    }
    state = state.copyWith(expandedChapterIds: updated);
  }
}

final roadmapProvider =
    StateNotifierProvider<RoadmapNotifier, RoadmapState>((ref) {
  final repo = ref.watch(roadmapRepositoryProvider);
  return RoadmapNotifier(repo);
});
