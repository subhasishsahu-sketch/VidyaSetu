class AnswerOption {
  final String id;
  final String textEn;
  final String textOr;

  const AnswerOption({
    required this.id,
    required this.textEn,
    required this.textOr,
  });

  factory AnswerOption.fromJson(Map<String, dynamic> json) {
    return AnswerOption(
      id: json['id'] as String? ?? '',
      textEn: json['text_en'] as String? ?? '',
      textOr: json['text_or'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text_en': textEn,
        'text_or': textOr,
      };
}
