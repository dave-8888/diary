import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

enum DiaryThemePreset {
  daylight,
  night,
  cyberpunk,
  hacker,
  spaceLines,
}

final appThemeStorageProvider = Provider<AppThemeStorage>((ref) {
  return AppThemeStorage();
});

final appThemeControllerProvider =
    AsyncNotifierProvider<AppThemeController, DiaryThemePreset>(
  AppThemeController.new,
);

class AppThemeStorage {
  Future<DiaryThemePreset> read() async {
    final file = await _settingsFile();
    if (!await file.exists()) return DiaryThemePreset.daylight;

    try {
      final raw = jsonDecode(await file.readAsString());
      if (raw is! Map<String, dynamic>) return DiaryThemePreset.daylight;
      final value = raw['theme'];
      if (value is! String) return DiaryThemePreset.daylight;

      return DiaryThemePreset.values.firstWhere(
        (theme) => theme.name == value,
        orElse: () => DiaryThemePreset.daylight,
      );
    } on FormatException {
      return DiaryThemePreset.daylight;
    }
  }

  Future<void> write(DiaryThemePreset theme) async {
    final file = await _settingsFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'theme': theme.name,
      }),
      flush: true,
    );
  }

  Future<File> _settingsFile() async {
    final documents = await getApplicationDocumentsDirectory();
    final settingsDir = Directory(
      p.join(documents.path, 'diary_mvp', 'settings'),
    );
    return File(p.join(settingsDir.path, 'theme_settings.json'));
  }
}

class AppThemeController extends AsyncNotifier<DiaryThemePreset> {
  AppThemeStorage get _storage => ref.read(appThemeStorageProvider);

  @override
  Future<DiaryThemePreset> build() {
    return _storage.read();
  }

  Future<void> setTheme(DiaryThemePreset theme) async {
    final previous = state.valueOrNull ?? DiaryThemePreset.daylight;
    state = AsyncData(theme);

    try {
      await _storage.write(theme);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      state = AsyncData(previous);
      rethrow;
    }
  }
}

DiaryThemePreset resolveThemePreset(AsyncValue<DiaryThemePreset> themeAsync) {
  return themeAsync.maybeWhen(
    data: (theme) => theme,
    orElse: () => DiaryThemePreset.daylight,
  );
}

ThemeData buildDiaryTheme(DiaryThemePreset preset) {
  switch (preset) {
    case DiaryThemePreset.daylight:
      return _buildTheme(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF28666E),
          brightness: Brightness.light,
        ),
        scaffoldColor: const Color(0xFFF6F3EE),
        cardColor: Colors.white,
        inputFillColor: Colors.white,
        cardRadius: 24,
      );
    case DiaryThemePreset.night:
      return _buildTheme(
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: Color(0xFF8ED3FF),
          onPrimary: Color(0xFF042135),
          secondary: Color(0xFFB7A6FF),
          onSecondary: Color(0xFF190C3B),
          error: Color(0xFFFF8A80),
          onError: Color(0xFF3E0603),
          surface: Color(0xFF171D29),
          onSurface: Color(0xFFEAF1FF),
        ),
        scaffoldColor: const Color(0xFF0D121C),
        cardColor: const Color(0xFF171D29),
        inputFillColor: const Color(0xFF1D2534),
        outlineColor: const Color(0xFF30405C),
        cardRadius: 24,
      );
    case DiaryThemePreset.cyberpunk:
      return _buildTheme(
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: Color(0xFF00F6FF),
          onPrimary: Color(0xFF001E20),
          secondary: Color(0xFFFF47A6),
          onSecondary: Color(0xFF2E0016),
          error: Color(0xFFFF7B7B),
          onError: Color(0xFF300404),
          surface: Color(0xFF180C2C),
          onSurface: Color(0xFFF8EDFF),
        ),
        scaffoldColor: const Color(0xFF090312),
        cardColor: const Color(0xFF150A24),
        inputFillColor: const Color(0xFF1B0F30),
        outlineColor: const Color(0x66FF47A6),
        cardRadius: 22,
      );
    case DiaryThemePreset.hacker:
      return _buildTheme(
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: Color(0xFF5CFF6A),
          onPrimary: Color(0xFF022406),
          secondary: Color(0xFF9CFF9F),
          onSecondary: Color(0xFF08240A),
          error: Color(0xFFFF6D6D),
          onError: Color(0xFF300303),
          surface: Color(0xFF0A120A),
          onSurface: Color(0xFFB9FFB3),
        ),
        scaffoldColor: const Color(0xFF030703),
        cardColor: const Color(0xFF081008),
        inputFillColor: const Color(0xFF0B150B),
        outlineColor: const Color(0xFF245C2A),
        cardRadius: 18,
      );
    case DiaryThemePreset.spaceLines:
      return _buildTheme(
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF4A63FF),
          onPrimary: Colors.white,
          secondary: Color(0xFF7C8BA3),
          onSecondary: Colors.white,
          error: Color(0xFFD63B56),
          onError: Colors.white,
          surface: Colors.white,
          onSurface: Color(0xFF142033),
        ),
        scaffoldColor: const Color(0xFFF2F6FF),
        cardColor: const Color(0xFFFCFDFF),
        inputFillColor: Colors.white,
        outlineColor: const Color(0xFFC8D4E8),
        cardRadius: 16,
        emphasizeLines: true,
      );
  }
}

ThemeData _buildTheme({
  required ColorScheme colorScheme,
  required Color scaffoldColor,
  required Color cardColor,
  required Color inputFillColor,
  required double cardRadius,
  Color? outlineColor,
  bool emphasizeLines = false,
}) {
  final borderColor = outlineColor ?? colorScheme.outlineVariant;
  final dividerColor = borderColor.withValues(alpha: 0.9);
  final textTheme = TextTheme(
    headlineMedium: TextStyle(
      fontWeight: FontWeight.w700,
      color: colorScheme.onSurface,
      letterSpacing: emphasizeLines ? 0.2 : 0,
    ),
    titleLarge: TextStyle(
      fontWeight: FontWeight.w700,
      color: colorScheme.onSurface,
      letterSpacing: emphasizeLines ? 0.12 : 0,
    ),
    titleMedium: TextStyle(
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurface,
    ),
    bodyLarge: TextStyle(
      color: colorScheme.onSurface,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      color: colorScheme.onSurface,
      height: 1.4,
    ),
    bodySmall: TextStyle(
      color: colorScheme.onSurface.withValues(alpha: 0.72),
    ),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: scaffoldColor,
    textTheme: textTheme,
    dividerColor: dividerColor,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: textTheme.titleLarge,
      iconTheme: IconThemeData(color: colorScheme.onSurface),
    ),
    cardTheme: CardThemeData(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        side: BorderSide(
          color: emphasizeLines
              ? borderColor
              : borderColor.withValues(alpha: 0.45),
          width: emphasizeLines ? 1.2 : 0.8,
        ),
      ),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        side: BorderSide(
          color:
              emphasizeLines ? borderColor : borderColor.withValues(alpha: 0.4),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: inputFillColor,
      labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      hintStyle: TextStyle(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.72),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(cardRadius - 6),
        borderSide: BorderSide(
          color: emphasizeLines ? borderColor : Colors.transparent,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(cardRadius - 6),
        borderSide: BorderSide(
          color: emphasizeLines ? borderColor : Colors.transparent,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(cardRadius - 6),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius - 8),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.onSurface,
        side: BorderSide(color: borderColor),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius - 8),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor:
          colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
      selectedColor: colorScheme.secondaryContainer,
      secondarySelectedColor: colorScheme.secondaryContainer,
      deleteIconColor: colorScheme.onSurfaceVariant,
      labelStyle: TextStyle(color: colorScheme.onSurface),
      secondaryLabelStyle: TextStyle(color: colorScheme.onSecondaryContainer),
      side: BorderSide(color: borderColor.withValues(alpha: 0.45)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius - 10),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
      behavior: SnackBarBehavior.floating,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: cardColor,
      indicatorColor: colorScheme.secondaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final color = states.contains(WidgetState.selected)
            ? colorScheme.onSurface
            : colorScheme.onSurfaceVariant;
        return TextStyle(color: color, fontWeight: FontWeight.w600);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final color = states.contains(WidgetState.selected)
            ? colorScheme.onSecondaryContainer
            : colorScheme.onSurfaceVariant;
        return IconThemeData(color: color);
      }),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: scaffoldColor,
      indicatorColor: colorScheme.secondaryContainer,
      selectedIconTheme: IconThemeData(color: colorScheme.onSecondaryContainer),
      unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
      selectedLabelTextStyle: TextStyle(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: TextStyle(color: colorScheme.onSurfaceVariant),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius - 6),
        side: BorderSide(color: borderColor.withValues(alpha: 0.5)),
      ),
    ),
  );
}
