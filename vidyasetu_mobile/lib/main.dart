import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('====================================================');
  debugPrint('[VidyaSetu Startup] Resolved API Base URL: ${AppConfig.apiBaseUrl}');
  debugPrint('====================================================');
  // Safe offline font fetching policy
  GoogleFonts.config.allowRuntimeFetching = true;

  runApp(
    const ProviderScope(
      child: VidyaSetuApp(),
    ),
  );
}
