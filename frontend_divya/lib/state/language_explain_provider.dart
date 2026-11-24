import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../data/models/language_model.dart';
import 'health_provider.dart';

/// State for concept explanation via 3-Way Language Bridge.
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
  final ApiClient _apiClient;

  LanguageExplainNotifier(this._apiClient) : super(const LanguageExplainState());

  /// Calls POST /api/v1/language/explain with the given request.
  Future<void> explainConcept(LanguageExplainRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final json = await _apiClient.post('/language/explain', request.toJson());
      final response = LanguageExplainResponse.fromJson(json);
      state = state.copyWith(response: response, isLoading: false);
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
  final apiClient = ref.watch(apiClientProvider);
  return LanguageExplainNotifier(apiClient);
});
