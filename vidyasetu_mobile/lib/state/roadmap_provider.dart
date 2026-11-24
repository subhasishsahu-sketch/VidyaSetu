import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/mock/mock_data.dart';
import '../models/subject.dart';
import '../models/chapter.dart';

class ChapterMilestoneData {
  final String subjectId;
  final String subjectNameEn;
  final String subjectNameOr;
  final MilestoneProgress overallMilestone;
  final List<Chapter> completedChapters;
  final Chapter currentChapter;
  final List<Chapter> nextGoals;

  const ChapterMilestoneData({
    required this.subjectId,
    required this.subjectNameEn,
    required this.subjectNameOr,
    required this.overallMilestone,
    required this.completedChapters,
    required this.currentChapter,
    required this.nextGoals,
  });
}

class MilestoneProgress {
  final int clearedUnits;
  final int totalUnits;
  final int examTargetPercent;
  final int currentProgressPercent;

  const MilestoneProgress({
    required this.clearedUnits,
    required this.totalUnits,
    required this.examTargetPercent,
    required this.currentProgressPercent,
  });

  factory MilestoneProgress.fromJson(Map<String, dynamic> json) {
    return MilestoneProgress(
      clearedUnits: json['cleared_units'] as int? ?? 1,
      totalUnits: json['total_units'] as int? ?? 4,
      examTargetPercent: json['exam_target_percent'] as int? ?? 85,
      currentProgressPercent: json['current_progress_percent'] as int? ?? 42,
    );
  }
}

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
  RoadmapNotifier() : super(const RoadmapState(isLoading: true)) {
    loadRoadmap();
  }

  Future<void> loadRoadmap() async {
    state = state.copyWith(isLoading: true);
    try {
      final subjects = await MockDataStore.getSubjects();
      final roadmap = await _loadSubjectMilestones(state.selectedSubjectId);
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
    final roadmap = await _loadSubjectMilestones(subjectId);
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

  Future<ChapterMilestoneData> _loadSubjectMilestones(String subjectId) async {
    final raw = await MockDataStore.getRoadmapRaw();
    return ChapterMilestoneData(
      subjectId: raw['subject_id'] as String? ?? 'hist',
      subjectNameEn: raw['subject_name_en'] as String? ?? 'History',
      subjectNameOr: raw['subject_name_or'] as String? ?? 'ଇତିହାସ',
      overallMilestone: MilestoneProgress.fromJson(
        raw['overall_milestone'] as Map<String, dynamic>? ?? {},
      ),
      completedChapters: (raw['completed_chapters'] as List<dynamic>?)
              ?.map((c) => Chapter.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      currentChapter: Chapter.fromJson(
        raw['current_chapter'] as Map<String, dynamic>? ?? {},
      ),
      nextGoals: (raw['next_goals'] as List<dynamic>?)
              ?.map((c) => Chapter.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

final roadmapProvider =
    StateNotifierProvider<RoadmapNotifier, RoadmapState>((ref) {
  return RoadmapNotifier();
});
