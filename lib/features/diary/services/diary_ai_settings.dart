import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final diaryAiSettingsStorageProvider = Provider<DiaryAiSettingsStorage>((ref) {
  return DiaryAiSettingsStorage();
});

final diaryAiApiKeyStorageProvider = Provider<DiaryAiSettingsStorage>((ref) {
  return ref.read(diaryAiSettingsStorageProvider);
});

final diaryAiApiKeyControllerProvider =
    AsyncNotifierProvider<DiaryAiApiKeyController, String?>(
  DiaryAiApiKeyController.new,
);

final diaryAiVisibilityControllerProvider =
    AsyncNotifierProvider<DiaryAiVisibilityController, bool>(
  DiaryAiVisibilityController.new,
);

final emotionalCompanionVisibilityControllerProvider =
    AsyncNotifierProvider<EmotionalCompanionVisibilityController, bool>(
  EmotionalCompanionVisibilityController.new,
);

class DiaryAiSettingsStorage {
  Future<String?> read() async {
    final raw = await _readRaw();
    final value = raw['dashscope_api_key'];
    if (value is! String) return null;
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  Future<void> write(String? apiKey) async {
    final normalized = apiKey?.trim();
    final raw = await _readRaw();

    if (normalized == null || normalized.isEmpty) {
      raw.remove('dashscope_api_key');
    } else {
      raw['dashscope_api_key'] = normalized;
    }

    await _writeRaw(raw);
  }

  Future<bool> readVisibility() async {
    final raw = await _readRaw();
    final value = raw['ai_analysis_enabled'];
    if (value is bool) return value;
    return true;
  }

  Future<void> writeVisibility(bool enabled) async {
    final raw = await _readRaw();
    raw['ai_analysis_enabled'] = enabled;
    await _writeRaw(raw);
  }

  Future<bool> readEmotionalCompanionVisibility() async {
    final raw = await _readRaw();
    final value = raw['emotional_companion_enabled'];
    if (value is bool) return value;
    return true;
  }

  Future<void> writeEmotionalCompanionVisibility(bool enabled) async {
    final raw = await _readRaw();
    raw['emotional_companion_enabled'] = enabled;
    await _writeRaw(raw);
  }

  Future<File> _settingsFile() async {
    final documents = await getApplicationDocumentsDirectory();
    final settingsDir = Directory(
      p.join(documents.path, 'diary_mvp', 'settings'),
    );
    return File(p.join(settingsDir.path, 'diary_ai_settings.json'));
  }

  Future<Map<String, dynamic>> _readRaw() async {
    final file = await _settingsFile();
    if (!await file.exists()) return <String, dynamic>{};

    try {
      final raw = jsonDecode(await file.readAsString());
      if (raw is Map<String, dynamic>) {
        return Map<String, dynamic>.from(raw);
      }
    } on FormatException {
      return <String, dynamic>{};
    }

    return <String, dynamic>{};
  }

  Future<void> _writeRaw(Map<String, dynamic> raw) async {
    final file = await _settingsFile();

    if (raw.isEmpty) {
      if (await file.exists()) {
        await file.delete();
      }
      return;
    }

    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(raw),
      flush: true,
    );
  }
}

class DiaryAiApiKeyController extends AsyncNotifier<String?> {
  DiaryAiSettingsStorage get _storage => ref.read(diaryAiApiKeyStorageProvider);

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

class DiaryAiVisibilityController extends AsyncNotifier<bool> {
  DiaryAiSettingsStorage get _storage =>
      ref.read(diaryAiSettingsStorageProvider);

  @override
  Future<bool> build() {
    return _storage.readVisibility();
  }

  Future<void> setEnabled(bool enabled) async {
    final previous = state.valueOrNull ?? true;
    state = AsyncData(enabled);

    try {
      await _storage.writeVisibility(enabled);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      state = AsyncData(previous);
      rethrow;
    }
  }
}

class EmotionalCompanionVisibilityController extends AsyncNotifier<bool> {
  DiaryAiSettingsStorage get _storage =>
      ref.read(diaryAiSettingsStorageProvider);

  @override
  Future<bool> build() {
    return _storage.readEmotionalCompanionVisibility();
  }

  Future<void> setEnabled(bool enabled) async {
    final previous = state.valueOrNull ?? true;
    state = AsyncData(enabled);

    try {
      await _storage.writeEmotionalCompanionVisibility(enabled);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      state = AsyncData(previous);
      rethrow;
    }
  }
}

const String diaryAiEnvironmentApiKey =
    String.fromEnvironment('DASHSCOPE_API_KEY');
