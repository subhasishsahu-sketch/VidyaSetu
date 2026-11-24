import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../models/student_model.dart';
import '../models/progress_model.dart';
import '../models/question_model.dart';
import '../models/diagnostic_model.dart';
import '../models/language_model.dart';
import '../models/offline_pack_model.dart';
import '../models/sync_batch_model.dart';
import '../models/voice_model.dart';
import '../../core/config/app_config.dart';
import 'vidyasetu_repository.dart';

/// Cloud implementation of VidyaSetuRepository targeting FastAPI `/api/v1/*`.
class CloudVidyaSetuRepository implements VidyaSetuRepository {
  final http.Client _client;
  final String _baseUrl;

  CloudVidyaSetuRepository({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  String get baseUrl => _baseUrl;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  @override
  Future<Map<String, dynamic>> checkHealth() async {
    final uri = Uri.parse('$_baseUrl/health');
    try {
      final res = await _client.get(uri).timeout(AppConfig.healthTimeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      return {'status': 'unhealthy', 'statusCode': res.statusCode};
    } catch (e) {
      return {'status': 'disconnected', 'error': e.toString()};
    }
  }

  @override
  Future<StudentModel> registerStudent(StudentCreateRequest request) async {
    final uri = Uri.parse('$_baseUrl/students');
    final res = await _client
        .post(uri, headers: _headers, body: jsonEncode(request.toJson()))
        .timeout(AppConfig.requestTimeout);

    _assertSuccess(res, 'Failed to register student');
    return StudentModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  @override
  Future<StudentModel> getStudent(String studentId) async {
    final uri = Uri.parse('$_baseUrl/students/${studentId.trim().toLowerCase()}');
    final res = await _client.get(uri, headers: _headers).timeout(AppConfig.requestTimeout);

    _assertSuccess(res, 'Student $studentId not found');
    return StudentModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  @override
  Future<ProgressModel> updateProgress(
      String studentId, ProgressUpdateRequest request) async {
    final uri = Uri.parse('$_baseUrl/students/${studentId.trim().toLowerCase()}/progress');
    final res = await _client
        .post(uri, headers: _headers, body: jsonEncode(request.toJson()))
        .timeout(AppConfig.requestTimeout);

    _assertSuccess(res, 'Failed to update progress');
    return ProgressModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  @override
  Future<ProgressModel> getChapterProgress(
      String studentId, String chapterName) async {
    final encoded = Uri.encodeComponent(chapterName.trim());
    final uri = Uri.parse('$_baseUrl/students/${studentId.trim().toLowerCase()}/progress/$encoded');
    final res = await _client.get(uri, headers: _headers).timeout(AppConfig.requestTimeout);

    _assertSuccess(res, 'Progress for $chapterName not found');
    return ProgressModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  @override
  Future<List<ProgressModel>> getProgressList(String studentId) async {
    final uri = Uri.parse('$_baseUrl/students/${studentId.trim().toLowerCase()}/progress');
    final res = await _client.get(uri, headers: _headers).timeout(AppConfig.requestTimeout);

    _assertSuccess(res, 'Failed to get progress list');
    final list = jsonDecode(res.body) as List;
    return list.map((item) => ProgressModel.fromJson(Map<String, dynamic>.from(item as Map))).toList();
  }

  @override
  Future<List<QuestionModel>> getQuestions({
    String? subject,
    String? chapterName,
    String? conceptName,
  }) async {
    final qParams = <String, String>{};
    if (subject != null) qParams['subject'] = subject;
    if (chapterName != null) qParams['chapter_name'] = chapterName;
    if (conceptName != null) qParams['concept_name'] = conceptName;

    final uri = Uri.parse('$_baseUrl/questions').replace(queryParameters: qParams.isNotEmpty ? qParams : null);
    final res = await _client.get(uri, headers: _headers).timeout(AppConfig.requestTimeout);

    _assertSuccess(res, 'Failed to list questions');
    final list = jsonDecode(res.body) as List;
    return list.map((item) => QuestionModel.fromJson(Map<String, dynamic>.from(item as Map))).toList();
  }

  @override
  Future<QuestionModel> getQuestion(String questionId) async {
    final uri = Uri.parse('$_baseUrl/questions/${questionId.trim().toLowerCase()}');
    final res = await _client.get(uri, headers: _headers).timeout(AppConfig.requestTimeout);

    _assertSuccess(res, 'Question $questionId not found');
    return QuestionModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  @override
  Future<AttemptResponse> submitAttempt(AttemptRequest request) async {
    final uri = Uri.parse('$_baseUrl/diagnostics/attempt');
    final res = await _client
        .post(uri, headers: _headers, body: jsonEncode(request.toJson()))
        .timeout(AppConfig.requestTimeout);

    _assertSuccess(res, 'Diagnostic attempt evaluation failed');
    return AttemptResponse.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  @override
  Future<ProbeResponseResult> submitProbeResponse(
      ProbeResponseRequest request) async {
    final uri = Uri.parse('$_baseUrl/diagnostics/probe-response');
    final res = await _client
        .post(uri, headers: _headers, body: jsonEncode(request.toJson()))
        .timeout(AppConfig.requestTimeout);

    _assertSuccess(res, 'Diagnostic probe evaluation failed');
    return ProbeResponseResult.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  @override
  Future<RecoverySubmitResponse> submitRecovery(
      RecoverySubmitRequest request) async {
    final uri = Uri.parse('$_baseUrl/diagnostics/recovery');
    final res = await _client
        .post(uri, headers: _headers, body: jsonEncode(request.toJson()))
        .timeout(AppConfig.requestTimeout);

    _assertSuccess(res, 'Recovery evaluation failed');
    return RecoverySubmitResponse.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  @override
  Future<LanguageExplainResponse> explainConcept(
      LanguageExplainRequest request) async {
    final uri = Uri.parse('$_baseUrl/language/explain');
    final res = await _client
        .post(uri, headers: _headers, body: jsonEncode(request.toJson()))
        .timeout(AppConfig.requestTimeout);

    _assertSuccess(res, 'Language explanation failed');
    return LanguageExplainResponse.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  @override
  Future<LanguageProgressResponse> getLanguageProgress(String studentId) async {
    final uri = Uri.parse('$_baseUrl/language/progress/${studentId.trim().toLowerCase()}');
    final res = await _client.get(uri, headers: _headers).timeout(AppConfig.requestTimeout);

    _assertSuccess(res, 'Failed to fetch language progress');
    return LanguageProgressResponse.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  @override
  Future<OfflinePackModel> downloadOfflinePack(
      OfflinePackRequest request) async {
    final uri = Uri.parse('$_baseUrl/offline-packs');
    final res = await _client
        .post(uri, headers: _headers, body: jsonEncode(request.toJson()))
        .timeout(const Duration(seconds: 30));

    _assertSuccess(res, 'Failed to download offline pack');
    return OfflinePackModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  @override
  Future<OfflineSyncBatchResponse> syncPendingOfflineEvents({
    String? studentId,
    OfflineSyncBatchRequest? batchRequest,
  }) async {
    if (batchRequest == null) {
      return const OfflineSyncBatchResponse();
    }
    final uri = Uri.parse('$_baseUrl/sync/offline-analysis');
    final res = await _client
        .post(uri, headers: _headers, body: jsonEncode(batchRequest.toJson()))
        .timeout(const Duration(seconds: 30));

    _assertSuccess(res, 'Offline sync failed');
    return OfflineSyncBatchResponse.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  @override
  Future<TtsResponse> synthesizeSpeech(TtsRequest request) async {
    final uri = Uri.parse('$_baseUrl/voice/tts');
    final res = await _client
        .post(uri, headers: _headers, body: jsonEncode(request.toJson()))
        .timeout(AppConfig.requestTimeout);

    _assertSuccess(res, 'Voice synthesis failed');
    return TtsResponse.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  @override
  Future<List<int>> synthesizeSpeechAudio(TtsRequest request) async {
    final uri = Uri.parse('$_baseUrl/voice/tts/audio');
    final res = await _client
        .post(uri, headers: _headers, body: jsonEncode(request.toJson()))
        .timeout(AppConfig.requestTimeout);

    _assertSuccess(res, 'Audio synthesis failed');
    return res.bodyBytes;
  }

  @override
  Future<SttResponse> transcribeAudio({
    required List<int> audioBytes,
    required String filename,
    String languageCode = 'od-IN',
    String mode = 'codemix',
    String? keytermsCsv,
  }) async {
    final uri = Uri.parse('$_baseUrl/voice/stt');
    final request = http.MultipartRequest('POST', uri);
    request.fields['language_code'] = languageCode;
    request.fields['mode'] = mode;
    if (keytermsCsv != null) {
      request.fields['keyterms_csv'] = keytermsCsv;
    }
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      audioBytes,
      filename: filename,
    ));

    final streamedResponse =
        await _client.send(request).timeout(const Duration(seconds: 30));
    final res = await http.Response.fromStream(streamedResponse);
    _assertSuccess(res, 'Voice transcription failed');
    return SttResponse.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  void _assertSuccess(http.Response res, String message) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    String detail = res.body;
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map && decoded['detail'] != null) {
        detail = decoded['detail'].toString();
      }
    } catch (_) {}
    throw HttpException('$message [${res.statusCode}]: $detail');
  }

  void dispose() {
    _client.close();
  }
}
