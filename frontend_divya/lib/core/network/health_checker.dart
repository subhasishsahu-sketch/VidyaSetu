import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'api_client.dart';

/// Checks device connectivity + backend health to decide online vs offline routing.
class HealthChecker {
  final ApiClient _apiClient;
  final Connectivity _connectivity;

  HealthChecker({
    required ApiClient apiClient,
    Connectivity? connectivity,
  })  : _apiClient = apiClient,
        _connectivity = connectivity ?? Connectivity();

  /// Returns true if the device has network AND the backend is reachable.
  Future<bool> isOnline() async {
    try {
      final results = await _connectivity.checkConnectivity();
      if (results.contains(ConnectivityResult.none)) {
        return false;
      }
      final health = await _apiClient.checkHealth();
      final status = health['status']?.toString() ?? '';
      return status == 'healthy' || status == 'degraded';
    } catch (_) {
      return false;
    }
  }

  /// Returns the full health response from the backend.
  Future<Map<String, dynamic>> getHealthStatus() async {
    return _apiClient.checkHealth();
  }
}
