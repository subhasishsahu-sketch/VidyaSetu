import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/student_model.dart';
import '../models/progress_model.dart';
import '../models/question_model.dart';
import '../models/diagnostic_model.dart';
import '../models/language_model.dart';
import '../models/offline_pack_model.dart';
import '../models/sync_batch_model.dart';
import '../models/voice_model.dart';
import '../../core/offline/local_database.dart';
import 'vidyasetu_repository.dart';
import 'cloud_vidyasetu_repository.dart';
import 'offline_vidyasetu_repository.dart';

/// Single facade repository coordinating cloud endpoints and offline edge autopsy.
/// Automatically detects connectivity, routes requests, and drains `pending_sync_queue`.
class HybridVidyaSetuRepository implements VidyaSetuRepository {
  final CloudVidyaSetuRepository cloudRepo;
  final OfflineVidyaSetuRepository offlineRepo;
  final LocalDatabase localDb;
  final Connectivity? connectivity;

  HybridVidyaSetuRepository({
    required this.cloudRepo,
    required this.offlineRepo,
    required this.localDb,
    this.connectivity,
  });

  /// Fast connectivity and backend health check.
  Future<bool> isOnline() async {
    if (connectivity != null) {
      final results = await connectivity!.checkConnectivity();
      if (results.contains(ConnectivityResult.none)) {
        return false;
      }
    }
    final health = await cloudRepo.checkHealth();
    return health['status'] == 'healthy' || health['status'] == 'degraded';
  }

  @override
  Future<Map<String, dynamic>> checkHealth() async {
    final online = await isOnline();
    if (online) {
      final cloudHealth = await cloudRepo.checkHealth();
      return {...cloudHealth, 'mode': 'online'};
    }
    final offlineHealth = await offlineRepo.checkHealth();
    return {...offlineHealth, 'mode': 'offline'};
  }

  @override
  Future<StudentModel> registerStudent(StudentCreateRequest request) async {
    if (await isOnline()) {
      try {
        final student = await cloudRepo.registerStudent(request);
        localDb.saveStudent(student);
        return student;
      } catch (_) {
        // Fallback to offline on transient cloud errors
      }
    }
    return offlineRepo.registerStudent(request);
  }

  @override
  Future<StudentModel> getStudent(String studentId) async {
    if (await isOnline()) {
      try {
        final student = await cloudRepo.getStudent(studentId);
        localDb.saveStudent(student);
        return student;
      } catch (_) {
        // Fallback to offline
      }
    }
    return offlineRepo.getStudent(studentId);
  }

  @override
  Future<ProgressModel> updateProgress(
      String studentId, ProgressUpdateRequest request) async {
    if (await isOnline()) {
      try {
        final progress = await cloudRepo.updateProgress(studentId, request);
        localDb.upsertProgress(progress);
        return progress;
      } catch (_) {
        // Fallback to offline
      }
    }
    return offlineRepo.updateProgress(studentId, request);
  }

  @override
  Future<ProgressModel> getChapterProgress(
      String studentId, String chapterName) async {
    if (await isOnline()) {
      try {
        final progress = await cloudRepo.getChapterProgress(studentId, chapterName);
        localDb.upsertProgress(progress);
        return progress;
      } catch (_) {
        // Fallback to offline
      }
    }
    return offlineRepo.getChapterProgress(studentId, chapterName);
  }

  @override
  Future<List<ProgressModel>> getProgressList(String studentId) async {
    if (await isOnline()) {
      try {
        final list = await cloudRepo.getProgressList(studentId);
        for (final p in list) {
          localDb.upsertProgress(p);
        }
        return list;
      } catch (_) {
        // Fallback to offline
      }
    }
    return offlineRepo.getProgressList(studentId);
  }

  @override
  Future<List<QuestionModel>> getQuestions({
    String? subject,
    String? chapterName,
    String? conceptName,
  }) async {
    if (await isOnline()) {
      try {
        return await cloudRepo.getQuestions(
          subject: subject,
          chapterName: chapterName,
          conceptName: conceptName,
        );
      } catch (_) {
        // Fallback to offline
      }
    }
    return offlineRepo.getQuestions(
      subject: subject,
      chapterName: chapterName,
      conceptName: conceptName,
    );
  }

  @override
  Future<QuestionModel> getQuestion(String questionId) async {
    if (await isOnline()) {
      try {
        return await cloudRepo.getQuestion(questionId);
      } catch (_) {
        // Fallback to offline
      }
    }
    return offlineRepo.getQuestion(questionId);
  }

  @override
  Future<AttemptResponse> submitAttempt(AttemptRequest request) async {
    if (await isOnline()) {
      try {
        return await cloudRepo.submitAttempt(request);
      } catch (_) {
        // Fallback to offline
      }
    }
    return offlineRepo.submitAttempt(request);
  }

  @override
  Future<ProbeResponseResult> submitProbeResponse(
      ProbeResponseRequest request) async {
    if (await isOnline()) {
      try {
        return await cloudRepo.submitProbeResponse(request);
      } catch (_) {
        // Fallback to offline
      }
    }
    return offlineRepo.submitProbeResponse(request);
  }

  @override
  Future<RecoverySubmitResponse> submitRecovery(
      RecoverySubmitRequest request) async {
    if (await isOnline()) {
      try {
        final res = await cloudRepo.submitRecovery(request);
        // Sync flushed queue if any
        unawaited(syncPendingOfflineEvents());
        return res;
      } catch (_) {
        // Fallback to offline
      }
    }
    return offlineRepo.submitRecovery(request);
  }

  @override
  Future<LanguageExplainResponse> explainConcept(
      LanguageExplainRequest request) async {
    if (await isOnline()) {
      try {
        return await cloudRepo.explainConcept(request);
      } catch (_) {
        // Fallback to offline
      }
    }
    return offlineRepo.explainConcept(request);
  }

  @override
  Future<LanguageProgressResponse> getLanguageProgress(String studentId) async {
    if (await isOnline()) {
      try {
        return await cloudRepo.getLanguageProgress(studentId);
      } catch (_) {
        // Fallback to offline
      }
    }
    return offlineRepo.getLanguageProgress(studentId);
  }

  @override
  Future<OfflinePackModel> downloadOfflinePack(
      OfflinePackRequest request) async {
    final pack = await cloudRepo.downloadOfflinePack(request);
    localDb.cacheOfflinePack(pack);
    return pack;
  }

  @override
  Future<OfflineSyncBatchResponse> syncPendingOfflineEvents({String? studentId}) async {
    final pendingEvents = localDb.getPendingSyncEvents(studentId: studentId);
    if (pendingEvents.isEmpty) {
      return const OfflineSyncBatchResponse();
    }

    if (!await isOnline()) {
      return const OfflineSyncBatchResponse();
    }

    final targetStudentId = studentId ?? pendingEvents.first.studentId;
    final batchReq = OfflineSyncBatchRequest(
      studentId: targetStudentId,
      batchTimestamp: DateTime.now().toUtc(),
      events: pendingEvents,
    );

    final res = await cloudRepo.syncPendingOfflineEvents(
      studentId: targetStudentId,
      batchRequest: batchReq,
    );

    // Remove successfully processed events (synced + duplicate)
    final acknowledgedIds = {...res.syncedIds, ...res.duplicateIds}.toList();
    localDb.removeSyncedEvents(acknowledgedIds);

    return res;
  }

  @override
  Future<TtsResponse> synthesizeSpeech(TtsRequest request) async {
    if (await isOnline()) {
      return cloudRepo.synthesizeSpeech(request);
    }
    return offlineRepo.synthesizeSpeech(request);
  }

  @override
  Future<List<int>> synthesizeSpeechAudio(TtsRequest request) async {
    if (await isOnline()) {
      return cloudRepo.synthesizeSpeechAudio(request);
    }
    return offlineRepo.synthesizeSpeechAudio(request);
  }

  @override
  Future<SttResponse> transcribeAudio({
    required List<int> audioBytes,
    required String filename,
    String languageCode = 'od-IN',
    String mode = 'codemix',
    String? keytermsCsv,
  }) async {
    if (await isOnline()) {
      return cloudRepo.transcribeAudio(
        audioBytes: audioBytes,
        filename: filename,
        languageCode: languageCode,
        mode: mode,
        keytermsCsv: keytermsCsv,
      );
    }
    return offlineRepo.transcribeAudio(
      audioBytes: audioBytes,
      filename: filename,
      languageCode: languageCode,
      mode: mode,
      keytermsCsv: keytermsCsv,
    );
  }
}
