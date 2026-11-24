import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/language_model.dart';
import '../data/repositories/vidyasetu_repository.dart';
import 'repository_provider.dart';

class LanguageExplainState {
  final LanguageExplainResponse? response;
  final bool isLoading;
  final String? error;

  const LanguageExplainState({
    this.response,
    this.isLoading = false,
    this.error,
  });

  LanguageExplainState copyWith({
    LanguageExplainResponse? response,
    bool? isLoading,
    String? error,
  }) {
    return LanguageExplainState(
      response: response ?? this.response,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class LanguageExplainNotifier extends StateNotifier<LanguageExplainState> {
  final VidyaSetuRepository _repo;

  LanguageExplainNotifier(this._repo) : super(const LanguageExplainState());

  Future<void> explainConcept(LanguageExplainRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _repo.explainConcept(request);
      state = state.copyWith(response: res, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  void clear() {
    state = const LanguageExplainState();
  }
}

final languageExplainProvider =
    StateNotifierProvider<LanguageExplainNotifier, LanguageExplainState>((ref) {
  final repo = ref.watch(vidyasetuRepositoryProvider);
  return LanguageExplainNotifier(repo);
});
