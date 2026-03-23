import 'package:diary_mvp/features/diary/data/diary_repository.dart';
import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
import 'package:diary_mvp/core/storage/local_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

final diaryControllerProvider =
    AsyncNotifierProvider<DiaryController, List<DiaryEntry>>(
        DiaryController.new);
final selectedTagFilterProvider = StateProvider<String?>((ref) => null);

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

  Future<DiaryEntry> addEntry({
    required String title,
    required String content,
    required DiaryMood mood,
    required String location,
    required List<String> tags,
    required List<DiaryMedia> media,
    DiaryEntryAiAnalysis? aiAnalysis,
  }) async {
    return _runMutation(() async {
      final entry = await _repository.createEntry(
        title: title,
        content: content,
        mood: mood,
        location: location,
        tags: tags,
        media: media,
        aiAnalysis: aiAnalysis,
      );
      ref.invalidate(tagLibraryControllerProvider);
      return entry;
    });
  }

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
    return _runMutation(() async {
      final updated = await _repository.updateEntry(
        entry: entry,
        title: title,
        content: content,
        mood: mood,
        location: location,
        tags: tags,
        media: media,
        aiAnalysis: aiAnalysis,
      );
      ref.invalidate(tagLibraryControllerProvider);
      return updated;
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

  Future<T> _runMutation<T>(Future<T> Function() mutation) async {
    state = const AsyncLoading();
    try {
      final result = await mutation();
      state = AsyncData(await _repository.listEntries());
      return result;
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

final tagLibraryControllerProvider =
    AsyncNotifierProvider<TagLibraryController, List<String>>(
        TagLibraryController.new);

class TagLibraryController extends AsyncNotifier<List<String>> {
  DiaryRepository get _repository => ref.read(diaryRepositoryProvider);

  @override
  Future<List<String>> build() async {
    return _repository.listTagLibrary();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repository.listTagLibrary);
  }

  Future<void> saveTag(String tag) async {
    state = const AsyncLoading();
    try {
      await _repository.saveTag(tag);
      state = AsyncData(await _repository.listTagLibrary());
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteTag(String tag) async {
    state = const AsyncLoading();
    try {
      await _repository.deleteTag(tag);
      final selectedTag = ref.read(selectedTagFilterProvider);
      if (selectedTag?.toLowerCase() == tag.toLowerCase()) {
        ref.read(selectedTagFilterProvider.notifier).state = null;
      }
      ref.invalidate(diaryControllerProvider);
      ref.invalidate(trashDiaryControllerProvider);
      state = AsyncData(await _repository.listTagLibrary());
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

final moodLibraryControllerProvider =
    AsyncNotifierProvider<MoodLibraryController, List<DiaryMood>>(
        MoodLibraryController.new);

class MoodLibraryController extends AsyncNotifier<List<DiaryMood>> {
  final Uuid _uuid = const Uuid();

  DiaryRepository get _repository => ref.read(diaryRepositoryProvider);

  @override
  Future<List<DiaryMood>> build() async {
    return _repository.listMoodLibrary();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repository.listMoodLibrary);
  }

  Future<void> createMood({
    required String label,
    required String emoji,
  }) async {
    final current = state.valueOrNull ?? await _repository.listMoodLibrary();
    final nextSortOrder = current.isEmpty
        ? 0
        : current
                .map((mood) => mood.sortOrder)
                .reduce((value, element) => value > element ? value : element) +
            1;

    await saveMood(
      DiaryMood(
        id: 'custom_${_uuid.v4()}',
        label: label.trim(),
        emoji: emoji.trim(),
        sortOrder: nextSortOrder,
      ),
    );
  }

  Future<void> saveMood(DiaryMood mood) async {
    state = const AsyncLoading();
    try {
      await _repository.saveMood(mood);
      ref.invalidate(diaryControllerProvider);
      ref.invalidate(trashDiaryControllerProvider);
      state = AsyncData(await _repository.listMoodLibrary());
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> resetToDefaults() async {
    state = const AsyncLoading();
    try {
      await _repository.resetMoodLibraryToDefaults();
      ref.invalidate(diaryControllerProvider);
      ref.invalidate(trashDiaryControllerProvider);
      state = AsyncData(await _repository.listMoodLibrary());
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}
