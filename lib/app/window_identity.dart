import 'dart:io';

import 'package:diary_mvp/app/app_display_name.dart';
import 'package:diary_mvp/app/localization/app_strings.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final windowIconStorageProvider = Provider<WindowIconStorage>((ref) {
  return WindowIconStorage();
});

final windowIconControllerProvider =
    AsyncNotifierProvider<WindowIconController, WindowIconSnapshot?>(
  WindowIconController.new,
);

bool get supportsNativeWindowIdentityCustomization => Platform.isWindows;

class WindowIconSnapshot {
  const WindowIconSnapshot({
    required this.path,
    required this.revision,
  });

  final String path;
  final int revision;
}

class WindowIconStorage {
  Future<WindowIconSnapshot?> read() async {
    final file = await _iconFile();
    if (!await file.exists()) return null;
    return _snapshotFor(file);
  }

  Future<WindowIconSnapshot> saveFromSource(String sourcePath) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw Exception('Selected image file does not exist.');
    }

    final decoded = img.decodeImage(await sourceFile.readAsBytes());
    if (decoded == null) {
      throw Exception('Unsupported image format.');
    }

    final normalized = _normalizeIcon(decoded);
    final output = await _iconFile();
    await output.parent.create(recursive: true);
    await output.writeAsBytes(img.encodePng(normalized), flush: true);
    return _snapshotFor(output);
  }

  Future<void> reset() async {
    final file = await _iconFile();
    if (await file.exists()) {
      await file.delete();
    }
  }

  img.Image _normalizeIcon(img.Image source) {
    final squareSize =
        source.width < source.height ? source.width : source.height;
    final offsetX = (source.width - squareSize) ~/ 2;
    final offsetY = (source.height - squareSize) ~/ 2;
    final square = img.copyCrop(
      source,
      x: offsetX,
      y: offsetY,
      width: squareSize,
      height: squareSize,
    );
    return img.copyResize(
      square,
      width: 256,
      height: 256,
      interpolation: img.Interpolation.linear,
    );
  }

  Future<File> _iconFile() async {
    final documents = await getApplicationDocumentsDirectory();
    final settingsDir = Directory(
      p.join(documents.path, 'diary_mvp', 'settings'),
    );
    return File(p.join(settingsDir.path, 'window_app_icon.png'));
  }

  Future<WindowIconSnapshot> _snapshotFor(File file) async {
    final stat = await file.stat();
    return WindowIconSnapshot(
      path: file.path,
      revision: stat.modified.millisecondsSinceEpoch,
    );
  }
}

class WindowIconController extends AsyncNotifier<WindowIconSnapshot?> {
  WindowIconStorage get _storage => ref.read(windowIconStorageProvider);

  @override
  Future<WindowIconSnapshot?> build() {
    return _storage.read();
  }

  Future<void> saveFromSource(String sourcePath) async {
    final previous = state.valueOrNull;

    try {
      final savedPath = await _storage.saveFromSource(sourcePath);
      state = AsyncData(savedPath);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> reset() async {
    final previous = state.valueOrNull;
    state = const AsyncData(null);

    try {
      await _storage.reset();
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      state = AsyncData(previous);
      rethrow;
    }
  }
}

class WindowIdentitySync extends ConsumerStatefulWidget {
  const WindowIdentitySync({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<WindowIdentitySync> createState() => _WindowIdentitySyncState();
}

class _WindowIdentitySyncState extends ConsumerState<WindowIdentitySync> {
  static const MethodChannel _channel = MethodChannel(
    'diary_mvp/window_identity',
  );

  String? _lastTitle;
  String? _lastIconKey;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final title = resolveAppDisplayName(
      strings: strings,
      customNameAsync: ref.watch(appDisplayNameControllerProvider),
    );
    final iconSnapshot = ref.watch(windowIconControllerProvider).valueOrNull;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncWindowIdentity(title: title, iconSnapshot: iconSnapshot);
    });

    return widget.child;
  }

  Future<void> _syncWindowIdentity({
    required String title,
    required WindowIconSnapshot? iconSnapshot,
  }) async {
    if (!mounted || !supportsNativeWindowIdentityCustomization) {
      return;
    }

    final normalizedIconPath = iconSnapshot?.path.trim();
    final normalizedIconKey =
        normalizedIconPath == null || normalizedIconPath.isEmpty
            ? null
            : '$normalizedIconPath#${iconSnapshot!.revision}';
    if (_lastTitle == title && _lastIconKey == normalizedIconKey) {
      return;
    }

    _lastTitle = title;
    _lastIconKey = normalizedIconKey;

    try {
      await _channel.invokeMethod<void>('applyWindowIdentity', {
        'title': title,
        'iconPath': normalizedIconPath ?? '',
      });
    } catch (_) {
      // Keep startup resilient if the native platform doesn't support updates.
    }
  }
}
