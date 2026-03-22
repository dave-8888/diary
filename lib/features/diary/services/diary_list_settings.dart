import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final diaryListSettingsStorageProvider = Provider<DiaryListSettingsStorage>((
  ref,
) {
  return DiaryListSettingsStorage();
});

final diaryListVisualMediaVisibilityControllerProvider =
    AsyncNotifierProvider<DiaryListVisualMediaVisibilityController, bool>(
  DiaryListVisualMediaVisibilityController.new,
);

class DiaryListSettingsStorage {
  Future<bool> readShowVisualMedia() async {
    final raw = await _readRaw();
    final value = raw['show_visual_media'];
    if (value is bool) {
      return value;
    }
    return true;
  }

  Future<void> writeShowVisualMedia(bool enabled) async {
    final raw = await _readRaw();
    if (enabled) {
      raw.remove('show_visual_media');
    } else {
      raw['show_visual_media'] = false;
    }
    await _writeRaw(raw);
  }

  Future<File> _settingsFile() async {
    final documents = await getApplicationDocumentsDirectory();
    final settingsDir = Directory(
      p.join(documents.path, 'diary_mvp', 'settings'),
    );
    return File(p.join(settingsDir.path, 'diary_list_settings.json'));
  }

  Future<Map<String, dynamic>> _readRaw() async {
    final file = await _settingsFile();
    if (!await file.exists()) {
      return <String, dynamic>{};
    }

    try {
      final raw = jsonDecode(await file.readAsString());
      if (raw is Map<String, dynamic>) {
        return Map<String, dynamic>.from(raw);
      }
    } on FormatException {
      return <String, dynamic>{};
    }

    return <String, dynamic>{};
  }

  Future<void> _writeRaw(Map<String, dynamic> raw) async {
    final file = await _settingsFile();

    if (raw.isEmpty) {
      if (await file.exists()) {
        await file.delete();
      }
      return;
    }

    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(raw),
      flush: true,
    );
  }
}

class DiaryListVisualMediaVisibilityController extends AsyncNotifier<bool> {
  DiaryListSettingsStorage get _storage =>
      ref.read(diaryListSettingsStorageProvider);

  @override
  Future<bool> build() {
    return _storage.readShowVisualMedia();
  }

  Future<void> setEnabled(bool enabled) async {
    final previous = state.valueOrNull ?? true;
    state = AsyncData(enabled);

    try {
      await _storage.writeShowVisualMedia(enabled);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      state = AsyncData(previous);
      rethrow;
    }
  }
}
