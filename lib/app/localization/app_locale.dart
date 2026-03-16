import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

enum AppLanguage { system, english, chinese }

final appLanguageStorageProvider = Provider<AppLanguageStorage>((ref) {
  return AppLanguageStorage();
});

final appLanguageProvider =
    AsyncNotifierProvider<AppLanguageController, AppLanguage>(
  AppLanguageController.new,
);

final appLocaleProvider = Provider<Locale?>((ref) {
  final language = resolveAppLanguage(ref.watch(appLanguageProvider));
  switch (language) {
    case AppLanguage.system:
      return null;
    case AppLanguage.english:
      return const Locale('en');
    case AppLanguage.chinese:
      return const Locale('zh');
  }
});

class AppLanguageStorage {
  Future<AppLanguage> read() async {
    final file = await _settingsFile();
    if (!await file.exists()) return AppLanguage.system;

    try {
      final raw = jsonDecode(await file.readAsString());
      if (raw is! Map<String, dynamic>) return AppLanguage.system;
      final value = raw['language'];
      if (value is! String) return AppLanguage.system;
      return AppLanguage.values.firstWhere(
        (language) => language.name == value,
        orElse: () => AppLanguage.system,
      );
    } on FormatException {
      return AppLanguage.system;
    }
  }

  Future<void> write(AppLanguage language) async {
    final file = await _settingsFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'language': language.name,
      }),
      flush: true,
    );
  }

  Future<File> _settingsFile() async {
    final documents = await getApplicationDocumentsDirectory();
    final settingsDir = Directory(
      p.join(documents.path, 'diary_mvp', 'settings'),
    );
    return File(p.join(settingsDir.path, 'language_settings.json'));
  }
}

class AppLanguageController extends AsyncNotifier<AppLanguage> {
  AppLanguageStorage get _storage => ref.read(appLanguageStorageProvider);

  @override
  Future<AppLanguage> build() {
    return _storage.read();
  }

  Future<void> setLanguage(AppLanguage language) async {
    final previous = state.valueOrNull ?? AppLanguage.system;
    state = AsyncData(language);

    try {
      await _storage.write(language);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      state = AsyncData(previous);
      rethrow;
    }
  }
}

AppLanguage resolveAppLanguage(AsyncValue<AppLanguage> languageAsync) {
  return languageAsync.maybeWhen(
    data: (language) => language,
    orElse: () => AppLanguage.system,
  );
}
