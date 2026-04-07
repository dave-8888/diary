import 'dart:io';

import 'package:diary_mvp/features/diary/data/local/diary_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  test('database migration adds is_hidden column and preserves old entries',
      () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'diary-hidden-migration',
    );
    addTearDown(() => tempDir.delete(recursive: true));

    final dbFile = File('${tempDir.path}/diary.db');
    final legacyDatabase = sqlite.sqlite3.open(dbFile.path);
    legacyDatabase.execute('PRAGMA user_version = 7;');
    legacyDatabase.execute('''
      CREATE TABLE diary_entries (
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
    legacyDatabase.execute('''
      CREATE TABLE diary_media (
        id TEXT PRIMARY KEY,
        diary_id TEXT NOT NULL,
        type TEXT NOT NULL,
        path TEXT NOT NULL,
        duration_label TEXT,
        captured_at INTEGER,
        added_at INTEGER,
        location TEXT,
        origin TEXT NOT NULL DEFAULT 'unknown'
      );
    ''');
    legacyDatabase.execute('''
      CREATE TABLE diary_tags (
        name TEXT PRIMARY KEY COLLATE NOCASE,
        created_at INTEGER NOT NULL
      );
    ''');
    legacyDatabase.execute('''
      CREATE TABLE mood_library (
        id TEXT PRIMARY KEY,
        label TEXT NOT NULL,
        emoji TEXT NOT NULL,
        sort_order INTEGER NOT NULL,
        is_default INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      );
    ''');
    legacyDatabase.execute('''
      INSERT INTO diary_entries (
        id, title, content, mood, created_at, location, trashed_at, tags_json, ai_analysis_json
      ) VALUES (
        'legacy-entry', 'Legacy entry', 'Still visible after migration.', 'calm', 1710842400000, NULL, NULL, '[]', NULL
      );
    ''');
    legacyDatabase.dispose();

    final database = DiaryDatabase.forTesting(NativeDatabase(dbFile));
    addTearDown(database.close);

    final entries = await database.listEntries();
    final columns =
        await database.customSelect('PRAGMA table_info(diary_entries);').get();

    expect(entries, hasLength(1));
    expect(entries.single.id, 'legacy-entry');
    expect(entries.single.isHidden, isFalse);
    expect(
      columns.any((row) => row.read<String>('name') == 'is_hidden'),
      isTrue,
    );
  });
}
