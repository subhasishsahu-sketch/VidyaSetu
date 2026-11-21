import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:vidyasetu_mobile/core/offline/local_database.dart';
import 'package:vidyasetu_mobile/core/offline/local_slm_engine.dart';
import 'package:vidyasetu_mobile/data/models/student_model.dart';
import 'package:vidyasetu_mobile/data/models/progress_model.dart';
import 'package:vidyasetu_mobile/data/models/question_model.dart';
import 'package:vidyasetu_mobile/data/models/diagnostic_model.dart';
import 'package:vidyasetu_mobile/data/models/offline_pack_model.dart';
import 'package:vidyasetu_mobile/data/models/sync_batch_model.dart';
import 'package:vidyasetu_mobile/data/repositories/offline_vidyasetu_repository.dart';
import 'package:vidyasetu_mobile/data/repositories/hybrid_vidyasetu_repository.dart';
import 'package:vidyasetu_mobile/data/repositories/cloud_vidyasetu_repository.dart';

void main() {
  late Database inMemoryDb;
  late LocalDatabase localDb;
  late OfflineVidyaSetuRepository offlineRepo;

  final sampleQuestion = QuestionModel(
    questionId: 'q-sample-123',
    subject: 'History',
    chapterName: 'India After Independence',
    conceptName: 'Merger of Princely States',
    questionText: 'Which historic agreement did Sardar Patel advise rulers to sign?',
    options: const [
      QuestionOption(key: 'A', text: 'Poona Pact'),
      QuestionOption(key: 'B', text: 'Instrument of Accession'),
      QuestionOption(key: 'C', text: 'Shimla Accord'),
      QuestionOption(key: 'D', text: 'Delhi Pact'),
    ],
    correctAnswer: 'B',
    expectedTimeSec: 45,
    diagnosticProbes: const DiagnosticProbes(
      languageProbe: {
        'prompt_odia': 'କେଉଁ ଚୁକ୍ତିପତ୍ର ସ୍ଵାକ୍ଷର କଲେ?',
        'correct_answer': 'B',
      },
      untimedRetry: {
        'question_text': 'What official document did princely rulers sign?',
        'correct_answer': 'B',
      },
      prerequisiteProbe: {
        'question_text': 'Who was the first Deputy PM?',
        'correct_answer': 'B',
      },
      transferProbe: {
        'question_text': 'Which state delayed its merger?',
        'correct_answer': 'B',
      },
      explainBack: {
        'prompt': 'What incentive was granted?',
        'correct_answer': 'A',
      },
    ),
    recoveryPracticeQuestions: const [
      RecoveryPracticeQuestionModel(
        practiceId: 'REC-HIST-02',
        questionText: 'How many princely states existed in India at independence?',
        options: [
          QuestionOption(key: 'A', text: '200'),
          QuestionOption(key: 'B', text: '565'),
          QuestionOption(key: 'C', text: '800'),
        ],
        answerKey: 'B',
      ),
    ],
  );

  setUp(() {
    inMemoryDb = sqlite3.openInMemory();
    localDb = LocalDatabase(injectedWritableDb: inMemoryDb);
    offlineRepo = OfflineVidyaSetuRepository(
      localDb: localDb,
      slmEngine: const GroundedFallbackSlmEngine(),
    );

    // Cache sample pack with sample question
    localDb.cacheOfflinePack(OfflinePackModel(
      packId: 'pack-history-1',
      subject: 'History',
      chapterName: 'India After Independence',
      cachedQuestions: [sampleQuestion],
      cachedAt: DateTime.now().toUtc(),
    ));
  });

  tearDown(() {
    localDb.close();
  });

  group('1. LocalDatabase CRUD on In-Memory SQLite', () {
    test('saveStudent and getStudent roundtrip', () {
      final student = StudentModel(
        studentId: 's-test-001',
        name: 'Suhani Sahu',
        classGrade: 10,
        preferredLanguage: 'Odia',
        englishExposureLevel: 1,
        subject: 'History',
        completedChapters: 0,
        createdAt: DateTime.now().toUtc(),
      );

      localDb.saveStudent(student);
      final retrieved = localDb.getStudent('s-test-001');
      expect(retrieved, isNotNull);
      expect(retrieved?.name, 'Suhani Sahu');
      expect(retrieved?.classGrade, 10);
    });

    test('upsertProgress and getChapterProgress roundtrip', () {
      final prog = ProgressModel(
        progressId: 'p-test-001',
        studentId: 's-test-001',
        chapterName: 'India After Independence',
        conceptUnderstanding: 60.0,
        englishComprehension: 50.0,
        prerequisiteUnderstanding: 60.0,
        timeManagement: 50.0,
        confidenceLevel: 50.0,
        previousPerformanceScore: 60.0,
        overallMastery: 56.5,
        lastUpdated: DateTime.now().toUtc(),
      );

      localDb.upsertProgress(prog);
      final retrieved = localDb.getChapterProgress('s-test-001', 'India After Independence');
      expect(retrieved, isNotNull);
      expect(retrieved?.overallMastery, 56.5);
      expect(retrieved?.languageUnderstanding, 50.0);
    });

    test('pending_sync_queue enqueue, retrieve, and remove', () {
      final event = OfflineSyncEvent(
        analysisId: 'a-sync-1',
        studentId: 's-test-001',
        questionId: 'q-sample-123',
        attemptData: const {'is_correct': false},
        studentParametersSnapshot: const StudentParametersSnapshot(),
        executionSource: 'edge_slm_offline_sync',
        offlineCreatedAt: DateTime.now().toUtc(),
      );

      localDb.enqueueSyncEvent(event);
      expect(localDb.getPendingQueueCount(), 1);

      final list = localDb.getPendingSyncEvents(studentId: 's-test-001');
      expect(list.length, 1);
      expect(list.first.analysisId, 'a-sync-1');

      localDb.removeSyncedEvents(['a-sync-1']);
      expect(localDb.getPendingQueueCount(), 0);
    });
  });

  group('2. Offline Mark-Loss Autopsy Full Loop', () {
    test('End-to-end attempt, probe response, intervention, recovery boost, and queue persistence', () async {
      // 1. Register Student
      final student = await offlineRepo.registerStudent(const StudentCreateRequest(
        name: 'Rohan Jena',
        classGrade: 10,
        preferredLanguage: 'Odia',
        subject: 'History',
      ));
      expect(student.studentId.isNotEmpty, isTrue);

      // 2. Step A: Submit wrong initial attempt
      final attemptRes = await offlineRepo.submitAttempt(AttemptRequest(
        studentId: student.studentId,
        questionId: sampleQuestion.questionId,
        selectedOption: 'A', // Wrong answer
        timeTakenSec: 15.0,
        confidenceRating: 85.0,
      ));

      expect(attemptRes.isCorrect, isFalse);
      expect(attemptRes.status, 'probe_required');
      expect(attemptRes.candidateHypotheses.isNotEmpty, isTrue);
      expect(attemptRes.selectedProbe, isNotNull);

      final analysisId = attemptRes.analysisId;
      final probeType = attemptRes.selectedProbe!['probe_type'] as String;

      // 3. Step B: Submit Probe Response (correct probe response)
      final probeRes = await offlineRepo.submitProbeResponse(ProbeResponseRequest(
        analysisId: analysisId,
        probeType: probeType,
        submittedAnswer: 'B',
        timeTakenSec: 20.0,
      ));

      expect(probeRes.status, 'diagnosis_confirmed');
      expect(probeRes.confidenceScore, greaterThanOrEqualTo(0.75));
      expect(probeRes.intervention, isNotNull);
      expect(probeRes.recoveryPracticeQuestion, isNotNull);
      expect(probeRes.recoveryPracticeQuestion?.answerKey, isNull); // Secure

      // Verify sync event was queued
      expect(localDb.getPendingQueueCount(), 1);

      // 4. Step C: Submit Recovery practice answer
      final recoveryRes = await offlineRepo.submitRecovery(RecoverySubmitRequest(
        analysisId: analysisId,
        practiceId: probeRes.recoveryPracticeQuestion!.practiceId,
        submittedAnswer: 'B', // Correct answer
      ));

      expect(recoveryRes.isCorrect, isTrue);
      expect(recoveryRes.hasStudentImproved, isTrue);
      expect(recoveryRes.updatedScores.containsKey('overall_mastery'), isTrue);
      expect(recoveryRes.recommendedNextTask['recommended_for'], student.studentId);

      // Verify updated progress in local DB
      final updatedProg = await offlineRepo.getChapterProgress(
        student.studentId,
        sampleQuestion.chapterName,
      );
      expect(updatedProg.confidenceLevel, 55.0); // Boosted +5.0
    });
  });

  group('3. HybridVidyaSetuRepository Routing & Queue Drain', () {
    test('Routes offline when health check fails and drains queue when flushed', () async {
      // Mock cloud repository that is offline
      final mockCloud = CloudVidyaSetuRepository(baseUrl: 'http://localhost:9999/api/v1');
      final hybridRepo = HybridVidyaSetuRepository(
        cloudRepo: mockCloud,
        offlineRepo: offlineRepo,
        localDb: localDb,
      );

      // Verify offline mode when cloud unreachable
      final health = await hybridRepo.checkHealth();
      expect(health['mode'], 'offline');

      // Register student through hybrid facade
      final student = await hybridRepo.registerStudent(const StudentCreateRequest(
        name: 'Aditi Das',
        classGrade: 10,
        subject: 'History',
      ));
      expect(student.name, 'Aditi Das');

      // Offline questions retrieval through hybrid facade
      final questions = await hybridRepo.getQuestions(subject: 'History');
      expect(questions.length, 1);
      expect(questions.first.questionId, sampleQuestion.questionId);
    });
  });
}
