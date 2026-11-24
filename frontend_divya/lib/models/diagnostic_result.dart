class DiagnosticResult {
  final String questionId;
  final String diagnosisTitle;
  final String diagnosisTitleOr;
  final int certaintyPercent;
  final String sourceEngine;
  final String causalWhyTitle;
  final String causalWhyEn;
  final String causalWhyOr;
  final String citation;
  final String dbStorageBadge;

  const DiagnosticResult({
    required this.questionId,
    required this.diagnosisTitle,
    required this.diagnosisTitleOr,
    required this.certaintyPercent,
    required this.sourceEngine,
    required this.causalWhyTitle,
    required this.causalWhyEn,
    required this.causalWhyOr,
    required this.citation,
    required this.dbStorageBadge,
  });

  factory DiagnosticResult.fromJson(Map<String, dynamic> json) {
    return DiagnosticResult(
      questionId: json['question_id'] as String? ?? '',
      diagnosisTitle: json['diagnosis_title'] as String? ?? 'Careless Terminology Confusion',
      diagnosisTitleOr: json['diagnosis_title_or'] as String? ?? 'ଅସାବଧାନତା ଜନିତ ଶବ୍ଦାବଳୀ ଭ୍ରାନ୍ତି',
      certaintyPercent: json['certainty_percent'] as int? ?? 94,
      sourceEngine: json['source_engine'] as String? ?? 'Causal Error Mapping • VidyaSetu Cognitive Engine',
      causalWhyTitle: json['causal_why_title'] as String? ?? 'କାହିଁକି ଏହି ଭୁଲ୍ ହେଲା? (Causal Why)',
      causalWhyEn: json['causal_why_en'] as String? ?? '',
      causalWhyOr: json['causal_why_or'] as String? ?? '',
      citation: json['citation'] as String? ?? '',
      dbStorageBadge: json['db_storage_badge'] as String? ?? 'Diagnostics indexed locally in SQLite DB (32KB cached) • Auto-saved',
    );
  }

  Map<String, dynamic> toJson() => {
        'question_id': questionId,
        'diagnosis_title': diagnosisTitle,
        'diagnosis_title_or': diagnosisTitleOr,
        'certainty_percent': certaintyPercent,
        'source_engine': sourceEngine,
        'causal_why_title': causalWhyTitle,
        'causal_why_en': causalWhyEn,
        'causal_why_or': causalWhyOr,
        'citation': citation,
        'db_storage_badge': dbStorageBadge,
      };
}
