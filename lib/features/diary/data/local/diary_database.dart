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
  int get schemaVersion => 2;

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
        tags_json TEXT NOT NULL
      );
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS diary_media (
        id TEXT PRIMARY KEY,
        diary_id TEXT NOT NULL,
        type TEXT NOT NULL,
        path TEXT NOT NULL,
        duration_label TEXT,
        FOREIGN KEY (diary_id) REFERENCES diary_entries (id) ON DELETE CASCADE
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
        COALESCE(tags_json, '[]') AS tags_json
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
        SELECT id, type, path, duration_label
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
          mood: _moodFromDb(row.read<String>('mood')),
          createdAt:
              DateTime.fromMillisecondsSinceEpoch(row.read<int>('created_at')),
          location: row.readNullable<String>('location'),
          trashedAt: _trashedAtFromDb(row.readNullable<int>('trashed_at')),
          tags: _decodeTags(row.read<String>('tags_json')),
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
        INSERT INTO diary_entries (id, title, content, mood, created_at, location, trashed_at, tags_json)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?);
        ''',
        [
          entry.id,
          entry.title,
          entry.content,
          entry.mood.name,
          entry.createdAt.millisecondsSinceEpoch,
          entry.location,
          entry.trashedAt?.millisecondsSinceEpoch,
          jsonEncode(entry.tags),
        ],
      );

      for (final media in entry.media) {
        await customStatement(
          '''
          INSERT INTO diary_media (id, diary_id, type, path, duration_label)
          VALUES (?, ?, ?, ?, ?);
          ''',
          [
            media.id,
            entry.id,
            media.type.name,
            media.path,
            media.durationLabel,
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
        SET title = ?, content = ?, mood = ?, created_at = ?, location = ?, trashed_at = ?, tags_json = ?
        WHERE id = ?;
        ''',
        [
          entry.title,
          entry.content,
          entry.mood.name,
          entry.createdAt.millisecondsSinceEpoch,
          entry.location,
          entry.trashedAt?.millisecondsSinceEpoch,
          jsonEncode(entry.tags),
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
          INSERT INTO diary_media (id, diary_id, type, path, duration_label)
          VALUES (?, ?, ?, ?, ?);
          ''',
          [
            media.id,
            entry.id,
            media.type.name,
            media.path,
            media.durationLabel,
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
  }

  DiaryMedia _mapMediaRow(QueryRow row) {
    return DiaryMedia(
      id: row.read<String>('id'),
      type: _mediaTypeFromDb(row.read<String>('type')),
      path: row.read<String>('path'),
      durationLabel: row.readNullable<String>('duration_label'),
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

  DiaryMood _moodFromDb(String raw) {
    return DiaryMood.values.firstWhere(
      (mood) => mood.name == raw,
      orElse: () => DiaryMood.neutral,
    );
  }

  MediaType _mediaTypeFromDb(String raw) {
    return MediaType.values.firstWhere(
      (type) => type.name == raw,
      orElse: () => MediaType.image,
    );
  }

  DateTime? _trashedAtFromDb(int? raw) {
    if (raw == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(raw);
  }
}
