import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/explanation.dart';

final explanationModeProvider =
    StateNotifierProvider<ExplanationModeNotifier, ExplanationMode>((ref) {
  return ExplanationModeNotifier();
});

class ExplanationModeNotifier extends StateNotifier<ExplanationMode> {
  ExplanationModeNotifier() : super(ExplanationMode.bilingualMix);

  void setMode(ExplanationMode mode) {
    state = mode;
  }
}
