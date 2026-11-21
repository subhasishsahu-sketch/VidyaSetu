import 'package:flutter/foundation.dart';

/// Request payload for updating or initializing chapter progress.
/// Supports both `english_comprehension` and `language_understanding` aliases,
/// and `previous_performance_score` and `accuracy` aliases.
@immutable
class ProgressUpdateRequest {
  final String chapterName;
  final double conceptUnderstanding;
  final double englishComprehension;
  final double prerequisiteUnderstanding;
  final double timeManagement;
  final double confidenceLevel;
  final double previousPerformanceScore;

  ProgressUpdateRequest({
    required String chapterName,
    this.conceptUnderstanding = 50.0,
    double? englishComprehension,
    double? languageUnderstanding,
    this.prerequisiteUnderstanding = 50.0,
    this.timeManagement = 50.0,
    this.confidenceLevel = 50.0,
    double? previousPerformanceScore,
    double? accuracy,
  })  : chapterName = chapterName.trim(),
        englishComprehension = englishComprehension ?? languageUnderstanding ?? 50.0,
        previousPerformanceScore = previousPerformanceScore ?? accuracy ?? 50.0 {
    if (this.chapterName.isEmpty) {
      throw ArgumentError('chapterName cannot be empty or whitespace only');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'chapter_name': chapterName,
      'concept_understanding': conceptUnderstanding,
      'english_comprehension': englishComprehension,
      'language_understanding': englishComprehension,
      'prerequisite_understanding': prerequisiteUnderstanding,
      'time_management': timeManagement,
      'confidence_level': confidenceLevel,
      'previous_performance_score': previousPerformanceScore,
      'accuracy': previousPerformanceScore,
    };
  }

  factory ProgressUpdateRequest.fromJson(Map<String, dynamic> json) {
    final rawChapter = (json['chapter_name'] ?? '').toString();
    final eng = (json['english_comprehension'] ?? json['language_understanding'] ?? 50.0) as num;
    final prev = (json['previous_performance_score'] ?? json['accuracy'] ?? 50.0) as num;

    return ProgressUpdateRequest(
      chapterName: rawChapter,
      conceptUnderstanding: ((json['concept_understanding'] as num?) ?? 50.0).toDouble(),
      englishComprehension: eng.toDouble(),
      prerequisiteUnderstanding: ((json['prerequisite_understanding'] as num?) ?? 50.0).toDouble(),
      timeManagement: ((json['time_management'] as num?) ?? 50.0).toDouble(),
      confidenceLevel: ((json['confidence_level'] as num?) ?? 50.0).toDouble(),
      previousPerformanceScore: prev.toDouble(),
    );
  }
}

/// Chapter progress response model.
/// Exposes both canonical `english_comprehension` and `@computed_field` alias `language_understanding`.
@immutable
class ProgressModel {
  final String progressId;
  final String studentId;
  final String chapterName;
  final double conceptUnderstanding;
  final double englishComprehension;
  final double prerequisiteUnderstanding;
  final double timeManagement;
  final double confidenceLevel;
  final double previousPerformanceScore;
  final double overallMastery;
  final DateTime lastUpdated;

  const ProgressModel({
    required this.progressId,
    required this.studentId,
    required this.chapterName,
    required this.conceptUnderstanding,
    required this.englishComprehension,
    required this.prerequisiteUnderstanding,
    required this.timeManagement,
    required this.confidenceLevel,
    required this.previousPerformanceScore,
    required this.overallMastery,
    required this.lastUpdated,
  });

  /// Alias for englishComprehension required by mobile chart widgets.
  double get languageUnderstanding => englishComprehension;

  Map<String, dynamic> toJson() {
    return {
      'progress_id': progressId,
      'student_id': studentId,
      'chapter_name': chapterName,
      'concept_understanding': conceptUnderstanding,
      'english_comprehension': englishComprehension,
      'language_understanding': languageUnderstanding,
      'prerequisite_understanding': prerequisiteUnderstanding,
      'time_management': timeManagement,
      'confidence_level': confidenceLevel,
      'previous_performance_score': previousPerformanceScore,
      'overall_mastery': overallMastery,
      'last_updated': lastUpdated.toUtc().toIso8601String(),
    };
  }

  factory ProgressModel.fromJson(Map<String, dynamic> json) {
    final id = json['progress_id'] ?? json['_id'] ?? '';
    final eng = (json['english_comprehension'] ?? json['language_understanding'] ?? 50.0) as num;
    final prev = (json['previous_performance_score'] ?? json['accuracy'] ?? 50.0) as num;
    final updated = json['last_updated'] != null
        ? DateTime.parse(json['last_updated'] as String)
        : DateTime.now().toUtc();

    return ProgressModel(
      progressId: id.toString().toLowerCase(),
      studentId: (json['student_id'] ?? '').toString().toLowerCase(),
      chapterName: (json['chapter_name'] ?? '').toString(),
      conceptUnderstanding: ((json['concept_understanding'] as num?) ?? 50.0).toDouble(),
      englishComprehension: eng.toDouble(),
      prerequisiteUnderstanding: ((json['prerequisite_understanding'] as num?) ?? 50.0).toDouble(),
      timeManagement: ((json['time_management'] as num?) ?? 50.0).toDouble(),
      confidenceLevel: ((json['confidence_level'] as num?) ?? 50.0).toDouble(),
      previousPerformanceScore: prev.toDouble(),
      overallMastery: ((json['overall_mastery'] as num?) ?? 0.0).toDouble(),
      lastUpdated: updated,
    );
  }

  ProgressModel copyWith({
    String? progressId,
    String? studentId,
    String? chapterName,
    double? conceptUnderstanding,
    double? englishComprehension,
    double? prerequisiteUnderstanding,
    double? timeManagement,
    double? confidenceLevel,
    double? previousPerformanceScore,
    double? overallMastery,
    DateTime? lastUpdated,
  }) {
    return ProgressModel(
      progressId: progressId ?? this.progressId,
      studentId: studentId ?? this.studentId,
      chapterName: chapterName ?? this.chapterName,
      conceptUnderstanding: conceptUnderstanding ?? this.conceptUnderstanding,
      englishComprehension: englishComprehension ?? this.englishComprehension,
      prerequisiteUnderstanding: prerequisiteUnderstanding ?? this.prerequisiteUnderstanding,
      timeManagement: timeManagement ?? this.timeManagement,
      confidenceLevel: confidenceLevel ?? this.confidenceLevel,
      previousPerformanceScore: previousPerformanceScore ?? this.previousPerformanceScore,
      overallMastery: overallMastery ?? this.overallMastery,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
