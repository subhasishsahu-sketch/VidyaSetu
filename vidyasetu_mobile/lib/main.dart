import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sql;

void main() => runApp(const MaterialApp(home: OfflineRagSlmTestScreen()));

class OfflineRagSlmTestScreen extends StatefulWidget {
  const OfflineRagSlmTestScreen({super.key});

  @override
  State<OfflineRagSlmTestScreen> createState() => _OfflineRagSlmTestScreenState();
}

class _OfflineRagSlmTestScreenState extends State<OfflineRagSlmTestScreen> {
  final TextEditingController _searchController = TextEditingController(text: 'India After Independence');
  String _mode = 'questions'; // 'questions' or 'explain'
  String _status = 'Ready. Turn on Airplane Mode and tap Run Test.';
  String _citation = '';
  String _retrievedSnippet = '';
  String _streamedOutput = '';
  bool _running = false;

  static const Set<String> _stopwords = {
    'a', 'an', 'and', 'are', 'as', 'at', 'be', 'by', 'can', 'describe',
    'define', 'do', 'does', 'explain', 'for', 'from', 'give', 'how', 'i',
    'in', 'is', 'it', 'list', 'me', 'name', 'of', 'on', 'or', 'short',
    'state', 'tell', 'that', 'the', 'their', 'them', 'these', 'this',
    'to', 'was', 'were', 'what', 'when', 'where', 'which', 'who', 'why',
    'with', 'write', 'note', 'about', 'between',
    'କଣ', 'କାହିଁକି', 'କିପରି', 'କେଉଁ', 'କେତେ', 'ଏବଂ', 'ଓ', 'କିମ୍ବା', 'ବୁଝାଅ',
  };

  /// Port of `build_fts5_match_expression` from rag_runtime.py
  String _buildFts5MatchExpression(String rawQuery) {
    final tokenRegex = RegExp(r'[A-Za-z0-9\u0B00-\u0B7F]{2,}');
    final rawTokens = tokenRegex
        .allMatches(rawQuery)
        .map((m) => m.group(0)!)
        .toList();
    if (rawTokens.isEmpty) return '';

    final filtered = rawTokens
        .where((t) => !_stopwords.contains(t.toLowerCase()))
        .toList();
    final selected = filtered.isNotEmpty ? filtered : rawTokens;

    final seen = <String>{};
    final uniqueQuoted = <String>[];
    for (final tok in selected) {
      final low = tok.toLowerCase();
      if (seen.add(low)) {
        uniqueQuoted.add('"${tok.replaceAll('"', '')}"');
      }
    }
    return uniqueQuoted.join(' OR ');
  }

  Future<String> _prepareStaticRagDb() async {
    final docDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docDir.path, 'offline_curriculum.db');
    if (!await File(dbPath).exists()) {
      final data = await rootBundle.load('assets/db/offline_curriculum.db');
      await File(dbPath).writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
    }
    return dbPath;
  }

  Future<String> _getTestModelPath() async {
    final docDir = await getApplicationDocumentsDirectory();
    final file = File(p.join(docDir.path, 'vidyasetu_slm.gguf'));
    if (!await file.exists()) {
      throw FileSystemException('vidyasetu_slm.gguf not found in app_flutter.', file.path);
    }
    return file.path;
  }

  Future<void> _runOfflineTest() async {
    final sw = Stopwatch()..start();
    setState(() {
      _running = true;
      _status = '[0.0s] 1/4 Searching offline_chunks_fts with BM25...';
      _citation = '';
      _retrievedSnippet = '';
      _streamedOutput = '';
    });

    sql.Database? db;
    LlamaEngine? engine;

    try {
      final dbPath = await _prepareStaticRagDb();
      db = sql.sqlite3.open(dbPath, mode: sql.OpenMode.readOnly);

      final queryText = _searchController.text.trim();
      final ftsExpr = _buildFts5MatchExpression(queryText);

      sql.ResultSet rows = ftsExpr.isNotEmpty
          ? db.select(
              '''
              SELECT subject, chapter_name, section_heading, page_numbers,
                     source_name, english_tech_terms, content_odia,
                     bm25(offline_chunks_fts) AS rank_score
              FROM offline_chunks_fts
              WHERE offline_chunks_fts MATCH ?
              ORDER BY rank_score ASC
              LIMIT 1
              ''',
              [ftsExpr],
            )
          : db.select('SELECT * FROM offline_chunks_fts WHERE 1=0');

      if (rows.isEmpty) {
        setState(() {
          _status =
              'Insufficient textbook context: No matching passages found for "$queryText".';
        });
        return;
      }

      final row = rows.first;
      final subject = (row['subject'] ?? '').toString();
      final chapter = (row['chapter_name'] ?? '').toString();
      final section = (row['section_heading'] ?? '').toString();
      final pages = (row['page_numbers'] ?? '').toString();
      final source = (row['source_name'] ?? '').toString();
      final chunkOdia = (row['content_odia'] ?? '').toString();

      setState(() {
        _citation = '[1] $source • $subject — $chapter ($section, p. $pages)';
        _retrievedSnippet = chunkOdia;
        _status =
            '[${(sw.elapsedMilliseconds / 1000).toStringAsFixed(1)}s] 2/4 Loading 851 MB GGUF in Worker Isolate...';
      });

      final modelPath = await _getTestModelPath();
      engine = await LlamaEngine.spawn(
        modelParams: ModelParams(path: modelPath),
        contextParams: const ContextParams(
          nCtx: 2048,
          nBatch: 256,
          nUbatch: 256,
          nThreads: 4,
          nThreadsBatch: 4,
        ),
      );

      setState(() {
        _status =
            '[${(sw.elapsedMilliseconds / 1000).toStringAsFixed(1)}s] 3/4 Model loaded! Prefilling prompt...';
      });

      // Keep context around 650 chars (~500 Odia byte tokens) so prefill + 420 output tokens stay well under nCtx=2048
      final clippedContext =
          chunkOdia.length > 650 ? '${chunkOdia.substring(0, 650)}...' : chunkOdia;

      final chat = await engine.createChat();

      if (_mode == 'questions') {
        // Exact Question-Generation prompt from rag_runtime.py
        chat.addSystem(
          'You are a test generator for Class 10. '
          'Your job is to read the provided Odia TEXTBOOK CONTEXT and write practice questions in ENGLISH. '
          'Focus only on historical dates, people, and events in the context.',
        );
        chat.addUser('''
TEXTBOOK CONTEXT:
SOURCE [1]: $_citation
$clippedContext

TOPIC: $queryText

TASK:
Write the questions in English based on the context above. Do not write explanations. Ignore the list of English 'Terms' at the bottom of the context.

Follow this exact format:

### MCQs
Q1. [Question]
A) [Option 1]
B) [Option 2]
C) [Option 3]
D) [Option 4]
Correct Answer: [Letter] [1]

### Descriptive
Q1. [Question]
Answer: [Answer] [1]

Generate 2 MCQs and 1 Descriptive question now.
''');
      } else {
        // Grounded Explanation Mode from rag_runtime.py
        chat.addSystem(
          'You are Nidana, an offline Odisha State Board tutor for Class 10. '
          'Answer ONLY using the provided TEXTBOOK CONTEXT. Never invent facts outside the context. '
          'Cite [1] for every factual claim.',
        );
        chat.addUser('''
TEXTBOOK CONTEXT:
SOURCE [1]: $_citation
$clippedContext

STUDENT QUESTION (Class 10):
$queryText

Provide a clear grounded explanation citing [1] in under 90 words:
''');
      }

      var gotFirstToken = false;
      final maxOutTokens = _mode == 'questions' ? 420 : 180;

      await for (final event in chat.generate(maxTokens: maxOutTokens)) {
        if (event is TokenEvent) {
          if (!gotFirstToken) {
            gotFirstToken = true;
            setState(() {
              _status =
                  '[${(sw.elapsedMilliseconds / 1000).toStringAsFixed(1)}s] 4/4 Streaming ${_mode == 'questions' ? 'MCQs & Descriptive Questions' : 'Explanation'}...';
            });
          }
          setState(() => _streamedOutput += event.text);
        } else if (event is DoneEvent && event.trailingText.isNotEmpty) {
          setState(() => _streamedOutput += event.trailingText);
        }
      }

      setState(() {
        _status =
            'Done in ${(sw.elapsedMilliseconds / 1000).toStringAsFixed(1)}s! 100% offline.';
      });
    } catch (e, st) {
      debugPrint('SLM_ERROR: $e\n$st');
      setState(() => _status = 'Error: $e');
    } finally {
      db?.dispose();
      await engine?.dispose();
      setState(() => _running = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('VidyaSetu Offline RAG + SLM')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'questions', label: Text('Generate Questions')),
                ButtonSegment(value: 'explain', label: Text('Explain Concept')),
              ],
              selected: {_mode},
              onSelectionChanged: _running
                  ? null
                  : (selection) => setState(() => _mode = selection.first),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Topic / Keyword (e.g., Independence, Hirakud, Planning)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _running ? null : _runOfflineTest,
              child: Text(
                _running
                    ? 'Running Offline...'
                    : (_mode == 'questions'
                        ? 'Generate Offline MCQs & Questions'
                        : 'Generate Offline Explanation'),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_status, style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (_citation.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _citation,
                        style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.w600),
                      ),
                    ],
                    const Divider(height: 20),
                    if (_retrievedSnippet.isNotEmpty) ...[
                      const Text(
                        '1. Retrieved Textbook Source Passage (Verbatim):',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(_retrievedSnippet, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                      const Divider(height: 20),
                    ],
                    Text(
                      _mode == 'questions'
                          ? '2. Generated Practice Questions:'
                          : '2. Generated Grounded Explanation:',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(_streamedOutput, style: const TextStyle(fontSize: 15, height: 1.5)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
