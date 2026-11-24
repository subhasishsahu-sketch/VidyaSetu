import 'topic.dart';

class Chapter {
  final String chapterId;
  final int chapterNo;
  final String titleEn;
  final String titleOr;
  final int masteryPercent;
  final String? eventsMapped;
  final String? clearedDate;
  final String status; // 'completed', 'in_progress', 'locked'
  final int? estimatedMinsLeft;
  final int? clearedTopicsCount;
  final int? totalTopicsCount;
  final int? progressPercent;
  final List<Topic> topics;
  final AudioExplainer? audioExplainer;
  final String? lockReason;

  const Chapter({
    required this.chapterId,
    required this.chapterNo,
    required this.titleEn,
    required this.titleOr,
    this.masteryPercent = 0,
    this.eventsMapped,
    this.clearedDate,
    required this.status,
    this.estimatedMinsLeft,
    this.clearedTopicsCount,
    this.totalTopicsCount,
    this.progressPercent,
    this.topics = const [],
    this.audioExplainer,
    this.lockReason,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      chapterId: json['chapter_id'] as String? ?? '',
      chapterNo: json['chapter_no'] as int? ?? 1,
      titleEn: json['title_en'] as String? ?? '',
      titleOr: json['title_or'] as String? ?? '',
      masteryPercent: json['mastery_percent'] as int? ?? 0,
      eventsMapped: json['events_mapped'] as String?,
      clearedDate: json['cleared_date'] as String?,
      status: json['status'] as String? ?? 'locked',
      estimatedMinsLeft: json['estimated_mins_left'] as int?,
      clearedTopicsCount: json['cleared_topics_count'] as int?,
      totalTopicsCount: json['total_topics_count'] as int?,
      progressPercent: json['progress_percent'] as int?,
      topics: (json['topics'] as List<dynamic>?)
              ?.map((t) => Topic.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
      audioExplainer: json['audio_explainer'] != null
          ? AudioExplainer.fromJson(
              json['audio_explainer'] as Map<String, dynamic>)
          : null,
      lockReason: json['lock_reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'chapter_id': chapterId,
        'chapter_no': chapterNo,
        'title_en': titleEn,
        'title_or': titleOr,
        'mastery_percent': masteryPercent,
        'events_mapped': eventsMapped,
        'cleared_date': clearedDate,
        'status': status,
        'estimated_mins_left': estimatedMinsLeft,
        'cleared_topics_count': clearedTopicsCount,
        'total_topics_count': totalTopicsCount,
        'progress_percent': progressPercent,
        'topics': topics.map((t) => t.toJson()).toList(),
        'audio_explainer': audioExplainer?.toJson(),
        'lock_reason': lockReason,
      };
}

class AudioExplainer {
  final String title;
  final String heading;
  final String description;

  const AudioExplainer({
    required this.title,
    required this.heading,
    required this.description,
  });

  factory AudioExplainer.fromJson(Map<String, dynamic> json) {
    return AudioExplainer(
      title: json['title'] as String? ?? '',
      heading: json['heading'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'heading': heading,
        'description': description,
      };
}
