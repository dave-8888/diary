import 'dart:io';

import 'package:diary_mvp/app/window_identity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

final windowsBuildIdentityServiceProvider =
    Provider<WindowsBuildIdentityService>((ref) {
  return WindowsBuildIdentityService();
});

class WindowsBuildIdentityService {
  bool get canSyncBuildIcon => _findProjectRoot() != null;

  Future<void> applyBuildIcon(WindowIconSnapshot snapshot) async {
    final projectRoot = _findProjectRoot();
    if (projectRoot == null) {
      throw Exception('Windows build resources were not found.');
    }

    final resourcesDir =
        Directory(p.join(projectRoot.path, 'windows', 'runner', 'resources'));
    final appIconFile = File(p.join(resourcesDir.path, 'app_icon.ico'));
    final backupIconFile =
        File(p.join(resourcesDir.path, 'app_icon_default.ico'));

    if (!await appIconFile.exists()) {
      throw Exception('The Windows app icon resource is missing.');
    }

    if (!await backupIconFile.exists()) {
      await appIconFile.copy(backupIconFile.path);
    }

    final sourceFile = File(snapshot.path);
    if (!await sourceFile.exists()) {
      throw Exception('The selected window icon image no longer exists.');
    }

    final decoded = img.decodeImage(await sourceFile.readAsBytes());
    if (decoded == null) {
      throw Exception('Unsupported image format.');
    }

    final normalized = _normalizeForBuildIcon(decoded);
    final iconSheet = img.Image.from(normalized, noAnimation: true);
    for (final size in const [128, 64, 48, 32, 24, 16]) {
      iconSheet.addFrame(
        img.copyResize(
          normalized,
          width: size,
          height: size,
          interpolation: img.Interpolation.linear,
        ),
      );
    }

    await appIconFile.writeAsBytes(
      img.encodeIco(iconSheet),
      flush: true,
    );
  }

  Future<void> resetBuildIcon() async {
    final projectRoot = _findProjectRoot();
    if (projectRoot == null) {
      throw Exception('Windows build resources were not found.');
    }

    final resourcesDir =
        Directory(p.join(projectRoot.path, 'windows', 'runner', 'resources'));
    final appIconFile = File(p.join(resourcesDir.path, 'app_icon.ico'));
    final backupIconFile =
        File(p.join(resourcesDir.path, 'app_icon_default.ico'));

    if (!await backupIconFile.exists()) {
      throw Exception('No default Windows icon backup is available yet.');
    }

    await backupIconFile.copy(appIconFile.path);
  }

  img.Image _normalizeForBuildIcon(img.Image source) {
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

  Directory? _findProjectRoot() {
    if (!Platform.isWindows) {
      return null;
    }

    final candidates = <Directory>{
      Directory.current,
      File(Platform.resolvedExecutable).parent,
    };

    for (final candidate in candidates) {
      final projectRoot = _walkUpForProjectRoot(candidate);
      if (projectRoot != null) {
        return projectRoot;
      }
    }

    return null;
  }

  Directory? _walkUpForProjectRoot(Directory start) {
    Directory current = start.absolute;
    while (true) {
      final hasPubspec =
          File(p.join(current.path, 'pubspec.yaml')).existsSync();
      final hasWindowsIcon = File(
        p.join(current.path, 'windows', 'runner', 'resources', 'app_icon.ico'),
      ).existsSync();
      if (hasPubspec && hasWindowsIcon) {
        return current;
      }

      final parent = current.parent;
      if (parent.path == current.path) {
        return null;
      }
      current = parent;
    }
  }
}
