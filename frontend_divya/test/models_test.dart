import 'package:flutter_test/flutter_test.dart';
import 'package:vidyasetu/core/utils/telemetry_tracker.dart';
import 'package:vidyasetu/models/student.dart';
import 'package:vidyasetu/models/subject.dart';
import 'package:vidyasetu/models/chapter.dart';
import 'package:vidyasetu/models/question.dart';
import 'package:vidyasetu/models/diagnostic_result.dart';
import 'package:vidyasetu/models/explanation.dart';

void main() {
  group('VidyaSetu Data Models Test Suite', () {
    test('Student model JSON serialization', () {
      final json = {
        'student_id': 'test-123',
        'name': 'Sunita',
        'class_grade': 10,
        'board': 'BSE Odisha',
        'preferred_language': 'Odia',
        'english_exposure_level': 1,
        'subject': 'History',
        'daily_goal_minutes': 15,
        'completed_minutes': 10,
        'remaining_minutes': 5,
        'goal_percentage': 65,
        'streak_days': 7,
        'school_mesh_peers_synced': 22,
        'offline_slm_active': true,
        'active_chapter': {
          'subject': 'History',
          'title_en': 'India After Independence',
          'title_or': 'ସ୍ୱାଧୀନତା ପରବର୍ତ୍ତୀ ଭାରତ',
          'chapter_no': 1,
          'section_no': 2,
          'status': 'Ready Offline',
        }
      };

      final student = Student.fromJson(json);
      expect(student.studentId, 'test-123');
      expect(student.name, 'Sunita');
      expect(student.goalPercentage, 65);
      expect(student.activeChapter.chapterNo, 1);
      expect(student.toJson()['student_id'], 'test-123');
    });

    test('Subject model JSON serialization', () {
      final json = {
        'id': 'hist',
        'name_en': 'History',
        'name_or': 'ଇତିହାସ',
        'code': 'HIST',
        'icon': 'account_balance',
        'total_chapters': 4,
        'completed_chapters': 1,
        'mastery_percent': 88,
        'is_cached': true,
      };

      final subject = Subject.fromJson(json);
      expect(subject.id, 'hist');
      expect(subject.masteryPercent, 88);
      expect(subject.toJson()['code'], 'HIST');
    });

    test('Chapter and Topic models JSON serialization', () {
      final json = {
        'chapter_id': 'HIST_CH2',
        'chapter_no': 2,
        'title_en': 'India After Independence',
        'title_or': 'ସ୍ୱାଧୀନତା ପରବର୍ତ୍ତୀ ଭାରତ',
        'status': 'in_progress',
        'progress_percent': 60,
        'topics': [
          {
            'topic_id': 'HIST_CH2_T1',
            'title_en': 'Topic 1',
            'title_or': 'ପ୍ରସଙ୍ଗ ୧',
            'status': 'completed',
            'status_label': 'Completed'
          }
        ]
      };

      final chapter = Chapter.fromJson(json);
      expect(chapter.chapterNo, 2);
      expect(chapter.topics.length, 1);
      expect(chapter.topics.first.status, 'completed');
    });

    test('Question and DiagnosticResult JSON serialization', () {
      final qJson = {
        'id': 'HIST_CH2_Q03',
        'step_number': 3,
        'total_steps': 5,
        'subject': 'History',
        'topic': 'Economic Planning',
        'type_badge_en': 'Q3 • Objective Type (1 Mark)',
        'type_badge_or': 'ପ୍ର୩',
        'standard': 'BSE Odisha Standard',
        'question_text_en': 'Which commission was responsible?',
        'question_text_or': 'କେଉଁ ସଂସ୍ଥା ଦାୟୀ ଥିଲା?',
        'options': [
          {'id': 'A', 'text_en': 'Planning Commission', 'text_or': 'ଯୋଜନା ଆୟୋଗ'},
          {'id': 'C', 'text_en': 'State Planning Board', 'text_or': 'ରାଜ୍ୟ ଯୋଜନା ବୋର୍ଡ'}
        ],
        'correct_option_id': 'C'
      };

      final q = Question.fromJson(qJson);
      expect(q.correctOptionId, 'C');
      expect(q.options.length, 2);

      final diagJson = {
        'question_id': 'HIST_CH2_Q03',
        'diagnosis_title': 'Careless Terminology Confusion',
        'diagnosis_title_or': 'ଅସାବଧାନତା ଜନିତ ଶବ୍ଦାବଳୀ ଭ୍ରାନ୍ତି',
        'certainty_percent': 94,
        'source_engine': 'Causal Error Mapping • VidyaSetu Cognitive Engine',
        'causal_why_title': 'କାହିଁକି ଏହି ଭୁଲ୍ ହେଲା?',
        'causal_why_en': 'You remembered the timeline...',
        'causal_why_or': 'ଆପଣ ସମୟରେଖା...',
        'citation': 'BSE Ch 2',
        'db_storage_badge': 'Diagnostics indexed locally',
      };

      final diag = DiagnosticResult.fromJson(diagJson);
      expect(diag.certaintyPercent, 94);
      expect(diag.diagnosisTitle, 'Careless Terminology Confusion');
    });

    test('Explanation mode switching', () {
      final expJson = {
        'question_id': 'HIST_CH2_Q03',
        'title': 'State Planning Board',
        'sub_header': 'CONCEPT REPAIR',
        'mistake_tag': 'Jurisdiction confusion',
        'subject_tag': 'Class 10 Polity',
        'modes': {
          'bilingual_mix': 'Bilingual text sample',
          'pure_odia': 'ସମ୍ପୂର୍ଣ୍ଣ ଓଡ଼ିଆ ପାଠ୍ୟ',
          'pure_english': 'English text sample'
        },
        'comparison_cards': [],
        'grounded_citation': {},
        'historical_reference': {},
        'audio': {},
        'insight': 'Great insight!'
      };

      final exp = Explanation.fromJson(expJson);
      expect(exp.getTextForMode(ExplanationMode.bilingualMix), 'Bilingual text sample');
      expect(exp.getTextForMode(ExplanationMode.pureOdia), 'ସମ୍ପୂର୍ଣ୍ଣ ଓଡ଼ିଆ ପାଠ୍ୟ');
      expect(exp.getTextForMode(ExplanationMode.pureEnglish), 'English text sample');
    });

    test('AttemptTelemetryTracker tracks option changes and confidence', () {
      final tracker = AttemptTelemetryTracker();
      tracker.startQuestion();
      expect(tracker.optionChangeCount, 0);

      tracker.onOptionSelected('A');
      expect(tracker.selectedOption, 'A');
      expect(tracker.optionChangeCount, 0);

      // Change answer to B
      tracker.onOptionSelected('B');
      expect(tracker.optionChangeCount, 1);
      expect(tracker.inferredConfidence, 'normal');

      // Change answer to C
      tracker.onOptionSelected('C');
      expect(tracker.optionChangeCount, 2);
      // When swaps >= 2, confidence inferred as low
      expect(tracker.inferredConfidence, 'low');
    });
  });
}
