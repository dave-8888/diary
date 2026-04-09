import 'package:diary_mvp/features/diary/services/diary_ai_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DiaryAiProviderConfig', () {
    test('serializes and restores persisted model type', () {
      const config = DiaryAiProviderConfig(
        presetId: 'gemini',
        baseUrl: 'https://example.com/v1/',
        model: 'gemini-2.5-flash',
        modelType: 'multimodal',
        modelSource: DiaryAiModelSelectionSource.catalog,
        apiKey: 'secret-key',
      );

      expect(config.toJson(), {
        'ai_provider_preset': 'gemini',
        'ai_base_url': 'https://example.com/v1/',
        'ai_model': 'gemini-2.5-flash',
        'ai_model_type': 'multimodal',
        'ai_model_source': 'catalog',
        'ai_api_key': 'secret-key',
      });

      final restored = DiaryAiProviderConfig.fromJson(config.toJson());

      expect(restored.presetId, 'gemini');
      expect(restored.normalizedBaseUrl, 'https://example.com/v1/');
      expect(restored.normalizedModel, 'gemini-2.5-flash');
      expect(restored.normalizedModelType, 'multimodal');
      expect(
          restored.normalizedModelSource, DiaryAiModelSelectionSource.catalog);
      expect(restored.normalizedApiKey, 'secret-key');
    });
  });
}
