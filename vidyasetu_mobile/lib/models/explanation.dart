import 'grounded_citation.dart';

enum ExplanationMode {
  bilingualMix,
  pureOdia,
  pureEnglish,
}

class Explanation {
  final String questionId;
  final String title;
  final String subHeader;
  final String mistakeTag;
  final String subjectTag;
  final String bilingualMix;
  final String pureOdia;
  final String pureEnglish;
  final List<ComparisonCardData> comparisonCards;
  final GroundedCitation groundedCitation;
  final HistoricalReference historicalReference;
  final AudioMeta audio;
  final String insight;

  const Explanation({
    required this.questionId,
    required this.title,
    required this.subHeader,
    required this.mistakeTag,
    required this.subjectTag,
    required this.bilingualMix,
    required this.pureOdia,
    required this.pureEnglish,
    required this.comparisonCards,
    required this.groundedCitation,
    required this.historicalReference,
    required this.audio,
    required this.insight,
  });

  /// Semantic alias getters for Odia and English breakdowns
  String get breakdownOr => pureOdia;
  String get breakdownEn => pureEnglish;

  factory Explanation.fromJson(Map<dynamic, dynamic> json) {
    final rawModes = json['modes'];
    final modes = rawModes is Map ? Map<String, dynamic>.from(rawModes) : <String, dynamic>{};

    final rawCards = json['comparison_cards'];
    final cards = rawCards is List
        ? rawCards.map((c) => ComparisonCardData.fromJson(Map<String, dynamic>.from(c as Map))).toList()
        : <ComparisonCardData>[];

    final rawCitation = json['grounded_citation'];
    final citation = rawCitation is Map
        ? GroundedCitation.fromJson(Map<String, dynamic>.from(rawCitation))
        : const GroundedCitation(
            bookTitle: 'BSE Odisha Class 10 History',
            chapterNo: 2,
            pageNo: 58,
            paragraphNo: 3,
            code: 'BSE-OD-C10-H2',
            status: 'Verified Syllabus Context',
            subtext: 'Zero Data Used',
          );

    final rawHist = json['historical_reference'];
    final hist = rawHist is Map
        ? HistoricalReference.fromJson(Map<String, dynamic>.from(rawHist))
        : const HistoricalReference(
            location: 'Rourkela, Odisha Case Study',
            description: 'Established under India\'s 2nd Five Year Plan',
            archiveLabel: 'Historic Reference Archive',
          );

    final rawAudio = json['audio'];
    final audio = rawAudio is Map
        ? AudioMeta.fromJson(Map<String, dynamic>.from(rawAudio))
        : const AudioMeta(
            title: 'Listen in Odia Voice',
            badge: 'Offline Edge TTS',
            currentTime: '01:24',
            totalTime: '02:40',
            currentSeconds: 84,
            totalSeconds: 160,
          );

    return Explanation(
      questionId: json['question_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subHeader: json['sub_header'] as String? ?? '',
      mistakeTag: json['mistake_tag'] as String? ?? '',
      subjectTag: json['subject_tag'] as String? ?? '',
      bilingualMix: modes['bilingual_mix'] as String? ?? '',
      pureOdia: modes['pure_odia'] as String? ?? '',
      pureEnglish: modes['pure_english'] as String? ?? '',
      comparisonCards: cards,
      groundedCitation: citation,
      historicalReference: hist,
      audio: audio,
      insight: json['insight'] as String? ?? '',
    );
  }

  String getTextForMode(ExplanationMode mode) {
    switch (mode) {
      case ExplanationMode.bilingualMix:
        return bilingualMix;
      case ExplanationMode.pureOdia:
        return pureOdia;
      case ExplanationMode.pureEnglish:
        return pureEnglish;
    }
  }
}

class ComparisonCardData {
  final String title;
  final String scope;
  final String colorType; // 'primary' or 'terracotta'

  const ComparisonCardData({
    required this.title,
    required this.scope,
    required this.colorType,
  });

  factory ComparisonCardData.fromJson(Map<dynamic, dynamic> json) {
    return ComparisonCardData(
      title: json['title'] as String? ?? '',
      scope: json['scope'] as String? ?? '',
      colorType: json['color_type'] as String? ?? 'primary',
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'scope': scope,
        'color_type': colorType,
      };
}

class HistoricalReference {
  final String location;
  final String description;
  final String archiveLabel;

  const HistoricalReference({
    required this.location,
    required this.description,
    required this.archiveLabel,
  });

  factory HistoricalReference.fromJson(Map<dynamic, dynamic> json) {
    return HistoricalReference(
      location: json['location'] as String? ?? '',
      description: json['description'] as String? ?? '',
      archiveLabel: json['archive_label'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'location': location,
        'description': description,
        'archive_label': archiveLabel,
      };
}

class AudioMeta {
  final String title;
  final String badge;
  final String currentTime;
  final String totalTime;
  final int currentSeconds;
  final int totalSeconds;

  const AudioMeta({
    required this.title,
    required this.badge,
    required this.currentTime,
    required this.totalTime,
    required this.currentSeconds,
    required this.totalSeconds,
  });

  factory AudioMeta.fromJson(Map<dynamic, dynamic> json) {
    return AudioMeta(
      title: json['title'] as String? ?? '',
      badge: json['badge'] as String? ?? 'Offline Edge TTS',
      currentTime: json['currentTime'] as String? ?? '01:24',
      totalTime: json['totalTime'] as String? ?? '02:40',
      currentSeconds: json['currentSeconds'] as int? ?? 84,
      totalSeconds: json['totalSeconds'] as int? ?? 160,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'badge': badge,
        'currentTime': currentTime,
        'totalTime': totalTime,
        'currentSeconds': currentSeconds,
        'totalSeconds': totalSeconds,
      };
}
