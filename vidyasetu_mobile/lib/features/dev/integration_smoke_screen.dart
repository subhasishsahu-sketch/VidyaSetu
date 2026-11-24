import 'dart:convert';
import 'package:flutter/material.dart';

import '../../core/offline/local_database.dart';
import '../../data/models/student_model.dart';
import '../../data/models/question_model.dart';
import '../../data/models/diagnostic_model.dart';
import '../../data/models/offline_pack_model.dart';
import '../../data/repositories/cloud_vidyasetu_repository.dart';
import '../../data/repositories/offline_vidyasetu_repository.dart';
import '../../data/repositories/hybrid_vidyasetu_repository.dart';

class IntegrationSmokeScreen extends StatefulWidget {
  const IntegrationSmokeScreen({super.key});

  @override
  State<IntegrationSmokeScreen> createState() => _IntegrationSmokeScreenState();
}

class _IntegrationSmokeScreenState extends State<IntegrationSmokeScreen> {
  late final LocalDatabase _localDb;
  late final CloudVidyaSetuRepository _cloudRepo;
  late final OfflineVidyaSetuRepository _offlineRepo;
  late final HybridVidyaSetuRepository _hybridRepo;

  bool _initialized = false;
  bool _loading = false;
  final StringBuffer _logs = StringBuffer();
  final ScrollController _scrollController = ScrollController();

  StudentModel? _demoStudent;

  @override
  void initState() {
    super.initState();
    _initSdk();
  }

  Future<void> _initSdk() async {
    setState(() => _loading = true);
    try {
      _localDb = LocalDatabase();
      await _localDb.init();
      _cloudRepo = CloudVidyaSetuRepository();
      _offlineRepo = OfflineVidyaSetuRepository(localDb: _localDb);
      _hybridRepo = HybridVidyaSetuRepository(
        cloudRepo: _cloudRepo,
        offlineRepo: _offlineRepo,
        localDb: _localDb,
      );
      _appendLog('[INIT] VidyaSetu SDK initialized successfully.');
      _appendLog('[CONFIG] Base URL: ${_cloudRepo.baseUrl}');
      setState(() => _initialized = true);
    } catch (e, st) {
      _appendLog('[INIT ERROR] Failed to initialize SDK: $e\n$st');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _appendLog(String text) {
    final now = DateTime.now().toIso8601String().substring(11, 19);
    setState(() {
      _logs.writeln('[$now] $text');
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatJson(dynamic data) {
    const encoder = JsonEncoder.withIndent('  ');
    try {
      return encoder.convert(data);
    } catch (_) {
      return data.toString();
    }
  }

  // 1. Check Backend Health
  Future<void> _checkHealth() async {
    setState(() => _loading = true);
    _appendLog('--- 1. Checking Backend Health ---');
    try {
      final health = await _hybridRepo.checkHealth();
      _appendLog('Health Check Result:\n${_formatJson(health)}');
    } catch (e) {
      _appendLog('Health Check Failed: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  // 2. Register Demo Student & Load Questions
  Future<void> _registerStudentAndLoadQuestions() async {
    setState(() => _loading = true);
    _appendLog('--- 2. Registering Student & Fetching Questions ---');
    try {
      final req = const StudentCreateRequest(
        name: 'Suhani Sahu',
        classGrade: 10,
        preferredLanguage: 'Odia',
        subject: 'History',
      );
      final student = await _hybridRepo.registerStudent(req);
      _demoStudent = student;
      _appendLog('Student Registered:\n${_formatJson(student.toJson())}');

      final questions = await _hybridRepo.getQuestions(subject: 'History');
      _appendLog('Fetched ${questions.length} question(s) for History.');
      if (questions.isNotEmpty) {
        _appendLog(
          'First Question Sample (Answers Stripped):\n${_formatJson(questions.first.toJson(includeAnswers: false))}',
        );
      }
    } catch (e) {
      _appendLog('Register/Fetch Questions Failed: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  // 3. Download History Offline Pack
  Future<void> _downloadOfflinePack() async {
    setState(() => _loading = true);
    _appendLog('--- 3. Downloading History Offline Pack ---');
    try {
      final req = OfflinePackRequest(
        subject: 'History',
        chapterName: 'India After Independence',
      );
      final pack = await _hybridRepo.downloadOfflinePack(req);
      _appendLog('Offline Pack Cached:\n'
          '  Pack ID: ${pack.packId}\n'
          '  Subject: ${pack.subject}\n'
          '  Chapter: ${pack.chapterName}\n'
          '  Cached Questions: ${pack.cachedQuestions.length}\n'
          '  Local RAG Vectors: ${pack.localRagVectors.length}\n'
          '  Cached At: ${pack.cachedAt.toIso8601String()}');
    } catch (e) {
      _appendLog('Download Offline Pack Failed: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  // 4. Run Offline Autopsy (Attempt -> Probe -> Recovery)
  Future<void> _runOfflineAutopsy() async {
    setState(() => _loading = true);
    _appendLog('--- 4. Running Offline Mark-Loss Autopsy ---');
    try {
      var student = _demoStudent;
      if (student == null) {
        _appendLog('No demo student loaded. Creating offline student profile...');
        student = await _offlineRepo.registerStudent(const StudentCreateRequest(
          name: 'Offline Learner',
          classGrade: 10,
          preferredLanguage: 'Odia',
          subject: 'History',
        ));
        _demoStudent = student;
      }

      var questions = await _offlineRepo.getQuestions(subject: 'History');
      if (questions.isEmpty) {
        _appendLog('No offline questions found in cache. Creating fallback offline question...');
        final fallbackQ = QuestionModel(
          questionId: 'q-demo-offline-01',
          subject: 'History',
          chapterName: 'India After Independence',
          conceptName: 'Merger of Princely States',
          questionText: 'Which agreement did Sardar Patel ask rulers to sign?',
          options: const [
            QuestionOption(key: 'A', text: 'Poona Pact'),
            QuestionOption(key: 'B', text: 'Instrument of Accession'),
          ],
          correctAnswer: 'B',
          expectedTimeSec: 45,
          diagnosticProbes: const DiagnosticProbes(
            languageProbe: {
              'prompt_odia': 'କେଉଁ ଚୁକ୍ତିପତ୍ର ସ୍ଵାକ୍ଷର କଲେ?',
              'correct_answer': 'B',
            },
            untimedRetry: {},
            prerequisiteProbe: {},
            transferProbe: {},
            explainBack: {},
          ),
          recoveryPracticeQuestions: const [
            RecoveryPracticeQuestionModel(
              practiceId: 'REC-DEMO-01',
              questionText: 'How many princely states were there?',
              options: [QuestionOption(key: 'B', text: '565')],
              answerKey: 'B',
            ),
          ],
        );
        _localDb.cacheOfflinePack(OfflinePackModel(
          packId: 'demo-pack',
          subject: 'History',
          chapterName: 'India After Independence',
          cachedQuestions: [fallbackQ],
          cachedAt: DateTime.now().toUtc(),
        ));
        questions = [fallbackQ];
      }

      final targetQ = questions.first;

      // Step A: Attempt wrong answer
      _appendLog('[Step A] Submitting incorrect option A...');
      final attemptRes = await _offlineRepo.submitAttempt(AttemptRequest(
        studentId: student.studentId,
        questionId: targetQ.questionId,
        selectedOption: 'A',
        timeTakenSec: 18.0,
        confidenceRating: 80.0,
      ));
      _appendLog('Attempt Result: is_correct=${attemptRes.isCorrect}, status=${attemptRes.status}');
      _appendLog(
        'Ranked Root Cause Hypotheses:\n${_formatJson(attemptRes.candidateHypotheses.map((h) => h.toJson()).toList())}',
      );

      final analysisId = attemptRes.analysisId;
      final probeType = attemptRes.selectedProbe?['probe_type'] ?? 'language_probe';

      // Step B: Submit Probe
      _appendLog('[Step B] Submitting probe answer ($probeType)...');
      final probeRes = await _offlineRepo.submitProbeResponse(ProbeResponseRequest(
        analysisId: analysisId,
        probeType: probeType,
        submittedAnswer: 'B',
        timeTakenSec: 15.0,
      ));
      _appendLog('Probe Result: status=${probeRes.status}, confidence=${probeRes.confidenceScore}');

      if (probeRes.intervention != null) {
        _appendLog('=== 3-WAY LANGUAGE BRIDGE INTERVENTION (ODIA UNICODE) ===\n'
            '${_formatJson(probeRes.intervention!.toJson())}');
      }

      // Step C: Submit Recovery
      final practiceId = probeRes.recoveryPracticeQuestion?.practiceId ??
          targetQ.recoveryPracticeQuestions.firstOrNull?.practiceId ??
          'REC-DEMO-01';

      _appendLog('[Step C] Submitting recovery answer ($practiceId)...');
      final recoveryRes = await _offlineRepo.submitRecovery(RecoverySubmitRequest(
        analysisId: analysisId,
        practiceId: practiceId,
        submittedAnswer: 'B',
      ));
      _appendLog('Recovery Result: is_correct=${recoveryRes.isCorrect}, improved=${recoveryRes.hasStudentImproved}');
      _appendLog('Updated Scores Boost:\n${_formatJson(recoveryRes.updatedScores)}');
      _appendLog('Recommended Next Task:\n${_formatJson(recoveryRes.recommendedNextTask)}');
      _appendLog('Pending Offline Events Queued: ${_localDb.getPendingQueueCount()}');
    } catch (e, st) {
      _appendLog('Offline Autopsy Error: $e\n$st');
    } finally {
      setState(() => _loading = false);
    }
  }

  // 5. Sync Offline Queue to MongoDB
  Future<void> _syncOfflineQueue() async {
    setState(() => _loading = true);
    _appendLog('--- 5. Synchronizing Offline Queue to MongoDB ---');
    try {
      final queueCount = _localDb.getPendingQueueCount();
      _appendLog('Queued events in local SQLite: $queueCount');
      if (queueCount == 0) {
        _appendLog('Queue is empty. Run Step 4 first to generate offline events.');
        return;
      }

      final res = await _hybridRepo.syncPendingOfflineEvents(
        studentId: _demoStudent?.studentId,
      );
      _appendLog('Batch Sync Response:\n${_formatJson(res.toJson())}');
      _appendLog('Remaining in Local Queue: ${_localDb.getPendingQueueCount()}');
    } catch (e) {
      _appendLog('Sync Failed: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _localDb.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VidyaSetu Integration Smoke Screen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear Logs',
            onPressed: () => setState(() => _logs.clear()),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_loading) const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _loading || !_initialized ? null : _checkHealth,
                  icon: const Icon(Icons.health_and_safety),
                  label: const Text('1. Check Backend Health'),
                ),
                ElevatedButton.icon(
                  onPressed: _loading || !_initialized ? null : _registerStudentAndLoadQuestions,
                  icon: const Icon(Icons.person_add),
                  label: const Text('2. Register Demo Student & Load Questions'),
                ),
                ElevatedButton.icon(
                  onPressed: _loading || !_initialized ? null : _downloadOfflinePack,
                  icon: const Icon(Icons.cloud_download),
                  label: const Text('3. Download History Offline Pack'),
                ),
                ElevatedButton.icon(
                  onPressed: _loading || !_initialized ? null : _runOfflineAutopsy,
                  icon: const Icon(Icons.biotech),
                  label: const Text('4. Run Offline Autopsy (Attempt -> Probe -> Recovery)'),
                ),
                ElevatedButton.icon(
                  onPressed: _loading || !_initialized ? null : _syncOfflineQueue,
                  icon: const Icon(Icons.sync),
                  label: const Text('5. Sync Offline Queue to MongoDB'),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'JSON & Telemetry Output Console:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  _initialized ? 'SDK: READY' : 'SDK: INITIALIZING...',
                  style: TextStyle(
                    color: _initialized ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade700),
                ),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: SelectableText(
                    _logs.isEmpty ? 'Tap any button above to test the integration SDK...' : _logs.toString(),
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 12,
                      color: Colors.greenAccent,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
