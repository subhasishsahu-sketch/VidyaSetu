import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../core/network/health_checker.dart';

/// Singleton ApiClient provider.
final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient();
  ref.onDispose(() => client.dispose());
  return client;
});

/// HealthChecker provider.
final healthCheckerProvider = Provider<HealthChecker>((ref) {
  return HealthChecker(apiClient: ref.watch(apiClientProvider));
});

/// Async provider that checks whether the backend is online.
/// Call `ref.refresh(isOnlineProvider)` to re-check connectivity.
final isOnlineProvider = FutureProvider<bool>((ref) async {
  final checker = ref.watch(healthCheckerProvider);
  return checker.isOnline();
});
