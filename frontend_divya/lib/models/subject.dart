class Subject {
  final String id;
  final String nameEn;
  final String nameOr;
  final String code;
  final String icon;
  final int totalChapters;
  final int completedChapters;
  final int masteryPercent;
  final bool isCached;

  const Subject({
    required this.id,
    required this.nameEn,
    required this.nameOr,
    required this.code,
    required this.icon,
    required this.totalChapters,
    required this.completedChapters,
    required this.masteryPercent,
    required this.isCached,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
      nameOr: json['name_or'] as String? ?? '',
      code: json['code'] as String? ?? '',
      icon: json['icon'] as String? ?? 'book',
      totalChapters: json['total_chapters'] as int? ?? 0,
      completedChapters: json['completed_chapters'] as int? ?? 0,
      masteryPercent: json['mastery_percent'] as int? ?? 0,
      isCached: json['is_cached'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name_en': nameEn,
        'name_or': nameOr,
        'code': code,
        'icon': icon,
        'total_chapters': totalChapters,
        'completed_chapters': completedChapters,
        'mastery_percent': masteryPercent,
        'is_cached': isCached,
      };
}
