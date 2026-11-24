class StudyPlan {
  final String auditStatus;
  final String engineStatus;
  final String title;
  final String subtitle;
  final String resolvedGap;
  final Step4Replan step4Replan;
  final Step5Storage step5Storage;
  final Step6Quiz step6Quiz;
  final String footerSync;

  const StudyPlan({
    required this.auditStatus,
    required this.engineStatus,
    required this.title,
    required this.subtitle,
    required this.resolvedGap,
    required this.step4Replan,
    required this.step5Storage,
    required this.step6Quiz,
    required this.footerSync,
  });

  factory StudyPlan.fromJson(Map<String, dynamic> json) {
    return StudyPlan(
      auditStatus: json['audit_status'] as String? ?? 'AUTONOMOUS AUDIT COMPLETE',
      engineStatus: json['engine_status'] as String? ?? 'Local SLM Active',
      title: json['title'] as String? ?? 'Adaptive Replan & Offline Recovery',
      subtitle: json['subtitle'] as String? ?? "Sunita's Intelligent Study Engine • BSE Odisha Class 10",
      resolvedGap: json['resolved_gap'] as String? ?? '',
      step4Replan: Step4Replan.fromJson(
        json['step_4_replan'] as Map<String, dynamic>? ?? {},
      ),
      step5Storage: Step5Storage.fromJson(
        json['step_5_storage'] as Map<String, dynamic>? ?? {},
      ),
      step6Quiz: Step6Quiz.fromJson(
        json['step_6_quiz'] as Map<String, dynamic>? ?? {},
      ),
      footerSync: json['footer_sync'] as String? ?? '',
    );
  }
}

class Step4Replan {
  final String stepLabel;
  final String title;
  final String description;
  final MicroLesson microLesson;

  const Step4Replan({
    required this.stepLabel,
    required this.title,
    required this.description,
    required this.microLesson,
  });

  factory Step4Replan.fromJson(Map<String, dynamic> json) {
    return Step4Replan(
      stepLabel: json['step_label'] as String? ?? 'STEP 4 • AUTONOMOUS REPLAN',
      title: json['title'] as String? ?? 'Study Plan Updated Automatically',
      description: json['description'] as String? ?? '',
      microLesson: MicroLesson.fromJson(
        json['micro_lesson'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class MicroLesson {
  final String tag;
  final String title;
  final String focus;
  final String slot;
  final String projectedGain;
  final String pacingNote;

  const MicroLesson({
    required this.tag,
    required this.title,
    required this.focus,
    required this.slot,
    required this.projectedGain,
    required this.pacingNote,
  });

  factory MicroLesson.fromJson(Map<String, dynamic> json) {
    return MicroLesson(
      tag: json['tag'] as String? ?? 'SCHEDULED 8-MIN MICRO-LESSON',
      title: json['title'] as String? ?? '',
      focus: json['focus'] as String? ?? '',
      slot: json['slot'] as String? ?? '',
      projectedGain: json['projected_gain'] as String? ?? '',
      pacingNote: json['pacing_note'] as String? ?? '',
    );
  }
}

class Step5Storage {
  final String stepLabel;
  final String title;
  final String details;
  final String networkBadge;
  final String commitId;
  final String storageUsed;
  final String readyPercent;
  final List<String> checkpoints;

  const Step5Storage({
    required this.stepLabel,
    required this.title,
    required this.details,
    required this.networkBadge,
    required this.commitId,
    required this.storageUsed,
    required this.readyPercent,
    required this.checkpoints,
  });

  factory Step5Storage.fromJson(Map<String, dynamic> json) {
    return Step5Storage(
      stepLabel: json['step_label'] as String? ?? 'STEP 5 • STORAGE VERIFIED',
      title: json['title'] as String? ?? 'Offline Diagnostic Pack Cached',
      details: json['details'] as String? ?? '',
      networkBadge: json['network_badge'] as String? ?? '0 KB Internet Needed',
      commitId: json['commit_id'] as String? ?? 'SQLite local commit #BSE-402',
      storageUsed: json['storage_used'] as String? ?? 'Storage used: 142 KB in local SQLite',
      readyPercent: json['ready_percent'] as String? ?? '100% Ready',
      checkpoints: (json['checkpoints'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class Step6Quiz {
  final String stepLabel;
  final String title;
  final String description;
  final String estimatedTime;
  final String rewardXp;
  final String buttonLabel;
  final String secondaryLabel;

  const Step6Quiz({
    required this.stepLabel,
    required this.title,
    required this.description,
    required this.estimatedTime,
    required this.rewardXp,
    required this.buttonLabel,
    required this.secondaryLabel,
  });

  factory Step6Quiz.fromJson(Map<String, dynamic> json) {
    return Step6Quiz(
      stepLabel: json['step_label'] as String? ?? 'STEP 6 • ACTION READY',
      title: json['title'] as String? ?? 'Recovery Quiz Ready',
      description: json['description'] as String? ?? '',
      estimatedTime: json['estimated_time'] as String? ?? '2 Minutes (3 Quick MCQs)',
      rewardXp: json['reward_xp'] as String? ?? '+100 XP',
      buttonLabel: json['button_label'] as String? ?? 'Take 2-Min Recovery Check ➔',
      secondaryLabel: json['secondary_label'] as String? ?? 'Back to Home / ମୁଖ୍ୟ ପୃଷ୍ଠାକୁ ଫେରନ୍ତୁ',
    );
  }
}
