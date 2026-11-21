import 'package:flutter_test/flutter_test.dart';

import 'package:vidyasetu_mobile/core/offline/mastery_calculator.dart';
import 'package:vidyasetu_mobile/core/offline/behavioral_analyzer.dart';

void main() {
  group('1. MasteryCalculator Exact Parity with test_mastery_service.py', () {
    test('clampScore clamps strictly between 0.0 and 100.0', () {
      expect(MasteryCalculator.clampScore(-10.5), 0.0);
      expect(MasteryCalculator.clampScore(0.0), 0.0);
      expect(MasteryCalculator.clampScore(55.5), 55.5);
      expect(MasteryCalculator.clampScore(100.0), 100.0);
      expect(MasteryCalculator.clampScore(125.0), 100.0);
    });

    test('computeOverallMastery 6-weight deterministic calculation', () {
      // 0.30 * 80 + 0.20 * 70 + 0.15 * 60 + 0.15 * 50 + 0.10 * 40 + 0.10 * 30
      // = 24.0 + 14.0 + 9.0 + 7.5 + 4.0 + 3.0 = 61.5
      final mastery = MasteryCalculator.computeOverallMastery(
        conceptUnderstanding: 80.0,
        previousPerformanceScore: 70.0,
        prerequisiteUnderstanding: 60.0,
        englishComprehension: 50.0,
        timeManagement: 40.0,
        confidenceLevel: 30.0,
      );
      expect(mastery, 61.5);

      // Out of bounds clamping check
      final maxMastery = MasteryCalculator.computeOverallMastery(
        conceptUnderstanding: 150.0,
        previousPerformanceScore: 150.0,
        prerequisiteUnderstanding: 150.0,
        englishComprehension: 150.0,
        timeManagement: 150.0,
        confidenceLevel: 150.0,
      );
      expect(maxMastery, 100.0);

      final minMastery = MasteryCalculator.computeOverallMastery(
        conceptUnderstanding: -10,
        previousPerformanceScore: -20,
        prerequisiteUnderstanding: -30,
        englishComprehension: -40,
        timeManagement: -50,
        confidenceLevel: -60,
      );
      expect(minMastery, 0.0);
    });

    test('mapEnglishExposureLevel continuous <= thresholds', () {
      // <= 45.0 -> 1
      expect(MasteryCalculator.mapEnglishExposureLevel(-5.0), 1);
      expect(MasteryCalculator.mapEnglishExposureLevel(0.0), 1);
      expect(MasteryCalculator.mapEnglishExposureLevel(45.0), 1);

      // <= 65.0 -> 2
      expect(MasteryCalculator.mapEnglishExposureLevel(45.05), 2);
      expect(MasteryCalculator.mapEnglishExposureLevel(50.0), 2);
      expect(MasteryCalculator.mapEnglishExposureLevel(65.0), 2);

      // <= 82.0 -> 3
      expect(MasteryCalculator.mapEnglishExposureLevel(65.01), 3);
      expect(MasteryCalculator.mapEnglishExposureLevel(75.0), 3);
      expect(MasteryCalculator.mapEnglishExposureLevel(82.0), 3);

      // > 82.0 -> 4
      expect(MasteryCalculator.mapEnglishExposureLevel(82.01), 4);
      expect(MasteryCalculator.mapEnglishExposureLevel(90.0), 4);
      expect(MasteryCalculator.mapEnglishExposureLevel(100.0), 4);
      expect(MasteryCalculator.mapEnglishExposureLevel(110.0), 4);
    });

    test('isChapterCompleted threshold check (>= 75.0)', () {
      expect(MasteryCalculator.isChapterCompleted(74.99), isFalse);
      expect(MasteryCalculator.isChapterCompleted(75.0), isTrue);
      expect(MasteryCalculator.isChapterCompleted(85.5), isTrue);
      expect(MasteryCalculator.isChapterCompleted(100.0), isTrue);
    });

    test('applyRecoveryBoost cause-specific boosts', () {
      // language_barrier -> english_comprehension += 8.0, confidence += 5.0
      final boostLang = MasteryCalculator.applyRecoveryBoost(
        currConcept: 50.0,
        currPrev: 50.0,
        currPrereq: 50.0,
        currEng: 50.0,
        currTime: 50.0,
        currConf: 50.0,
        rootCause: 'language_barrier',
      );
      expect(boostLang['english_comprehension'], 58.0);
      expect(boostLang['confidence_level'], 55.0);
      expect(boostLang['concept_understanding'], 50.0);

      // time_pressure -> time_management += 8.0
      final boostTime = MasteryCalculator.applyRecoveryBoost(
        currConcept: 50.0,
        currPrev: 50.0,
        currPrereq: 50.0,
        currEng: 50.0,
        currTime: 50.0,
        currConf: 50.0,
        rootCause: 'time_pressure',
      );
      expect(boostTime['time_management'], 58.0);
      expect(boostTime['confidence_level'], 55.0);

      // prerequisite_gap -> prerequisite_understanding += 8.0
      final boostPrereq = MasteryCalculator.applyRecoveryBoost(
        currConcept: 50.0,
        currPrev: 50.0,
        currPrereq: 50.0,
        currEng: 50.0,
        currTime: 50.0,
        currConf: 50.0,
        rootCause: 'prerequisite_gap',
      );
      expect(boostPrereq['prerequisite_understanding'], 58.0);
      expect(boostPrereq['confidence_level'], 55.0);

      // conceptual_misunderstanding -> concept_understanding += 8.0
      final boostConcept = MasteryCalculator.applyRecoveryBoost(
        currConcept: 50.0,
        currPrev: 50.0,
        currPrereq: 50.0,
        currEng: 50.0,
        currTime: 50.0,
        currConf: 50.0,
        rootCause: 'conceptual_misunderstanding',
      );
      expect(boostConcept['concept_understanding'], 58.0);
      expect(boostConcept['confidence_level'], 55.0);
    });
  });

  group('2. BehavioralAnalyzer Exact Parity with test_analysis_service.py', () {
    test('build7ParameterSnapshot clamping and categories', () {
      final snapshot = BehavioralAnalyzer.build7ParameterSnapshot(
        attemptTimeSec: -5.0,
        confidenceRating: 150.0,
        answerChangesCount: -2,
        studentPreferredLanguage: 'odia',
        conceptUnderstanding: -10.0,
        previousPerformance: 110.0,
        englishComprehension: 55.5,
      );
      expect(snapshot.timeTaken, 'Low');
      expect(snapshot.confidenceLevel, 'High');
      expect(snapshot.answerChanges, 'None');
      expect(snapshot.languagePreference, 'Odia');
      expect(snapshot.conceptUnderstanding, 'Weak');
      expect(snapshot.previousPerformance, 'Strong');
      expect(snapshot.englishComprehension, 'Weak');
    });

    test('rankHypotheses careless_mistake', () {
      final snapshot = {
        'time_taken': 15.0,
        'confidence_level': 85.0,
        'answer_changes': 0,
        'language_preference': 'Odia',
        'concept_understanding': 70.0,
        'previous_performance': 75.0,
        'english_comprehension': 70.0,
      };
      final hypotheses = BehavioralAnalyzer.rankHypotheses(snapshot: snapshot, expectedTimeSec: 60);
      expect(hypotheses.length, 5);
      final top = hypotheses.first;
      expect(top.hypothesis, 'careless_mistake');
      expect(top.recommendedProbe, 'untimed_retry');
      expect(top.score, greaterThanOrEqualTo(0.75));
    });

    test('rankHypotheses language_barrier', () {
      final snapshot = {
        'time_taken': 40.0,
        'confidence_level': 40.0,
        'answer_changes': 1,
        'language_preference': 'Odia',
        'concept_understanding': 60.0,
        'previous_performance': 60.0,
        'english_comprehension': 35.0,
      };
      final hypotheses = BehavioralAnalyzer.rankHypotheses(snapshot: snapshot, expectedTimeSec: 60);
      final top = hypotheses.first;
      expect(top.hypothesis, 'language_barrier');
      expect(top.recommendedProbe, 'language_probe');
      expect(top.score, greaterThanOrEqualTo(0.80));
    });

    test('rankHypotheses time_pressure', () {
      final snapshot = {
        'time_taken': 95.0,
        'confidence_level': 35.0,
        'answer_changes': 3,
        'language_preference': 'English',
        'concept_understanding': 65.0,
        'previous_performance': 65.0,
        'english_comprehension': 75.0,
      };
      final hypotheses = BehavioralAnalyzer.rankHypotheses(snapshot: snapshot, expectedTimeSec: 60);
      final top = hypotheses.first;
      expect(top.hypothesis, 'time_pressure');
      expect(top.recommendedProbe, 'untimed_retry');
      expect(top.score, greaterThanOrEqualTo(0.70));
    });

    test('rankHypotheses prerequisite_gap', () {
      final snapshot = {
        'time_taken': 45.0,
        'confidence_level': 50.0,
        'answer_changes': 1,
        'language_preference': 'English',
        'concept_understanding': 60.0,
        'previous_performance': 30.0,
        'english_comprehension': 70.0,
      };
      final hypotheses = BehavioralAnalyzer.rankHypotheses(snapshot: snapshot, expectedTimeSec: 60);
      final top = hypotheses.first;
      expect(top.hypothesis, 'prerequisite_gap');
      expect(top.recommendedProbe, 'prerequisite_probe');
    });

    test('rankHypotheses conceptual_misunderstanding', () {
      final snapshot = {
        'time_taken': 55.0,
        'confidence_level': 50.0,
        'answer_changes': 0,
        'language_preference': 'English',
        'concept_understanding': 25.0,
        'previous_performance': 35.0,
        'english_comprehension': 70.0,
      };
      final hypotheses = BehavioralAnalyzer.rankHypotheses(snapshot: snapshot, expectedTimeSec: 60);
      final top = hypotheses.first;
      expect(top.hypothesis, 'conceptual_misunderstanding');
      expect(top.recommendedProbe, 'transfer_probe');
    });

    test('calculateEvidenceConfidence supported (>= 0.75)', () {
      // Successful language probe confirming language barrier
      final conf = BehavioralAnalyzer.calculateEvidenceConfidence(
        probeType: 'language_probe',
        isProbeSuccessful: true,
        targetHypothesis: 'language_barrier',
        isTopHypothesis: true,
        previousPerformance: 50.0,
        probeTimeSec: 15.0,
        expectedProbeTimeSec: 30,
      );
      // 0.45 * 1.0 + 0.30 * 1.0 + 0.12 * 0.85 + 0.08 * 1.0 = 0.45 + 0.30 + 0.102 + 0.08 = 0.932 -> 0.93
      expect(conf, greaterThanOrEqualTo(0.75));
      expect(conf, closeTo(0.93, 0.02));
    });

    test('calculateEvidenceConfidence unsupported (< 0.75)', () {
      // Failed language probe refuting that language was the sole issue
      final conf = BehavioralAnalyzer.calculateEvidenceConfidence(
        probeType: 'language_probe',
        isProbeSuccessful: false,
        targetHypothesis: 'language_barrier',
        isTopHypothesis: false,
        previousPerformance: 70.0,
        probeTimeSec: 50.0,
        expectedProbeTimeSec: 30,
      );
      expect(conf, lessThan(0.75));
    });
  });
}
