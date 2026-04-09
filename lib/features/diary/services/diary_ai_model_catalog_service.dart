import 'dart:async';
import 'dart:convert';

import 'package:diary_mvp/features/diary/services/diary_ai_settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final diaryAiModelCatalogHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final diaryAiModelCatalogServiceProvider =
    Provider<DiaryAiModelCatalogService>((
  ref,
) {
  return DiaryAiModelCatalogService(
    client: ref.watch(diaryAiModelCatalogHttpClientProvider),
    environmentApiKey: ref.watch(diaryAiEnvironmentApiKeyProvider),
  );
});

final diaryAiModelCatalogControllerProvider =
    NotifierProvider<DiaryAiModelCatalogController, DiaryAiModelCatalogResult>(
  DiaryAiModelCatalogController.new,
);

enum DiaryAiModelCatalogStatus {
  idle,
  loading,
  success,
  empty,
  requestFailed,
  invalidConfig,
  apiKeyMissing,
}

enum DiaryAiModelTrait {
  multimodal,
  text,
  imageInput,
  imageOutput,
  audioInput,
  audioOutput,
  videoInput,
  videoOutput,
  reasoning,
  embedding,
  reranking,
  moderation,
  realtime,
}

enum DiaryAiModelDisplayGroup {
  multimodal,
  text,
  image,
  audio,
  video,
  reasoning,
  vectorAndReranking,
  realtime,
  moderation,
  other,
}

class DiaryAiModelCatalogEntry {
  const DiaryAiModelCatalogEntry({
    required this.id,
    this.name,
    this.description,
    this.traits = const <DiaryAiModelTrait>[],
  });

  final String id;
  final String? name;
  final String? description;
  final List<DiaryAiModelTrait> traits;

  List<DiaryAiModelDisplayGroup> get displayGroups {
    return resolveDiaryAiModelDisplayGroups(traits);
  }

  DiaryAiModelCatalogEntry merge(DiaryAiModelCatalogEntry other) {
    final mergedTraits = <DiaryAiModelTrait>{...traits, ...other.traits}.toList(
      growable: false,
    )..sort((a, b) => a.index.compareTo(b.index));
    return DiaryAiModelCatalogEntry(
      id: id,
      name: name ?? other.name,
      description: description ?? other.description,
      traits: mergedTraits,
    );
  }
}

class DiaryAiModelCatalogResult {
  const DiaryAiModelCatalogResult({
    required this.status,
    this.models = const <DiaryAiModelCatalogEntry>[],
    this.statusCode,
    this.error,
  });

  const DiaryAiModelCatalogResult.idle()
      : status = DiaryAiModelCatalogStatus.idle,
        models = const <DiaryAiModelCatalogEntry>[],
        statusCode = null,
        error = null;

  const DiaryAiModelCatalogResult.loading()
      : status = DiaryAiModelCatalogStatus.loading,
        models = const <DiaryAiModelCatalogEntry>[],
        statusCode = null,
        error = null;

  const DiaryAiModelCatalogResult.apiKeyMissing()
      : status = DiaryAiModelCatalogStatus.apiKeyMissing,
        models = const <DiaryAiModelCatalogEntry>[],
        statusCode = null,
        error = null;

  const DiaryAiModelCatalogResult.invalidConfig({
    this.error,
  })  : status = DiaryAiModelCatalogStatus.invalidConfig,
        models = const <DiaryAiModelCatalogEntry>[],
        statusCode = null;

  const DiaryAiModelCatalogResult.empty({
    this.statusCode,
  })  : status = DiaryAiModelCatalogStatus.empty,
        models = const <DiaryAiModelCatalogEntry>[],
        error = null;

  const DiaryAiModelCatalogResult.requestFailed({
    this.statusCode,
    this.error,
  })  : status = DiaryAiModelCatalogStatus.requestFailed,
        models = const <DiaryAiModelCatalogEntry>[];

  const DiaryAiModelCatalogResult.success(
    this.models, {
    this.statusCode,
  })  : status = DiaryAiModelCatalogStatus.success,
        error = null;

  final DiaryAiModelCatalogStatus status;
  final List<DiaryAiModelCatalogEntry> models;
  final int? statusCode;
  final Object? error;

  bool get isLoading => status == DiaryAiModelCatalogStatus.loading;
  bool get hasModels => models.isNotEmpty;

  List<DiaryAiModelCatalogEntry> modelsForGroup(
    DiaryAiModelDisplayGroup group,
  ) {
    return models
        .where((model) => model.displayGroups.contains(group))
        .toList(growable: false);
  }

  DiaryAiModelCatalogEntry? findById(String id) {
    final rawLookup = id.trim();
    final normalizedLookup = normalizeDiaryAiModelLookupValue(id);
    if (rawLookup.isEmpty || normalizedLookup == null) {
      return null;
    }

    DiaryAiModelCatalogEntry? normalizedNameMatch;
    for (final model in models) {
      if (model.id == rawLookup) {
        return model;
      }
      if (normalizeDiaryAiModelLookupValue(model.id) == normalizedLookup) {
        return model;
      }
      final modelName = model.name;
      if (modelName == null ||
          normalizeDiaryAiModelLookupValue(modelName) != normalizedLookup) {
        continue;
      }
      if (normalizedNameMatch != null) {
        return null;
      }
      normalizedNameMatch = model;
    }
    return normalizedNameMatch;
  }
}

String? normalizeDiaryAiModelLookupValue(String? raw) {
  final trimmed = raw?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }

  return trimmed
      .replaceAll('／', '/')
      .replaceAll(RegExp(r'\s*/\s*'), '/')
      .replaceAll(RegExp(r'\s+'), ' ')
      .toLowerCase();
}

List<DiaryAiModelDisplayGroup> resolveDiaryAiModelDisplayGroups(
  Iterable<DiaryAiModelTrait> traits,
) {
  final groups = <DiaryAiModelDisplayGroup>{};

  for (final trait in traits) {
    switch (trait) {
      case DiaryAiModelTrait.multimodal:
        groups.add(DiaryAiModelDisplayGroup.multimodal);
      case DiaryAiModelTrait.text:
        groups.add(DiaryAiModelDisplayGroup.text);
      case DiaryAiModelTrait.imageInput:
      case DiaryAiModelTrait.imageOutput:
        groups.add(DiaryAiModelDisplayGroup.image);
      case DiaryAiModelTrait.audioInput:
      case DiaryAiModelTrait.audioOutput:
        groups.add(DiaryAiModelDisplayGroup.audio);
      case DiaryAiModelTrait.videoInput:
      case DiaryAiModelTrait.videoOutput:
        groups.add(DiaryAiModelDisplayGroup.video);
      case DiaryAiModelTrait.reasoning:
        groups.add(DiaryAiModelDisplayGroup.reasoning);
      case DiaryAiModelTrait.embedding:
      case DiaryAiModelTrait.reranking:
        groups.add(DiaryAiModelDisplayGroup.vectorAndReranking);
      case DiaryAiModelTrait.realtime:
        groups.add(DiaryAiModelDisplayGroup.realtime);
      case DiaryAiModelTrait.moderation:
        groups.add(DiaryAiModelDisplayGroup.moderation);
    }
  }

  if (groups.isEmpty) {
    groups.add(DiaryAiModelDisplayGroup.other);
  }

  return DiaryAiModelDisplayGroup.values
      .where(groups.contains)
      .toList(growable: false);
}

class DiaryAiModelCatalogController
    extends Notifier<DiaryAiModelCatalogResult> {
  int _requestId = 0;

  DiaryAiModelCatalogService get _service =>
      ref.read(diaryAiModelCatalogServiceProvider);

  @override
  DiaryAiModelCatalogResult build() {
    return const DiaryAiModelCatalogResult.idle();
  }

  Future<DiaryAiModelCatalogResult> fetchModels(
    DiaryAiProviderConfig config,
  ) async {
    final requestId = ++_requestId;
    state = const DiaryAiModelCatalogResult.loading();

    final result = await _service.fetchModels(config);
    if (requestId != _requestId) {
      return state;
    }

    state = result;
    return result;
  }

  void reset() {
    _requestId++;
    state = const DiaryAiModelCatalogResult.idle();
  }
}

class DiaryAiModelCatalogService {
  DiaryAiModelCatalogService({
    required http.Client client,
    required String environmentApiKey,
  })  : _client = client,
        _environmentApiKey = environmentApiKey;

  static const _anthropicVersion = '2023-06-01';
  static const _requestTimeout = Duration(seconds: 20);

  final http.Client _client;
  final String _environmentApiKey;

  Future<DiaryAiModelCatalogResult> fetchModels(
    DiaryAiProviderConfig config,
  ) async {
    final requestUrl = _resolveModelsUrl(config.normalizedBaseUrl);
    if (requestUrl == null) {
      return const DiaryAiModelCatalogResult.invalidConfig();
    }

    final apiKey = config.resolvedApiKey(
      fallbackApiKey: _environmentApiKey,
    );
    if (apiKey == null) {
      return const DiaryAiModelCatalogResult.apiKeyMissing();
    }

    http.Response response;
    try {
      response = await _client
          .get(
            Uri.parse(requestUrl),
            headers: _buildHeaders(
              preset: config.preset,
              apiKey: apiKey,
            ),
          )
          .timeout(_requestTimeout);
    } on FormatException catch (error) {
      return DiaryAiModelCatalogResult.invalidConfig(error: error);
    } on TimeoutException catch (error) {
      return DiaryAiModelCatalogResult.requestFailed(error: error);
    } on http.ClientException catch (error) {
      return DiaryAiModelCatalogResult.requestFailed(error: error);
    }

    if (response.statusCode >= 400) {
      return DiaryAiModelCatalogResult.requestFailed(
        statusCode: response.statusCode,
      );
    }

    final models = _parseModels(response.body);
    if (models == null) {
      return DiaryAiModelCatalogResult.requestFailed(
        statusCode: response.statusCode,
        error: const FormatException('Invalid models response'),
      );
    }
    if (models.isEmpty) {
      return DiaryAiModelCatalogResult.empty(
        statusCode: response.statusCode,
      );
    }

    return DiaryAiModelCatalogResult.success(
      models,
      statusCode: response.statusCode,
    );
  }

  Map<String, String> _buildHeaders({
    required DiaryAiProviderPreset preset,
    required String apiKey,
  }) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    if (preset == DiaryAiProviderPreset.anthropic) {
      headers['x-api-key'] = apiKey;
      headers['anthropic-version'] = _anthropicVersion;
    }

    return headers;
  }

  String? _resolveModelsUrl(String baseUrl) {
    final trimmed = baseUrl.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    var normalized = trimmed;
    if (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }

    if (normalized.endsWith('/models')) {
      return normalized;
    }

    if (normalized.endsWith('/chat/completions')) {
      final prefix = normalized.substring(
        0,
        normalized.length - '/chat/completions'.length,
      );
      return prefix.endsWith('/') ? '${prefix}models' : '$prefix/models';
    }

    return '$normalized/models';
  }

  List<DiaryAiModelCatalogEntry>? _parseModels(String body) {
    dynamic decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      return null;
    }

    if (decoded is! Map) {
      return null;
    }

    final data = decoded['data'];
    if (data is! List) {
      return null;
    }

    final modelsById = <String, DiaryAiModelCatalogEntry>{};
    for (final item in data) {
      if (item is! Map) {
        continue;
      }
      final entry = _parseModelEntry(item);
      if (entry == null) {
        continue;
      }
      final previous = modelsById[entry.id];
      modelsById[entry.id] = previous == null ? entry : previous.merge(entry);
    }

    final sortedModels = modelsById.values.toList(growable: false)
      ..sort((a, b) => a.id.compareTo(b.id));
    return sortedModels;
  }

  DiaryAiModelCatalogEntry? _parseModelEntry(Map raw) {
    final id = _readString(raw['id']);
    if (id == null) {
      return null;
    }

    final description =
        _readString(raw['description']) ?? _readString(raw['summary']);
    final name = _readString(raw['name']) ?? _readString(raw['display_name']);
    final architecture = raw['architecture'];
    final inputModalities = <String>{
      ..._readStringList(raw['input_modalities']),
      if (architecture is Map)
        ..._readStringList(architecture['input_modalities']),
    };
    final outputModalities = <String>{
      ..._readStringList(raw['output_modalities']),
      if (architecture is Map)
        ..._readStringList(architecture['output_modalities']),
    };

    return DiaryAiModelCatalogEntry(
      id: id,
      name: name,
      description: description,
      traits: _inferTraits(
        id: id,
        name: name,
        description: description,
        inputModalities: inputModalities,
        outputModalities: outputModalities,
      ),
    );
  }

  List<DiaryAiModelTrait> _inferTraits({
    required String id,
    String? name,
    String? description,
    required Set<String> inputModalities,
    required Set<String> outputModalities,
  }) {
    final traits = <DiaryAiModelTrait>{};
    final haystack = '$id ${name ?? ''} ${description ?? ''}'.toLowerCase();

    for (final modality in inputModalities) {
      switch (modality.toLowerCase()) {
        case 'text':
          traits.add(DiaryAiModelTrait.text);
        case 'image':
          traits.add(DiaryAiModelTrait.imageInput);
        case 'audio':
          traits.add(DiaryAiModelTrait.audioInput);
        case 'video':
          traits.add(DiaryAiModelTrait.videoInput);
      }
    }

    for (final modality in outputModalities) {
      switch (modality.toLowerCase()) {
        case 'text':
          traits.add(DiaryAiModelTrait.text);
        case 'image':
          traits.add(DiaryAiModelTrait.imageOutput);
        case 'audio':
          traits.add(DiaryAiModelTrait.audioOutput);
        case 'video':
          traits.add(DiaryAiModelTrait.videoOutput);
      }
    }

    if (_containsAny(haystack, const ['embed', 'embedding'])) {
      traits.add(DiaryAiModelTrait.embedding);
    }
    if (_containsAny(haystack, const ['rerank', 're-rank'])) {
      traits.add(DiaryAiModelTrait.reranking);
    }
    if (_containsAny(haystack, const ['moderation', 'safety'])) {
      traits.add(DiaryAiModelTrait.moderation);
    }
    if (_containsAny(haystack, const ['realtime', 'real-time'])) {
      traits.add(DiaryAiModelTrait.realtime);
    }
    if (_containsAny(haystack, const ['reasoning', 'reasoner'])) {
      traits.add(DiaryAiModelTrait.reasoning);
    }
    if (RegExp(r'(^|[^a-z0-9])(o1|o3|o4|r1)([^a-z0-9]|$)').hasMatch(haystack)) {
      traits.add(DiaryAiModelTrait.reasoning);
    }
    if (_containsAny(
      haystack,
      const [
        'whisper',
        'transcribe',
        'transcription',
        'speech-to-text',
        'speech to text',
        'asr',
        'stt',
      ],
    )) {
      traits.addAll({
        DiaryAiModelTrait.audioInput,
        DiaryAiModelTrait.text,
      });
    }
    if (_containsAny(
      haystack,
      const [
        'tts',
        'text-to-speech',
        'text to speech',
      ],
    )) {
      traits.add(DiaryAiModelTrait.audioOutput);
    }
    if (_containsAny(
      haystack,
      const [
        'dall-e',
        'dall·e',
        'flux',
        'stable-diffusion',
        'sdxl',
        'image generation',
        'image-generation',
      ],
    )) {
      traits.add(DiaryAiModelTrait.imageOutput);
    }
    if (_containsAny(
      haystack,
      const [
        'vision',
        'vl',
        'pixtral',
        'llava',
      ],
    )) {
      traits.add(DiaryAiModelTrait.imageInput);
    }
    if (_containsAny(
      haystack,
      const [
        'video',
      ],
    )) {
      traits.add(DiaryAiModelTrait.videoInput);
    }
    if (_containsAny(
      haystack,
      const [
        'gemini',
        'claude',
        'gpt-4o',
        'gpt-4.1',
        'omni',
        'multimodal',
        'qwen-vl',
      ],
    )) {
      traits.add(DiaryAiModelTrait.multimodal);
      traits.add(DiaryAiModelTrait.imageInput);
      traits.add(DiaryAiModelTrait.text);
    }

    final nonTextTraits = traits.where((trait) {
      return trait != DiaryAiModelTrait.text &&
          trait != DiaryAiModelTrait.reasoning &&
          trait != DiaryAiModelTrait.realtime &&
          trait != DiaryAiModelTrait.embedding &&
          trait != DiaryAiModelTrait.reranking &&
          trait != DiaryAiModelTrait.moderation;
    });
    if (nonTextTraits.isNotEmpty) {
      traits.add(DiaryAiModelTrait.multimodal);
    }

    if (traits.isEmpty) {
      traits.add(DiaryAiModelTrait.text);
    }

    return traits.toList(growable: false)
      ..sort((a, b) => a.index.compareTo(b.index));
  }

  bool _containsAny(String text, List<String> patterns) {
    for (final pattern in patterns) {
      if (text.contains(pattern)) {
        return true;
      }
    }
    return false;
  }

  String? _readString(Object? raw) {
    if (raw is! String) {
      return null;
    }
    final normalized = raw.trim();
    return normalized.isEmpty ? null : normalized;
  }

  List<String> _readStringList(Object? raw) {
    if (raw is! List) {
      return const [];
    }
    final values = <String>[];
    for (final item in raw) {
      final value = _readString(item);
      if (value != null) {
        values.add(value);
      }
    }
    return values;
  }
}
