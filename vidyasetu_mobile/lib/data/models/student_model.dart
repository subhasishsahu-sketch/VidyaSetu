import 'package:flutter/foundation.dart';

/// Request payload for registering a new student.
/// Supports both `class` and `class_grade` JSON aliases.
@immutable
class StudentCreateRequest {
  final String name;
  final int classGrade;
  final String preferredLanguage; // 'Odia' | 'English'
  final int englishExposureLevel; // 1-4
  final String subject;

  const StudentCreateRequest({
    required this.name,
    required this.classGrade,
    this.preferredLanguage = 'Odia',
    this.englishExposureLevel = 1,
    required this.subject,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'class_grade': classGrade,
      'preferred_language': preferredLanguage,
      'english_exposure_level': englishExposureLevel,
      'subject': subject,
    };
  }

  factory StudentCreateRequest.fromJson(Map<String, dynamic> json) {
    final grade = json['class_grade'] ?? json['class'] ?? 10;
    return StudentCreateRequest(
      name: json['name'] as String,
      classGrade: (grade as num).toInt(),
      preferredLanguage: (json['preferred_language'] as String?) ?? 'Odia',
      englishExposureLevel: ((json['english_exposure_level'] as num?) ?? 1).toInt(),
      subject: json['subject'] as String,
    );
  }
}

/// Student profile response model.
@immutable
class StudentModel {
  final String studentId;
  final String name;
  final int classGrade;
  final String preferredLanguage;
  final int englishExposureLevel;
  final String subject;
  final int completedChapters;
  final Map<String, dynamic>? recommendedNextTask;
  final DateTime createdAt;

  // Derived / UI helper fields with safe defaults (zero backend serialization impact)
  final int goalPercentage;
  final int completedMinutes;
  final int remainingMinutes;
  final int dailyGoalMinutes;

  const StudentModel({
    required this.studentId,
    required this.name,
    required this.classGrade,
    required this.preferredLanguage,
    required this.englishExposureLevel,
    required this.subject,
    this.completedChapters = 0,
    this.recommendedNextTask,
    required this.createdAt,
    this.goalPercentage = 0,
    this.completedMinutes = 0,
    this.remainingMinutes = 15,
    this.dailyGoalMinutes = 15,
  });

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'name': name,
      'class_grade': classGrade,
      'preferred_language': preferredLanguage,
      'english_exposure_level': englishExposureLevel,
      'subject': subject,
      'completed_chapters': completedChapters,
      'recommended_next_task': recommendedNextTask,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    final id = json['student_id'] ?? json['_id'] ?? '';
    final grade = json['class_grade'] ?? json['class'] ?? 10;
    final created = json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String)
        : DateTime.now().toUtc();

    return StudentModel(
      studentId: id.toString().toLowerCase(),
      name: (json['name'] ?? '').toString(),
      classGrade: (grade as num).toInt(),
      preferredLanguage: (json['preferred_language'] ?? 'Odia').toString(),
      englishExposureLevel: ((json['english_exposure_level'] as num?) ?? 1).toInt(),
      subject: (json['subject'] ?? '').toString(),
      completedChapters: ((json['completed_chapters'] as num?) ?? 0).toInt(),
      recommendedNextTask: json['recommended_next_task'] != null
          ? Map<String, dynamic>.from(json['recommended_next_task'] as Map)
          : null,
      createdAt: created,
      goalPercentage: ((json['goal_percentage'] as num?) ?? 0).toInt(),
      completedMinutes: ((json['completed_minutes'] as num?) ?? 0).toInt(),
      remainingMinutes: ((json['remaining_minutes'] as num?) ?? 15).toInt(),
      dailyGoalMinutes: ((json['daily_goal_minutes'] as num?) ?? 15).toInt(),
    );
  }

  StudentModel copyWith({
    String? studentId,
    String? name,
    int? classGrade,
    String? preferredLanguage,
    int? englishExposureLevel,
    String? subject,
    int? completedChapters,
    Map<String, dynamic>? recommendedNextTask,
    DateTime? createdAt,
    int? goalPercentage,
    int? completedMinutes,
    int? remainingMinutes,
    int? dailyGoalMinutes,
  }) {
    return StudentModel(
      studentId: studentId ?? this.studentId,
      name: name ?? this.name,
      classGrade: classGrade ?? this.classGrade,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      englishExposureLevel: englishExposureLevel ?? this.englishExposureLevel,
      subject: subject ?? this.subject,
      completedChapters: completedChapters ?? this.completedChapters,
      recommendedNextTask: recommendedNextTask ?? this.recommendedNextTask,
      createdAt: createdAt ?? this.createdAt,
      goalPercentage: goalPercentage ?? this.goalPercentage,
      completedMinutes: completedMinutes ?? this.completedMinutes,
      remainingMinutes: remainingMinutes ?? this.remainingMinutes,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
    );
  }
}
