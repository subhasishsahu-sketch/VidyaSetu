import '../../models/subject.dart';
import '../../models/chapter.dart';
import '../mock/mock_data.dart';

abstract class RoadmapRepository {
  Future<List<Subject>> getSubjects();
  Future<ChapterMilestoneData> getSubjectRoadmap(String subjectId);
}

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

class MockRoadmapRepository implements RoadmapRepository {
  @override
  Future<List<Subject>> getSubjects() => MockDataStore.getSubjects();

  @override
  Future<ChapterMilestoneData> getSubjectRoadmap(String subjectId) async {
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
