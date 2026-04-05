import 'dart:io';

import 'package:diary_mvp/app/app_icon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

final macosBuildIdentityServiceProvider =
    Provider<MacOSBuildIdentityService>((ref) {
  return MacOSBuildIdentityService();
});

class MacOSBuildIdentityService {
  static const double _cornerRadiusRatio = 0.225;

  bool get canSyncBuildIcon => _findProjectRoot() != null;

  Future<void> applyBuildIcon(AppIconSelection selection) async {
    final projectRoot = _findProjectRoot();
    if (projectRoot == null) {
      throw Exception('macOS build resources were not found.');
    }

    final appIconSetDir = Directory(
      p.join(
        projectRoot.path,
        'macos',
        'Runner',
        'Assets.xcassets',
        'AppIcon.appiconset',
      ),
    );
    if (!await appIconSetDir.exists()) {
      throw Exception('The macOS app icon asset catalog is missing.');
    }

    final sourceFile = File(selection.windowIconPath);
    if (!await sourceFile.exists()) {
      throw Exception('The selected app icon image no longer exists.');
    }

    final decoded = img.decodeImage(await sourceFile.readAsBytes());
    if (decoded == null) {
      throw Exception('Unsupported image format.');
    }

    final normalized = _normalizeForBuildIcon(decoded);
    for (final size in const [16, 32, 64, 128, 256, 512, 1024]) {
      final output = File(p.join(appIconSetDir.path, 'app_icon_$size.png'));
      final resized = size == 1024
          ? normalized
          : img.copyResize(
              normalized,
              width: size,
              height: size,
              interpolation: img.Interpolation.linear,
            );
      final rounded = _applyRoundedRectMask(resized);
      await output.writeAsBytes(img.encodePng(rounded), flush: true);
    }
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
      width: 1024,
      height: 1024,
      interpolation: img.Interpolation.linear,
    );
  }

  img.Image _applyRoundedRectMask(img.Image source) {
    final masked = img.Image.from(source, noAnimation: true);
    final radius = masked.width * _cornerRadiusRatio;
    const sampleOffsets = <double>[0.125, 0.375, 0.625, 0.875];

    for (var y = 0; y < masked.height; y++) {
      for (var x = 0; x < masked.width; x++) {
        final coverage = _roundedRectCoverage(
          x: x,
          y: y,
          width: masked.width.toDouble(),
          height: masked.height.toDouble(),
          radius: radius,
          sampleOffsets: sampleOffsets,
        );
        if (coverage >= 0.999) {
          continue;
        }

        final pixel = masked.getPixel(x, y);
        final alpha = (pixel.a * coverage).round().clamp(0, 255);
        masked.setPixelRgba(
          x,
          y,
          pixel.r.toInt(),
          pixel.g.toInt(),
          pixel.b.toInt(),
          alpha,
        );
      }
    }

    return masked;
  }

  double _roundedRectCoverage({
    required int x,
    required int y,
    required double width,
    required double height,
    required double radius,
    required List<double> sampleOffsets,
  }) {
    var insideSamples = 0;
    final totalSamples = sampleOffsets.length * sampleOffsets.length;

    for (final offsetY in sampleOffsets) {
      for (final offsetX in sampleOffsets) {
        if (_isInsideRoundedRect(
          px: x + offsetX,
          py: y + offsetY,
          width: width,
          height: height,
          radius: radius,
        )) {
          insideSamples++;
        }
      }
    }

    return insideSamples / totalSamples;
  }

  bool _isInsideRoundedRect({
    required double px,
    required double py,
    required double width,
    required double height,
    required double radius,
  }) {
    if (px < 0 || py < 0 || px > width || py > height) {
      return false;
    }

    final left = radius;
    final right = width - radius;
    final top = radius;
    final bottom = height - radius;

    if (px >= left && px <= right) {
      return py >= 0 && py <= height;
    }
    if (py >= top && py <= bottom) {
      return px >= 0 && px <= width;
    }

    final cornerCenterX = px < left ? left : right;
    final cornerCenterY = py < top ? top : bottom;
    final dx = px - cornerCenterX;
    final dy = py - cornerCenterY;
    return (dx * dx) + (dy * dy) <= radius * radius;
  }

  Directory? _findProjectRoot() {
    if (!Platform.isMacOS) {
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
      final hasMacOSIconSet = Directory(
        p.join(
          current.path,
          'macos',
          'Runner',
          'Assets.xcassets',
          'AppIcon.appiconset',
        ),
      ).existsSync();
      if (hasPubspec && hasMacOSIconSet) {
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
