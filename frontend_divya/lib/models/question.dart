import 'answer_option.dart';

class Question {
  final String id;
  final int stepNumber;
  final int totalSteps;
  final String subject;
  final String topic;
  final String typeBadgeEn;
  final String typeBadgeOr;
  final String standard;
  final String questionTextEn;
  final String questionTextOr;
  final List<AnswerOption> options;
  final String correctOptionId;

  const Question({
    required this.id,
    required this.stepNumber,
    required this.totalSteps,
    required this.subject,
    required this.topic,
    required this.typeBadgeEn,
    required this.typeBadgeOr,
    required this.standard,
    required this.questionTextEn,
    required this.questionTextOr,
    required this.options,
    required this.correctOptionId,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String? ?? '',
      stepNumber: json['step_number'] as int? ?? 1,
      totalSteps: json['total_steps'] as int? ?? 5,
      subject: json['subject'] as String? ?? '',
      topic: json['topic'] as String? ?? '',
      typeBadgeEn: json['type_badge_en'] as String? ?? '',
      typeBadgeOr: json['type_badge_or'] as String? ?? '',
      standard: json['standard'] as String? ?? 'BSE Odisha Standard',
      questionTextEn: json['question_text_en'] as String? ?? '',
      questionTextOr: json['question_text_or'] as String? ?? '',
      options: (json['options'] as List<dynamic>?)
              ?.map((o) => AnswerOption.fromJson(o as Map<String, dynamic>))
              .toList() ??
          [],
      correctOptionId: json['correct_option_id'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'step_number': stepNumber,
        'total_steps': totalSteps,
        'subject': subject,
        'topic': topic,
        'type_badge_en': typeBadgeEn,
        'type_badge_or': typeBadgeOr,
        'standard': standard,
        'question_text_en': questionTextEn,
        'question_text_or': questionTextOr,
        'options': options.map((o) => o.toJson()).toList(),
        'correct_option_id': correctOptionId,
      };
}
