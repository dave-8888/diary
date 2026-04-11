import 'dart:async';
import 'dart:typed_data';

import 'package:diary_mvp/core/storage/local_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_clipboard/super_clipboard.dart';

final clipboardImageServiceProvider = Provider<ClipboardImageService>((ref) {
  return SystemClipboardImageService(
    storage: ref.read(localStorageServiceProvider),
  );
});

enum ClipboardImagePasteStatus { pasted, noImage, unavailable }

class ClipboardImagePasteResult {
  const ClipboardImagePasteResult.pasted(String this.savedPath)
      : status = ClipboardImagePasteStatus.pasted;

  const ClipboardImagePasteResult.noImage()
      : status = ClipboardImagePasteStatus.noImage,
        savedPath = null;

  const ClipboardImagePasteResult.unavailable()
      : status = ClipboardImagePasteStatus.unavailable,
        savedPath = null;

  final ClipboardImagePasteStatus status;
  final String? savedPath;

  bool get didPaste =>
      status == ClipboardImagePasteStatus.pasted && savedPath != null;
}

abstract class ClipboardImageService {
  Future<ClipboardImagePasteResult> pasteImageFromClipboard();
}

class SystemClipboardImageService implements ClipboardImageService {
  SystemClipboardImageService({
    required LocalStorageService storage,
  }) : _storage = storage;

  static const List<_ClipboardImageFormat> _preferredFormats =
      <_ClipboardImageFormat>[
    _ClipboardImageFormat(Formats.png, '.png'),
    _ClipboardImageFormat(Formats.jpeg, '.jpg'),
    _ClipboardImageFormat(Formats.webp, '.webp'),
    _ClipboardImageFormat(Formats.gif, '.gif'),
    _ClipboardImageFormat(Formats.bmp, '.bmp'),
    _ClipboardImageFormat(Formats.tiff, '.tiff'),
    _ClipboardImageFormat(Formats.heic, '.heic'),
    _ClipboardImageFormat(Formats.heif, '.heif'),
  ];

  final LocalStorageService _storage;

  @override
  Future<ClipboardImagePasteResult> pasteImageFromClipboard() async {
    final clipboard = SystemClipboard.instance;
    if (clipboard == null) {
      return const ClipboardImagePasteResult.unavailable();
    }

    final reader = await clipboard.read();
    for (final candidate in _preferredFormats) {
      final bytes = await _readFile(reader, candidate.format);
      if (bytes == null || bytes.isEmpty) {
        continue;
      }

      final savedPath = await _storage.saveImageBytesToAppStorage(
        bytes,
        extension: candidate.extension,
      );
      return ClipboardImagePasteResult.pasted(savedPath);
    }

    return const ClipboardImagePasteResult.noImage();
  }

  Future<Uint8List?> _readFile(
    ClipboardReader reader,
    FileFormat format,
  ) {
    final completer = Completer<Uint8List?>();
    final progress = reader.getFile(
      format,
      (file) async {
        try {
          final bytes = await file.readAll();
          if (!completer.isCompleted) {
            completer.complete(bytes);
          }
        } catch (error, stackTrace) {
          if (!completer.isCompleted) {
            completer.completeError(error, stackTrace);
          }
        }
      },
      onError: (error) {
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      },
    );
    if (progress == null) {
      return Future<Uint8List?>.value(null);
    }
    return completer.future;
  }
}

class _ClipboardImageFormat {
  const _ClipboardImageFormat(this.format, this.extension);

  final FileFormat format;
  final String extension;
}
