import 'package:flutter/foundation.dart';

/// Multiple-choice option model.
@immutable
class QuestionOption {
  final String key;
  final String text;

  const QuestionOption({
    required this.key,
    required this.text,
  });

  Map<String, dynamic> toJson() => {'key': key, 'text': text};

  factory QuestionOption.fromJson(Map<String, dynamic> json) {
    return QuestionOption(
      key: (json['key'] ?? '').toString(),
      text: (json['text'] ?? '').toString(),
    );
  }
}

/// The 5 canonical diagnostic probe branches.
@immutable
class DiagnosticProbes {
  final Map<String, dynamic> languageProbe;
  final Map<String, dynamic> untimedRetry;
  final Map<String, dynamic> prerequisiteProbe;
  final Map<String, dynamic> transferProbe;
  final Map<String, dynamic> explainBack;

  const DiagnosticProbes({
    required this.languageProbe,
    required this.untimedRetry,
    required this.prerequisiteProbe,
    required this.transferProbe,
    required this.explainBack,
  });

  Map<String, dynamic> toJson() {
    return {
      'language_probe': languageProbe,
      'untimed_retry': untimedRetry,
      'prerequisite_probe': prerequisiteProbe,
      'transfer_probe': transferProbe,
      'explain_back': explainBack,
    };
  }

  factory DiagnosticProbes.fromJson(Map<String, dynamic> json) {
    return DiagnosticProbes(
      languageProbe: Map<String, dynamic>.from((json['language_probe'] as Map?) ?? {}),
      untimedRetry: Map<String, dynamic>.from((json['untimed_retry'] as Map?) ?? {}),
      prerequisiteProbe: Map<String, dynamic>.from((json['prerequisite_probe'] as Map?) ?? {}),
      transferProbe: Map<String, dynamic>.from((json['transfer_probe'] as Map?) ?? {}),
      explainBack: Map<String, dynamic>.from((json['explain_back'] as Map?) ?? {}),
    );
  }
}

/// Recovery practice question model.
/// `answerKey` is nullable to safely omit correct answers in student-facing views.
@immutable
class RecoveryPracticeQuestionModel {
  final String practiceId;
  final String questionText;
  final List<QuestionOption> options;
  final String? answerKey;

  const RecoveryPracticeQuestionModel({
    required this.practiceId,
    required this.questionText,
    required this.options,
    this.answerKey,
  });

  Map<String, dynamic> toJson({bool includeAnswerKey = false}) {
    final map = <String, dynamic>{
      'practice_id': practiceId,
      'question_text': questionText,
      'options': options.map((o) => o.toJson()).toList(),
    };
    if (includeAnswerKey && answerKey != null) {
      map['answer_key'] = answerKey;
    }
    return map;
  }

  factory RecoveryPracticeQuestionModel.fromJson(Map<String, dynamic> json) {
    final opts = (json['options'] as List?)
            ?.map((o) => QuestionOption.fromJson(Map<String, dynamic>.from(o as Map)))
            .toList() ??
        [];
    return RecoveryPracticeQuestionModel(
      practiceId: (json['practice_id'] ?? '').toString(),
      questionText: (json['question_text'] ?? '').toString(),
      options: opts,
      answerKey: json['answer_key']?.toString(),
    );
  }
}

/// Question model representing curriculum items.
/// In public responses from the cloud, `correctAnswer` is stripped.
/// In offline packs and local SQLite cache, `correctAnswer` is present for edge grading.
@immutable
class QuestionModel {
  final String questionId;
  final String subject;
  final String chapterName;
  final String conceptName;
  final String questionText;
  final List<QuestionOption> options;
  final String? correctAnswer;
  final int expectedTimeSec;
  final DiagnosticProbes diagnosticProbes;
  final List<RecoveryPracticeQuestionModel> recoveryPracticeQuestions;

  const QuestionModel({
    required this.questionId,
    required this.subject,
    required this.chapterName,
    required this.conceptName,
    required this.questionText,
    required this.options,
    this.correctAnswer,
    this.expectedTimeSec = 60,
    required this.diagnosticProbes,
    this.recoveryPracticeQuestions = const [],
  });

  Map<String, dynamic> toJson({bool includeAnswers = false}) {
    final map = <String, dynamic>{
      'question_id': questionId,
      'subject': subject,
      'chapter_name': chapterName,
      'concept_name': conceptName,
      'question_text': questionText,
      'options': options.map((o) => o.toJson()).toList(),
      'expected_time_sec': expectedTimeSec,
      'diagnostic_probes': diagnosticProbes.toJson(),
      'recovery_practice_questions': recoveryPracticeQuestions
          .map((r) => r.toJson(includeAnswerKey: includeAnswers))
          .toList(),
    };
    if (includeAnswers && correctAnswer != null) {
      map['correct_answer'] = correctAnswer;
    }
    return map;
  }

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    final id = json['question_id'] ?? json['_id'] ?? '';
    final opts = (json['options'] as List?)
            ?.map((o) => QuestionOption.fromJson(Map<String, dynamic>.from(o as Map)))
            .toList() ??
        [];
    final probes = json['diagnostic_probes'] != null
        ? DiagnosticProbes.fromJson(Map<String, dynamic>.from(json['diagnostic_probes'] as Map))
        : const DiagnosticProbes(
            languageProbe: {},
            untimedRetry: {},
            prerequisiteProbe: {},
            transferProbe: {},
            explainBack: {},
          );
    final recovery = (json['recovery_practice_questions'] as List?)
            ?.map((r) => RecoveryPracticeQuestionModel.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList() ??
        [];

    return QuestionModel(
      questionId: id.toString().toLowerCase(),
      subject: (json['subject'] ?? '').toString(),
      chapterName: (json['chapter_name'] ?? '').toString(),
      conceptName: (json['concept_name'] ?? '').toString(),
      questionText: (json['question_text'] ?? '').toString(),
      options: opts,
      correctAnswer: json['correct_answer']?.toString(),
      expectedTimeSec: ((json['expected_time_sec'] as num?) ?? 60).toInt(),
      diagnosticProbes: probes,
      recoveryPracticeQuestions: recovery,
    );
  }
}
