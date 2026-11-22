class Student {
  final String studentId;
  final String name;
  final int classGrade;
  final String board;
  final String preferredLanguage;
  final int englishExposureLevel;
  final String subject;
  final int dailyGoalMinutes;
  final int completedMinutes;
  final int remainingMinutes;
  final int goalPercentage;
  final int streakDays;
  final int schoolMeshPeersSynced;
  final bool offlineSlmActive;
  final ActiveChapter activeChapter;

  const Student({
    required this.studentId,
    required this.name,
    required this.classGrade,
    required this.board,
    required this.preferredLanguage,
    required this.englishExposureLevel,
    required this.subject,
    required this.dailyGoalMinutes,
    required this.completedMinutes,
    required this.remainingMinutes,
    required this.goalPercentage,
    required this.streakDays,
    required this.schoolMeshPeersSynced,
    required this.offlineSlmActive,
    required this.activeChapter,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      studentId: json['student_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Sunita',
      classGrade: json['class_grade'] as int? ?? 10,
      board: json['board'] as String? ?? 'BSE Odisha',
      preferredLanguage: json['preferred_language'] as String? ?? 'Odia',
      englishExposureLevel: json['english_exposure_level'] as int? ?? 1,
      subject: json['subject'] as String? ?? 'History',
      dailyGoalMinutes: json['daily_goal_minutes'] as int? ?? 15,
      completedMinutes: json['completed_minutes'] as int? ?? 10,
      remainingMinutes: json['remaining_minutes'] as int? ?? 5,
      goalPercentage: json['goal_percentage'] as int? ?? 65,
      streakDays: json['streak_days'] as int? ?? 7,
      schoolMeshPeersSynced: json['school_mesh_peers_synced'] as int? ?? 22,
      offlineSlmActive: json['offline_slm_active'] as bool? ?? true,
      activeChapter: ActiveChapter.fromJson(
        json['active_chapter'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'student_id': studentId,
        'name': name,
        'class_grade': classGrade,
        'board': board,
        'preferred_language': preferredLanguage,
        'english_exposure_level': englishExposureLevel,
        'subject': subject,
        'daily_goal_minutes': dailyGoalMinutes,
        'completed_minutes': completedMinutes,
        'remaining_minutes': remainingMinutes,
        'goal_percentage': goalPercentage,
        'streak_days': streakDays,
        'school_mesh_peers_synced': schoolMeshPeersSynced,
        'offline_slm_active': offlineSlmActive,
        'active_chapter': activeChapter.toJson(),
      };
}

class ActiveChapter {
  final String subject;
  final String titleEn;
  final String titleOr;
  final int chapterNo;
  final int sectionNo;
  final String status;

  const ActiveChapter({
    required this.subject,
    required this.titleEn,
    required this.titleOr,
    required this.chapterNo,
    required this.sectionNo,
    required this.status,
  });

  factory ActiveChapter.fromJson(Map<String, dynamic> json) {
    return ActiveChapter(
      subject: json['subject'] as String? ?? 'History',
      titleEn: json['title_en'] as String? ?? 'India After Independence',
      titleOr: json['title_or'] as String? ?? 'ସ୍ୱାଧୀନତା ପରବର୍ତ୍ତୀ ଭାରତ',
      chapterNo: json['chapter_no'] as int? ?? 1,
      sectionNo: json['section_no'] as int? ?? 2,
      status: json['status'] as String? ?? 'Ready Offline',
    );
  }

  Map<String, dynamic> toJson() => {
        'subject': subject,
        'title_en': titleEn,
        'title_or': titleOr,
        'chapter_no': chapterNo,
        'section_no': sectionNo,
        'status': status,
      };
}
