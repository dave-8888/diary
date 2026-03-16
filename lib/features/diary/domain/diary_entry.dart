enum DiaryMood {
  happy('Happy', '😄'),
  calm('Calm', '😌'),
  neutral('Neutral', '🙂'),
  sad('Sad', '😔'),
  angry('Angry', '😤');

  const DiaryMood(this.label, this.emoji);

  final String label;
  final String emoji;
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
