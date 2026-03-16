import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final transcriptionApiKeyStorageProvider =
    Provider<TranscriptionApiKeyStorage>((ref) {
  return TranscriptionApiKeyStorage();
});

final transcriptionApiKeyControllerProvider =
    AsyncNotifierProvider<TranscriptionApiKeyController, String?>(
  TranscriptionApiKeyController.new,
);

class TranscriptionApiKeyStorage {
  Future<String?> read() async {
    final file = await _settingsFile();
    if (!await file.exists()) return null;

    try {
      final raw = jsonDecode(await file.readAsString());
      if (raw is! Map<String, dynamic>) return null;
      final value = raw['openai_api_key'];
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
        'openai_api_key': normalized,
      }),
      flush: true,
    );
  }

  Future<File> _settingsFile() async {
    final documents = await getApplicationDocumentsDirectory();
    final settingsDir = Directory(
      p.join(documents.path, 'diary_mvp', 'settings'),
    );
    return File(p.join(settingsDir.path, 'transcription_settings.json'));
  }
}

class TranscriptionApiKeyController extends AsyncNotifier<String?> {
  TranscriptionApiKeyStorage get _storage =>
      ref.read(transcriptionApiKeyStorageProvider);

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

const String transcriptionEnvironmentApiKey =
    String.fromEnvironment('OPENAI_API_KEY');
