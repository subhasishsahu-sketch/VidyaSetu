import 'dart:math' as math;
import '../../data/models/diagnostic_model.dart';
import 'mastery_calculator.dart';

/// Deterministic 7-parameter behavioral analyzer and hypothesis ranker.
/// Ported 1:1 from `vidyasetu-backend/app/services/analysis_service.py`.
class BehavioralAnalyzer {
  /// Builds a deterministic 7-parameter behavioral snapshot with exact categorical labels.
  static StudentParametersSnapshot build7ParameterSnapshot({
    required num attemptTimeSec,
    required num confidenceRating,
    required int answerChangesCount,
    String studentPreferredLanguage = 'Odia',
    num conceptUnderstanding = 50.0,
    num previousPerformance = 50.0,
    num englishComprehension = 50.0,
    int expectedTimeSec = 60,
  }) {
    final exp = math.max(10, expectedTimeSec);
    final timeSec = math.max(0.0, attemptTimeSec.toDouble());
    final timeRatio = timeSec / exp;

    String timeCat;
    if (timeRatio > 1.2) {
      timeCat = 'High';
    } else if (timeRatio < 0.6) {
      timeCat = 'Low';
    } else {
      timeCat = 'Normal';
    }

    final conf = MasteryCalculator.clampScore(confidenceRating);
    String confCat;
    if (conf >= 70.0) {
      confCat = 'High';
    } else if (conf <= 45.0) {
      confCat = 'Low';
    } else {
      confCat = 'Normal';
    }

    final changes = math.max(0, answerChangesCount);
    String changesCat;
    if (changes >= 2) {
      changesCat = 'Frequent';
    } else if (changes == 1) {
      changesCat = 'Occasional';
    } else {
      changesCat = 'None';
    }

    final langPref = studentPreferredLanguage.trim().toLowerCase() == 'english'
        ? 'English'
        : 'Odia';
    final conceptCat = MasteryCalculator.clampScore(conceptUnderstanding) >= 60.0
        ? 'Understood'
        : 'Weak';
    final prevCat = MasteryCalculator.clampScore(previousPerformance) >= 60.0
        ? 'Strong'
        : 'Weak';
    final engCat = MasteryCalculator.clampScore(englishComprehension) >= 60.0
        ? 'Strong'
        : 'Weak';

    return StudentParametersSnapshot(
      timeTaken: timeCat,
      confidenceLevel: confCat,
      answerChanges: changesCat,
      languagePreference: langPref,
      conceptUnderstanding: conceptCat,
      previousPerformance: prevCat,
      englishComprehension: engCat,
    );
  }

  /// Ranks 5 root-cause hypotheses deterministically based on the 7-parameter snapshot.
  ///
  /// Hypotheses evaluated:
  ///   1. careless_mistake -> untimed_retry
  ///   2. time_pressure -> untimed_retry
  ///   3. language_barrier -> language_probe
  ///   4. prerequisite_gap -> prerequisite_probe
  ///   5. conceptual_misunderstanding -> transfer_probe
  static List<CandidateHypothesis> rankHypotheses({
    required dynamic snapshot, // StudentParametersSnapshot or Map<String, dynamic>
    int expectedTimeSec = 60,
  }) {
    Map<String, dynamic> snapDict;
    if (snapshot is StudentParametersSnapshot) {
      snapDict = snapshot.toJson();
    } else if (snapshot is Map) {
      snapDict = Map<String, dynamic>.from(snapshot);
    } else {
      snapDict = {};
    }

    // Resolve time category
    final rawTime = snapDict['time_taken'] ?? 'Normal';
    String timeCat;
    if (rawTime is num) {
      final ratio = rawTime.toDouble() / math.max(10, expectedTimeSec);
      timeCat = ratio > 1.2 ? 'High' : (ratio < 0.6 ? 'Low' : 'Normal');
    } else {
      timeCat = _capitalize(rawTime.toString());
    }

    // Resolve confidence category
    final rawConf = snapDict['confidence_level'] ?? 'Normal';
    String confCat;
    if (rawConf is num) {
      confCat = rawConf >= 70.0 ? 'High' : (rawConf <= 45.0 ? 'Low' : 'Normal');
    } else {
      confCat = _capitalize(rawConf.toString());
    }

    // Resolve answer changes category
    final rawChanges = snapDict['answer_changes'] ?? 'None';
    String changesCat;
    if (rawChanges is num) {
      changesCat = rawChanges >= 2
          ? 'Frequent'
          : (rawChanges == 1 ? 'Occasional' : 'None');
    } else {
      changesCat = _capitalize(rawChanges.toString());
    }

    final rawLang = (snapDict['language_preference'] ?? 'Odia').toString();
    final langPref = rawLang.trim().toLowerCase() == 'english' ? 'English' : 'Odia';

    // Resolve concept category
    final rawConcept = snapDict['concept_understanding'] ?? 'Understood';
    String conceptCat;
    if (rawConcept is num) {
      conceptCat = rawConcept >= 60.0 ? 'Understood' : 'Weak';
    } else {
      conceptCat = _capitalize(rawConcept.toString());
    }

    // Resolve previous performance category
    final rawPrev = snapDict['previous_performance'] ?? 'Strong';
    String prevCat;
    if (rawPrev is num) {
      prevCat = rawPrev >= 60.0 ? 'Strong' : 'Weak';
    } else {
      prevCat = _capitalize(rawPrev.toString());
    }

    // Resolve english comprehension category
    final rawEng = snapDict['english_comprehension'] ?? 'Strong';
    String engCat;
    if (rawEng is num) {
      engCat = rawEng >= 60.0 ? 'Strong' : 'Weak';
    } else {
      engCat = _capitalize(rawEng.toString());
    }

    // 1. Careless Mistake
    double carelessScore = 0.10;
    if (timeCat == 'Low' && confCat == 'High' && (changesCat == 'None' || changesCat == 'Occasional')) {
      carelessScore = 0.88;
    } else if (timeCat == 'Low' && confCat == 'Normal') {
      carelessScore = 0.65;
    }

    // 2. Time Pressure
    double timePressureScore = 0.10;
    if (timeCat == 'High' || changesCat == 'Frequent') {
      timePressureScore = confCat == 'Low' ? 0.80 : 0.70;
    } else if (changesCat == 'Occasional' && confCat == 'Low') {
      timePressureScore = 0.55;
    }

    // 3. Language Barrier
    double languageBarrierScore = 0.10;
    if (engCat == 'Weak' && langPref == 'Odia') {
      languageBarrierScore = 0.85;
    } else if (engCat == 'Weak') {
      languageBarrierScore = 0.65;
    }

    // 4. Prerequisite Gap
    double prereqScore = 0.15;
    if (prevCat == 'Weak' && conceptCat == 'Understood') {
      prereqScore = 0.80;
    } else if (prevCat == 'Weak') {
      prereqScore = 0.60;
    }

    // 5. Conceptual Misunderstanding
    double conceptScore = 0.20;
    if (conceptCat == 'Weak') {
      conceptScore = prevCat == 'Weak' ? 0.85 : 0.78;
    } else if (prevCat == 'Weak') {
      conceptScore = 0.50;
    }

    final candidates = [
      CandidateHypothesis(
        hypothesis: 'careless_mistake',
        score: _round3(carelessScore.clamp(0.0, 1.0)),
        reason: 'Fast completion ($timeCat time) with $confCat confidence suggests oversight.',
        recommendedProbe: 'untimed_retry',
      ),
      CandidateHypothesis(
        hypothesis: 'time_pressure',
        score: _round3(timePressureScore.clamp(0.0, 1.0)),
        reason: 'Pacing strain detected ($timeCat time, $changesCat answer changes) under test timing.',
        recommendedProbe: 'untimed_retry',
      ),
      CandidateHypothesis(
        hypothesis: 'language_barrier',
        score: _round3(languageBarrierScore.clamp(0.0, 1.0)),
        reason: 'English comprehension level ($engCat) with $langPref preference indicates struggle with English terms.',
        recommendedProbe: 'language_probe',
      ),
      CandidateHypothesis(
        hypothesis: 'prerequisite_gap',
        score: _round3(prereqScore.clamp(0.0, 1.0)),
        reason: 'Historical performance ($prevCat) points to underlying prerequisite concept gaps.',
        recommendedProbe: 'prerequisite_probe',
      ),
      CandidateHypothesis(
        hypothesis: 'conceptual_misunderstanding',
        score: _round3(conceptScore.clamp(0.0, 1.0)),
        reason: 'Concept grasp ($conceptCat) suggests a core misconception in this chapter.',
        recommendedProbe: 'transfer_probe',
      ),
    ];

    // Sort by (-score, hypothesis)
    candidates.sort((a, b) {
      final scoreCmp = b.score.compareTo(a.score);
      if (scoreCmp != 0) return scoreCmp;
      return a.hypothesis.compareTo(b.hypothesis);
    });

    return candidates;
  }

  /// Calculates deterministic evidence confidence from probe response.
  ///
  /// Formula:
  ///   confidence = (0.45 * base) + (0.30 * match) + (0.12 * history) + (0.08 * speed)
  ///   Diagnosis supported if confidence >= 0.75.
  static double calculateEvidenceConfidence({
    required String probeType,
    required bool isProbeSuccessful,
    required String targetHypothesis,
    required bool isTopHypothesis,
    dynamic previousPerformance = 50.0,
    num probeTimeSec = 20.0,
    int expectedProbeTimeSec = 30,
  }) {
    // 1. Base Score (0.45 weight)
    double base;
    if (probeType == 'language_probe') {
      base = isProbeSuccessful ? 1.0 : 0.25;
    } else if (probeType == 'untimed_retry') {
      base = isProbeSuccessful ? 1.0 : 0.20;
    } else if (probeType == 'prerequisite_probe') {
      base = !isProbeSuccessful ? 1.0 : 0.20;
    } else if (probeType == 'transfer_probe') {
      base = !isProbeSuccessful ? 0.95 : 0.25;
    } else {
      // explain_back or general
      base = isProbeSuccessful ? 0.90 : 0.40;
    }

    // 2. Match Score (0.30 weight)
    final match = isTopHypothesis ? 1.0 : 0.65;

    // 3. History Score (0.12 weight)
    double history;
    if (previousPerformance is String) {
      history = previousPerformance.trim().toLowerCase() == 'weak' ? 0.85 : 0.60;
    } else {
      final p = MasteryCalculator.clampScore((previousPerformance as num?) ?? 50.0);
      history = p < 60.0 ? 0.85 : 0.60;
    }

    // 4. Speed Score (0.08 weight)
    final exp = math.max(10, expectedProbeTimeSec);
    final timeSec = probeTimeSec.toDouble();
    double speed;
    if (timeSec <= exp) {
      speed = 1.0;
    } else {
      speed = math.max(0.20, 1.0 - ((timeSec - exp) / exp));
    }

    final rawConf = (0.45 * base) + (0.30 * match) + (0.12 * history) + (0.08 * speed);
    return double.parse(rawConf.clamp(0.0, 1.0).toStringAsFixed(2));
  }

  static String _capitalize(String s) {
    final trimmed = s.trim();
    if (trimmed.isEmpty) return 'Normal';
    return '${trimmed[0].toUpperCase()}${trimmed.substring(1).toLowerCase()}';
  }

  static double _round3(double val) {
    return double.parse(val.toStringAsFixed(3));
  }
}
