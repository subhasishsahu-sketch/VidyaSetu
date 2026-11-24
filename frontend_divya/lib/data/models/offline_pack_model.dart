import 'package:flutter/foundation.dart';
import 'diagnostic_model.dart';
import 'question_model.dart';

/// Request payload for downloading an offline curriculum pack.
@immutable
class OfflinePackRequest {
  final String subject;
  final String chapterName;

  OfflinePackRequest({
    required String subject,
    required String chapterName,
  })  : subject = subject.trim(),
        chapterName = chapterName.trim() {
    if (this.subject.isEmpty || this.chapterName.isEmpty) {
      throw ArgumentError('Subject and chapterName cannot be empty or whitespace only');
    }
  }

  Map<String, dynamic> toJson() => {
        'subject': subject,
        'chapter_name': chapterName,
      };

  factory OfflinePackRequest.fromJson(Map<String, dynamic> json) {
    return OfflinePackRequest(
      subject: (json['subject'] ?? '').toString(),
      chapterName: (json['chapter_name'] ?? '').toString(),
    );
  }
}

/// Textbook chunk and semantic vector embedding for offline RAG.
@immutable
class RagTextbookVectorModel {
  final String chunkId;
  final String subject;
  final String chapterName;
  final String chunkText;
  final List<double> embedding;
  final String embeddingModel;
  final int embeddingDim;
  final GroundedReference groundedReference;
  final List<KeyTermPair> importantEnglishTerms;

  const RagTextbookVectorModel({
    required this.chunkId,
    required this.subject,
    required this.chapterName,
    required this.chunkText,
    required this.embedding,
    this.embeddingModel = 'intfloat/multilingual-e5-base',
    this.embeddingDim = 768,
    required this.groundedReference,
    this.importantEnglishTerms = const [],
  });

  Map<String, dynamic> toJson() => {
        'chunk_id': chunkId,
        'subject': subject,
        'chapter_name': chapterName,
        'chunk_text': chunkText,
        'embedding': embedding,
        'embedding_model': embeddingModel,
        'embedding_dim': embeddingDim,
        'grounded_reference': groundedReference.toJson(),
        'important_english_terms':
            importantEnglishTerms.map((t) => t.toJson()).toList(),
      };

  factory RagTextbookVectorModel.fromJson(Map<String, dynamic> json) {
    final id = json['chunk_id'] ?? json['_id'] ?? '';
    final emb = (json['embedding'] as List?)
            ?.map((e) => ((e as num?) ?? 0.0).toDouble())
            .toList() ??
        [];
    final ref = json['grounded_reference'] != null
        ? GroundedReference.fromJson(
            Map<String, dynamic>.from(json['grounded_reference'] as Map))
        : const GroundedReference(textbookName: 'BSE Odisha Curriculum', chapterNo: 1);
    final terms = (json['important_english_terms'] as List?)
            ?.map((t) => KeyTermPair.fromJson(Map<String, dynamic>.from(t as Map)))
            .toList() ??
        [];

    return RagTextbookVectorModel(
      chunkId: id.toString().toLowerCase(),
      subject: (json['subject'] ?? '').toString(),
      chapterName: (json['chapter_name'] ?? '').toString(),
      chunkText: (json['chunk_text'] ?? '').toString(),
      embedding: emb,
      embeddingModel: (json['embedding_model'] ?? 'intfloat/multilingual-e5-base').toString(),
      embeddingDim: ((json['embedding_dim'] as num?) ?? emb.length).toInt(),
      groundedReference: ref,
      importantEnglishTerms: terms,
    );
  }
}

/// Offline pack containing chapter questions and RAG vectors.
@immutable
class OfflinePackModel {
  final String packId;
  final String subject;
  final String chapterName;
  final List<QuestionModel> cachedQuestions;
  final List<RagTextbookVectorModel> localRagVectors;
  final DateTime cachedAt;

  const OfflinePackModel({
    required this.packId,
    required this.subject,
    required this.chapterName,
    this.cachedQuestions = const [],
    this.localRagVectors = const [],
    required this.cachedAt,
  });

  Map<String, dynamic> toJson() => {
        'pack_id': packId,
        'subject': subject,
        'chapter_name': chapterName,
        'cached_questions':
            cachedQuestions.map((q) => q.toJson(includeAnswers: true)).toList(),
        'local_rag_vectors': localRagVectors.map((v) => v.toJson()).toList(),
        'cached_at': cachedAt.toUtc().toIso8601String(),
      };

  factory OfflinePackModel.fromJson(Map<String, dynamic> json) {
    final qList = (json['cached_questions'] as List?)
            ?.map((q) => QuestionModel.fromJson(Map<String, dynamic>.from(q as Map)))
            .toList() ??
        [];
    final vList = (json['local_rag_vectors'] as List?)
            ?.map((v) => RagTextbookVectorModel.fromJson(Map<String, dynamic>.from(v as Map)))
            .toList() ??
        [];
    final cached = json['cached_at'] != null
        ? DateTime.parse(json['cached_at'] as String)
        : DateTime.now().toUtc();

    return OfflinePackModel(
      packId: (json['pack_id'] ?? '').toString(),
      subject: (json['subject'] ?? '').toString(),
      chapterName: (json['chapter_name'] ?? '').toString(),
      cachedQuestions: qList,
      localRagVectors: vList,
      cachedAt: cached,
    );
  }
}
