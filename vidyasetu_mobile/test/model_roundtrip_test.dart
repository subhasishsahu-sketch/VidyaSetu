import 'package:flutter_test/flutter_test.dart';

import 'package:vidyasetu_mobile/data/models/student_model.dart';
import 'package:vidyasetu_mobile/data/models/progress_model.dart';
import 'package:vidyasetu_mobile/data/models/question_model.dart';
import 'package:vidyasetu_mobile/data/models/diagnostic_model.dart';
import 'package:vidyasetu_mobile/data/models/sync_batch_model.dart';

void main() {
  group('1. Student Models Roundtrip & Alias Parity', () {
    test('StudentCreateRequest supports "class" alias', () {
      final json = {
        'name': 'Suhani Sahu',
        'class': 10,
        'preferred_language': 'Odia',
        'english_exposure_level': 1,
        'subject': 'History',
      };
      final req = StudentCreateRequest.fromJson(json);
      expect(req.name, 'Suhani Sahu');
      expect(req.classGrade, 10);
      expect(req.preferredLanguage, 'Odia');

      final serialized = req.toJson();
      expect(serialized['class_grade'], 10);
    });

    test('StudentModel roundtrip with recommendedNextTask and _id alias', () {
      final json = {
        '_id': 'a1b2c3d4-e5f6-4a5b-8c7d-9e0f1a2b3c4d',
        'name': 'Priya Mohanty',
        'class_grade': 10,
        'preferred_language': 'Odia',
        'english_exposure_level': 2,
        'subject': 'Science',
        'completed_chapters': 1,
        'recommended_next_task': {
          'subject': 'Science',
          'chapter_name': 'Light',
          'task_type': 'practice_reinforcement',
        },
        'created_at': '2026-11-21T18:00:00.000000Z',
      };
      final model = StudentModel.fromJson(json);
      expect(model.studentId, 'a1b2c3d4-e5f6-4a5b-8c7d-9e0f1a2b3c4d');
      expect(model.completedChapters, 1);
      expect(model.recommendedNextTask?['subject'], 'Science');

      final reserialized = StudentModel.fromJson(model.toJson());
      expect(reserialized.studentId, model.studentId);
      expect(reserialized.name, model.name);
      expect(reserialized.recommendedNextTask?['task_type'], 'practice_reinforcement');
    });
  });

  group('2. Progress Models Dual Alias Parity', () {
    test('ProgressUpdateRequest supports language_understanding and accuracy aliases', () {
      final json = {
        'chapter_name': '  Planning Commission & Five Year Plans  ',
        'concept_understanding': 80.0,
        'language_understanding': 60.0,
        'prerequisite_understanding': 70.0,
        'time_management': 65.0,
        'confidence_level': 70.0,
        'accuracy': 75.0,
      };
      final req = ProgressUpdateRequest.fromJson(json);
      expect(req.chapterName, 'Planning Commission & Five Year Plans');
      expect(req.englishComprehension, 60.0);
      expect(req.previousPerformanceScore, 75.0);

      final out = req.toJson();
      expect(out['english_comprehension'], 60.0);
      expect(out['language_understanding'], 60.0);
      expect(out['previous_performance_score'], 75.0);
      expect(out['accuracy'], 75.0);
    });

    test('ProgressModel exposes computed languageUnderstanding getter', () {
      final json = {
        'progress_id': 'p1234567-89ab-4cde-0123-456789abcdef',
        'student_id': 's1234567-89ab-4cde-0123-456789abcdef',
        'chapter_name': 'Light',
        'concept_understanding': 90.0,
        'english_comprehension': 85.0,
        'prerequisite_understanding': 85.0,
        'time_management': 80.0,
        'confidence_level': 80.0,
        'previous_performance_score': 85.0,
        'overall_mastery': 85.5,
        'last_updated': '2026-11-21T18:00:00.000000Z',
      };
      final model = ProgressModel.fromJson(json);
      expect(model.englishComprehension, 85.0);
      expect(model.languageUnderstanding, 85.0);

      final out = model.toJson();
      expect(out['language_understanding'], 85.0);
      expect(out['overall_mastery'], 85.5);
    });
  });

  group('3. Question Models & Safe Projection', () {
    test('QuestionModel strips secret answers in public view', () {
      final q = QuestionModel(
        questionId: 'q1234567-89ab-4cde-0123-456789abcdef',
        subject: 'History',
        chapterName: 'India After Independence',
        conceptName: 'Planning Commission',
        questionText: 'Which commission was established in 1950?',
        options: const [
          QuestionOption(key: 'A', text: 'Finance'),
          QuestionOption(key: 'B', text: 'Planning'),
        ],
        correctAnswer: 'B',
        expectedTimeSec: 60,
        diagnosticProbes: const DiagnosticProbes(
          languageProbe: {'odia': 'ପ୍ରଶ୍ନ'},
          untimedRetry: {},
          prerequisiteProbe: {},
          transferProbe: {},
          explainBack: {},
        ),
        recoveryPracticeQuestions: const [
          RecoveryPracticeQuestionModel(
            practiceId: 'REC-01',
            questionText: 'When was 1st plan?',
            options: [QuestionOption(key: 'A', text: '1951')],
            answerKey: 'A',
          ),
        ],
      );

      final publicJson = q.toJson(includeAnswers: false);
      expect(publicJson.containsKey('correct_answer'), false);
      final recList = publicJson['recovery_practice_questions'] as List;
      expect((recList.first as Map).containsKey('answer_key'), false);

      final internalJson = q.toJson(includeAnswers: true);
      expect(internalJson['correct_answer'], 'B');
      expect(((internalJson['recovery_practice_questions'] as List).first as Map)['answer_key'], 'A');
    });
  });

  group('4. Diagnostic & Telemetry Models Parity', () {
    test('AttemptRequest telemetry aliases mapping', () {
      final json = {
        'student_id': 's123',
        'question_id': 'q123',
        'submitted_answer': 'b ',
        'time_taken_seconds': 24.5,
        'answer_changes': 1,
        'confidence_level': 85.0,
      };
      final req = AttemptRequest.fromJson(json);
      expect(req.selectedOption, 'B');
      expect(req.timeTakenSec, 24.5);
      expect(req.answerChangesCount, 1);
      expect(req.confidenceRating, 85.0);

      final out = req.toJson();
      expect(out['selected_option'], 'B');
      expect(out['submitted_answer'], 'B');
    });

    test('CandidateHypothesis and AttemptResponse roundtrip', () {
      final json = {
        'analysis_id': 'a123',
        'is_correct': false,
        'status': 'probe_required',
        'candidate_hypotheses': [
          {
            'hypothesis': 'careless_mistake',
            'score': 0.88,
            'reason': 'Fast completion',
            'recommended_probe': 'untimed_retry',
          }
        ],
        'selected_probe': {'probe_type': 'untimed_retry'},
      };
      final res = AttemptResponse.fromJson(json);
      expect(res.status, 'probe_required');
      expect(res.candidateHypotheses.first.hypothesis, 'careless_mistake');
      expect(res.selectedProbe?['probe_type'], 'untimed_retry');
    });

    test('ProbeResponseResult with 3-Way Language Bridge intervention roundtrip', () {
      final json = {
        'analysis_id': 'a123',
        'status': 'diagnosis_confirmed',
        'confirmed_hypothesis': 'language_barrier',
        'confidence_score': 0.88,
        'intervention': {
          'bilingual_explanation_odia_english': 'ଧାରଣା ବୁଝାମଣା (Light): ପ୍ରତିଫଳନ',
          'pure_odia_explanation': 'ପ୍ରତିଫଳନ',
          'pure_english_explanation': 'Reflection of light',
          'english_terms_with_odia_meanings': [
            {'english_term': 'reflection', 'odia_meaning': 'ପ୍ରତିଫଳନ'}
          ],
          'grounded_textbook_reference': {
            'textbook_name': 'BSE Odisha Science',
            'chapter_no': 1,
          },
          'recorded_english_exposure_level': 2,
        },
        'recovery_practice_question': {
          'practice_id': 'REC-01',
          'question_text': 'What is focal length?',
          'options': [
            {'key': 'A', 'text': '10cm'}
          ],
        },
      };
      final result = ProbeResponseResult.fromJson(json);
      expect(result.status, 'diagnosis_confirmed');
      expect(result.confirmedHypothesis, 'language_barrier');
      expect(result.intervention?.recordedEnglishExposureLevel, 2);
      expect(result.intervention?.englishTermsWithOdiaMeanings.first.englishTerm, 'reflection');
      expect(result.recoveryPracticeQuestion?.practiceId, 'REC-01');
    });
  });

  group('5. Offline Pack & Batch Sync Models Parity', () {
    test('OfflineSyncBatchRequest and OfflineSyncBatchResponse roundtrip', () {
      final event = OfflineSyncEvent(
        analysisId: 'a123',
        studentId: 's123',
        questionId: 'q123',
        attemptData: {'selected_option': 'A', 'is_correct': false},
        studentParametersSnapshot: const StudentParametersSnapshot(
          timeTaken: 'Normal',
          confidenceLevel: 'High',
        ),
        executionSource: 'edge_slm_offline_sync',
        offlineCreatedAt: DateTime.now().toUtc(),
      );

      final batch = OfflineSyncBatchRequest(
        studentId: 's123',
        batchTimestamp: DateTime.now().toUtc(),
        events: [event],
      );

      final batchJson = batch.toJson();
      final roundtripBatch = OfflineSyncBatchRequest.fromJson(batchJson);
      expect(roundtripBatch.studentId, 's123');
      expect(roundtripBatch.events.length, 1);
      expect(roundtripBatch.events.first.studentParametersSnapshot.timeTaken, 'Normal');

      final respJson = {
        'synced_ids': ['a123'],
        'duplicate_ids': ['a456'],
        'failed_events': [
          {'analysis_id': 'a789', 'reason': 'Question not found'}
        ],
      };
      final batchResp = OfflineSyncBatchResponse.fromJson(respJson);
      expect(batchResp.syncedIds, ['a123']);
      expect(batchResp.duplicateIds, ['a456']);
      expect(batchResp.failedEvents.first.reason, 'Question not found');
    });
  });
}
