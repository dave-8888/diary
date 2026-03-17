import 'dart:async';
import 'dart:convert';

import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
import 'package:diary_mvp/features/diary/services/diary_ai_settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final diaryAiServiceProvider = Provider<DiaryAiService>((ref) {
  return DiaryAiService(ref);
});

enum DiaryAiFailure {
  apiKeyMissing,
  insufficientInput,
  requestFailed,
  invalidResponse,
}

class DiaryAiResult {
  const DiaryAiResult({
    required this.ok,
    this.suggestion,
    this.failure,
    this.statusCode,
  });

  final bool ok;
  final DiaryEntryAiAnalysis? suggestion;
  final DiaryAiFailure? failure;
  final int? statusCode;
}

class DiaryAiService {
  DiaryAiService(this._ref);

  static const String _apiUrl =
      'https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions';
  static const String _model = 'qwen-plus';

  final Ref _ref;

  Future<DiaryAiResult> analyzeEntry({
    required DiaryEntry draft,
    required bool preferChinese,
    required bool includeEmotionalCompanion,
    required bool includeProblemSuggestions,
  }) async {
    final apiKey = await _resolveApiKey();

    if (apiKey.isEmpty) {
      return const DiaryAiResult(
        ok: false,
        failure: DiaryAiFailure.apiKeyMissing,
      );
    }

    if (_isInputEmpty(draft)) {
      return const DiaryAiResult(
        ok: false,
        failure: DiaryAiFailure.insufficientInput,
      );
    }

    http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode(
              {
                'model': _model,
                'temperature': 0.2,
                'max_tokens': 700,
                'response_format': {
                  'type': 'json_object',
                },
                'messages': [
                  {
                    'role': 'system',
                    'content': _buildSystemPrompt(
                      preferChinese: preferChinese,
                      includeEmotionalCompanion: includeEmotionalCompanion,
                      includeProblemSuggestions: includeProblemSuggestions,
                    ),
                  },
                  {
                    'role': 'user',
                    'content': _buildUserPrompt(
                      draft: draft,
                    ),
                  },
                ],
              },
            ),
          )
          .timeout(const Duration(seconds: 45));
    } on TimeoutException {
      return const DiaryAiResult(
        ok: false,
        failure: DiaryAiFailure.requestFailed,
      );
    } on http.ClientException {
      return const DiaryAiResult(
        ok: false,
        failure: DiaryAiFailure.requestFailed,
      );
    }

    if (response.statusCode >= 400) {
      return DiaryAiResult(
        ok: false,
        failure: DiaryAiFailure.requestFailed,
        statusCode: response.statusCode,
      );
    }

    final suggestion = _parseSuggestion(response.body);
    if (suggestion == null || suggestion.isEmpty) {
      return const DiaryAiResult(
        ok: false,
        failure: DiaryAiFailure.invalidResponse,
      );
    }

    return DiaryAiResult(
      ok: true,
      suggestion: suggestion,
    );
  }

  Future<String> _resolveApiKey() async {
    final configuredApiKey =
        _ref.read(diaryAiApiKeyControllerProvider).valueOrNull;
    final inMemory = configuredApiKey?.trim();
    if (inMemory != null && inMemory.isNotEmpty) {
      return inMemory;
    }

    try {
      final persisted = await _ref.read(diaryAiSettingsStorageProvider).read();
      final normalized = persisted?.trim();
      if (normalized != null && normalized.isNotEmpty) {
        return normalized;
      }
    } catch (_) {
      // Fall through to the environment fallback below.
    }

    return diaryAiEnvironmentApiKey.trim();
  }

  bool _isInputEmpty(DiaryEntry draft) {
    return draft.title.trim().isEmpty &&
        draft.content.trim().isEmpty &&
        (draft.location?.trim().isEmpty ?? true) &&
        draft.tags.isEmpty;
  }

  String _buildSystemPrompt({
    required bool preferChinese,
    required bool includeEmotionalCompanion,
    required bool includeProblemSuggestions,
  }) {
    final toneInstruction = preferChinese
        ? 'Write the overview text and tags in Simplified Chinese unless the diary is clearly written in another language.'
        : 'Write the overview text and tags in the same language as the diary entry. Use English when the language is unclear.';

    final requiredKeys = [
      '"overview_text"',
      '"tags"',
      if (includeEmotionalCompanion) '"emotional_support_text"',
      if (includeProblemSuggestions) '"question_suggestion_text"',
    ].join(', ');

    return '''
You are a diary analysis assistant.
Return JSON only.
The JSON object must use exactly these keys: $requiredKeys.
"overview_text" must be a string.
"tags" must be an array of short strings.
${includeEmotionalCompanion ? '"emotional_support_text" must combine emotional companionship, comforting reply, response style, and priority support into one empathetic paragraph.' : ''}
${includeProblemSuggestions ? '"question_suggestion_text" must combine the core trouble and the brief analysis into one concise empathetic paragraph.' : ''}
Do not include markdown, code fences, or extra fields.
$toneInstruction
The first line of "overview_text" should be a concise natural title.
After the first line, add a short diary summary in 1-3 sentences.
Return 3-6 tags when possible, and avoid duplicates.
${includeEmotionalCompanion ? 'The emotional-support text should feel warm, emotionally aware, and gently supportive.' : ''}
${includeProblemSuggestions ? 'Keep the problem-suggestion text empathetic and concise. Avoid lecturing, blame, pressure, or moralizing.' : ''}
''';
  }

  String _buildUserPrompt({
    required DiaryEntry draft,
  }) {
    return jsonEncode(
      {
        'task': 'Analyze this diary entry and return JSON.',
        'entry': {
          'title': draft.title.trim(),
          'content': draft.content.trim(),
          'location': draft.location?.trim() ?? '',
          'tags': draft.tags,
        },
      },
    );
  }

  DiaryEntryAiAnalysis? _parseSuggestion(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is! Map<String, dynamic>) return null;

      final content = _extractMessageContent(decoded);
      if (content == null || content.trim().isEmpty) return null;

      final jsonString = _extractJsonString(content);
      if (jsonString == null) return null;

      final suggestionJson = jsonDecode(jsonString);
      if (suggestionJson is! Map<String, dynamic>) return null;

      final overviewText = _resolveOverviewText(suggestionJson);
      final tags = _readTags(suggestionJson['tags']);
      final emotionalSupportText = _resolveSectionText(
        primaryValue: suggestionJson['emotional_support_text'] ??
            suggestionJson['emotionalSupportText'],
        legacyValues: [
          suggestionJson['emotion_category'] ??
              suggestionJson['emotionCategory'],
          suggestionJson['companion_style'] ?? suggestionJson['companionStyle'],
          suggestionJson['comfort_reply'] ?? suggestionJson['comfortReply'],
          suggestionJson['priority_feedback'] ??
              suggestionJson['priorityFeedback'],
        ],
      );
      final questionSuggestionText = _resolveSectionText(
        primaryValue: suggestionJson['question_suggestion_text'] ??
            suggestionJson['questionSuggestionText'],
        legacyValues: [
          suggestionJson['distress_identification'] ??
              suggestionJson['distressIdentification'],
          suggestionJson['problem_analysis'] ??
              suggestionJson['problemAnalysis'],
        ],
      );

      return DiaryEntryAiAnalysis(
        overviewText: overviewText,
        suggestedTags: tags,
        emotionalSupportText:
            emotionalSupportText.isEmpty ? null : emotionalSupportText,
        questionSuggestionText:
            questionSuggestionText.isEmpty ? null : questionSuggestionText,
      );
    } on FormatException {
      return null;
    }
  }

  String? _extractMessageContent(Map<String, dynamic> decoded) {
    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty) return null;
    final firstChoice = choices.first;
    if (firstChoice is! Map<String, dynamic>) return null;
    final message = firstChoice['message'];
    if (message is! Map<String, dynamic>) return null;
    final content = message['content'];

    if (content is String) {
      return content;
    }

    if (content is List) {
      final buffer = StringBuffer();
      for (final item in content) {
        if (item is Map<String, dynamic>) {
          final text = item['text'];
          if (text is String) {
            buffer.write(text);
          }
        }
      }
      final merged = buffer.toString().trim();
      return merged.isEmpty ? null : merged;
    }

    return null;
  }

  String? _extractJsonString(String raw) {
    final trimmed = raw.trim();
    try {
      jsonDecode(trimmed);
      return trimmed;
    } on FormatException {
      final start = trimmed.indexOf('{');
      final end = trimmed.lastIndexOf('}');
      if (start < 0 || end <= start) return null;
      final candidate = trimmed.substring(start, end + 1);
      try {
        jsonDecode(candidate);
        return candidate;
      } on FormatException {
        return null;
      }
    }
  }

  String _readString(Object? value) {
    if (value is! String) return '';
    return value.trim();
  }

  List<String> _readTags(Object? value) {
    final tags = <String>[];
    final seen = <String>{};

    void addTag(String raw) {
      final trimmed = raw.trim().replaceFirst(RegExp(r'^#+'), '');
      if (trimmed.isEmpty) return;
      final key = trimmed.toLowerCase();
      if (seen.add(key)) {
        tags.add(trimmed);
      }
    }

    if (value is List) {
      for (final item in value) {
        if (item is String) {
          addTag(item);
        }
      }
    } else if (value is String) {
      for (final item in value.split(RegExp(r'[,\n/|]+'))) {
        addTag(item);
      }
    }

    return List.unmodifiable(tags.take(6));
  }

  String _resolveOverviewText(Map<String, dynamic> suggestionJson) {
    final direct = _readString(
      suggestionJson['overview_text'] ?? suggestionJson['overviewText'],
    );
    if (direct.isNotEmpty) {
      return direct;
    }

    final title = _readString(suggestionJson['title']);
    final summary = _readString(suggestionJson['summary']);
    if (title.isEmpty && summary.isEmpty) {
      return '';
    }
    if (title.isEmpty) return summary;
    if (summary.isEmpty) return title;
    return '$title\n$summary';
  }

  String _resolveSectionText({
    required Object? primaryValue,
    required List<Object?> legacyValues,
  }) {
    final primary = _readString(primaryValue);
    if (primary.isNotEmpty) {
      return primary;
    }

    final parts = legacyValues
        .map(_readString)
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    return parts.join('\n\n');
  }
}
