class DiaryMood {
  const DiaryMood({
    required this.id,
    required this.emoji,
    this.label = '',
    this.isDefault = false,
    this.sortOrder = 0,
  });

  const DiaryMood._default({
    required this.id,
    required this.emoji,
    required this.sortOrder,
  })  : label = '',
        isDefault = true;

  static const String happyId = 'happy';
  static const String calmId = 'calm';
  static const String neutralId = 'neutral';
  static const String sadId = 'sad';
  static const String angryId = 'angry';
  static const String defaultSelectionId = calmId;

  static const DiaryMood happy = DiaryMood._default(
    id: happyId,
    emoji: '😄',
    sortOrder: 0,
  );
  static const DiaryMood calm = DiaryMood._default(
    id: calmId,
    emoji: '😌',
    sortOrder: 1,
  );
  static const DiaryMood neutral = DiaryMood._default(
    id: neutralId,
    emoji: '🙂',
    sortOrder: 2,
  );
  static const DiaryMood sad = DiaryMood._default(
    id: sadId,
    emoji: '😔',
    sortOrder: 3,
  );
  static const DiaryMood angry = DiaryMood._default(
    id: angryId,
    emoji: '😤',
    sortOrder: 4,
  );

  static const List<DiaryMood> values = [
    happy,
    calm,
    neutral,
    sad,
    angry,
  ];

  final String id;
  final String emoji;
  final String label;
  final bool isDefault;
  final int sortOrder;

  String get name => id;
  bool get hasCustomLabel => label.trim().isNotEmpty;

  DiaryMood copyWith({
    String? id,
    String? emoji,
    String? label,
    bool? isDefault,
    int? sortOrder,
  }) {
    return DiaryMood(
      id: id ?? this.id,
      emoji: emoji ?? this.emoji,
      label: label ?? this.label,
      isDefault: isDefault ?? this.isDefault,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  static DiaryMood fallback([String? rawId]) {
    return byId(rawId) ?? neutral;
  }

  static DiaryMood? byId(String? rawId) {
    for (final mood in values) {
      if (mood.id == rawId) return mood;
    }
    return null;
  }

  static bool isDefaultId(String rawId) {
    return values.any((mood) => mood.id == rawId);
  }
}

enum MediaType { image, audio, video }

class DiaryMedia {
  const DiaryMedia({
    required this.id,
    required this.type,
    required this.path,
    this.durationLabel,
    this.capturedAt,
  });

  final String id;
  final MediaType type;
  final String path;
  final String? durationLabel;
  final DateTime? capturedAt;

  DiaryMedia copyWith({
    String? id,
    MediaType? type,
    String? path,
    String? durationLabel,
    DateTime? capturedAt,
  }) {
    return DiaryMedia(
      id: id ?? this.id,
      type: type ?? this.type,
      path: path ?? this.path,
      durationLabel: durationLabel ?? this.durationLabel,
      capturedAt: capturedAt ?? this.capturedAt,
    );
  }
}

class DiaryEntryAiAnalysis {
  const DiaryEntryAiAnalysis({
    required this.overviewText,
    this.suggestedTags = const [],
    this.emotionalSupportText,
    this.questionSuggestionText,
  });

  final String overviewText;
  final List<String> suggestedTags;
  final String? emotionalSupportText;
  final String? questionSuggestionText;

  bool get isEmpty =>
      overviewText.trim().isEmpty &&
      suggestedTags.isEmpty &&
      (emotionalSupportText?.trim().isEmpty ?? true) &&
      (questionSuggestionText?.trim().isEmpty ?? true);

  DiaryEntryAiAnalysis copyWith({
    String? overviewText,
    List<String>? suggestedTags,
    String? emotionalSupportText,
    String? questionSuggestionText,
  }) {
    return DiaryEntryAiAnalysis(
      overviewText: overviewText ?? this.overviewText,
      suggestedTags: suggestedTags ?? this.suggestedTags,
      emotionalSupportText: emotionalSupportText ?? this.emotionalSupportText,
      questionSuggestionText:
          questionSuggestionText ?? this.questionSuggestionText,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'overview_text': overviewText,
      'suggested_tags': suggestedTags,
      'emotional_support_text': emotionalSupportText,
      'question_suggestion_text': questionSuggestionText,
    };
  }

  factory DiaryEntryAiAnalysis.fromJson(Map<String, dynamic> json) {
    final rawTags = json['suggested_tags'] ?? json['tags'];
    final tags = <String>[];
    final seen = <String>{};

    void addTag(String raw) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return;
      final key = trimmed.toLowerCase();
      if (seen.add(key)) {
        tags.add(trimmed);
      }
    }

    if (rawTags is List) {
      for (final item in rawTags) {
        if (item is String) {
          addTag(item);
        }
      }
    } else if (rawTags is String) {
      for (final item in rawTags.split(RegExp(r'[,\n/|]+'))) {
        addTag(item);
      }
    }

    final overviewText =
        (json['overview_text'] ?? json['overviewText'] ?? '').toString().trim();
    final emotionalSupportText =
        (json['emotional_support_text'] ?? json['emotionalSupportText'])
            ?.toString()
            .trim();
    final questionSuggestionText =
        (json['question_suggestion_text'] ?? json['questionSuggestionText'])
            ?.toString()
            .trim();

    return DiaryEntryAiAnalysis(
      overviewText: overviewText,
      suggestedTags: List<String>.unmodifiable(tags),
      emotionalSupportText:
          emotionalSupportText?.isEmpty == true ? null : emotionalSupportText,
      questionSuggestionText: questionSuggestionText?.isEmpty == true
          ? null
          : questionSuggestionText,
    );
  }
}

class DiaryEntry {
  static const Object _unset = Object();

  const DiaryEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.mood,
    required this.createdAt,
    this.location,
    this.trashedAt,
    this.tags = const [],
    this.media = const [],
    this.aiAnalysis,
  });

  final String id;
  final String title;
  final String content;
  final DiaryMood mood;
  final DateTime createdAt;
  final String? location;
  final DateTime? trashedAt;
  final List<String> tags;
  final List<DiaryMedia> media;
  final DiaryEntryAiAnalysis? aiAnalysis;

  DiaryEntry copyWith({
    String? id,
    String? title,
    String? content,
    DiaryMood? mood,
    DateTime? createdAt,
    Object? location = _unset,
    Object? trashedAt = _unset,
    List<String>? tags,
    List<DiaryMedia>? media,
    Object? aiAnalysis = _unset,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      mood: mood ?? this.mood,
      createdAt: createdAt ?? this.createdAt,
      location:
          identical(location, _unset) ? this.location : location as String?,
      trashedAt: identical(trashedAt, _unset)
          ? this.trashedAt
          : trashedAt as DateTime?,
      tags: tags ?? this.tags,
      media: media ?? this.media,
      aiAnalysis: identical(aiAnalysis, _unset)
          ? this.aiAnalysis
          : aiAnalysis as DiaryEntryAiAnalysis?,
    );
  }
}
