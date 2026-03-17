import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
import 'package:diary_mvp/features/diary/data/local/diary_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

final diaryRepositoryProvider = Provider<DiaryRepository>((ref) {
  final database = ref.watch(diaryDatabaseProvider);
  return DriftDiaryRepository(database);
});

abstract class DiaryRepository {
  Future<List<DiaryEntry>> listEntries();
  Future<List<DiaryEntry>> listTrashedEntries();
  Future<List<String>> listTagLibrary();
  Future<List<DiaryMood>> listMoodLibrary();
  Future<DiaryEntry> createEntry({
    required String title,
    required String content,
    required DiaryMood mood,
    required String location,
    required List<String> tags,
    required List<DiaryMedia> media,
    DiaryEntryAiAnalysis? aiAnalysis,
  });
  Future<DiaryEntry> updateEntry({
    required DiaryEntry entry,
    required String title,
    required String content,
    required DiaryMood mood,
    required String location,
    required List<String> tags,
    required List<DiaryMedia> media,
    DiaryEntryAiAnalysis? aiAnalysis,
  });
  Future<void> saveEntry(DiaryEntry entry);
  Future<void> deleteEntry(String id);
  Future<void> saveTag(String tag);
  Future<void> deleteTag(String tag);
  Future<void> saveMood(DiaryMood mood);
  Future<void> resetMoodLibraryToDefaults();
}

class DriftDiaryRepository implements DiaryRepository {
  DriftDiaryRepository(this._database);

  final DiaryDatabase _database;
  final _uuid = const Uuid();

  @override
  Future<List<DiaryEntry>> listEntries() {
    return _database.listEntries();
  }

  @override
  Future<List<DiaryEntry>> listTrashedEntries() {
    return _database.listTrashedEntries();
  }

  @override
  Future<List<String>> listTagLibrary() {
    return _database.listTagLibrary();
  }

  @override
  Future<List<DiaryMood>> listMoodLibrary() {
    return _database.listMoodLibrary();
  }

  @override
  Future<DiaryEntry> createEntry({
    required String title,
    required String content,
    required DiaryMood mood,
    required String location,
    required List<String> tags,
    required List<DiaryMedia> media,
    DiaryEntryAiAnalysis? aiAnalysis,
  }) async {
    final entry = DiaryEntry(
      id: _uuid.v4(),
      title: title.trim().isEmpty ? 'Untitled entry' : title.trim(),
      content: content.trim(),
      mood: mood,
      createdAt: DateTime.now(),
      location: location.trim().isEmpty ? null : location.trim(),
      media: media,
      tags: _normalizeTags(tags),
      aiAnalysis: aiAnalysis,
    );

    await _database.insertEntry(entry);
    await _database.upsertTagLibrary(entry.tags);
    return entry;
  }

  @override
  Future<void> saveEntry(DiaryEntry entry) async {
    await _database.updateEntry(entry);
    await _database.upsertTagLibrary(entry.tags);
  }

  @override
  Future<DiaryEntry> updateEntry({
    required DiaryEntry entry,
    required String title,
    required String content,
    required DiaryMood mood,
    required String location,
    required List<String> tags,
    required List<DiaryMedia> media,
    DiaryEntryAiAnalysis? aiAnalysis,
  }) async {
    final updated = entry.copyWith(
      title: title.trim().isEmpty ? 'Untitled entry' : title.trim(),
      content: content.trim(),
      mood: mood,
      location: location.trim().isEmpty ? null : location.trim(),
      media: media,
      tags: _normalizeTags(tags),
      aiAnalysis: aiAnalysis,
    );

    await saveEntry(updated);
    return updated;
  }

  @override
  Future<void> deleteEntry(String id) {
    return _database.deleteEntry(id);
  }

  @override
  Future<void> saveTag(String tag) {
    return _database.upsertTagLibrary([tag]);
  }

  @override
  Future<void> deleteTag(String tag) {
    return _database.deleteTagFromLibrary(tag);
  }

  @override
  Future<void> saveMood(DiaryMood mood) {
    return _database.saveMood(mood);
  }

  @override
  Future<void> resetMoodLibraryToDefaults() {
    return _database.resetMoodLibraryToDefaults();
  }

  List<String> _normalizeTags(List<String> tags) {
    final normalized = <String>[];
    final seen = <String>{};

    for (final rawTag in tags) {
      final trimmed = rawTag.trim();
      if (trimmed.isEmpty) continue;

      final tag = trimmed.startsWith('#') ? trimmed : '#$trimmed';
      final key = tag.toLowerCase();
      if (seen.add(key)) {
        normalized.add(tag);
      }
    }

    return List.unmodifiable(normalized);
  }
}
