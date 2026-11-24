import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Environment and network configuration for VidyaSetu client SDK.
class AppConfig {
  static const String _envBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// Dynamically resolved base API URL.
  /// Priority:
  /// 1. `--dart-define=API_BASE_URL=...`
  /// 2. Android Emulator -> `http://10.0.2.2:8000/api/v1`
  /// 3. Windows / macOS / Linux / Web -> `http://localhost:8000/api/v1`
  static String get apiBaseUrl {
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl;
    }
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api/v1';
    }
    return 'http://localhost:8000/api/v1';
  }

  /// Timeout for connectivity & health checking (2-3 seconds).
  static const Duration healthTimeout = Duration(seconds: 3);

  /// General HTTP request timeout.
  static const Duration requestTimeout = Duration(seconds: 10);

  /// Max number of offline events sent in a single sync batch.
  static const int maxBatchSyncSize = 50;

  /// Default asset path to the pre-packaged offline curriculum SQLite database.
  static const String offlineDbAssetPath = 'assets/db/offline_curriculum.db';
}
