import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

enum AppIconPreset {
  orbital,
  sunrise,
  neonPulse,
  terminalCore,
  navigator,
}

enum AppIconMode {
  preset,
  custom,
}

class AppIconSelection {
  const AppIconSelection({
    required this.mode,
    required this.preset,
    required this.windowIconPath,
    required this.revision,
    this.customImagePath,
  });

  final AppIconMode mode;
  final AppIconPreset preset;
  final String windowIconPath;
  final int revision;
  final String? customImagePath;

  bool get isCustom =>
      mode == AppIconMode.custom &&
      customImagePath != null &&
      customImagePath!.trim().isNotEmpty;

  bool get isPreset => !isCustom;

  String get cacheKey =>
      '$windowIconPath#$revision#${mode.name}#${preset.name}';

  AppIconSelection copyWith({
    AppIconMode? mode,
    AppIconPreset? preset,
    String? windowIconPath,
    int? revision,
    String? customImagePath,
    bool clearCustomImage = false,
  }) {
    return AppIconSelection(
      mode: mode ?? this.mode,
      preset: preset ?? this.preset,
      windowIconPath: windowIconPath ?? this.windowIconPath,
      revision: revision ?? this.revision,
      customImagePath:
          clearCustomImage ? null : (customImagePath ?? this.customImagePath),
    );
  }
}

final appIconStorageProvider = Provider<AppIconStorage>((ref) {
  return AppIconStorage();
});

final appIconControllerProvider =
    AsyncNotifierProvider<AppIconController, AppIconSelection>(
  AppIconController.new,
);

class AppIconStorage {
  Future<AppIconSelection> read() async {
    final settingsFile = await _settingsFile();
    final generatedIcon = await _windowIconFile();
    var mode = AppIconMode.preset;
    var preset = AppIconPreset.orbital;

    if (await settingsFile.exists()) {
      try {
        final raw = jsonDecode(await settingsFile.readAsString());
        if (raw is Map<String, dynamic>) {
          final rawMode = raw['mode'];
          if (rawMode is String) {
            mode = AppIconMode.values.firstWhere(
              (value) => value.name == rawMode,
              orElse: () => AppIconMode.preset,
            );
          }
          final rawPreset = raw['app_icon'];
          if (rawPreset is String) {
            preset = AppIconPreset.values.firstWhere(
              (value) => value.name == rawPreset,
              orElse: () => AppIconPreset.orbital,
            );
          }
        }
      } on FormatException {
        mode = AppIconMode.preset;
        preset = AppIconPreset.orbital;
      }
    }

    if (mode == AppIconMode.custom && await generatedIcon.exists()) {
      return _selectionForFile(
        generatedIcon,
        mode: AppIconMode.custom,
        preset: preset,
        customImagePath: generatedIcon.path,
      );
    }

    await _writePresetWindowIcon(preset);
    return _selectionForFile(
      generatedIcon,
      mode: AppIconMode.preset,
      preset: preset,
    );
  }

  Future<AppIconSelection> writePreset(AppIconPreset preset) async {
    await _writeSettings(
      mode: AppIconMode.preset,
      preset: preset,
    );
    final file = await _writePresetWindowIcon(preset);
    return _selectionForFile(
      file,
      mode: AppIconMode.preset,
      preset: preset,
    );
  }

  Future<AppIconSelection> writeCustomImage(String sourcePath) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw Exception('Selected image file does not exist.');
    }

    final decoded = img.decodeImage(await sourceFile.readAsBytes());
    if (decoded == null) {
      throw Exception('Unsupported image format.');
    }

    final output = await _windowIconFile();
    await output.parent.create(recursive: true);
    final normalized = _normalizeIcon(decoded);
    await output.writeAsBytes(img.encodePng(normalized), flush: true);
    await _writeSettings(
      mode: AppIconMode.custom,
      preset: AppIconPreset.orbital,
    );
    return _selectionForFile(
      output,
      mode: AppIconMode.custom,
      preset: AppIconPreset.orbital,
      customImagePath: output.path,
    );
  }

  Future<AppIconSelection> reset() {
    return writePreset(AppIconPreset.orbital);
  }

  Future<void> _writeSettings({
    required AppIconMode mode,
    required AppIconPreset preset,
  }) async {
    final file = await _settingsFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'mode': mode.name,
        'app_icon': preset.name,
      }),
      flush: true,
    );
  }

  Future<AppIconSelection> _selectionForFile(
    File file, {
    required AppIconMode mode,
    required AppIconPreset preset,
    String? customImagePath,
  }) async {
    final stat = await file.stat();
    return AppIconSelection(
      mode: mode,
      preset: preset,
      windowIconPath: file.path,
      revision: stat.modified.millisecondsSinceEpoch,
      customImagePath: customImagePath,
    );
  }

  Future<File> _writePresetWindowIcon(AppIconPreset preset) async {
    final file = await _windowIconFile();
    await file.parent.create(recursive: true);
    final image = _renderPresetImage(preset);
    await file.writeAsBytes(img.encodePng(image), flush: true);
    return file;
  }

  img.Image _renderPresetImage(AppIconPreset preset) {
    final image = img.Image(width: 256, height: 256, numChannels: 4);
    switch (preset) {
      case AppIconPreset.orbital:
        _fillDiagonalGradient(
          image,
          const [
            _Rgb(0x31, 0x5C, 0xFF),
            _Rgb(0x4E, 0x84, 0xFF),
            _Rgb(0x8C, 0xC8, 0xFF),
          ],
        );
        img.drawCircle(
          image,
          x: 128,
          y: 128,
          radius: 78,
          color: img.ColorRgba8(255, 255, 255, 170),
          antialias: true,
        );
        img.fillCircle(
          image,
          x: 182,
          y: 74,
          radius: 12,
          color: img.ColorRgba8(255, 255, 255, 255),
          antialias: true,
        );
        img.fillRect(
          image,
          x1: 92,
          y1: 92,
          x2: 164,
          y2: 170,
          color: img.ColorRgba8(255, 255, 255, 255),
          radius: 18,
        );
        for (final y in [114, 132, 150]) {
          img.drawLine(
            image,
            x1: 104,
            y1: y,
            x2: 152,
            y2: y,
            color: img.ColorRgba8(0x31, 0x5C, 0xFF, 255),
            thickness: 8,
          );
        }
        break;
      case AppIconPreset.sunrise:
        _fillVerticalGradient(
          image,
          const [
            _Rgb(0xFF, 0xF2, 0xD8),
            _Rgb(0xFF, 0xC9, 0x87),
            _Rgb(0xFF, 0x9A, 0x5A),
          ],
        );
        img.fillRect(
          image,
          x1: 46,
          y1: 176,
          x2: 210,
          y2: 192,
          color: img.ColorRgba8(255, 255, 255, 180),
          radius: 999,
        );
        img.fillCircle(
          image,
          x: 128,
          y: 152,
          radius: 46,
          color: img.ColorRgba8(255, 247, 234, 255),
          antialias: true,
        );
        img.fillRect(
          image,
          x1: 92,
          y1: 78,
          x2: 164,
          y2: 156,
          color: img.ColorRgba8(0xFF, 0xF7, 0xEA, 255),
          radius: 18,
        );
        img.drawLine(
          image,
          x1: 108,
          y1: 106,
          x2: 148,
          y2: 106,
          color: img.ColorRgba8(0x8E, 0x45, 0x1A, 255),
          thickness: 6,
        );
        img.drawLine(
          image,
          x1: 108,
          y1: 126,
          x2: 148,
          y2: 126,
          color: img.ColorRgba8(0x8E, 0x45, 0x1A, 255),
          thickness: 6,
        );
        break;
      case AppIconPreset.neonPulse:
        _fillDiagonalGradient(
          image,
          const [
            _Rgb(0x0D, 0x04, 0x1A),
            _Rgb(0x1B, 0x0A, 0x2A),
            _Rgb(0x29, 0x0D, 0x3A),
          ],
        );
        img.drawRect(
          image,
          x1: 48,
          y1: 48,
          x2: 208,
          y2: 208,
          color: img.ColorRgba8(0x00, 0xF6, 0xFF, 200),
          thickness: 6,
          radius: 28,
        );
        img.fillRect(
          image,
          x1: 42,
          y1: 42,
          x2: 90,
          y2: 58,
          color: img.ColorRgba8(0xFF, 0x47, 0xA6, 255),
        );
        img.drawLine(
          image,
          x1: 148,
          y1: 84,
          x2: 112,
          y2: 134,
          color: img.ColorRgba8(0x00, 0xF6, 0xFF, 255),
          thickness: 18,
        );
        img.drawLine(
          image,
          x1: 112,
          y1: 134,
          x2: 150,
          y2: 134,
          color: img.ColorRgba8(0x00, 0xF6, 0xFF, 255),
          thickness: 18,
        );
        img.drawLine(
          image,
          x1: 150,
          y1: 134,
          x2: 108,
          y2: 188,
          color: img.ColorRgba8(0x00, 0xF6, 0xFF, 255),
          thickness: 18,
        );
        break;
      case AppIconPreset.terminalCore:
        _fillVerticalGradient(
          image,
          const [
            _Rgb(0x05, 0x11, 0x05),
            _Rgb(0x08, 0x18, 0x08),
            _Rgb(0x04, 0x10, 0x04),
          ],
        );
        img.drawRect(
          image,
          x1: 42,
          y1: 42,
          x2: 214,
          y2: 214,
          color: img.ColorRgba8(0x5C, 0xFF, 0x6A, 160),
          thickness: 6,
          radius: 24,
        );
        img.drawLine(
          image,
          x1: 88,
          y1: 120,
          x2: 116,
          y2: 144,
          color: img.ColorRgba8(0x5C, 0xFF, 0x6A, 255),
          thickness: 10,
        );
        img.drawLine(
          image,
          x1: 88,
          y1: 168,
          x2: 116,
          y2: 144,
          color: img.ColorRgba8(0x5C, 0xFF, 0x6A, 255),
          thickness: 10,
        );
        img.drawLine(
          image,
          x1: 130,
          y1: 172,
          x2: 170,
          y2: 172,
          color: img.ColorRgba8(0x5C, 0xFF, 0x6A, 255),
          thickness: 10,
        );
        img.drawLine(
          image,
          x1: 160,
          y1: 132,
          x2: 176,
          y2: 188,
          color: img.ColorRgba8(0x5C, 0xFF, 0x6A, 255),
          thickness: 8,
        );
        break;
      case AppIconPreset.navigator:
        _fillDiagonalGradient(
          image,
          const [
            _Rgb(0xF7, 0xFB, 0xFF),
            _Rgb(0xDD, 0xE9, 0xFF),
            _Rgb(0xB7, 0xD1, 0xFF),
          ],
        );
        img.drawRect(
          image,
          x1: 40,
          y1: 40,
          x2: 216,
          y2: 216,
          color: img.ColorRgba8(0x4A, 0x63, 0xFF, 110),
          thickness: 5,
          radius: 30,
        );
        img.drawCircle(
          image,
          x: 128,
          y: 128,
          radius: 58,
          color: img.ColorRgba8(0x31, 0x5C, 0xFF, 180),
          antialias: true,
        );
        img.drawLine(
          image,
          x1: 128,
          y1: 86,
          x2: 166,
          y2: 160,
          color: img.ColorRgba8(0x31, 0x5C, 0xFF, 255),
          thickness: 14,
        );
        img.drawLine(
          image,
          x1: 166,
          y1: 160,
          x2: 126,
          y2: 142,
          color: img.ColorRgba8(0x31, 0x5C, 0xFF, 255),
          thickness: 14,
        );
        break;
    }

    return image;
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

  void _fillVerticalGradient(img.Image image, List<_Rgb> colors) {
    for (var y = 0; y < image.height; y++) {
      final color = _sampleGradient(colors, y / (image.height - 1));
      for (var x = 0; x < image.width; x++) {
        image.setPixelRgba(x, y, color.r, color.g, color.b, 255);
      }
    }
  }

  void _fillDiagonalGradient(img.Image image, List<_Rgb> colors) {
    final maxDistance = (image.width - 1) + (image.height - 1);
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final t = (x + y) / maxDistance;
        final color = _sampleGradient(colors, t);
        image.setPixelRgba(x, y, color.r, color.g, color.b, 255);
      }
    }
  }

  _Rgb _sampleGradient(List<_Rgb> colors, double t) {
    if (colors.length == 1) return colors.first;
    final clamped = t.clamp(0.0, 1.0);
    final segmentSize = 1 / (colors.length - 1);
    final index = (clamped / segmentSize).floor().clamp(0, colors.length - 2);
    final localT = (clamped - (index * segmentSize)) / segmentSize;
    return _Rgb.lerp(colors[index], colors[index + 1], localT);
  }

  Future<File> _settingsFile() async {
    final documents = await getApplicationDocumentsDirectory();
    final settingsDir = Directory(
      p.join(documents.path, 'diary_mvp', 'settings'),
    );
    return File(p.join(settingsDir.path, 'app_icon_settings.json'));
  }

  Future<File> _windowIconFile() async {
    final documents = await getApplicationDocumentsDirectory();
    final settingsDir = Directory(
      p.join(documents.path, 'diary_mvp', 'settings'),
    );
    return File(p.join(settingsDir.path, 'app_icon_window.png'));
  }
}

class AppIconController extends AsyncNotifier<AppIconSelection> {
  AppIconStorage get _storage => ref.read(appIconStorageProvider);

  @override
  Future<AppIconSelection> build() {
    return _storage.read();
  }

  Future<void> setPreset(AppIconPreset preset) async {
    final previous = state.valueOrNull;

    try {
      final selection = await _storage.writePreset(preset);
      state = AsyncData(selection);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      if (previous != null) {
        state = AsyncData(previous);
      }
      rethrow;
    }
  }

  Future<void> setCustomImage(String sourcePath) async {
    final previous = state.valueOrNull;

    try {
      final selection = await _storage.writeCustomImage(sourcePath);
      state = AsyncData(selection);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      if (previous != null) {
        state = AsyncData(previous);
      }
      rethrow;
    }
  }

  Future<void> reset() async {
    final previous = state.valueOrNull;

    try {
      final selection = await _storage.reset();
      state = AsyncData(selection);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      if (previous != null) {
        state = AsyncData(previous);
      }
      rethrow;
    }
  }
}

AppIconSelection resolveAppIconSelection(
    AsyncValue<AppIconSelection> iconAsync) {
  return iconAsync.maybeWhen(
    data: (selection) => selection,
    orElse: () => const AppIconSelection(
      mode: AppIconMode.preset,
      preset: AppIconPreset.orbital,
      windowIconPath: '',
      revision: 0,
    ),
  );
}

AppIconPreset resolveAppIconPreset(AsyncValue<AppIconSelection> iconAsync) {
  return resolveAppIconSelection(iconAsync).preset;
}

class AppIconBadge extends StatelessWidget {
  const AppIconBadge({
    super.key,
    this.selection,
    this.preset,
    this.size = 32,
  }) : assert(selection != null || preset != null);

  final AppIconSelection? selection;
  final AppIconPreset? preset;
  final double size;

  @override
  Widget build(BuildContext context) {
    final resolvedSelection = selection;
    final resolvedPreset =
        resolvedSelection?.preset ?? preset ?? AppIconPreset.orbital;
    final radius = BorderRadius.circular(size * 0.28);

    if (resolvedSelection?.isCustom == true) {
      final imagePath = resolvedSelection!.customImagePath!;
      return ClipRRect(
        borderRadius: radius,
        child: SizedBox(
          width: size,
          height: size,
          child: Image.file(
            File(imagePath),
            key: ValueKey('${resolvedSelection.cacheKey}#$size'),
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) {
              return _buildPresetBadge(resolvedPreset, radius);
            },
          ),
        ),
      );
    }

    return _buildPresetBadge(resolvedPreset, radius);
  }

  Widget _buildPresetBadge(AppIconPreset resolvedPreset, BorderRadius radius) {
    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: _decorationForPreset(resolvedPreset),
          child: Stack(
            fit: StackFit.expand,
            children: _layersForPreset(resolvedPreset),
          ),
        ),
      ),
    );
  }

  BoxDecoration _decorationForPreset(AppIconPreset resolvedPreset) {
    switch (resolvedPreset) {
      case AppIconPreset.orbital:
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF315CFF),
              Color(0xFF4E84FF),
              Color(0xFF8CC8FF),
            ],
          ),
        );
      case AppIconPreset.sunrise:
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF2D8),
              Color(0xFFFFC987),
              Color(0xFFFF9A5A),
            ],
          ),
        );
      case AppIconPreset.neonPulse:
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D041A),
              Color(0xFF1B0A2A),
              Color(0xFF290D3A),
            ],
          ),
        );
      case AppIconPreset.terminalCore:
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF051105),
              Color(0xFF081808),
              Color(0xFF041004),
            ],
          ),
        );
      case AppIconPreset.navigator:
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF7FBFF),
              Color(0xFFDDE9FF),
              Color(0xFFB7D1FF),
            ],
          ),
        );
    }
  }

  List<Widget> _layersForPreset(AppIconPreset resolvedPreset) {
    switch (resolvedPreset) {
      case AppIconPreset.orbital:
        return [
          Positioned(
            left: size * 0.18,
            top: size * 0.18,
            right: size * 0.18,
            bottom: size * 0.18,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.58)),
              ),
            ),
          ),
          Positioned(
            right: size * 0.14,
            top: size * 0.22,
            child: Container(
              width: size * 0.12,
              height: size * 0.12,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Center(
            child: Icon(
              Icons.auto_stories_rounded,
              color: Colors.white,
              size: size * 0.48,
            ),
          ),
        ];
      case AppIconPreset.sunrise:
        return [
          Positioned(
            left: size * 0.18,
            right: size * 0.18,
            bottom: size * 0.2,
            child: Container(
              height: size * 0.08,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.62),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            left: size * 0.27,
            right: size * 0.27,
            bottom: size * 0.24,
            child: Container(
              height: size * 0.28,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF7EA),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Center(
            child: Icon(
              Icons.edit_note_rounded,
              color: const Color(0xFF8E451A),
              size: size * 0.46,
            ),
          ),
        ];
      case AppIconPreset.neonPulse:
        return [
          Positioned(
            top: size * 0.18,
            left: size * 0.18,
            right: size * 0.18,
            bottom: size * 0.18,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF00F6FF).withValues(alpha: 0.68),
                ),
                borderRadius: BorderRadius.circular(size * 0.18),
              ),
            ),
          ),
          Positioned(
            left: size * 0.16,
            top: size * 0.16,
            child: Container(
              width: size * 0.18,
              height: size * 0.06,
              color: const Color(0xFFFF47A6),
            ),
          ),
          Center(
            child: Icon(
              Icons.bolt_rounded,
              color: const Color(0xFF00F6FF),
              size: size * 0.48,
            ),
          ),
        ];
      case AppIconPreset.terminalCore:
        return [
          Positioned(
            left: size * 0.16,
            top: size * 0.16,
            right: size * 0.16,
            bottom: size * 0.16,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF5CFF6A).withValues(alpha: 0.56),
                ),
                borderRadius: BorderRadius.circular(size * 0.14),
              ),
            ),
          ),
          Center(
            child: Text(
              '>_',
              style: TextStyle(
                color: const Color(0xFF5CFF6A),
                fontWeight: FontWeight.w800,
                fontSize: size * 0.26,
              ),
            ),
          ),
        ];
      case AppIconPreset.navigator:
        return [
          Positioned(
            top: size * 0.16,
            left: size * 0.16,
            right: size * 0.16,
            bottom: size * 0.16,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF4A63FF).withValues(alpha: 0.38),
                ),
                borderRadius: BorderRadius.circular(size * 0.2),
              ),
            ),
          ),
          Center(
            child: Icon(
              Icons.explore_rounded,
              color: const Color(0xFF315CFF),
              size: size * 0.46,
            ),
          ),
        ];
    }
  }
}

class _Rgb {
  const _Rgb(this.r, this.g, this.b);

  final int r;
  final int g;
  final int b;

  static _Rgb lerp(_Rgb a, _Rgb b, double t) {
    return _Rgb(
      (a.r + ((b.r - a.r) * t)).round(),
      (a.g + ((b.g - a.g) * t)).round(),
      (a.b + ((b.b - a.b) * t)).round(),
    );
  }
}
