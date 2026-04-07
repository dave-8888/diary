import 'package:diary_mvp/features/diary/data/diary_repository.dart';
import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
import 'package:diary_mvp/core/storage/local_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

final diaryControllerProvider =
    AsyncNotifierProvider<DiaryController, List<DiaryEntry>>(
        DiaryController.new);
final selectedTagFilterProvider =
    StateProvider<List<String>>((ref) => const <String>[]);

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
    required bool isHidden,
    required List<String> tags,
    required List<DiaryMedia> media,
    DiaryEntryAiAnalysis? aiAnalysis,
  }) async {
    final previousState = state;
    final previousEntries =
        state.valueOrNull ?? await _repository.listEntries();

    try {
      final entry = await _repository.createEntry(
        title: title,
        content: content,
        mood: mood,
        location: location,
        isHidden: isHidden,
        tags: tags,
        media: media,
        aiAnalysis: aiAnalysis,
      );
      ref.invalidate(tagLibraryControllerProvider);
      state = AsyncData(_upsertVisibleEntry(previousEntries, entry));
      return entry;
    } catch (error, stackTrace) {
      state = previousState;
      if (previousState is! AsyncData<List<DiaryEntry>>) {
        state = AsyncError(error, stackTrace);
      }
      rethrow;
    }
  }

  Future<DiaryEntry> updateEntry({
    required DiaryEntry entry,
    required String title,
    required String content,
    required DiaryMood mood,
    required String location,
    required bool isHidden,
    required List<String> tags,
    required List<DiaryMedia> media,
    DiaryEntryAiAnalysis? aiAnalysis,
  }) async {
    final previousState = state;
    final previousEntries =
        state.valueOrNull ?? await _repository.listEntries();

    try {
      final updated = await _repository.updateEntry(
        entry: entry,
        title: title,
        content: content,
        mood: mood,
        location: location,
        isHidden: isHidden,
        tags: tags,
        media: media,
        aiAnalysis: aiAnalysis,
      );
      ref.invalidate(tagLibraryControllerProvider);
      state = AsyncData(_upsertVisibleEntry(previousEntries, updated));
      return updated;
    } catch (error, stackTrace) {
      state = previousState;
      if (previousState is! AsyncData<List<DiaryEntry>>) {
        state = AsyncError(error, stackTrace);
      }
      rethrow;
    }
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

  Future<void> setEntryHidden({
    required DiaryEntry entry,
    required bool isHidden,
  }) async {
    final updated = entry.copyWith(isHidden: isHidden);
    await _runMutation(() async {
      await _repository.saveEntry(updated);
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

  List<DiaryEntry> _upsertVisibleEntry(
    List<DiaryEntry> currentEntries,
    DiaryEntry nextEntry,
  ) {
    final nextEntries = currentEntries
        .where((entry) => entry.id != nextEntry.id && entry.trashedAt == null)
        .toList(growable: true)
      ..add(nextEntry);
    nextEntries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(nextEntries);
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
      final selectedTags = ref.read(selectedTagFilterProvider);
      final nextSelectedTags = selectedTags
          .where((item) => item.toLowerCase() != tag.toLowerCase())
          .toList(growable: false);
      if (nextSelectedTags.length != selectedTags.length) {
        ref.read(selectedTagFilterProvider.notifier).state = nextSelectedTags;
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
