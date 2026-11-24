/// Locked VidyaSetu mastery calculation service.
/// Ported 1:1 from `vidyasetu-backend/app/services/mastery_service.py`.
class MasteryCalculator {
  /// Clamps score strictly between 0.0 and 100.0.
  static double clampScore(num score) {
    return score.toDouble().clamp(0.0, 100.0);
  }

  /// Computes deterministic overall mastery from the 6 locked parameters.
  ///
  /// Weights:
  ///   - conceptUnderstanding: 0.30
  ///   - previousPerformanceScore: 0.20
  ///   - prerequisiteUnderstanding: 0.15
  ///   - englishComprehension: 0.15
  ///   - timeManagement: 0.10
  ///   - confidenceLevel: 0.10
  ///
  /// Returns overall mastery clamped to [0.0, 100.0] and rounded to 2 decimal places.
  static double computeOverallMastery({
    required num conceptUnderstanding,
    required num previousPerformanceScore,
    required num prerequisiteUnderstanding,
    required num englishComprehension,
    required num timeManagement,
    required num confidenceLevel,
  }) {
    final c = clampScore(conceptUnderstanding);
    final p = clampScore(previousPerformanceScore);
    final pr = clampScore(prerequisiteUnderstanding);
    final e = clampScore(englishComprehension);
    final t = clampScore(timeManagement);
    final conf = clampScore(confidenceLevel);

    final rawMastery = (0.30 * c) +
        (0.20 * p) +
        (0.15 * pr) +
        (0.15 * e) +
        (0.10 * t) +
        (0.10 * conf);

    return double.parse(clampScore(rawMastery).toStringAsFixed(2));
  }

  /// Maps englishComprehension score to englishExposureLevel (1..4).
  ///
  /// Clamps score to [0.0, 100.0] and uses continuous <= thresholds:
  ///   - score <= 45.0  -> Level 1 (Full Bilingual Support)
  ///   - score <= 65.0  -> Level 2 (English Term Emphasis)
  ///   - score <= 82.0  -> Level 3 (English with Odia Hints)
  ///   - score > 82.0   -> Level 4 (Exam English)
  static int mapEnglishExposureLevel(num score) {
    final clamped = clampScore(score);
    if (clamped <= 45.0) {
      return 1;
    } else if (clamped <= 65.0) {
      return 2;
    } else if (clamped <= 82.0) {
      return 3;
    } else {
      return 4;
    }
  }

  /// Returns true if chapter overallMastery meets or exceeds completion threshold (>= 75.0).
  static bool isChapterCompleted(num overallMastery) {
    return clampScore(overallMastery) >= 75.0;
  }

  /// Applies cause-specific +8.0 boost and +5.0 confidence boost upon successful recovery check.
  ///
  /// Mapping:
  ///   - 'language_barrier' -> englishComprehension += 8.0
  ///   - 'time_pressure' -> timeManagement += 8.0
  ///   - 'prerequisite_gap' -> prerequisiteUnderstanding += 8.0
  ///   - 'conceptual_misunderstanding' / 'careless_mistake' -> conceptUnderstanding += 8.0
  ///   - confidenceLevel += 5.0
  /// All metrics clamped strictly to [0.0, 100.0].
  static Map<String, double> applyRecoveryBoost({
    required num currConcept,
    required num currPrev,
    required num currPrereq,
    required num currEng,
    required num currTime,
    required num currConf,
    required String rootCause,
  }) {
    final cause = rootCause.toLowerCase().trim();
    double updConcept = currConcept.toDouble();
    double updPrev = currPrev.toDouble();
    double updPrereq = currPrereq.toDouble();
    double updEng = currEng.toDouble();
    double updTime = currTime.toDouble();

    if (cause == 'language_barrier') {
      updEng = clampScore(currEng + 8.0);
    } else if (cause == 'time_pressure') {
      updTime = clampScore(currTime + 8.0);
    } else if (cause == 'prerequisite_gap') {
      updPrereq = clampScore(currPrereq + 8.0);
    } else {
      // conceptual_misunderstanding, careless_mistake, or default
      updConcept = clampScore(currConcept + 8.0);
    }

    final updConf = clampScore(currConf + 5.0);

    return {
      'concept_understanding': updConcept,
      'previous_performance_score': updPrev,
      'prerequisite_understanding': updPrereq,
      'english_comprehension': updEng,
      'time_management': updTime,
      'confidence_level': updConf,
    };
  }

  /// Builds a structured planner dictionary for student recommendedNextTask.
  static Map<String, dynamic> buildRecommendedNextTask({
    required String studentId,
    required String subject,
    required String chapterName,
    required String conceptName,
    required String rootCause,
    required num overallMastery,
  }) {
    final causeWords = rootCause.replaceAll('_', ' ').split(' ');
    final causeLabel = causeWords
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');

    if (overallMastery >= 75.0) {
      return {
        'subject': subject,
        'chapter_name': chapterName,
        'task_type': 'chapter_mastery',
        'reason':
            'Mastery target achieved (${overallMastery.toStringAsFixed(1)}% >= 75%). Ready for next syllabus chapter.',
        'recommended_for': studentId,
      };
    }
    return {
      'subject': subject,
      'chapter_name': chapterName,
      'task_type': 'practice_reinforcement',
      'reason':
          'Recovered from $causeLabel. Complete 1 more practice question on $conceptName to solidify mastery.',
      'recommended_for': studentId,
    };
  }
}
