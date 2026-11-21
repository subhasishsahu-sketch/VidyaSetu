import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../config/app_config.dart';
import '../../data/models/student_model.dart';
import '../../data/models/progress_model.dart';
import '../../data/models/question_model.dart';
import '../../data/models/offline_pack_model.dart';
import '../../data/models/sync_batch_model.dart';

/// Local SQLite database manager for offline persistence and curriculum RAG.
class LocalDatabase {
  Database? _writableDb;
  Database? _curriculumDb;

  final Database? injectedWritableDb;
  final Database? injectedCurriculumDb;

  LocalDatabase({
    this.injectedWritableDb,
    this.injectedCurriculumDb,
  }) {
    if (injectedWritableDb != null) {
      _writableDb = injectedWritableDb;
      _createWritableSchema(_writableDb!);
    }
    if (injectedCurriculumDb != null) {
      _curriculumDb = injectedCurriculumDb;
    }
  }

  Database get writableDb {
    if (_writableDb == null) {
      throw StateError('Writable database not initialized. Call init() first.');
    }
    return _writableDb!;
  }

  Database? get curriculumDb => _curriculumDb;

  /// Initializes writable app database and static offline curriculum database.
  Future<void> init() async {
    if (_writableDb == null) {
      final docDir = await getApplicationDocumentsDirectory();
      final appDbPath = p.join(docDir.path, 'vidyasetu_local.db');
      _writableDb = sqlite3.open(appDbPath);
      _createWritableSchema(_writableDb!);
    }

    if (_curriculumDb == null) {
      try {
        final docDir = await getApplicationDocumentsDirectory();
        final currPath = p.join(docDir.path, 'offline_curriculum.db');
        final currFile = File(currPath);

        if (!await currFile.exists()) {
          final assetData = await rootBundle.load(AppConfig.offlineDbAssetPath);
          await currFile.writeAsBytes(
            assetData.buffer.asUint8List(
              assetData.offsetInBytes,
              assetData.lengthInBytes,
            ),
            flush: true,
          );
        }
        _curriculumDb = sqlite3.open(currPath, mode: OpenMode.readOnly);
      } catch (e) {
        // Fallback: in headless or unit tests without Flutter assets, curriculumDb remains null
      }
    }
  }

  void _createWritableSchema(Database db) {
    db.execute('''
      CREATE TABLE IF NOT EXISTS students_local (
        student_id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        class_grade INTEGER NOT NULL,
        preferred_language TEXT NOT NULL,
        english_exposure_level INTEGER NOT NULL,
        subject TEXT NOT NULL,
        completed_chapters INTEGER DEFAULT 0,
        recommended_next_task TEXT,
        created_at TEXT NOT NULL
      );
    ''');

    db.execute('''
      CREATE TABLE IF NOT EXISTS progress_local (
        progress_id TEXT PRIMARY KEY,
        student_id TEXT NOT NULL,
        chapter_name TEXT NOT NULL,
        concept_understanding REAL NOT NULL,
        english_comprehension REAL NOT NULL,
        prerequisite_understanding REAL NOT NULL,
        time_management REAL NOT NULL,
        confidence_level REAL NOT NULL,
        previous_performance_score REAL NOT NULL,
        overall_mastery REAL NOT NULL,
        last_updated TEXT NOT NULL,
        UNIQUE(student_id, chapter_name)
      );
    ''');

    db.execute('''
      CREATE TABLE IF NOT EXISTS offline_pack_cache (
        pack_id TEXT PRIMARY KEY,
        subject TEXT NOT NULL,
        chapter_name TEXT NOT NULL,
        cached_questions_json TEXT NOT NULL,
        local_rag_vectors_json TEXT,
        cached_at TEXT NOT NULL,
        UNIQUE(subject, chapter_name)
      );
    ''');

    db.execute('''
      CREATE TABLE IF NOT EXISTS pending_sync_queue (
        analysis_id TEXT PRIMARY KEY,
        student_id TEXT NOT NULL,
        question_id TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        created_at TEXT NOT NULL
      );
    ''');
  }

  // --- Student operations ---

  void saveStudent(StudentModel student) {
    final stmt = writableDb.prepare('''
      INSERT OR REPLACE INTO students_local (
        student_id, name, class_grade, preferred_language,
        english_exposure_level, subject, completed_chapters,
        recommended_next_task, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
    ''');
    try {
      stmt.execute([
        student.studentId.toLowerCase(),
        student.name,
        student.classGrade,
        student.preferredLanguage,
        student.englishExposureLevel,
        student.subject,
        student.completedChapters,
        student.recommendedNextTask != null
            ? jsonEncode(student.recommendedNextTask)
            : null,
        student.createdAt.toUtc().toIso8601String(),
      ]);
    } finally {
      stmt.close();
    }
  }

  StudentModel? getStudent(String studentId) {
    final cleanId = studentId.trim().toLowerCase();
    final rows = writableDb.select(
      'SELECT * FROM students_local WHERE student_id = ? LIMIT 1;',
      [cleanId],
    );
    if (rows.isEmpty) return null;
    final r = rows.first;
    return StudentModel(
      studentId: cleanId,
      name: (r['name'] ?? '').toString(),
      classGrade: (r['class_grade'] as num).toInt(),
      preferredLanguage: (r['preferred_language'] ?? 'Odia').toString(),
      englishExposureLevel: (r['english_exposure_level'] as num).toInt(),
      subject: (r['subject'] ?? '').toString(),
      completedChapters: ((r['completed_chapters'] as num?) ?? 0).toInt(),
      recommendedNextTask: r['recommended_next_task'] != null
          ? jsonDecode(r['recommended_next_task'].toString()) as Map<String, dynamic>
          : null,
      createdAt: DateTime.parse(r['created_at'].toString()),
    );
  }

  // --- Progress operations ---

  void upsertProgress(ProgressModel progress) {
    final stmt = writableDb.prepare('''
      INSERT INTO progress_local (
        progress_id, student_id, chapter_name, concept_understanding,
        english_comprehension, prerequisite_understanding, time_management,
        confidence_level, previous_performance_score, overall_mastery, last_updated
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(student_id, chapter_name) DO UPDATE SET
        concept_understanding = excluded.concept_understanding,
        english_comprehension = excluded.english_comprehension,
        prerequisite_understanding = excluded.prerequisite_understanding,
        time_management = excluded.time_management,
        confidence_level = excluded.confidence_level,
        previous_performance_score = excluded.previous_performance_score,
        overall_mastery = excluded.overall_mastery,
        last_updated = excluded.last_updated;
    ''');
    try {
      stmt.execute([
        progress.progressId.toLowerCase(),
        progress.studentId.toLowerCase(),
        progress.chapterName.trim(),
        progress.conceptUnderstanding,
        progress.englishComprehension,
        progress.prerequisiteUnderstanding,
        progress.timeManagement,
        progress.confidenceLevel,
        progress.previousPerformanceScore,
        progress.overallMastery,
        progress.lastUpdated.toUtc().toIso8601String(),
      ]);
    } finally {
      stmt.close();
    }
  }

  ProgressModel? getChapterProgress(String studentId, String chapterName) {
    final cleanId = studentId.trim().toLowerCase();
    final cleanChap = chapterName.trim();
    final rows = writableDb.select(
      'SELECT * FROM progress_local WHERE student_id = ? AND chapter_name = ? LIMIT 1;',
      [cleanId, cleanChap],
    );
    if (rows.isEmpty) return null;
    final r = rows.first;
    return ProgressModel(
      progressId: (r['progress_id'] ?? '').toString().toLowerCase(),
      studentId: cleanId,
      chapterName: cleanChap,
      conceptUnderstanding: (r['concept_understanding'] as num).toDouble(),
      englishComprehension: (r['english_comprehension'] as num).toDouble(),
      prerequisiteUnderstanding: (r['prerequisite_understanding'] as num).toDouble(),
      timeManagement: (r['time_management'] as num).toDouble(),
      confidenceLevel: (r['confidence_level'] as num).toDouble(),
      previousPerformanceScore: (r['previous_performance_score'] as num).toDouble(),
      overallMastery: (r['overall_mastery'] as num).toDouble(),
      lastUpdated: DateTime.parse(r['last_updated'].toString()),
    );
  }

  List<ProgressModel> getProgressList(String studentId) {
    final cleanId = studentId.trim().toLowerCase();
    final rows = writableDb.select(
      'SELECT * FROM progress_local WHERE student_id = ? ORDER BY last_updated DESC;',
      [cleanId],
    );
    return rows.map((r) {
      return ProgressModel(
        progressId: (r['progress_id'] ?? '').toString().toLowerCase(),
        studentId: cleanId,
        chapterName: (r['chapter_name'] ?? '').toString(),
        conceptUnderstanding: (r['concept_understanding'] as num).toDouble(),
        englishComprehension: (r['english_comprehension'] as num).toDouble(),
        prerequisiteUnderstanding: (r['prerequisite_understanding'] as num).toDouble(),
        timeManagement: (r['time_management'] as num).toDouble(),
        confidenceLevel: (r['confidence_level'] as num).toDouble(),
        previousPerformanceScore: (r['previous_performance_score'] as num).toDouble(),
        overallMastery: (r['overall_mastery'] as num).toDouble(),
        lastUpdated: DateTime.parse(r['last_updated'].toString()),
      );
    }).toList();
  }

  // --- Offline Pack operations ---

  void cacheOfflinePack(OfflinePackModel pack) {
    final qJson = jsonEncode(pack.cachedQuestions.map((q) => q.toJson(includeAnswers: true)).toList());
    final vJson = jsonEncode(pack.localRagVectors.map((v) => v.toJson()).toList());

    final stmt = writableDb.prepare('''
      INSERT INTO offline_pack_cache (
        pack_id, subject, chapter_name, cached_questions_json,
        local_rag_vectors_json, cached_at
      ) VALUES (?, ?, ?, ?, ?, ?)
      ON CONFLICT(subject, chapter_name) DO UPDATE SET
        pack_id = excluded.pack_id,
        cached_questions_json = excluded.cached_questions_json,
        local_rag_vectors_json = excluded.local_rag_vectors_json,
        cached_at = excluded.cached_at;
    ''');
    try {
      stmt.execute([
        pack.packId,
        pack.subject.trim(),
        pack.chapterName.trim(),
        qJson,
        vJson,
        pack.cachedAt.toUtc().toIso8601String(),
      ]);
    } finally {
      stmt.close();
    }
  }

  OfflinePackModel? getCachedOfflinePack(String subject, String chapterName) {
    final cleanSub = subject.trim();
    final cleanChap = chapterName.trim();
    final rows = writableDb.select(
      'SELECT * FROM offline_pack_cache WHERE LOWER(subject) = LOWER(?) AND LOWER(chapter_name) = LOWER(?) LIMIT 1;',
      [cleanSub, cleanChap],
    );
    if (rows.isEmpty) return null;
    final r = rows.first;

    final qList = (jsonDecode(r['cached_questions_json'].toString()) as List)
        .map((q) => QuestionModel.fromJson(Map<String, dynamic>.from(q as Map)))
        .toList();

    List<RagTextbookVectorModel> vList = [];
    if (r['local_rag_vectors_json'] != null) {
      vList = (jsonDecode(r['local_rag_vectors_json'].toString()) as List)
          .map((v) => RagTextbookVectorModel.fromJson(Map<String, dynamic>.from(v as Map)))
          .toList();
    }

    return OfflinePackModel(
      packId: (r['pack_id'] ?? '').toString(),
      subject: (r['subject'] ?? '').toString(),
      chapterName: (r['chapter_name'] ?? '').toString(),
      cachedQuestions: qList,
      localRagVectors: vList,
      cachedAt: DateTime.parse(r['cached_at'].toString()),
    );
  }

  List<QuestionModel> getCachedQuestions({
    String? subject,
    String? chapterName,
    String? conceptName,
  }) {
    final rows = writableDb.select('SELECT cached_questions_json FROM offline_pack_cache;');
    final allQuestions = <QuestionModel>[];
    for (final r in rows) {
      final list = (jsonDecode(r['cached_questions_json'].toString()) as List)
          .map((q) => QuestionModel.fromJson(Map<String, dynamic>.from(q as Map)));
      allQuestions.addAll(list);
    }

    return allQuestions.where((q) {
      if (subject != null && q.subject.toLowerCase() != subject.trim().toLowerCase()) {
        return false;
      }
      if (chapterName != null && q.chapterName.toLowerCase() != chapterName.trim().toLowerCase()) {
        return false;
      }
      if (conceptName != null && q.conceptName.toString().toLowerCase() != conceptName.trim().toLowerCase()) {
        return false;
      }
      return true;
    }).toList();
  }

  // --- Pending Sync Queue ---

  void enqueueSyncEvent(OfflineSyncEvent event) {
    final stmt = writableDb.prepare('''
      INSERT OR REPLACE INTO pending_sync_queue (
        analysis_id, student_id, question_id, payload_json, created_at
      ) VALUES (?, ?, ?, ?, ?);
    ''');
    try {
      stmt.execute([
        event.analysisId.toLowerCase(),
        event.studentId.toLowerCase(),
        event.questionId.toLowerCase(),
        jsonEncode(event.toJson()),
        event.offlineCreatedAt.toUtc().toIso8601String(),
      ]);
    } finally {
      stmt.close();
    }
  }

  List<OfflineSyncEvent> getPendingSyncEvents({String? studentId, int limit = 50}) {
    ResultSet rows;
    if (studentId != null && studentId.isNotEmpty) {
      rows = writableDb.select(
        'SELECT payload_json FROM pending_sync_queue WHERE student_id = ? ORDER BY created_at ASC LIMIT ?;',
        [studentId.trim().toLowerCase(), limit],
      );
    } else {
      rows = writableDb.select(
        'SELECT payload_json FROM pending_sync_queue ORDER BY created_at ASC LIMIT ?;',
        [limit],
      );
    }

    return rows.map((r) {
      final map = jsonDecode(r['payload_json'].toString()) as Map<String, dynamic>;
      return OfflineSyncEvent.fromJson(map);
    }).toList();
  }

  void removeSyncedEvents(List<String> analysisIds) {
    if (analysisIds.isEmpty) return;
    final placeholders = List.filled(analysisIds.length, '?').join(',');
    final cleanIds = analysisIds.map((id) => id.trim().toLowerCase()).toList();
    writableDb.execute(
      'DELETE FROM pending_sync_queue WHERE analysis_id IN ($placeholders);',
      cleanIds,
    );
  }

  int getPendingQueueCount() {
    final rows = writableDb.select('SELECT COUNT(*) AS cnt FROM pending_sync_queue;');
    return (rows.first['cnt'] as num).toInt();
  }

  // --- Static Curriculum Textbook FTS Queries ---

  Map<String, dynamic>? queryOfflineFtsChunk(String queryText, {String? subject, String? chapterName}) {
    final db = _curriculumDb;
    if (db == null) return null;

    final tokenRegex = RegExp(r'[A-Za-z0-9\u0B00-\u0B7F]{2,}');
    final rawTokens = tokenRegex.allMatches(queryText).map((m) => m.group(0)!).toList();
    if (rawTokens.isEmpty) return null;

    final escapedQuery = rawTokens.map((t) => '"${t.replaceAll('"', '')}"').join(' OR ');

    try {
      final rows = db.select(
        '''
        SELECT chunk_id, subject, chapter_name, section_heading,
               english_tech_terms, content_odia
        FROM offline_chunks_fts
        WHERE offline_chunks_fts MATCH ?
        LIMIT 1;
        ''',
        [escapedQuery],
      );
      if (rows.isNotEmpty) {
        final r = rows.first;
        return {
          'chunk_id': r['chunk_id'],
          'subject': r['subject'],
          'chapter_name': r['chapter_name'],
          'section_heading': r['section_heading'],
          'english_tech_terms': r['english_tech_terms'],
          'chunk_text': r['content_odia'],
        };
      }
    } catch (_) {
      // Fallback if FTS match expression fails or table missing
    }
    return null;
  }

  void close() {
    _writableDb?.close();
    _curriculumDb?.close();
    _writableDb = null;
    _curriculumDb = null;
  }
}
