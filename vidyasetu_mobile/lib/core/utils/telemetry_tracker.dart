/// Behavioral Signal Telemetry Collector
/// Captures high-frequency student interactions during mock assessments:
/// - Millisecond time delta
/// - Option change / hesitation counts
/// - Inferred confidence levels
class AttemptTelemetryTracker {
  late DateTime _questionStartTime;
  int _optionChangeCount = 0;
  String? _selectedOption;
  String _confidenceRating = "normal";

  void startQuestion() {
    _questionStartTime = DateTime.now();
    _optionChangeCount = 0;
    _selectedOption = null;
    _confidenceRating = "normal";
  }

  void onOptionSelected(String optionKey) {
    if (_selectedOption != null && _selectedOption != optionKey) {
      _optionChangeCount++;
    }
    _selectedOption = optionKey;
  }

  void setConfidence(String rating) {
    _confidenceRating = rating;
  }

  int get optionChangeCount => _optionChangeCount;
  String? get selectedOption => _selectedOption;
  int get elapsedSeconds => DateTime.now().difference(_questionStartTime).inSeconds;

  String get inferredConfidence {
    if (_optionChangeCount >= 2) return "low";
    return _confidenceRating;
  }
}
