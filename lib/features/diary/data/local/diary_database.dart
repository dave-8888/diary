import 'dart:convert';
import 'dart:io';

import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final diaryDatabaseProvider = Provider<DiaryDatabase>((ref) {
  final database = DiaryDatabase();
  ref.onDispose(database.close);
  return database;
});

class DiaryDatabase extends GeneratedDatabase {
  DiaryDatabase() : super(_openExecutor());

  bool _initialized = false;

  @override
  int get schemaVersion => 7;

  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (_) => _ensureInitialized(),
        onUpgrade: (_, __, ___) => _ensureInitialized(),
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON;');
        },
      );

  static QueryExecutor _openExecutor() {
    return LazyDatabase(() async {
      final documents = await getApplicationDocumentsDirectory();
      final dbDir = Directory(p.join(documents.path, 'diary_mvp', 'db'));
      await dbDir.create(recursive: true);
      final dbFile = File(p.join(dbDir.path, 'diary.db'));
      return NativeDatabase.createInBackground(dbFile);
    });
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await customStatement('PRAGMA foreign_keys = ON;');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS diary_entries (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        mood TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        location TEXT,
        trashed_at INTEGER,
        tags_json TEXT NOT NULL,
        ai_analysis_json TEXT
      );
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS diary_media (
        id TEXT PRIMARY KEY,
        diary_id TEXT NOT NULL,
        type TEXT NOT NULL,
        path TEXT NOT NULL,
        duration_label TEXT,
        captured_at INTEGER,
        added_at INTEGER,
        location TEXT,
        origin TEXT NOT NULL DEFAULT 'unknown',
        FOREIGN KEY (diary_id) REFERENCES diary_entries (id) ON DELETE CASCADE
      );
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS diary_tags (
        name TEXT PRIMARY KEY COLLATE NOCASE,
        created_at INTEGER NOT NULL
      );
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS mood_library (
        id TEXT PRIMARY KEY,
        label TEXT NOT NULL,
        emoji TEXT NOT NULL,
        sort_order INTEGER NOT NULL,
        is_default INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      );
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_diary_entries_created_at
      ON diary_entries (created_at DESC);
    ''');
    await _ensureDiaryEntriesColumns();
    await _ensureDiaryMediaColumns();
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_diary_entries_trashed_at
      ON diary_entries (trashed_at DESC);
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_diary_media_diary_id
      ON diary_media (diary_id);
    ''');
    await _ensureTagLibrarySeeded();
    await _ensureMoodLibrarySeeded();
    _initialized = true;
  }

  Future<List<DiaryEntry>> listEntries() async {
    return _listEntries(trashed: false);
  }

  Future<List<DiaryEntry>> listTrashedEntries() async {
    return _listEntries(trashed: true);
  }

  Future<List<DiaryEntry>> _listEntries({
    required bool trashed,
  }) async {
    await _ensureInitialized();
    final moodLibrary = {
      for (final mood in await listMoodLibrary()) mood.id: mood,
    };
    final rows = await customSelect(
      '''
      SELECT
        id,
        title,
        content,
        mood,
        created_at,
        location,
        trashed_at,
        COALESCE(tags_json, '[]') AS tags_json,
        ai_analysis_json
      FROM diary_entries
      WHERE trashed_at ${trashed ? 'IS NOT NULL' : 'IS NULL'}
      ORDER BY ${trashed ? 'trashed_at DESC,' : ''} created_at DESC;
      ''',
    ).get();

    final entries = <DiaryEntry>[];
    for (final row in rows) {
      final id = row.read<String>('id');
      final mediaRows = await customSelect(
        '''
        SELECT id, type, path, duration_label, captured_at, added_at, location, origin
        FROM diary_media
        WHERE diary_id = ?
        ORDER BY rowid ASC;
        ''',
        variables: [Variable.withString(id)],
      ).get();

      entries.add(
        DiaryEntry(
          id: id,
          title: row.read<String>('title'),
          content: row.read<String>('content'),
          mood: _moodFromDb(row.read<String>('mood'), moodLibrary),
          createdAt:
              DateTime.fromMillisecondsSinceEpoch(row.read<int>('created_at')),
          location: row.readNullable<String>('location'),
          trashedAt: _trashedAtFromDb(row.readNullable<int>('trashed_at')),
          tags: _decodeTags(row.read<String>('tags_json')),
          aiAnalysis:
              _decodeAiAnalysis(row.readNullable<String>('ai_analysis_json')),
          media: mediaRows.map(_mapMediaRow).toList(growable: false),
        ),
      );
    }

    return entries;
  }

  Future<void> insertEntry(DiaryEntry entry) async {
    await _ensureInitialized();
    await transaction(() async {
      await customStatement(
        '''
        INSERT INTO diary_entries (id, title, content, mood, created_at, location, trashed_at, tags_json, ai_analysis_json)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
        ''',
        [
          entry.id,
          entry.title,
          entry.content,
          entry.mood.id,
          entry.createdAt.millisecondsSinceEpoch,
          entry.location,
          entry.trashedAt?.millisecondsSinceEpoch,
          jsonEncode(entry.tags),
          entry.aiAnalysis == null
              ? null
              : jsonEncode(entry.aiAnalysis!.toJson()),
        ],
      );

      for (final media in entry.media) {
        await customStatement(
          '''
          INSERT INTO diary_media (id, diary_id, type, path, duration_label, captured_at, added_at, location, origin)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
          ''',
          [
            media.id,
            entry.id,
            media.type.name,
            media.path,
            media.durationLabel,
            media.capturedAt?.millisecondsSinceEpoch,
            media.addedAt?.millisecondsSinceEpoch,
            media.location,
            media.origin.name,
          ],
        );
      }
    });
  }

  Future<void> updateEntry(DiaryEntry entry) async {
    await _ensureInitialized();
    await transaction(() async {
      await customStatement(
        '''
        UPDATE diary_entries
        SET title = ?, content = ?, mood = ?, created_at = ?, location = ?, trashed_at = ?, tags_json = ?, ai_analysis_json = ?
        WHERE id = ?;
        ''',
        [
          entry.title,
          entry.content,
          entry.mood.id,
          entry.createdAt.millisecondsSinceEpoch,
          entry.location,
          entry.trashedAt?.millisecondsSinceEpoch,
          jsonEncode(entry.tags),
          entry.aiAnalysis == null
              ? null
              : jsonEncode(entry.aiAnalysis!.toJson()),
          entry.id,
        ],
      );

      await customStatement(
        '''
        DELETE FROM diary_media
        WHERE diary_id = ?;
        ''',
        [entry.id],
      );

      for (final media in entry.media) {
        await customStatement(
          '''
          INSERT INTO diary_media (id, diary_id, type, path, duration_label, captured_at, added_at, location, origin)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
          ''',
          [
            media.id,
            entry.id,
            media.type.name,
            media.path,
            media.durationLabel,
            media.capturedAt?.millisecondsSinceEpoch,
            media.addedAt?.millisecondsSinceEpoch,
            media.location,
            media.origin.name,
          ],
        );
      }
    });
  }

  Future<List<String>> listTagLibrary() async {
    await _ensureInitialized();
    final rows = await customSelect(
      '''
      SELECT name
      FROM diary_tags
      ORDER BY created_at DESC, name COLLATE NOCASE ASC;
      ''',
    ).get();

    return rows.map((row) => row.read<String>('name')).toList(growable: false);
  }

  Future<List<DiaryMood>> listMoodLibrary() async {
    await _ensureInitialized();
    final rows = await customSelect(
      '''
      SELECT id, label, emoji, sort_order, is_default
      FROM mood_library
      ORDER BY sort_order ASC, updated_at ASC, id COLLATE NOCASE ASC;
      ''',
    ).get();

    return rows.map(_mapMoodRow).toList(growable: false);
  }

  Future<void> saveMood(DiaryMood mood) async {
    await _ensureInitialized();
    final normalized = _normalizeMood(mood);
    final updatedAt = DateTime.now().millisecondsSinceEpoch;

    await customStatement(
      '''
      INSERT INTO mood_library (id, label, emoji, sort_order, is_default, updated_at)
      VALUES (?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        label = excluded.label,
        emoji = excluded.emoji,
        sort_order = excluded.sort_order,
        is_default = excluded.is_default,
        updated_at = excluded.updated_at;
      ''',
      [
        normalized.id,
        normalized.label,
        normalized.emoji,
        normalized.sortOrder,
        normalized.isDefault ? 1 : 0,
        updatedAt,
      ],
    );
  }

  Future<void> replaceMoodLibrary(Iterable<DiaryMood> moods) async {
    await _ensureInitialized();
    final normalized = moods.isEmpty
        ? DiaryMood.values
        : moods.map(_normalizeMood).toList(growable: false);
    final allowedIds = normalized.map((mood) => "'${mood.id}'").join(', ');
    final updatedAt = DateTime.now().millisecondsSinceEpoch;

    await transaction(() async {
      await customStatement('DELETE FROM mood_library;');
      for (final mood in normalized) {
        await customStatement(
          '''
          INSERT INTO mood_library (id, label, emoji, sort_order, is_default, updated_at)
          VALUES (?, ?, ?, ?, ?, ?);
          ''',
          [
            mood.id,
            mood.label,
            mood.emoji,
            mood.sortOrder,
            mood.isDefault ? 1 : 0,
            updatedAt,
          ],
        );
      }
      await customStatement(
        '''
        UPDATE diary_entries
        SET mood = '${DiaryMood.neutralId}'
        WHERE mood NOT IN ($allowedIds);
        ''',
      );
    });
  }

  Future<void> resetMoodLibraryToDefaults() async {
    await replaceMoodLibrary(DiaryMood.values);
  }

  Future<void> upsertTagLibrary(Iterable<String> tags) async {
    await _ensureInitialized();
    final normalized = _normalizeTags(tags);
    if (normalized.isEmpty) return;

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await transaction(() async {
      for (final tag in normalized) {
        await customStatement(
          '''
          INSERT OR IGNORE INTO diary_tags (name, created_at)
          VALUES (?, ?);
          ''',
          [tag, timestamp],
        );
      }
    });
  }

  Future<void> deleteTagFromLibrary(String tag) async {
    await _ensureInitialized();
    final normalizedTag = _normalizeTag(tag);
    if (normalizedTag == null) return;

    final rows = await customSelect(
      '''
      SELECT id, COALESCE(tags_json, '[]') AS tags_json
      FROM diary_entries;
      ''',
    ).get();

    await transaction(() async {
      await customStatement(
        '''
        DELETE FROM diary_tags
        WHERE name = ?;
        ''',
        [normalizedTag],
      );

      for (final row in rows) {
        final tags = _decodeTags(row.read<String>('tags_json'))
            .where(
              (item) => item.toLowerCase() != normalizedTag.toLowerCase(),
            )
            .toList(growable: false);

        await customStatement(
          '''
          UPDATE diary_entries
          SET tags_json = ?
          WHERE id = ?;
          ''',
          [
            jsonEncode(tags),
            row.read<String>('id'),
          ],
        );
      }
    });
  }

  Future<void> deleteEntry(String id) async {
    await _ensureInitialized();
    await customStatement(
      '''
      DELETE FROM diary_entries
      WHERE id = ?;
      ''',
      [id],
    );
  }

  Future<void> _ensureDiaryEntriesColumns() async {
    final rows = await customSelect('PRAGMA table_info(diary_entries);').get();
    final columns = rows.map((row) => row.read<String>('name')).toSet();
    if (!columns.contains('trashed_at')) {
      await customStatement(
        'ALTER TABLE diary_entries ADD COLUMN trashed_at INTEGER;',
      );
    }
    if (!columns.contains('tags_json')) {
      await customStatement(
        "ALTER TABLE diary_entries ADD COLUMN tags_json TEXT;",
      );
    }
    if (!columns.contains('ai_analysis_json')) {
      await customStatement(
        'ALTER TABLE diary_entries ADD COLUMN ai_analysis_json TEXT;',
      );
    }
    await customStatement(
      "UPDATE diary_entries SET tags_json = '[]' WHERE tags_json IS NULL OR TRIM(tags_json) = '';",
    );
  }

  Future<void> _ensureDiaryMediaColumns() async {
    final rows = await customSelect('PRAGMA table_info(diary_media);').get();
    final columns = rows.map((row) => row.read<String>('name')).toSet();
    if (!columns.contains('duration_label')) {
      await customStatement(
        'ALTER TABLE diary_media ADD COLUMN duration_label TEXT;',
      );
    }
    if (!columns.contains('captured_at')) {
      await customStatement(
        'ALTER TABLE diary_media ADD COLUMN captured_at INTEGER;',
      );
    }
    if (!columns.contains('added_at')) {
      await customStatement(
        'ALTER TABLE diary_media ADD COLUMN added_at INTEGER;',
      );
    }
    if (!columns.contains('location')) {
      await customStatement(
        'ALTER TABLE diary_media ADD COLUMN location TEXT;',
      );
    }
    if (!columns.contains('origin')) {
      await customStatement(
        "ALTER TABLE diary_media ADD COLUMN origin TEXT NOT NULL DEFAULT 'unknown';",
      );
    }
  }

  Future<void> _ensureTagLibrarySeeded() async {
    final countRow = await customSelect(
      '''
      SELECT COUNT(*) AS count
      FROM diary_tags;
      ''',
    ).getSingle();
    if (countRow.read<int>('count') > 0) {
      return;
    }

    final entryRows = await customSelect(
      '''
      SELECT COALESCE(tags_json, '[]') AS tags_json
      FROM diary_entries;
      ''',
    ).get();

    final tags = <String>[];
    for (final row in entryRows) {
      tags.addAll(_decodeTags(row.read<String>('tags_json')));
    }

    final normalized = _normalizeTags(tags);
    if (normalized.isEmpty) return;

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    for (final tag in normalized) {
      await customStatement(
        '''
        INSERT OR IGNORE INTO diary_tags (name, created_at)
        VALUES (?, ?);
        ''',
        [tag, timestamp],
      );
    }
  }

  Future<void> _ensureMoodLibrarySeeded() async {
    final countRow = await customSelect(
      '''
      SELECT COUNT(*) AS count
      FROM mood_library;
      ''',
    ).getSingle();
    if (countRow.read<int>('count') > 0) {
      return;
    }

    final updatedAt = DateTime.now().millisecondsSinceEpoch;
    for (final mood in DiaryMood.values) {
      await customStatement(
        '''
        INSERT OR IGNORE INTO mood_library (id, label, emoji, sort_order, is_default, updated_at)
        VALUES (?, ?, ?, ?, ?, ?);
        ''',
        [
          mood.id,
          mood.label,
          mood.emoji,
          mood.sortOrder,
          1,
          updatedAt,
        ],
      );
    }
  }

  DiaryMood _mapMoodRow(QueryRow row) {
    return DiaryMood(
      id: row.read<String>('id'),
      label: row.read<String>('label'),
      emoji: row.read<String>('emoji'),
      sortOrder: row.read<int>('sort_order'),
      isDefault: row.read<int>('is_default') == 1,
    );
  }

  DiaryMedia _mapMediaRow(QueryRow row) {
    final type = _mediaTypeFromDb(row.read<String>('type'));
    final path = row.read<String>('path');
    final capturedAt = _mediaCapturedAtFromDb(
      row.readNullable<int>('captured_at'),
      type: type,
      path: path,
    );
    final addedAt = _mediaAddedAtFromDb(
      row.readNullable<int>('added_at'),
    );
    return DiaryMedia(
      id: row.read<String>('id'),
      type: type,
      path: path,
      durationLabel: row.readNullable<String>('duration_label'),
      capturedAt: capturedAt,
      addedAt: addedAt,
      location: row.readNullable<String>('location'),
      origin: _mediaOriginFromDb(
        row.readNullable<String>('origin'),
        type: type,
        capturedAt: capturedAt,
      ),
    );
  }

  List<String> _decodeTags(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! List) return const [];
      return decoded.whereType<String>().toList(growable: false);
    } on FormatException {
      return const [];
    }
  }

  DiaryEntryAiAnalysis? _decodeAiAnalysis(String? rawJson) {
    final normalized = rawJson?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(normalized);
      if (decoded is! Map<String, dynamic>) return null;
      final analysis = DiaryEntryAiAnalysis.fromJson(decoded);
      return analysis.isEmpty ? null : analysis;
    } on FormatException {
      return null;
    }
  }

  DiaryMood _moodFromDb(String raw, Map<String, DiaryMood> moodLibrary) {
    return moodLibrary[raw] ??
        DiaryMood.byId(raw) ??
        moodLibrary[DiaryMood.neutralId] ??
        DiaryMood.neutral;
  }

  MediaType _mediaTypeFromDb(String raw) {
    return MediaType.values.firstWhere(
      (type) => type.name == raw,
      orElse: () => MediaType.image,
    );
  }

  DateTime? _mediaCapturedAtFromDb(
    int? rawMilliseconds, {
    required MediaType type,
    required String path,
  }) {
    if (rawMilliseconds != null) {
      return DateTime.fromMillisecondsSinceEpoch(rawMilliseconds);
    }
    if (type != MediaType.video) {
      return null;
    }

    try {
      final file = File(path);
      if (!file.existsSync()) {
        return null;
      }
      return file.lastModifiedSync();
    } on FileSystemException {
      return null;
    }
  }

  DateTime? _mediaAddedAtFromDb(int? rawMilliseconds) {
    if (rawMilliseconds == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(rawMilliseconds);
  }

  MediaOrigin _mediaOriginFromDb(
    String? raw, {
    required MediaType type,
    required DateTime? capturedAt,
  }) {
    if (raw != null) {
      for (final origin in MediaOrigin.values) {
        if (origin.name == raw) {
          return origin;
        }
      }
    }

    if (type == MediaType.audio || type == MediaType.video) {
      return MediaOrigin.recorded;
    }
    if (capturedAt != null) {
      return MediaOrigin.captured;
    }
    return MediaOrigin.unknown;
  }

  DateTime? _trashedAtFromDb(int? raw) {
    if (raw == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(raw);
  }

  List<String> _normalizeTags(Iterable<String> tags) {
    final normalized = <String>[];
    final seen = <String>{};

    for (final tag in tags) {
      final normalizedTag = _normalizeTag(tag);
      if (normalizedTag == null) continue;

      final key = normalizedTag.toLowerCase();
      if (seen.add(key)) {
        normalized.add(normalizedTag);
      }
    }

    return normalized;
  }

  String? _normalizeTag(String rawTag) {
    final trimmed = rawTag.trim();
    if (trimmed.isEmpty) return null;
    return trimmed.startsWith('#') ? trimmed : '#$trimmed';
  }

  DiaryMood _normalizeMood(DiaryMood mood) {
    final normalizedLabel = mood.label.trim();
    final normalizedEmoji = mood.emoji.trim();
    return mood.copyWith(
      label: normalizedLabel,
      emoji:
          normalizedEmoji.isEmpty ? DiaryMood.neutral.emoji : normalizedEmoji,
    );
  }
}
