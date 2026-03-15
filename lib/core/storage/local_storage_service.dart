import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

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

  Future<String> createAudioRecordingPath() async {
    final audioDir = await audioDirectory();
    return p.join(audioDir.path, '${_uuid.v4()}.m4a');
  }
}
