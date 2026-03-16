import 'package:diary_mvp/features/diary/data/diary_repository.dart';
import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
import 'package:diary_mvp/core/storage/local_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final diaryControllerProvider =
    AsyncNotifierProvider<DiaryController, List<DiaryEntry>>(
        DiaryController.new);

class DiaryController extends AsyncNotifier<List<DiaryEntry>> {
  DiaryRepository get _repository => ref.read(diaryRepositoryProvider);

  @override
  Future<List<DiaryEntry>> build() async {
    return _repository.listEntries();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repository.listEntries);
  }

  Future<void> addEntry({
    required String title,
    required String content,
    required DiaryMood mood,
    required String location,
    required List<DiaryMedia> media,
  }) async {
    await _runMutation(() async {
      await _repository.createEntry(
        title: title,
        content: content,
        mood: mood,
        location: location,
        media: media,
      );
    });
  }

  Future<void> updateEntry({
    required DiaryEntry entry,
    required String title,
    required String content,
    required DiaryMood mood,
    required String location,
    required List<DiaryMedia> media,
  }) async {
    await _runMutation(() async {
      await _repository.updateEntry(
        entry: entry,
        title: title,
        content: content,
        mood: mood,
        location: location,
        media: media,
      );
    });
  }

  Future<void> moveEntryToTrash(DiaryEntry entry) async {
    final storage = ref.read(localStorageServiceProvider);
    final movedMedia = await storage.moveMediaFilesToTrash(entry.media);
    final trashedEntry = entry.copyWith(
      media: movedMedia.map((move) => move.moved).toList(growable: false),
      trashedAt: DateTime.now(),
    );

    await _runMutation(() async {
      try {
        await _repository.saveEntry(trashedEntry);
      } catch (error) {
        await storage.revertMediaMoves(movedMedia);
        rethrow;
      }
      ref.invalidate(trashDiaryControllerProvider);
    });
  }

  Future<void> deleteEntry(String id) async {
    await _runMutation(() async {
      await _repository.deleteEntry(id);
    });
  }

  Future<void> _runMutation(Future<void> Function() mutation) async {
    state = const AsyncLoading();
    try {
      await mutation();
      state = AsyncData(await _repository.listEntries());
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

final trashDiaryControllerProvider =
    AsyncNotifierProvider<TrashDiaryController, List<DiaryEntry>>(
        TrashDiaryController.new);

class TrashDiaryController extends AsyncNotifier<List<DiaryEntry>> {
  DiaryRepository get _repository => ref.read(diaryRepositoryProvider);

  @override
  Future<List<DiaryEntry>> build() async {
    return _repository.listTrashedEntries();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repository.listTrashedEntries);
  }

  Future<void> restoreEntries(List<DiaryEntry> entries) async {
    state = const AsyncLoading();
    try {
      final storage = ref.read(localStorageServiceProvider);
      for (final entry in entries) {
        final movedMedia =
            await storage.restoreMediaFilesFromTrash(entry.media);
        final restoredEntry = entry.copyWith(
          media: movedMedia.map((move) => move.moved).toList(growable: false),
          trashedAt: null,
        );
        try {
          await _repository.saveEntry(restoredEntry);
        } catch (error) {
          await storage.revertMediaMoves(movedMedia);
          rethrow;
        }
      }
      ref.invalidate(diaryControllerProvider);
      state = AsyncData(await _repository.listTrashedEntries());
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> clearTrash(List<DiaryEntry> entries) async {
    if (entries.isEmpty) return;

    state = const AsyncLoading();
    try {
      final storage = ref.read(localStorageServiceProvider);
      for (final entry in entries) {
        await storage.deleteMediaFiles(entry.media);
        await _repository.deleteEntry(entry.id);
      }
      state = AsyncData(await _repository.listTrashedEntries());
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}
