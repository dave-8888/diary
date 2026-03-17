import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final diaryAiApiKeyStorageProvider = Provider<DiaryAiApiKeyStorage>((ref) {
  return DiaryAiApiKeyStorage();
});

final diaryAiApiKeyControllerProvider =
    AsyncNotifierProvider<DiaryAiApiKeyController, String?>(
  DiaryAiApiKeyController.new,
);

class DiaryAiApiKeyStorage {
  Future<String?> read() async {
    final file = await _settingsFile();
    if (!await file.exists()) return null;

    try {
      final raw = jsonDecode(await file.readAsString());
      if (raw is! Map<String, dynamic>) return null;
      final value = raw['dashscope_api_key'];
      if (value is! String) return null;
      final normalized = value.trim();
      return normalized.isEmpty ? null : normalized;
    } on FormatException {
      return null;
    }
  }

  Future<void> write(String? apiKey) async {
    final normalized = apiKey?.trim();
    final file = await _settingsFile();

    if (normalized == null || normalized.isEmpty) {
      if (await file.exists()) {
        await file.delete();
      }
      return;
    }

    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'dashscope_api_key': normalized,
      }),
      flush: true,
    );
  }

  Future<File> _settingsFile() async {
    final documents = await getApplicationDocumentsDirectory();
    final settingsDir = Directory(
      p.join(documents.path, 'diary_mvp', 'settings'),
    );
    return File(p.join(settingsDir.path, 'diary_ai_settings.json'));
  }
}

class DiaryAiApiKeyController extends AsyncNotifier<String?> {
  DiaryAiApiKeyStorage get _storage => ref.read(diaryAiApiKeyStorageProvider);

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

const String diaryAiEnvironmentApiKey =
    String.fromEnvironment('DASHSCOPE_API_KEY');
