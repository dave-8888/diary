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
  Future<DiaryEntry> createEntry({
    required String title,
    required String content,
    required DiaryMood mood,
    required String location,
    required List<DiaryMedia> media,
  });
  Future<DiaryEntry> updateEntry({
    required DiaryEntry entry,
    required String title,
    required String content,
    required DiaryMood mood,
    required String location,
    required List<DiaryMedia> media,
  });
  Future<void> deleteEntry(String id);
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
  Future<DiaryEntry> createEntry({
    required String title,
    required String content,
    required DiaryMood mood,
    required String location,
    required List<DiaryMedia> media,
  }) async {
    final entry = DiaryEntry(
      id: _uuid.v4(),
      title: title.trim().isEmpty ? 'Untitled entry' : title.trim(),
      content: content.trim(),
      mood: mood,
      createdAt: DateTime.now(),
      location: location.trim().isEmpty ? null : location.trim(),
      media: media,
      tags: _buildTags(content),
    );

    await _database.insertEntry(entry);
    return entry;
  }

  @override
  Future<DiaryEntry> updateEntry({
    required DiaryEntry entry,
    required String title,
    required String content,
    required DiaryMood mood,
    required String location,
    required List<DiaryMedia> media,
  }) async {
    final updated = entry.copyWith(
      title: title.trim().isEmpty ? 'Untitled entry' : title.trim(),
      content: content.trim(),
      mood: mood,
      location: location.trim().isEmpty ? null : location.trim(),
      media: media,
      tags: _buildTags(content),
    );

    await _database.updateEntry(updated);
    return updated;
  }

  @override
  Future<void> deleteEntry(String id) {
    return _database.deleteEntry(id);
  }

  List<String> _buildTags(String content) {
    final lower = content.toLowerCase();
    if (lower.contains('work')) {
      return const ['#work'];
    }
    if (lower.contains('travel') || lower.contains('park')) {
      return const ['#life'];
    }
    return const ['#journal'];
  }
}
