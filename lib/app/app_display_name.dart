import 'dart:convert';
import 'dart:io';

import 'package:diary_mvp/app/localization/app_strings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final appDisplayNameStorageProvider = Provider<AppDisplayNameStorage>((ref) {
  return AppDisplayNameStorage();
});

final appDisplayNameControllerProvider =
    AsyncNotifierProvider<AppDisplayNameController, String?>(
  AppDisplayNameController.new,
);

class AppDisplayNameStorage {
  Future<String?> read() async {
    final file = await _settingsFile();
    if (!await file.exists()) return null;

    try {
      final raw = jsonDecode(await file.readAsString());
      if (raw is! Map<String, dynamic>) return null;
      final value = raw['app_display_name'];
      if (value is! String) return null;
      final normalized = value.trim();
      return normalized.isEmpty ? null : normalized;
    } on FormatException {
      return null;
    }
  }

  Future<void> write(String? value) async {
    final file = await _settingsFile();
    final normalized = value?.trim();

    if (normalized == null || normalized.isEmpty) {
      if (await file.exists()) {
        await file.delete();
      }
      return;
    }

    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'app_display_name': normalized,
      }),
      flush: true,
    );
  }

  Future<File> _settingsFile() async {
    final documents = await getApplicationDocumentsDirectory();
    final settingsDir = Directory(
      p.join(documents.path, 'diary_mvp', 'settings'),
    );
    return File(p.join(settingsDir.path, 'app_settings.json'));
  }
}

class AppDisplayNameController extends AsyncNotifier<String?> {
  AppDisplayNameStorage get _storage => ref.read(appDisplayNameStorageProvider);

  @override
  Future<String?> build() {
    return _storage.read();
  }

  Future<void> save(String value) async {
    final previous = state.valueOrNull;
    final normalized = _normalize(value);
    state = AsyncData(normalized);

    try {
      await _storage.write(normalized);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> reset() async {
    final previous = state.valueOrNull;
    state = const AsyncData(null);

    try {
      await _storage.write(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      state = AsyncData(previous);
      rethrow;
    }
  }

  String? _normalize(String raw) {
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

String resolveAppDisplayName({
  required AppStrings strings,
  required AsyncValue<String?> customNameAsync,
}) {
  return customNameAsync.maybeWhen(
    data: (customName) {
      final normalized = customName?.trim();
      if (normalized == null || normalized.isEmpty) {
        return strings.appTitle;
      }
      return normalized;
    },
    orElse: () => strings.appTitle,
  );
}
