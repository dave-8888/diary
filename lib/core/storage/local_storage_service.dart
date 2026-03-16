import 'dart:io';
import 'dart:typed_data';

import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

class MediaFileMove {
  const MediaFileMove({
    required this.original,
    required this.moved,
  });

  final DiaryMedia original;
  final DiaryMedia moved;
}

class LocalStorageService {
  final Uuid _uuid = const Uuid();
  Directory? _baseDirectory;

  Future<Directory> baseDirectory() async {
    if (_baseDirectory != null) return _baseDirectory!;
    final documents = await getApplicationDocumentsDirectory();
    final base = Directory(p.join(documents.path, 'diary_mvp', 'user_data'));
    await base.create(recursive: true);
    _baseDirectory = base;
    return base;
  }

  Future<Directory> imagesDirectory() async {
    final base = await baseDirectory();
    final dir = Directory(p.join(base.path, 'diary', 'images'));
    await dir.create(recursive: true);
    return dir;
  }

  Future<Directory> audioDirectory() async {
    final base = await baseDirectory();
    final dir = Directory(p.join(base.path, 'diary', 'audio'));
    await dir.create(recursive: true);
    return dir;
  }

  Future<Directory> videoDirectory() async {
    final base = await baseDirectory();
    final dir = Directory(p.join(base.path, 'diary', 'video'));
    await dir.create(recursive: true);
    return dir;
  }

  Future<Directory> trashDirectory() async {
    final base = await baseDirectory();
    final dir = Directory(p.join(base.path, 'trash'));
    await dir.create(recursive: true);
    return dir;
  }

  Future<Directory> trashImagesDirectory() async {
    final base = await trashDirectory();
    final dir = Directory(p.join(base.path, 'images'));
    await dir.create(recursive: true);
    return dir;
  }

  Future<Directory> trashAudioDirectory() async {
    final base = await trashDirectory();
    final dir = Directory(p.join(base.path, 'audio'));
    await dir.create(recursive: true);
    return dir;
  }

  Future<Directory> trashVideoDirectory() async {
    final base = await trashDirectory();
    final dir = Directory(p.join(base.path, 'video'));
    await dir.create(recursive: true);
    return dir;
  }

  Future<String> copyImageToAppStorage(String sourcePath) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw StateError('Image file does not exist: $sourcePath');
    }

    final extension = p.extension(sourcePath).toLowerCase();
    final imagesDir = await imagesDirectory();
    final targetPath = p.join(imagesDir.path, '${_uuid.v4()}$extension');
    await source.copy(targetPath);
    return targetPath;
  }

  Future<String> saveImageBytesToAppStorage(
    Uint8List bytes, {
    String extension = '.jpg',
  }) async {
    final normalizedExtension =
        extension.startsWith('.') ? extension : '.$extension';
    final imagesDir = await imagesDirectory();
    final targetPath = p.join(
        imagesDir.path, '${_uuid.v4()}${normalizedExtension.toLowerCase()}');
    final file = File(targetPath);
    await file.writeAsBytes(bytes, flush: true);
    return targetPath;
  }

  Future<String> copyVideoToAppStorage(String sourcePath) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw StateError('Video file does not exist: $sourcePath');
    }

    final extension = p.extension(sourcePath).toLowerCase();
    final videoDir = await videoDirectory();
    final targetPath = p.join(videoDir.path, '${_uuid.v4()}$extension');
    await source.copy(targetPath);
    return targetPath;
  }

  Future<String> createAudioRecordingPath() async {
    final audioDir = await audioDirectory();
    return p.join(audioDir.path, '${_uuid.v4()}.m4a');
  }

  Future<void> deleteMediaFiles(Iterable<DiaryMedia> media) async {
    for (final item in media) {
      final file = File(item.path);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  Future<List<MediaFileMove>> moveMediaFilesToTrash(
    Iterable<DiaryMedia> media,
  ) {
    return _moveMediaFiles(
      media,
      targetDirectoryForType: (type) => _directoryForType(type, useTrash: true),
    );
  }

  Future<List<MediaFileMove>> restoreMediaFilesFromTrash(
    Iterable<DiaryMedia> media,
  ) {
    return _moveMediaFiles(
      media,
      targetDirectoryForType: (type) =>
          _directoryForType(type, useTrash: false, createFreshName: true),
    );
  }

  Future<void> revertMediaMoves(Iterable<MediaFileMove> moves) async {
    for (final move in moves) {
      if (move.original.path == move.moved.path) continue;
      final source = File(move.moved.path);
      if (!await source.exists()) continue;
      await _moveFile(source.path, move.original.path);
    }
  }

  Future<List<MediaFileMove>> _moveMediaFiles(
    Iterable<DiaryMedia> media, {
    required Future<Directory> Function(MediaType type) targetDirectoryForType,
  }) async {
    final moves = <MediaFileMove>[];
    for (final item in media) {
      final source = File(item.path);
      if (!await source.exists()) {
        moves.add(MediaFileMove(original: item, moved: item));
        continue;
      }

      final directory = await targetDirectoryForType(item.type);
      final extension = p.extension(item.path).toLowerCase();
      final targetPath = p.join(directory.path, '${_uuid.v4()}$extension');
      await _moveFile(item.path, targetPath);
      moves.add(
        MediaFileMove(
          original: item,
          moved: item.copyWith(path: targetPath),
        ),
      );
    }
    return moves;
  }

  Future<Directory> _directoryForType(
    MediaType type, {
    required bool useTrash,
    bool createFreshName = false,
  }) {
    switch (type) {
      case MediaType.image:
        return useTrash ? trashImagesDirectory() : imagesDirectory();
      case MediaType.audio:
        return useTrash ? trashAudioDirectory() : audioDirectory();
      case MediaType.video:
        return useTrash ? trashVideoDirectory() : videoDirectory();
    }
  }

  Future<void> _moveFile(String sourcePath, String targetPath) async {
    final source = File(sourcePath);
    if (p.equals(sourcePath, targetPath)) return;
    await Directory(p.dirname(targetPath)).create(recursive: true);
    try {
      await source.rename(targetPath);
    } on FileSystemException {
      await source.copy(targetPath);
      await source.delete();
    }
  }
}
