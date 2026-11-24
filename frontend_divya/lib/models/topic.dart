class Topic {
  final String topicId;
  final String titleEn;
  final String titleOr;
  final String status; // 'completed', 'active_focus', 'locked', 'final_assessment'
  final String statusLabel;

  const Topic({
    required this.topicId,
    required this.titleEn,
    required this.titleOr,
    required this.status,
    required this.statusLabel,
  });

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      topicId: json['topic_id'] as String? ?? '',
      titleEn: json['title_en'] as String? ?? '',
      titleOr: json['title_or'] as String? ?? '',
      status: json['status'] as String? ?? 'locked',
      statusLabel: json['status_label'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'topic_id': topicId,
        'title_en': titleEn,
        'title_or': titleOr,
        'status': status,
        'status_label': statusLabel,
      };
}
