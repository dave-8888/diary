import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

enum AppIconPreset {
  orbital,
  sunrise,
  neonPulse,
  terminalCore,
  navigator,
}

final appIconStorageProvider = Provider<AppIconStorage>((ref) {
  return AppIconStorage();
});

final appIconControllerProvider =
    AsyncNotifierProvider<AppIconController, AppIconPreset>(
  AppIconController.new,
);

class AppIconStorage {
  Future<AppIconPreset> read() async {
    final file = await _settingsFile();
    if (!await file.exists()) return AppIconPreset.orbital;

    try {
      final raw = jsonDecode(await file.readAsString());
      if (raw is! Map<String, dynamic>) return AppIconPreset.orbital;
      final value = raw['app_icon'];
      if (value is! String) return AppIconPreset.orbital;
      return AppIconPreset.values.firstWhere(
        (preset) => preset.name == value,
        orElse: () => AppIconPreset.orbital,
      );
    } on FormatException {
      return AppIconPreset.orbital;
    }
  }

  Future<void> write(AppIconPreset preset) async {
    final file = await _settingsFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'app_icon': preset.name,
      }),
      flush: true,
    );
  }

  Future<File> _settingsFile() async {
    final documents = await getApplicationDocumentsDirectory();
    final settingsDir = Directory(
      p.join(documents.path, 'diary_mvp', 'settings'),
    );
    return File(p.join(settingsDir.path, 'app_icon_settings.json'));
  }
}

class AppIconController extends AsyncNotifier<AppIconPreset> {
  AppIconStorage get _storage => ref.read(appIconStorageProvider);

  @override
  Future<AppIconPreset> build() {
    return _storage.read();
  }

  Future<void> setIcon(AppIconPreset preset) async {
    final previous = state.valueOrNull ?? AppIconPreset.orbital;
    state = AsyncData(preset);

    try {
      await _storage.write(preset);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> reset() {
    return setIcon(AppIconPreset.orbital);
  }
}

AppIconPreset resolveAppIconPreset(AsyncValue<AppIconPreset> iconAsync) {
  return iconAsync.maybeWhen(
    data: (preset) => preset,
    orElse: () => AppIconPreset.orbital,
  );
}

class AppIconBadge extends StatelessWidget {
  const AppIconBadge({
    super.key,
    required this.preset,
    this.size = 32,
  });

  final AppIconPreset preset;
  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.28);

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: _decorationForPreset(),
          child: Stack(
            fit: StackFit.expand,
            children: _layersForPreset(context),
          ),
        ),
      ),
    );
  }

  BoxDecoration _decorationForPreset() {
    switch (preset) {
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

  List<Widget> _layersForPreset(BuildContext context) {
    switch (preset) {
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
