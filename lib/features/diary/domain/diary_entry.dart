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
  });

  final String id;
  final MediaType type;
  final String path;
  final String? durationLabel;

  DiaryMedia copyWith({
    String? id,
    MediaType? type,
    String? path,
    String? durationLabel,
  }) {
    return DiaryMedia(
      id: id ?? this.id,
      type: type ?? this.type,
      path: path ?? this.path,
      durationLabel: durationLabel ?? this.durationLabel,
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
    );
  }
}
