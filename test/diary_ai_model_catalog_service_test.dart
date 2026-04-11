import 'dart:async';

import 'package:diary_mvp/features/diary/services/diary_ai_model_catalog_service.dart';
import 'package:diary_mvp/features/diary/services/diary_ai_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('DiaryAiModelCatalogService', () {
    test('uses OpenAI-compatible models endpoint and auth header', () async {
      final service = DiaryAiModelCatalogService(
        client: MockClient((request) async {
          expect(request.url.toString(), 'https://api.openai.com/v1/models');
          expect(request.headers['authorization'], 'Bearer openai-key');
          return http.Response(
            '{"data":[{"id":"gpt-4.1-mini"}]}',
            200,
          );
        }),
        environmentApiKey: '',
      );

      final result = await service.fetchModels(
        DiaryAiProviderConfig.forPreset(
          DiaryAiProviderPreset.openAi,
          apiKey: 'openai-key',
        ),
      );

      expect(result.status, DiaryAiModelCatalogStatus.success);
      expect(result.models.map((model) => model.id).toList(), ['gpt-4.1-mini']);
    });

    test('converts chat completions endpoint into models endpoint', () async {
      final service = DiaryAiModelCatalogService(
        client: MockClient((request) async {
          expect(request.url.toString(), 'https://example.com/v1/models');
          return http.Response(
            '{"data":[{"id":"model-a"}]}',
            200,
          );
        }),
        environmentApiKey: '',
      );

      final result = await service.fetchModels(
        const DiaryAiProviderConfig(
          presetId: 'custom',
          baseUrl: 'https://example.com/v1/chat/completions',
          model: '',
          apiKey: 'custom-key',
        ),
      );

      expect(result.status, DiaryAiModelCatalogStatus.success);
      expect(result.models.map((model) => model.id).toList(), ['model-a']);
    });

    test('adds Anthropic compatibility headers', () async {
      final service = DiaryAiModelCatalogService(
        client: MockClient((request) async {
          expect(request.url.toString(), 'https://api.anthropic.com/v1/models');
          expect(request.headers['authorization'], 'Bearer claude-key');
          expect(request.headers['x-api-key'], 'claude-key');
          expect(request.headers['anthropic-version'], '2023-06-01');
          return http.Response(
            '{"data":[{"id":"claude-sonnet-4-5"}]}',
            200,
          );
        }),
        environmentApiKey: '',
      );

      final result = await service.fetchModels(
        DiaryAiProviderConfig.forPreset(
          DiaryAiProviderPreset.anthropic,
          apiKey: 'claude-key',
        ),
      );

      expect(result.status, DiaryAiModelCatalogStatus.success);
      expect(
        result.models.map((model) => model.id).toList(),
        ['claude-sonnet-4-5'],
      );
    });

    test('uses environment API key fallback when local key is empty', () async {
      final service = DiaryAiModelCatalogService(
        client: MockClient((request) async {
          expect(request.headers['authorization'], 'Bearer env-key');
          return http.Response(
            '{"data":[{"id":"qwen-plus"}]}',
            200,
          );
        }),
        environmentApiKey: 'env-key',
      );

      final result = await service.fetchModels(
        DiaryAiProviderConfig.forPreset(DiaryAiProviderPreset.dashScope),
      );

      expect(result.status, DiaryAiModelCatalogStatus.success);
      expect(result.models.map((model) => model.id).toList(), ['qwen-plus']);
    });

    test('sorts and deduplicates returned model ids', () async {
      final service = DiaryAiModelCatalogService(
        client: MockClient((request) async {
          return http.Response(
            '''
            {
              "data": [
                {"id":"model-b"},
                {"id":"model-a"},
                {"id":"model-b"},
                {"id":"  model-c  "},
                {"name":"ignored"}
              ]
            }
            ''',
            200,
          );
        }),
        environmentApiKey: '',
      );

      final result = await service.fetchModels(
        DiaryAiProviderConfig.forPreset(
          DiaryAiProviderPreset.openRouter,
          apiKey: 'router-key',
        ),
      );

      expect(result.status, DiaryAiModelCatalogStatus.success);
      expect(
        result.models.map((model) => model.id).toList(),
        ['model-a', 'model-b', 'model-c'],
      );
    });

    test('parses model description and modality traits when available',
        () async {
      final service = DiaryAiModelCatalogService(
        client: MockClient((request) async {
          return http.Response(
            '''
            {
              "data": [
                {
                  "id": "vision-pro",
                  "name": "Vision Pro",
                  "description": "Fast multimodal assistant.",
                  "architecture": {
                    "input_modalities": ["text", "image"],
                    "output_modalities": ["text"]
                  }
                }
              ]
            }
            ''',
            200,
          );
        }),
        environmentApiKey: '',
      );

      final result = await service.fetchModels(
        DiaryAiProviderConfig.forPreset(
          DiaryAiProviderPreset.openRouter,
          apiKey: 'router-key',
        ),
      );

      expect(result.status, DiaryAiModelCatalogStatus.success);
      final model = result.models.single;
      expect(model.id, 'vision-pro');
      expect(model.name, 'Vision Pro');
      expect(model.description, 'Fast multimodal assistant.');
      expect(model.traits, contains(DiaryAiModelTrait.multimodal));
      expect(model.traits, contains(DiaryAiModelTrait.imageInput));
      expect(model.traits, contains(DiaryAiModelTrait.text));
      expect(
        model.displayGroups,
        [
          DiaryAiModelDisplayGroup.multimodal,
          DiaryAiModelDisplayGroup.text,
          DiaryAiModelDisplayGroup.image,
        ],
      );
    });

    test('maps one model into multiple display groups', () {
      const entry = DiaryAiModelCatalogEntry(
        id: 'vision-chat',
        traits: [
          DiaryAiModelTrait.multimodal,
          DiaryAiModelTrait.text,
          DiaryAiModelTrait.imageInput,
          DiaryAiModelTrait.reasoning,
        ],
      );

      expect(
        entry.displayGroups,
        [
          DiaryAiModelDisplayGroup.multimodal,
          DiaryAiModelDisplayGroup.text,
          DiaryAiModelDisplayGroup.image,
          DiaryAiModelDisplayGroup.reasoning,
        ],
      );
    });

    test('findById matches normalized ids and unique display names', () {
      const result = DiaryAiModelCatalogResult.success([
        DiaryAiModelCatalogEntry(
          id: 'minimax/minimax-m2.5',
          name: 'MiniMax/MiniMax-M2.5',
        ),
      ]);

      expect(
        result.findById('  MiniMax / MiniMax-M2.5  ')?.id,
        'minimax/minimax-m2.5',
      );
      expect(
        result.findById('MiniMax／MiniMax-M2.5')?.id,
        'minimax/minimax-m2.5',
      );
    });

    test('serializes and restores stored model catalog snapshots', () {
      final fetchedAt = DateTime(2026, 4, 10, 9, 45);
      final snapshot = DiaryAiStoredModelCatalog(
        configSignature: 'gemini|https://example.com/v1/|secret',
        fetchedAt: fetchedAt,
        models: const [
          DiaryAiModelCatalogEntry(
            id: 'gemini-2.5-flash',
            name: 'Gemini Flash',
            description: 'Fast multimodal model.',
            traits: [
              DiaryAiModelTrait.multimodal,
              DiaryAiModelTrait.text,
              DiaryAiModelTrait.imageInput,
            ],
          ),
        ],
      );

      final restored = DiaryAiStoredModelCatalog.fromJson(snapshot.toJson());

      expect(restored, isNotNull);
      expect(restored!.configSignature, snapshot.configSignature);
      expect(restored.fetchedAt, fetchedAt);
      expect(restored.models.single.id, 'gemini-2.5-flash');
      expect(restored.models.single.name, 'Gemini Flash');
      expect(
        restored.models.single.traits,
        [
          DiaryAiModelTrait.multimodal,
          DiaryAiModelTrait.text,
          DiaryAiModelTrait.imageInput,
        ],
      );
    });

    test('builds model catalog signature with fallback API key', () {
      const config = DiaryAiProviderConfig(
        presetId: 'gemini',
        baseUrl: 'https://example.com/v1/',
        model: 'gemini-2.5-flash',
      );

      expect(
        buildDiaryAiModelCatalogConfigSignature(
          config,
          fallbackApiKey: 'env-key',
        ),
        'gemini|https://example.com/v1/|env-key',
      );
    });

    test('groups embedding and reranking together', () {
      expect(
        resolveDiaryAiModelDisplayGroups(
          const [
            DiaryAiModelTrait.embedding,
            DiaryAiModelTrait.reranking,
          ],
        ),
        [DiaryAiModelDisplayGroup.vectorAndReranking],
      );
    });

    test('uses other group when no traits are available', () {
      expect(
        resolveDiaryAiModelDisplayGroups(const []),
        [DiaryAiModelDisplayGroup.other],
      );
    });

    test('returns apiKeyMissing without making a request', () async {
      var called = false;
      final service = DiaryAiModelCatalogService(
        client: MockClient((request) async {
          called = true;
          return http.Response('{"data":[]}', 200);
        }),
        environmentApiKey: '',
      );

      final result = await service.fetchModels(
        DiaryAiProviderConfig.forPreset(DiaryAiProviderPreset.openAi),
      );

      expect(result.status, DiaryAiModelCatalogStatus.apiKeyMissing);
      expect(called, isFalse);
    });

    test('returns invalidConfig when base url is empty', () async {
      final service = DiaryAiModelCatalogService(
        client: MockClient((request) async {
          return http.Response('{"data":[]}', 200);
        }),
        environmentApiKey: '',
      );

      final result = await service.fetchModels(
        const DiaryAiProviderConfig(
          presetId: 'custom',
          baseUrl: '',
          model: '',
          apiKey: 'custom-key',
        ),
      );

      expect(result.status, DiaryAiModelCatalogStatus.invalidConfig);
    });

    test('returns empty when response has no model ids', () async {
      final service = DiaryAiModelCatalogService(
        client: MockClient((request) async {
          return http.Response('{"data":[]}', 200);
        }),
        environmentApiKey: '',
      );

      final result = await service.fetchModels(
        DiaryAiProviderConfig.forPreset(
          DiaryAiProviderPreset.openAi,
          apiKey: 'openai-key',
        ),
      );

      expect(result.status, DiaryAiModelCatalogStatus.empty);
      expect(result.models, isEmpty);
    });

    test('returns requestFailed for HTTP errors', () async {
      final service = DiaryAiModelCatalogService(
        client: MockClient((request) async {
          return http.Response('{"error":"forbidden"}', 403);
        }),
        environmentApiKey: '',
      );

      final result = await service.fetchModels(
        DiaryAiProviderConfig.forPreset(
          DiaryAiProviderPreset.openAi,
          apiKey: 'bad-key',
        ),
      );

      expect(result.status, DiaryAiModelCatalogStatus.requestFailed);
      expect(result.statusCode, 403);
    });

    test('returns requestFailed for invalid JSON', () async {
      final service = DiaryAiModelCatalogService(
        client: MockClient((request) async {
          return http.Response('not json', 200);
        }),
        environmentApiKey: '',
      );

      final result = await service.fetchModels(
        DiaryAiProviderConfig.forPreset(
          DiaryAiProviderPreset.openAi,
          apiKey: 'openai-key',
        ),
      );

      expect(result.status, DiaryAiModelCatalogStatus.requestFailed);
      expect(result.error, isA<FormatException>());
    });

    test('returns requestFailed for timeout and client exceptions', () async {
      final timeoutService = DiaryAiModelCatalogService(
        client: MockClient((request) async {
          throw TimeoutException('slow');
        }),
        environmentApiKey: '',
      );
      final clientErrorService = DiaryAiModelCatalogService(
        client: MockClient((request) async {
          throw http.ClientException('offline');
        }),
        environmentApiKey: '',
      );

      final timeoutResult = await timeoutService.fetchModels(
        DiaryAiProviderConfig.forPreset(
          DiaryAiProviderPreset.openAi,
          apiKey: 'openai-key',
        ),
      );
      final clientErrorResult = await clientErrorService.fetchModels(
        DiaryAiProviderConfig.forPreset(
          DiaryAiProviderPreset.openAi,
          apiKey: 'openai-key',
        ),
      );

      expect(timeoutResult.status, DiaryAiModelCatalogStatus.requestFailed);
      expect(timeoutResult.error, isA<TimeoutException>());
      expect(
        clientErrorResult.status,
        DiaryAiModelCatalogStatus.requestFailed,
      );
      expect(clientErrorResult.error, isA<http.ClientException>());
    });
  });
}
