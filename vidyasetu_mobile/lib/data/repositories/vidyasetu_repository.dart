import '../../data/models/student_model.dart';
import '../../data/models/progress_model.dart';
import '../../data/models/question_model.dart';
import '../../data/models/diagnostic_model.dart';
import '../../data/models/language_model.dart';
import '../../data/models/offline_pack_model.dart';
import '../../data/models/sync_batch_model.dart';
import '../../data/models/voice_model.dart';

/// Unified repository interface for VidyaSetu client SDK.
/// UI screens and feature blocs interact exclusively with this contract.
abstract class VidyaSetuRepository {
  /// Checks backend health and database connectivity.
  Future<Map<String, dynamic>> checkHealth();

  /// Registers a new student profile.
  Future<StudentModel> registerStudent(StudentCreateRequest request);

  /// Retrieves student profile by ID.
  Future<StudentModel> getStudent(String studentId);

  /// Upserts chapter progress metrics.
  Future<ProgressModel> updateProgress(String studentId, ProgressUpdateRequest request);

  /// Retrieves chapter progress for a specific chapter.
  Future<ProgressModel> getChapterProgress(String studentId, String chapterName);

  /// Retrieves all chapter progress records for a student.
  Future<List<ProgressModel>> getProgressList(String studentId);

  /// Retrieves questions matching optional filters.
  Future<List<QuestionModel>> getQuestions({
    String? subject,
    String? chapterName,
    String? conceptName,
  });

  /// Retrieves a single question by ID.
  Future<QuestionModel> getQuestion(String questionId);

  /// Step A: Submits question answer telemetry to trigger the WHY Engine.
  Future<AttemptResponse> submitAttempt(AttemptRequest request);

  /// Step B: Submits student response to a diagnostic probe.
  Future<ProbeResponseResult> submitProbeResponse(ProbeResponseRequest request);

  /// Step C: Submits student answer to immediate recovery practice question.
  Future<RecoverySubmitResponse> submitRecovery(RecoverySubmitRequest request);

  /// Requests 3-Way Language Bridge explanation for text/concept.
  Future<LanguageExplainResponse> explainConcept(LanguageExplainRequest request);

  /// Retrieves student language progression metrics.
  Future<LanguageProgressResponse> getLanguageProgress(String studentId);

  /// Downloads complete offline curriculum pack for on-device study.
  Future<OfflinePackModel> downloadOfflinePack(OfflinePackRequest request);

  /// Synchronizes queued offline events to the cloud.
  Future<OfflineSyncBatchResponse> syncPendingOfflineEvents({String? studentId});

  /// Synthesizes speech from text via Sarvam AI TTS (Base64 JSON).
  Future<TtsResponse> synthesizeSpeech(TtsRequest request);

  /// Synthesizes speech from text and returns raw binary audio bytes.
  Future<List<int>> synthesizeSpeechAudio(TtsRequest request);

  /// Transcribes audio payload into text using Sarvam AI STT.
  Future<SttResponse> transcribeAudio({
    required List<int> audioBytes,
    required String filename,
    String languageCode = 'od-IN',
    String mode = 'codemix',
    String? keytermsCsv,
  });
}
