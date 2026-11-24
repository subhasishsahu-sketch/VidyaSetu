import 'package:flutter/foundation.dart';
import 'diagnostic_model.dart';

/// Request for concept explanation via 3-Way Language Bridge.
@immutable
class LanguageExplainRequest {
  final String text;
  final String? subject;
  final String? chapterName;
  final String? studentId;
  final int? targetLevel;

  const LanguageExplainRequest({
    required this.text,
    this.subject,
    this.chapterName,
    this.studentId,
    this.targetLevel,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'text': text};
    if (subject != null) map['subject'] = subject;
    if (chapterName != null) map['chapter_name'] = chapterName;
    if (studentId != null) map['student_id'] = studentId;
    if (targetLevel != null) map['target_level'] = targetLevel;
    return map;
  }

  factory LanguageExplainRequest.fromJson(Map<String, dynamic> json) {
    return LanguageExplainRequest(
      text: (json['text'] ?? '').toString(),
      subject: json['subject']?.toString(),
      chapterName: json['chapter_name']?.toString(),
      studentId: json['student_id']?.toString(),
      targetLevel: (json['target_level'] as num?)?.toInt(),
    );
  }
}

/// Response returned from Language Intelligence explain service.
@immutable
class LanguageExplainResponse {
  final String bilingualExplanationOdiaEnglish;
  final String pureOdiaExplanation;
  final String pureEnglishExplanation;
  final List<KeyTermPair> englishTermsWithOdiaMeanings;
  final GroundedReference? groundedTextbookReference;
  final int recordedEnglishExposureLevel;

  const LanguageExplainResponse({
    required this.bilingualExplanationOdiaEnglish,
    required this.pureOdiaExplanation,
    required this.pureEnglishExplanation,
    this.englishTermsWithOdiaMeanings = const [],
    this.groundedTextbookReference,
    required this.recordedEnglishExposureLevel,
  });

  Map<String, dynamic> toJson() => {
        'bilingual_explanation_odia_english': bilingualExplanationOdiaEnglish,
        'pure_odia_explanation': pureOdiaExplanation,
        'pure_english_explanation': pureEnglishExplanation,
        'english_terms_with_odia_meanings':
            englishTermsWithOdiaMeanings.map((t) => t.toJson()).toList(),
        'grounded_textbook_reference': groundedTextbookReference?.toJson(),
        'recorded_english_exposure_level': recordedEnglishExposureLevel,
      };

  factory LanguageExplainResponse.fromJson(Map<String, dynamic> json) {
    final terms = (json['english_terms_with_odia_meanings'] as List?)
            ?.map((t) => KeyTermPair.fromJson(Map<String, dynamic>.from(t as Map)))
            .toList() ??
        [];
    final ref = json['grounded_textbook_reference'] != null
        ? GroundedReference.fromJson(
            Map<String, dynamic>.from(json['grounded_textbook_reference'] as Map))
        : null;

    return LanguageExplainResponse(
      bilingualExplanationOdiaEnglish:
          (json['bilingual_explanation_odia_english'] ?? '').toString(),
      pureOdiaExplanation: (json['pure_odia_explanation'] ?? '').toString(),
      pureEnglishExplanation: (json['pure_english_explanation'] ?? '').toString(),
      englishTermsWithOdiaMeanings: terms,
      groundedTextbookReference: ref,
      recordedEnglishExposureLevel:
          ((json['recorded_english_exposure_level'] as num?) ?? 1).toInt(),
    );
  }
}

/// Response for student language progression and calibration tracking.
@immutable
class LanguageProgressResponse {
  final String studentId;
  final int englishExposureLevel;
  final double meanEnglishComprehension;
  final int totalChaptersTracked;
  final String languageProficiencyBand;

  const LanguageProgressResponse({
    required this.studentId,
    required this.englishExposureLevel,
    required this.meanEnglishComprehension,
    required this.totalChaptersTracked,
    required this.languageProficiencyBand,
  });

  Map<String, dynamic> toJson() => {
        'student_id': studentId,
        'english_exposure_level': englishExposureLevel,
        'mean_english_comprehension': meanEnglishComprehension,
        'total_chapters_tracked': totalChaptersTracked,
        'language_proficiency_band': languageProficiencyBand,
      };

  factory LanguageProgressResponse.fromJson(Map<String, dynamic> json) {
    return LanguageProgressResponse(
      studentId: (json['student_id'] ?? '').toString().toLowerCase(),
      englishExposureLevel: ((json['english_exposure_level'] as num?) ?? 1).toInt(),
      meanEnglishComprehension:
          ((json['mean_english_comprehension'] as num?) ?? 50.0).toDouble(),
      totalChaptersTracked: ((json['total_chapters_tracked'] as num?) ?? 0).toInt(),
      languageProficiencyBand: (json['language_proficiency_band'] ?? '').toString(),
    );
  }
}
