import 'package:diary_mvp/features/diary/data/diary_repository.dart';
import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final diaryControllerProvider =
    AsyncNotifierProvider<DiaryController, List<DiaryEntry>>(
        DiaryController.new);

class DiaryController extends AsyncNotifier<List<DiaryEntry>> {
  late final DiaryRepository _repository;

  @override
  Future<List<DiaryEntry>> build() async {
    _repository = ref.read(diaryRepositoryProvider);
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
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.createEntry(
        title: title,
        content: content,
        mood: mood,
        location: location,
        media: media,
      );
      return _repository.listEntries();
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
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.updateEntry(
        entry: entry,
        title: title,
        content: content,
        mood: mood,
        location: location,
        media: media,
      );
      return _repository.listEntries();
    });
  }
}
