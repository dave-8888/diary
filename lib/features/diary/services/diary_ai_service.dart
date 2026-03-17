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

class DiaryAiSuggestion {
  const DiaryAiSuggestion({
    required this.summary,
    required this.title,
    required this.moodId,
    required this.tags,
    required this.emotionCategory,
    required this.comfortReply,
    required this.companionStyle,
    required this.priorityFeedback,
    required this.distressIdentification,
    required this.problemAnalysis,
    required this.suggestionOutput,
  });

  final String summary;
  final String title;
  final String moodId;
  final List<String> tags;
  final String emotionCategory;
  final String comfortReply;
  final String companionStyle;
  final String priorityFeedback;
  final String distressIdentification;
  final String problemAnalysis;
  final String suggestionOutput;

  bool get isEmpty =>
      summary.trim().isEmpty &&
      title.trim().isEmpty &&
      tags.isEmpty &&
      moodId.trim().isEmpty &&
      emotionCategory.trim().isEmpty &&
      comfortReply.trim().isEmpty &&
      companionStyle.trim().isEmpty &&
      priorityFeedback.trim().isEmpty &&
      distressIdentification.trim().isEmpty &&
      problemAnalysis.trim().isEmpty &&
      suggestionOutput.trim().isEmpty;
}

class DiaryAiResult {
  const DiaryAiResult({
    required this.ok,
    this.suggestion,
    this.failure,
    this.statusCode,
  });

  final bool ok;
  final DiaryAiSuggestion? suggestion;
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
    required List<DiaryMood> availableMoods,
    required bool preferChinese,
    required bool includeEmotionalCompanion,
    required bool includeProblemSuggestions,
  }) async {
    final configuredApiKey =
        _ref.read(diaryAiApiKeyControllerProvider).valueOrNull;
    final apiKey = (configuredApiKey?.trim().isNotEmpty == true)
        ? configuredApiKey!.trim()
        : diaryAiEnvironmentApiKey;

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
                      availableMoods: availableMoods,
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

    final suggestion = _parseSuggestion(
      response.body,
      availableMoods: availableMoods,
    );
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

  bool _isInputEmpty(DiaryEntry draft) {
    return draft.title.trim().isEmpty &&
        draft.content.trim().isEmpty &&
        (draft.location?.trim().isEmpty ?? true) &&
        draft.tags.isEmpty;
  }

  String _buildSystemPrompt({
    required List<DiaryMood> availableMoods,
    required bool preferChinese,
    required bool includeEmotionalCompanion,
    required bool includeProblemSuggestions,
  }) {
    final toneInstruction = preferChinese
        ? 'Write title, summary, and tags in Simplified Chinese unless the diary is clearly written in another language.'
        : 'Write title, summary, and tags in the same language as the diary entry. Use English when the language is unclear.';

    final moodGuide = availableMoods
        .map(
          (mood) => '- ${mood.id}: ${_describeMood(mood)}',
        )
        .join('\n');

    final requiredKeys = [
      '"title"',
      '"summary"',
      '"mood_id"',
      '"tags"',
      if (includeEmotionalCompanion) ...[
        '"emotion_category"',
        '"comfort_reply"',
        '"companion_style"',
        '"priority_feedback"',
      ],
      if (includeProblemSuggestions) ...[
        '"distress_identification"',
        '"problem_analysis"',
        '"suggestion_output"',
      ],
    ].join(', ');

    return '''
You are a diary analysis assistant.
Return JSON only.
The JSON object must use exactly these keys: $requiredKeys.
"title" must be a string.
"summary" must be a string.
"mood_id" must be one of the allowed mood ids.
"tags" must be an array of short strings.
${includeEmotionalCompanion ? '"emotion_category" must be a short emotion classification phrase.' : ''}
${includeEmotionalCompanion ? '"comfort_reply" must be a warm and helpful reply tailored to the diary tone.' : ''}
${includeEmotionalCompanion ? '"companion_style" must be a short label describing the response style.' : ''}
${includeEmotionalCompanion ? '"priority_feedback" must be extra supportive feedback for important emotions. Use an empty string if not needed.' : ''}
${includeProblemSuggestions ? '"distress_identification" must identify the core trouble or pressure point in one short sentence.' : ''}
${includeProblemSuggestions ? '"problem_analysis" must explain the likely cause or conflict clearly and briefly.' : ''}
${includeProblemSuggestions ? '"suggestion_output" must provide practical, gentle, non-preachy suggestions.' : ''}
Do not include markdown, code fences, or extra fields.
$toneInstruction
Keep the title concise and natural.
Keep the summary to 1-3 sentences.
Return 3-6 tags when possible, and avoid duplicates.
${includeEmotionalCompanion ? 'The comforting reply should feel emotionally aware, and the style should adapt to the user tone.' : ''}
${includeProblemSuggestions ? 'The suggestions must avoid lecturing, blame, pressure, or moralizing. Focus on empathy, clarity, and practical next steps.' : ''}
Allowed mood ids:
$moodGuide
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

  DiaryAiSuggestion? _parseSuggestion(
    String responseBody, {
    required List<DiaryMood> availableMoods,
  }) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is! Map<String, dynamic>) return null;

      final content = _extractMessageContent(decoded);
      if (content == null || content.trim().isEmpty) return null;

      final jsonString = _extractJsonString(content);
      if (jsonString == null) return null;

      final suggestionJson = jsonDecode(jsonString);
      if (suggestionJson is! Map<String, dynamic>) return null;

      final summary = _readString(suggestionJson['summary']);
      final title = _readString(suggestionJson['title']);
      final moodId = _resolveMoodId(
        suggestionJson['mood_id'] ?? suggestionJson['mood'],
        availableMoods,
      );
      final tags = _readTags(suggestionJson['tags']);
      final emotionCategory = _readString(
        suggestionJson['emotion_category'] ?? suggestionJson['emotionCategory'],
      );
      final comfortReply = _readString(
        suggestionJson['comfort_reply'] ?? suggestionJson['comfortReply'],
      );
      final companionStyle = _readString(
        suggestionJson['companion_style'] ?? suggestionJson['companionStyle'],
      );
      final priorityFeedback = _readString(
        suggestionJson['priority_feedback'] ??
            suggestionJson['priorityFeedback'],
      );
      final distressIdentification = _readString(
        suggestionJson['distress_identification'] ??
            suggestionJson['distressIdentification'],
      );
      final problemAnalysis = _readString(
        suggestionJson['problem_analysis'] ?? suggestionJson['problemAnalysis'],
      );
      final suggestionOutput = _readString(
        suggestionJson['suggestion_output'] ??
            suggestionJson['suggestionOutput'],
      );

      return DiaryAiSuggestion(
        summary: summary,
        title: title,
        moodId: moodId,
        tags: tags,
        emotionCategory: emotionCategory,
        comfortReply: comfortReply,
        companionStyle: companionStyle,
        priorityFeedback: priorityFeedback,
        distressIdentification: distressIdentification,
        problemAnalysis: problemAnalysis,
        suggestionOutput: suggestionOutput,
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

  String _resolveMoodId(Object? rawMood, List<DiaryMood> availableMoods) {
    if (rawMood == null) return DiaryMood.neutralId;

    final normalized = switch (rawMood) {
      String value => value.trim().toLowerCase(),
      Map<String, dynamic> value => _readString(value['id']).toLowerCase(),
      _ => rawMood.toString().trim().toLowerCase(),
    };

    for (final mood in availableMoods) {
      if (mood.id.toLowerCase() == normalized) {
        return mood.id;
      }
    }

    for (final mood in availableMoods) {
      final aliases = <String>{
        mood.label.trim().toLowerCase(),
        ..._moodAliases(mood.id),
      }..removeWhere((item) => item.trim().isEmpty);
      if (aliases.contains(normalized)) {
        return mood.id;
      }
    }

    return DiaryMood.neutralId;
  }

  String _describeMood(DiaryMood mood) {
    final customLabel = mood.label.trim();
    if (customLabel.isNotEmpty) {
      return customLabel;
    }

    switch (mood.id) {
      case DiaryMood.happyId:
        return 'happy / joyful / positive';
      case DiaryMood.calmId:
        return 'calm / peaceful / steady';
      case DiaryMood.neutralId:
        return 'neutral / ordinary / mixed';
      case DiaryMood.sadId:
        return 'sad / low / disappointed';
      case DiaryMood.angryId:
        return 'angry / frustrated / upset';
      default:
        return mood.id;
    }
  }

  Set<String> _moodAliases(String moodId) {
    switch (moodId) {
      case DiaryMood.happyId:
        return const {'happy', 'joyful', 'positive', 'kaixin', 'happy mood'};
      case DiaryMood.calmId:
        return const {'calm', 'peaceful', 'steady', 'relaxed'};
      case DiaryMood.neutralId:
        return const {'neutral', 'ordinary', 'mixed', 'normal'};
      case DiaryMood.sadId:
        return const {'sad', 'down', 'low', 'disappointed'};
      case DiaryMood.angryId:
        return const {'angry', 'mad', 'frustrated', 'upset'};
      default:
        return {moodId.toLowerCase()};
    }
  }
}
