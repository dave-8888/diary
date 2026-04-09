import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final diaryAiSettingsStorageProvider = Provider<DiaryAiSettingsStorage>((ref) {
  return DiaryAiSettingsStorage();
});

final diaryAiEnvironmentApiKeyProvider = Provider<String>((ref) {
  return resolvedDiaryAiEnvironmentApiKey;
});

final diaryAiConfigControllerProvider =
    AsyncNotifierProvider<DiaryAiConfigController, DiaryAiProviderConfig>(
  DiaryAiConfigController.new,
);

final diaryAiVisibilityControllerProvider =
    AsyncNotifierProvider<DiaryAiVisibilityController, bool>(
  DiaryAiVisibilityController.new,
);

final emotionalCompanionVisibilityControllerProvider =
    AsyncNotifierProvider<EmotionalCompanionVisibilityController, bool>(
  EmotionalCompanionVisibilityController.new,
);

final problemSuggestionVisibilityControllerProvider =
    AsyncNotifierProvider<ProblemSuggestionVisibilityController, bool>(
  ProblemSuggestionVisibilityController.new,
);

enum DiaryAiProviderPreset {
  dashScope,
  openAi,
  anthropic,
  gemini,
  openRouter,
  custom,
}

extension DiaryAiProviderPresetX on DiaryAiProviderPreset {
  String get id {
    switch (this) {
      case DiaryAiProviderPreset.dashScope:
        return 'dashscope';
      case DiaryAiProviderPreset.openAi:
        return 'openai';
      case DiaryAiProviderPreset.anthropic:
        return 'anthropic';
      case DiaryAiProviderPreset.gemini:
        return 'gemini';
      case DiaryAiProviderPreset.openRouter:
        return 'openrouter';
      case DiaryAiProviderPreset.custom:
        return 'custom';
    }
  }

  String get label {
    switch (this) {
      case DiaryAiProviderPreset.dashScope:
        return 'Qwen / DashScope';
      case DiaryAiProviderPreset.openAi:
        return 'OpenAI';
      case DiaryAiProviderPreset.anthropic:
        return 'Claude (compat)';
      case DiaryAiProviderPreset.gemini:
        return 'Gemini (compat)';
      case DiaryAiProviderPreset.openRouter:
        return 'OpenRouter';
      case DiaryAiProviderPreset.custom:
        return 'Custom';
    }
  }

  String get defaultBaseUrl {
    switch (this) {
      case DiaryAiProviderPreset.dashScope:
        return 'https://dashscope.aliyuncs.com/compatible-mode/v1/';
      case DiaryAiProviderPreset.openAi:
        return 'https://api.openai.com/v1/';
      case DiaryAiProviderPreset.anthropic:
        return 'https://api.anthropic.com/v1/';
      case DiaryAiProviderPreset.gemini:
        return 'https://generativelanguage.googleapis.com/v1beta/openai/';
      case DiaryAiProviderPreset.openRouter:
        return 'https://openrouter.ai/api/v1/';
      case DiaryAiProviderPreset.custom:
        return '';
    }
  }

  String get defaultModel {
    switch (this) {
      case DiaryAiProviderPreset.dashScope:
        return 'qwen-plus';
      case DiaryAiProviderPreset.openAi:
        return 'gpt-4.1-mini';
      case DiaryAiProviderPreset.anthropic:
        return 'claude-sonnet-4-5';
      case DiaryAiProviderPreset.gemini:
        return 'gemini-2.5-flash';
      case DiaryAiProviderPreset.openRouter:
        return 'openai/gpt-4.1-mini';
      case DiaryAiProviderPreset.custom:
        return '';
    }
  }

  static DiaryAiProviderPreset fromId(String? rawId) {
    final normalized = rawId?.trim().toLowerCase();
    for (final preset in DiaryAiProviderPreset.values) {
      if (preset.id == normalized) {
        return preset;
      }
    }
    return DiaryAiProviderPreset.custom;
  }
}

enum DiaryAiModelSelectionSource {
  catalog,
  manual,
}

extension DiaryAiModelSelectionSourceX on DiaryAiModelSelectionSource {
  String get id {
    switch (this) {
      case DiaryAiModelSelectionSource.catalog:
        return 'catalog';
      case DiaryAiModelSelectionSource.manual:
        return 'manual';
    }
  }

  static DiaryAiModelSelectionSource? fromId(String? rawId) {
    final normalized = rawId?.trim().toLowerCase();
    for (final source in DiaryAiModelSelectionSource.values) {
      if (source.id == normalized) {
        return source;
      }
    }
    return null;
  }
}

class DiaryAiProviderConfig {
  const DiaryAiProviderConfig({
    required this.presetId,
    required this.baseUrl,
    required this.model,
    this.modelType,
    this.modelSource,
    this.apiKey,
  });

  final String presetId;
  final String baseUrl;
  final String model;
  final String? modelType;
  final DiaryAiModelSelectionSource? modelSource;
  final String? apiKey;

  DiaryAiProviderPreset get preset => DiaryAiProviderPresetX.fromId(presetId);

  String get normalizedBaseUrl {
    final value = baseUrl.trim();
    if (value.isNotEmpty) {
      return value;
    }
    return preset.defaultBaseUrl;
  }

  String get normalizedModel {
    final value = model.trim();
    if (value.isNotEmpty) {
      return value;
    }
    return preset.defaultModel;
  }

  String? get normalizedModelType {
    final value = modelType?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  DiaryAiModelSelectionSource? get normalizedModelSource => modelSource;

  String? get normalizedApiKey {
    final value = apiKey?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  String? resolvedApiKey({
    String? fallbackApiKey,
  }) {
    final configured = normalizedApiKey;
    if (configured != null) {
      return configured;
    }

    final fallback = fallbackApiKey?.trim();
    if (fallback == null || fallback.isEmpty) {
      return null;
    }
    return fallback;
  }

  DiaryAiProviderConfig copyWith({
    String? presetId,
    String? baseUrl,
    String? model,
    Object? modelType = _copyWithSentinel,
    Object? modelSource = _copyWithSentinel,
    Object? apiKey = _copyWithSentinel,
  }) {
    return DiaryAiProviderConfig(
      presetId: presetId ?? this.presetId,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      modelType: identical(modelType, _copyWithSentinel)
          ? this.modelType
          : modelType as String?,
      modelSource: identical(modelSource, _copyWithSentinel)
          ? this.modelSource
          : modelSource as DiaryAiModelSelectionSource?,
      apiKey: identical(apiKey, _copyWithSentinel)
          ? this.apiKey
          : apiKey as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'ai_provider_preset': preset.id,
      'ai_base_url': normalizedBaseUrl,
      'ai_model': normalizedModel,
      if (normalizedModelType != null) 'ai_model_type': normalizedModelType,
      if (normalizedModelSource != null)
        'ai_model_source': normalizedModelSource!.id,
      if (normalizedApiKey != null) 'ai_api_key': normalizedApiKey,
    };
  }

  static DiaryAiProviderConfig forPreset(
    DiaryAiProviderPreset preset, {
    String? apiKey,
  }) {
    return DiaryAiProviderConfig(
      presetId: preset.id,
      baseUrl: preset.defaultBaseUrl,
      model: preset.defaultModel,
      apiKey: apiKey,
    );
  }

  static DiaryAiProviderConfig fromJson(Map<String, dynamic> raw) {
    final hasStoredConfig = raw.containsKey('ai_provider_preset') ||
        raw.containsKey('ai_base_url') ||
        raw.containsKey('ai_model');
    final preset = hasStoredConfig
        ? DiaryAiProviderPresetX.fromId(
            _readString(raw['ai_provider_preset']),
          )
        : DiaryAiProviderPreset.dashScope;
    final baseUrl = _readString(raw['ai_base_url']);
    final model = _readString(raw['ai_model']);
    final modelType = _readString(raw['ai_model_type']);
    final modelSource = DiaryAiModelSelectionSourceX.fromId(
      _readString(raw['ai_model_source']),
    );
    final apiKey =
        _readString(raw['ai_api_key']) ?? _readString(raw['dashscope_api_key']);

    return DiaryAiProviderConfig(
      presetId: preset.id,
      baseUrl: baseUrl ?? preset.defaultBaseUrl,
      model: model ?? preset.defaultModel,
      modelType: modelType,
      modelSource: modelSource,
      apiKey: apiKey,
    );
  }

  static String? _readString(Object? raw) {
    if (raw is! String) {
      return null;
    }
    final normalized = raw.trim();
    return normalized.isEmpty ? null : normalized;
  }
}

class DiaryAiSettingsStorage {
  Future<DiaryAiProviderConfig> readConfig() async {
    final raw = await _readRaw();
    return DiaryAiProviderConfig.fromJson(raw);
  }

  Future<void> writeConfig(DiaryAiProviderConfig config) async {
    final raw = await _readRaw();
    raw
      ..remove('dashscope_api_key')
      ..remove('ai_provider_preset')
      ..remove('ai_base_url')
      ..remove('ai_model')
      ..remove('ai_model_type')
      ..remove('ai_model_source')
      ..remove('ai_api_key')
      ..addAll(config.toJson());
    await _writeRaw(raw);
  }

  Future<String?> read() async {
    return (await readConfig()).normalizedApiKey;
  }

  Future<void> write(String? apiKey) async {
    final current = await readConfig();
    await writeConfig(current.copyWith(apiKey: apiKey));
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

  Future<bool> readProblemSuggestionVisibility() async {
    final raw = await _readRaw();
    final value = raw['problem_suggestion_enabled'];
    if (value is bool) return value;
    return true;
  }

  Future<void> writeProblemSuggestionVisibility(bool enabled) async {
    final raw = await _readRaw();
    raw['problem_suggestion_enabled'] = enabled;
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

class DiaryAiConfigController extends AsyncNotifier<DiaryAiProviderConfig> {
  DiaryAiSettingsStorage get _storage =>
      ref.read(diaryAiSettingsStorageProvider);

  @override
  Future<DiaryAiProviderConfig> build() {
    return _storage.readConfig();
  }

  Future<void> save(DiaryAiProviderConfig config) async {
    final previous = state.valueOrNull ?? _defaultDiaryAiConfig;
    final normalized = config.copyWith(
      baseUrl: config.normalizedBaseUrl,
      model: config.normalizedModel,
      modelType: config.normalizedModelType,
      modelSource: config.normalizedModelSource,
      apiKey: config.normalizedApiKey,
    );
    state = AsyncData(normalized);

    try {
      await _storage.writeConfig(normalized);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> reset() async {
    final previous = state.valueOrNull ?? _defaultDiaryAiConfig;
    state = AsyncData(_defaultDiaryAiConfig);

    try {
      await _storage.writeConfig(_defaultDiaryAiConfig);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      state = AsyncData(previous);
      rethrow;
    }
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

class ProblemSuggestionVisibilityController extends AsyncNotifier<bool> {
  DiaryAiSettingsStorage get _storage =>
      ref.read(diaryAiSettingsStorageProvider);

  @override
  Future<bool> build() {
    return _storage.readProblemSuggestionVisibility();
  }

  Future<void> setEnabled(bool enabled) async {
    final previous = state.valueOrNull ?? true;
    state = AsyncData(enabled);

    try {
      await _storage.writeProblemSuggestionVisibility(enabled);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      state = AsyncData(previous);
      rethrow;
    }
  }
}

const Object _copyWithSentinel = Object();

final DiaryAiProviderConfig _defaultDiaryAiConfig =
    DiaryAiProviderConfig.forPreset(DiaryAiProviderPreset.dashScope);

const String diaryAiEnvironmentApiKey =
    String.fromEnvironment('DIARY_AI_API_KEY');
const String legacyDiaryAiEnvironmentApiKey =
    String.fromEnvironment('DASHSCOPE_API_KEY');

String get resolvedDiaryAiEnvironmentApiKey {
  final primary = diaryAiEnvironmentApiKey.trim();
  if (primary.isNotEmpty) {
    return primary;
  }
  return legacyDiaryAiEnvironmentApiKey.trim();
}
