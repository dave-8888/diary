import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppLanguage { system, english, chinese }

final appLanguageProvider =
    NotifierProvider<AppLanguageController, AppLanguage>(
  AppLanguageController.new,
);

final appLocaleProvider = Provider<Locale?>((ref) {
  final language = ref.watch(appLanguageProvider);
  switch (language) {
    case AppLanguage.system:
      return null;
    case AppLanguage.english:
      return const Locale('en');
    case AppLanguage.chinese:
      return const Locale('zh');
  }
});

class AppLanguageController extends Notifier<AppLanguage> {
  @override
  AppLanguage build() => AppLanguage.system;

  void setLanguage(AppLanguage language) {
    state = language;
  }
}
