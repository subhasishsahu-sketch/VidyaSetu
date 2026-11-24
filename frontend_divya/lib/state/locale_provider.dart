import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppLanguage { odia, english }

class LocaleNotifier extends StateNotifier<AppLanguage> {
  LocaleNotifier() : super(AppLanguage.odia);

  void toggleLanguage() {
    state = state == AppLanguage.odia ? AppLanguage.english : AppLanguage.odia;
  }

  void setLanguage(AppLanguage language) {
    state = language;
  }

  bool get isOdia => state == AppLanguage.odia;
}

final localeProvider = StateNotifierProvider<LocaleNotifier, AppLanguage>((ref) {
  return LocaleNotifier();
});
