import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/mock/mock_data.dart';
import '../models/subject.dart';
import '../models/chapter.dart';
import '../models/topic.dart';
import '../data/models/progress_model.dart';
import '../data/repositories/vidyasetu_repository.dart';
import 'repository_provider.dart';
import 'student_profile_provider.dart';

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
  final VidyaSetuRepository? _repo;
  final Ref? _ref;

  RoadmapNotifier([this._repo, this._ref])
      : super(const RoadmapState(isLoading: true)) {
    loadRoadmap();
  }

  Future<void> loadRoadmap() async {
    state = state.copyWith(isLoading: true);
    try {
      final baseSubjects = await MockDataStore.getSubjects();
      final roadmap = await _loadSubjectMilestones(state.selectedSubjectId);

      // Reconcile subject mastery with live progress if available
      final studentId = _ref?.read(studentProfileProvider).student?.studentId ??
          '9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d';
      List<ProgressModel> progressList = const [];
      if (_repo != null) {
        try {
          progressList = await _repo.getProgressList(studentId);
        } catch (_) {}
      }

      final subjects = baseSubjects.map((sub) {
        final matching = progressList.where((p) {
          final chName = p.chapterName.toLowerCase();
          if (sub.id == 'hist') {
            return chName.contains('independence') || chName.contains('history');
          } else if (sub.id == 'phys' || sub.id == 'bio') {
            return chName.contains('light') || chName.contains('science');
          } else if (sub.id == 'math') {
            return chName.contains('quadratic') || chName.contains('arithmetic');
          }
          return false;
        }).toList();

        if (matching.isNotEmpty) {
          final avg = matching.map((p) => p.overallMastery).reduce((a, b) => a + b) / matching.length;
          return sub.copyWith(masteryPercent: avg.round());
        }
        return sub;
      }).toList();

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
    // 1. Fetch real student progress list from repository if connected
    final studentId = _ref?.read(studentProfileProvider).student?.studentId ??
        '9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d';
    List<ProgressModel> progressList = const [];
    if (_repo != null) {
      try {
        progressList = await _repo.getProgressList(studentId);
      } catch (_) {
        // Fall back cleanly if offline
      }
    }

    final progressMap = <String, ProgressModel>{};
    for (final p in progressList) {
      progressMap[p.chapterName.toLowerCase().trim()] = p;
    }

    // 2. Structured BSE Odisha Class 10 curriculum by subject
    String subjectNameEn = 'History';
    String subjectNameOr = 'ଇତିହାସ';
    List<Chapter> rawChapters = [];

    switch (subjectId) {
      case 'phys':
        subjectNameEn = 'Science';
        subjectNameOr = 'ଭୌତିକ ବିଜ୍ଞାନ';
        rawChapters = [
          Chapter(
            chapterId: 'SCI_CH1',
            chapterNo: 1,
            titleEn: 'Light',
            titleOr: 'ଆଲୋକ - ପ୍ରତିଫଳନ ଓ ଗୋଲକୀୟ ଦର୍ପଣ',
            masteryPercent: 78,
            status: 'completed',
            eventsMapped: '8/8 Core principles verified',
            clearedDate: '18 Oct',
            topics: const [
              Topic(
                topicId: 'SCI_CH1_T1',
                titleEn: 'Reflection of Light & Laws of Reflection',
                titleOr: 'ଆଲୋକର ପ୍ରତିଫଳନ ନିୟମ',
                status: 'completed',
                statusLabel: 'Completed',
              ),
              Topic(
                topicId: 'SCI_CH1_T2',
                titleEn: 'Spherical Mirrors: Concave & Convex',
                titleOr: 'ଗୋଲକୀୟ ଦର୍ପଣ: ଅବତଳ ଓ ଉତ୍ତଳ',
                status: 'completed',
                statusLabel: 'Completed',
              ),
            ],
          ),
          Chapter(
            chapterId: 'SCI_CH2',
            chapterNo: 2,
            titleEn: 'Refraction & Lenses',
            titleOr: 'ଆଲୋକର ପ୍ରତିସରଣ ଓ ଲେନ୍ସ',
            masteryPercent: 55,
            status: 'in_progress',
            estimatedMinsLeft: 40,
            clearedTopicsCount: 2,
            totalTopicsCount: 4,
            progressPercent: 50,
            topics: const [
              Topic(
                topicId: 'SCI_CH2_T1',
                titleEn: 'Refraction through Glass Slab & Refractive Index',
                titleOr: 'କାଚ ଫଳକରେ ପ୍ରତିସରଣ',
                status: 'completed',
                statusLabel: 'Completed',
              ),
              Topic(
                topicId: 'SCI_CH2_T2',
                titleEn: 'Spherical Lenses & Ray Diagrams',
                titleOr: 'ଲେନ୍ସ ଓ ରଶ୍ମି ଚିତ୍ର',
                status: 'active_focus',
                statusLabel: 'Current',
              ),
              Topic(
                topicId: 'SCI_CH2_T3',
                titleEn: 'Lens Formula & Power of Lens',
                titleOr: 'ଲେନ୍ସ ସୂତ୍ର ଓ ପାୱାର',
                status: 'locked',
                statusLabel: 'Up next',
              ),
            ],
            audioExplainer: const AudioExplainer(
              title: 'AUDIO LAB READY',
              heading: 'Refraction & Lens Power Explained',
              description: 'Listen in Odia voice assistant (8 mins)',
            ),
          ),
          const Chapter(
            chapterId: 'SCI_CH3',
            chapterNo: 3,
            titleEn: 'Electricity & Circuits',
            titleOr: 'ବିଦ୍ୟୁତ୍ ଓ ପରିପଥ',
            masteryPercent: 0,
            status: 'locked',
            lockReason: 'Complete Chapter 2 to unlock',
          ),
          const Chapter(
            chapterId: 'SCI_CH4',
            chapterNo: 4,
            titleEn: 'Magnetic Effects of Current',
            titleOr: 'ବିଦ୍ୟୁତ୍ ପ୍ରବାହର ଚୁମ୍ବକୀୟ ପ୍ରଭାବ',
            masteryPercent: 0,
            status: 'locked',
            lockReason: 'Prerequisites required',
          ),
        ];
        break;

      case 'bio':
        subjectNameEn = 'Geography & Biology';
        subjectNameOr = 'ଭୂଗୋଳ ଓ ଜୀବ ବିଜ୍ଞାନ';
        rawChapters = [
          Chapter(
            chapterId: 'GEOG_CH1',
            chapterNo: 1,
            titleEn: 'Water Resources',
            titleOr: 'ଜଳ ସମ୍ପଦ ଓ ବହୁମୁଖୀ ନଦୀବନ୍ଧ ଯୋଜନା',
            masteryPercent: 82,
            status: 'completed',
            eventsMapped: 'Hirakud Dam case study completed',
            clearedDate: '22 Oct',
            topics: const [
              Topic(
                topicId: 'GEOG_CH1_T1',
                titleEn: 'Multipurpose River Valley Projects in Odisha',
                titleOr: 'ଓଡ଼ିଶାର ବହୁମୁଖୀ ନଦୀବନ୍ଧ ଯୋଜନା',
                status: 'completed',
                statusLabel: 'Completed',
              ),
            ],
          ),
          Chapter(
            chapterId: 'BIO_CH1',
            chapterNo: 2,
            titleEn: 'Life Processes & Nutrition',
            titleOr: 'ଜୈବିକ ପ୍ରକ୍ରିୟା ଓ ପୋଷଣ',
            masteryPercent: 45,
            status: 'in_progress',
            estimatedMinsLeft: 30,
            clearedTopicsCount: 1,
            totalTopicsCount: 3,
            progressPercent: 33,
            topics: const [
              Topic(
                topicId: 'BIO_CH1_T1',
                titleEn: 'Autotrophic & Heterotrophic Nutrition',
                titleOr: 'ସ୍ୱଭୋଜୀ ଓ ପରଭୋଜୀ ପୋଷଣ',
                status: 'completed',
                statusLabel: 'Completed',
              ),
              Topic(
                topicId: 'BIO_CH1_T2',
                titleEn: 'Cellular Respiration in Plants & Animals',
                titleOr: 'ଶ୍ୱସନ ପ୍ରକ୍ରିୟା',
                status: 'active_focus',
                statusLabel: 'Current',
              ),
            ],
            audioExplainer: const AudioExplainer(
              title: 'BIO EXPLAINER READY',
              heading: 'Photosynthesis & ATP Synthesis',
              description: 'Bilingual audio lesson (10 mins)',
            ),
          ),
          const Chapter(
            chapterId: 'GEOG_CH2',
            chapterNo: 3,
            titleEn: 'Forest & Wildlife Resources',
            titleOr: 'ଜଙ୍ଗଲ ଓ ବନ୍ୟପ୍ରାଣୀ ସମ୍ପଦ',
            masteryPercent: 0,
            status: 'locked',
          ),
          const Chapter(
            chapterId: 'BIO_CH2',
            chapterNo: 4,
            titleEn: 'Control & Coordination in Organisms',
            titleOr: 'ନିୟନ୍ତ୍ରଣ ଓ ସମନ୍ୱୟ',
            masteryPercent: 0,
            status: 'locked',
          ),
        ];
        break;

      case 'math':
        subjectNameEn = 'Mathematics';
        subjectNameOr = 'ଗଣିତ';
        rawChapters = [
          Chapter(
            chapterId: 'MATH_CH1',
            chapterNo: 1,
            titleEn: 'Quadratic Equations',
            titleOr: 'ଦ୍ୱିଘାତ ସମୀକରଣ',
            masteryPercent: 75,
            status: 'completed',
            eventsMapped: 'Standard formula derivations checked',
            clearedDate: '26 Oct',
            topics: const [
              Topic(
                topicId: 'MATH_CH1_T1',
                titleEn: 'Roots of Quadratic Equations by Factorisation',
                titleOr: 'ଉତ୍ପାଦକୀକରଣ ପଦ୍ଧତି',
                status: 'completed',
                statusLabel: 'Completed',
              ),
            ],
          ),
          Chapter(
            chapterId: 'MATH_CH2',
            chapterNo: 2,
            titleEn: 'Arithmetic Progression',
            titleOr: 'ସମାନ୍ତର ପ୍ରଗତି',
            masteryPercent: 40,
            status: 'in_progress',
            estimatedMinsLeft: 45,
            clearedTopicsCount: 1,
            totalTopicsCount: 3,
            progressPercent: 33,
            topics: const [
              Topic(
                topicId: 'MATH_CH2_T1',
                titleEn: 'nth Term of an AP formula (an = a + (n-1)d)',
                titleOr: 'ସମାନ୍ତର ପ୍ରଗତିର n-ତମ ପଦ',
                status: 'active_focus',
                statusLabel: 'Current',
              ),
            ],
          ),
          const Chapter(
            chapterId: 'MATH_CH3',
            chapterNo: 3,
            titleEn: 'Coordinate Geometry',
            titleOr: 'ସ୍ଥାନାଙ୍କ ଜ୍ୟାମିତି',
            masteryPercent: 0,
            status: 'locked',
          ),
          const Chapter(
            chapterId: 'MATH_CH4',
            chapterNo: 4,
            titleEn: 'Probability & Statistics',
            titleOr: 'ସମ୍ଭାବ୍ୟତା ଓ ପରିସଂଖ୍ୟାନ',
            masteryPercent: 0,
            status: 'locked',
          ),
        ];
        break;

      case 'hist':
      default:
        subjectNameEn = 'History';
        subjectNameOr = 'ଇତିହାସ';
        rawChapters = [
          Chapter(
            chapterId: 'HIST_CH1',
            chapterNo: 1,
            titleEn: 'Integration of Princely States',
            titleOr: 'ଦେଶୀୟ ରାଜ୍ୟ ମିଶ୍ରଣ',
            masteryPercent: 88,
            status: 'completed',
            eventsMapped: '12/12 Key events mapped',
            clearedDate: '14 Oct',
            topics: const [
              Topic(
                topicId: 'HIST_CH1_T1',
                titleEn: 'Role of Sardar Patel & V.P. Menon',
                titleOr: 'ସର୍ଦ୍ଦାର ପଟେଲଙ୍କ ଭୂମିକା',
                status: 'completed',
                statusLabel: 'Completed',
              ),
              Topic(
                topicId: 'HIST_CH1_T2',
                titleEn: 'Merger of 26 Garhjat States in Odisha',
                titleOr: 'ଓଡ଼ିଶାର ୨୬ଟି ଗଡ଼ଜାତ ମିଶ୍ରଣ',
                status: 'completed',
                statusLabel: 'Completed',
              ),
            ],
          ),
          Chapter(
            chapterId: 'HIST_CH2',
            chapterNo: 2,
            titleEn: 'India After Independence',
            titleOr: 'ଭାରତର ଆର୍ଥିକ ବିକାଶ ଓ ପଞ୍ଚବାର୍ଷିକ ଯୋଜନା',
            masteryPercent: 60,
            status: 'in_progress',
            estimatedMinsLeft: 35,
            clearedTopicsCount: 3,
            totalTopicsCount: 5,
            progressPercent: 60,
            topics: const [
              Topic(
                topicId: 'HIST_CH2_T1',
                titleEn: 'Post-Partition Challenges & Relief Measures',
                titleOr: 'ଦେଶ ବିଭାଜନ ପରବର୍ତ୍ତୀ ଆହ୍ୱାନ ଓ ଥଇଥାନ',
                status: 'completed',
                statusLabel: 'Completed',
              ),
              Topic(
                topicId: 'HIST_CH2_T2',
                titleEn: 'First Five-Year Plan & Agrarian Reforms',
                titleOr: 'ପ୍ରଥମ ପଞ୍ଚବାର୍ଷିକ ଯୋଜନା ଓ କୃଷି ସଂସ୍କାର',
                status: 'completed',
                statusLabel: 'Completed',
              ),
              Topic(
                topicId: 'HIST_CH2_T3',
                titleEn: 'Green Revolution & Rourkela Steel Plant',
                titleOr: 'ସବୁଜ ବିପ୍ଳବ ଏବଂ ରାଉରକେଲା ଇସ୍ପାତ କାରଖାନା',
                status: 'active_focus',
                statusLabel: 'Current',
              ),
              Topic(
                topicId: 'HIST_CH2_T4',
                titleEn: 'Industrial Policy Resolution of 1956',
                titleOr: '୧୯୫୬ ଶିଳ୍ପ ନୀତି ପ୍ରସ୍ତାବ',
                status: 'locked',
                statusLabel: 'Up next',
              ),
              Topic(
                topicId: 'HIST_CH2_T5',
                titleEn: 'Chapter Diagnostic Mastery Assessment',
                titleOr: 'ଅଧ୍ୟାୟ ଭିତ୍ତିକ ଦକ୍ଷତା ମୂଲ୍ୟାଙ୍କନ',
                status: 'final_assessment',
                statusLabel: 'Final',
              ),
            ],
            audioExplainer: const AudioExplainer(
              title: 'AUDIO EXPLAINER READY',
              heading: 'Rourkela Steel Plant & Green Revolution',
              description: 'Listen in Odia voice assistant (10 mins)',
            ),
          ),
          const Chapter(
            chapterId: 'HIST_CH3',
            chapterNo: 3,
            titleEn: 'Planning Commission & Five Year Plans',
            titleOr: 'ଯୋଜନା ଆୟୋଗ ଓ ପଞ୍ଚବାର୍ଷିକ ଯୋଜନା',
            masteryPercent: 0,
            status: 'locked',
            lockReason: 'Requires 75% in India After Independence',
          ),
          const Chapter(
            chapterId: 'HIST_CH4',
            chapterNo: 4,
            titleEn: 'Linguistic Reorganisation of States',
            titleOr: 'ଭାଷାଭିତ୍ତିକ ରାଜ୍ୟ ପୁନର୍ଗଠନ',
            masteryPercent: 0,
            status: 'locked',
            lockReason: 'Locked pathway',
          ),
        ];
        break;
    }

    // 3. Reconcile with live ProgressModel records if available
    final reconciledChapters = rawChapters.map((ch) {
      final key = ch.titleEn.toLowerCase().trim();
      final altKey = ch.chapterId.toLowerCase().trim();
      ProgressModel? matchingProgress = progressMap[key] ?? progressMap[altKey];

      // Also try partial match against chapter names
      if (matchingProgress == null) {
        for (final entry in progressMap.entries) {
          if (key.contains(entry.key) || entry.key.contains(key)) {
            matchingProgress = entry.value;
            break;
          }
        }
      }

      if (matchingProgress != null) {
        final mastery = matchingProgress.overallMastery.round();
        String status = ch.status;
        if (mastery >= 75) {
          status = 'completed';
        } else if (mastery > 0) {
          status = 'in_progress';
        }

        return Chapter(
          chapterId: ch.chapterId,
          chapterNo: ch.chapterNo,
          titleEn: ch.titleEn,
          titleOr: ch.titleOr,
          masteryPercent: mastery,
          status: status,
          eventsMapped: ch.eventsMapped,
          clearedDate: ch.clearedDate,
          estimatedMinsLeft: ch.estimatedMinsLeft,
          clearedTopicsCount: ch.clearedTopicsCount,
          totalTopicsCount: ch.totalTopicsCount,
          progressPercent: mastery,
          topics: ch.topics,
          audioExplainer: ch.audioExplainer,
          lockReason: ch.lockReason,
        );
      }
      return ch;
    }).toList();

    // 4. Group chapters into completed, current in-progress, and next goals
    final completed = reconciledChapters.where((c) => c.status == 'completed').toList();
    final inProgressList = reconciledChapters.where((c) => c.status == 'in_progress').toList();
    final locked = reconciledChapters.where((c) => c.status != 'completed' && c.status != 'in_progress').toList();

    Chapter current;
    if (inProgressList.isNotEmpty) {
      current = inProgressList.first;
    } else if (locked.isNotEmpty) {
      current = locked.first;
    } else if (completed.isNotEmpty) {
      current = completed.last;
    } else {
      current = reconciledChapters.first;
    }

    final nextGoals = reconciledChapters.where((c) => c.chapterId != current.chapterId && !completed.contains(c)).toList();

    final totalMasterySum = reconciledChapters.fold<int>(0, (s, c) => s + c.masteryPercent);
    final avgMastery = reconciledChapters.isNotEmpty ? (totalMasterySum / reconciledChapters.length).round() : 45;

    return ChapterMilestoneData(
      subjectId: subjectId,
      subjectNameEn: subjectNameEn,
      subjectNameOr: subjectNameOr,
      overallMilestone: MilestoneProgress(
        clearedUnits: completed.length,
        totalUnits: reconciledChapters.length,
        examTargetPercent: 85,
        currentProgressPercent: avgMastery,
      ),
      completedChapters: completed,
      currentChapter: current,
      nextGoals: nextGoals,
    );
  }
}

final roadmapProvider =
    StateNotifierProvider<RoadmapNotifier, RoadmapState>((ref) {
  final repo = ref.watch(vidyasetuRepositoryProvider);
  return RoadmapNotifier(repo, ref);
});
