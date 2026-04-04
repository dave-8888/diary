import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

enum DiaryThemePreset {
  daylight,
  girlPink,
  barbieShockPink,
  kidPink,
  happyBoy,
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
          seedColor: const Color(0xFF0F7CFF),
          brightness: Brightness.light,
        ),
        scaffoldColor: const Color(0xFFEEF4FF),
        cardColor: const Color(0xFFF9FBFF),
        inputFillColor: const Color(0xFFFFFFFF),
        outlineColor: const Color(0xFFC5D4F0),
        cardRadius: 28,
      );
    case DiaryThemePreset.girlPink:
      return _buildTheme(
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFFD46BA7),
          onPrimary: Colors.white,
          secondary: Color(0xFFF4B5CC),
          onSecondary: Color(0xFF482137),
          error: Color(0xFFCE3D5C),
          onError: Colors.white,
          surface: Color(0xFFFFFBFE),
          onSurface: Color(0xFF3A2430),
        ),
        scaffoldColor: const Color(0xFFFFF5FA),
        cardColor: const Color(0xFFFFFCFE),
        inputFillColor: Colors.white,
        outlineColor: const Color(0xFFE8C2D6),
        cardRadius: 28,
      );
    case DiaryThemePreset.barbieShockPink:
      return _buildTheme(
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFFFF1493),
          onPrimary: Colors.white,
          secondary: Color(0xFFFF72C8),
          onSecondary: Color(0xFF420926),
          error: Color(0xFFCF2354),
          onError: Colors.white,
          surface: Color(0xFFFFF6FB),
          onSurface: Color(0xFF2D0C1D),
        ),
        scaffoldColor: const Color(0xFFFFEEF7),
        cardColor: const Color(0xFFFFFBFE),
        inputFillColor: Colors.white,
        outlineColor: const Color(0xFFFF7BC4),
        cardRadius: 22,
      );
    case DiaryThemePreset.kidPink:
      return _buildTheme(
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFFFF7DB8),
          onPrimary: Colors.white,
          secondary: Color(0xFFFFD35B),
          onSecondary: Color(0xFF4A3500),
          error: Color(0xFFD94868),
          onError: Colors.white,
          surface: Color(0xFFFFFDFA),
          onSurface: Color(0xFF472B37),
        ),
        scaffoldColor: const Color(0xFFFFF9EF),
        cardColor: const Color(0xFFFFFEFC),
        inputFillColor: Colors.white,
        outlineColor: const Color(0xFFF3C4D7),
        cardRadius: 30,
      );
    case DiaryThemePreset.happyBoy:
      return _buildTheme(
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF2395FF),
          onPrimary: Colors.white,
          secondary: Color(0xFFFFB530),
          onSecondary: Color(0xFF4A2D00),
          error: Color(0xFFD94F40),
          onError: Colors.white,
          surface: Color(0xFFFFFEFB),
          onSurface: Color(0xFF15314A),
        ),
        scaffoldColor: const Color(0xFFF3FAFF),
        cardColor: const Color(0xFFFFFFFF),
        inputFillColor: Colors.white,
        outlineColor: const Color(0xFFBDD8F3),
        cardRadius: 24,
      );
    case DiaryThemePreset.night:
      return _buildTheme(
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: Color(0xFF7CE5FF),
          onPrimary: Color(0xFF032432),
          secondary: Color(0xFF8FA2FF),
          onSecondary: Color(0xFF11193F),
          error: Color(0xFFFF8A80),
          onError: Color(0xFF3E0603),
          surface: Color(0xFF111A28),
          onSurface: Color(0xFFEAF3FF),
        ),
        scaffoldColor: const Color(0xFF09111D),
        cardColor: const Color(0xFF111A28),
        inputFillColor: const Color(0xFF162335),
        outlineColor: const Color(0xFF2E4766),
        cardRadius: 26,
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
          primary: Color(0xFF2F6BFF),
          onPrimary: Colors.white,
          secondary: Color(0xFF5D86FF),
          onSecondary: Colors.white,
          error: Color(0xFFD63B56),
          onError: Colors.white,
          surface: Color(0xFFFDFEFF),
          onSurface: Color(0xFF142033),
        ),
        scaffoldColor: const Color(0xFFF1F6FF),
        cardColor: const Color(0xFFFBFDFF),
        inputFillColor: Colors.white,
        outlineColor: const Color(0xFFBDD0EB),
        cardRadius: 20,
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
  final isDark = colorScheme.brightness == Brightness.dark;
  const pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
      TargetPlatform.fuchsia: CupertinoPageTransitionsBuilder(),
    },
  );
  final dividerColor = borderColor.withValues(alpha: isDark ? 0.68 : 0.72);
  final layeredCardColor = Color.alphaBlend(
    colorScheme.primary.withValues(alpha: isDark ? 0.16 : 0.05),
    cardColor,
  );
  final layeredSurfaceColor = Color.alphaBlend(
    colorScheme.secondary.withValues(alpha: isDark ? 0.12 : 0.04),
    colorScheme.surface,
  );
  final resolvedInputFillColor = Color.alphaBlend(
    colorScheme.surface.withValues(alpha: isDark ? 0.22 : 0.55),
    inputFillColor,
  );
  final textTheme = TextTheme(
    displaySmall: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.2,
      color: colorScheme.onSurface,
    ),
    headlineMedium: TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.w800,
      color: colorScheme.onSurface,
      letterSpacing: emphasizeLines ? 0.24 : -0.6,
    ),
    titleLarge: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: colorScheme.onSurface,
      letterSpacing: emphasizeLines ? 0.16 : -0.24,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: colorScheme.onSurface,
      letterSpacing: 0.12,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: colorScheme.onSurface,
      letterSpacing: 0.16,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      color: colorScheme.onSurface,
      height: 1.55,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      color: colorScheme.onSurface,
      height: 1.5,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      color: colorScheme.onSurface.withValues(alpha: 0.72),
      height: 1.35,
    ),
    labelLarge: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: colorScheme.onSurface,
      letterSpacing: 0.18,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurfaceVariant,
      letterSpacing: 0.22,
    ),
  );
  final cupertinoTextTheme = CupertinoTextThemeData(
    primaryColor: colorScheme.primary,
    textStyle: textTheme.bodyLarge,
    actionTextStyle: textTheme.bodyLarge?.copyWith(
      color: colorScheme.primary,
      fontWeight: FontWeight.w600,
    ),
    actionSmallTextStyle: textTheme.bodyMedium?.copyWith(
      color: colorScheme.primary,
      fontWeight: FontWeight.w600,
    ),
    tabLabelTextStyle: textTheme.labelMedium?.copyWith(
      color: colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    ),
    navTitleTextStyle: textTheme.titleMedium?.copyWith(
      color: colorScheme.onSurface,
      fontWeight: FontWeight.w700,
    ),
    navLargeTitleTextStyle: textTheme.displaySmall?.copyWith(
      color: colorScheme.onSurface,
      fontWeight: FontWeight.w700,
    ),
    navActionTextStyle: textTheme.bodyLarge?.copyWith(
      color: colorScheme.primary,
      fontWeight: FontWeight.w600,
    ),
    pickerTextStyle: textTheme.titleMedium?.copyWith(
      color: colorScheme.onSurface,
      fontWeight: FontWeight.w500,
    ),
    dateTimePickerTextStyle: textTheme.titleMedium?.copyWith(
      color: colorScheme.onSurface,
      fontWeight: FontWeight.w500,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    platform: TargetPlatform.iOS,
    colorScheme: colorScheme,
    cupertinoOverrideTheme: NoDefaultCupertinoThemeData(
      brightness: colorScheme.brightness,
      primaryColor: colorScheme.primary,
      primaryContrastingColor: colorScheme.onPrimary,
      scaffoldBackgroundColor: scaffoldColor,
      barBackgroundColor: layeredCardColor.withValues(alpha: isDark ? 0.86 : 0.9),
      textTheme: cupertinoTextTheme,
    ),
    pageTransitionsTheme: pageTransitions,
    scaffoldBackgroundColor: scaffoldColor,
    canvasColor: scaffoldColor,
    textTheme: textTheme,
    dividerColor: dividerColor,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    splashColor: Colors.transparent,
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colorScheme.primary,
      circularTrackColor: colorScheme.primary.withValues(alpha: 0.12),
    ),
    dividerTheme: DividerThemeData(
      color: dividerColor,
      thickness: emphasizeLines ? 1.1 : 1,
      space: 1,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 76,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: textTheme.titleLarge,
      iconTheme: IconThemeData(color: colorScheme.onSurface),
    ),
    cardTheme: CardThemeData(
      color: layeredCardColor.withValues(alpha: isDark ? 0.9 : 0.84),
      elevation: 0,
      shadowColor: colorScheme.shadow.withValues(alpha: isDark ? 0.2 : 0.08),
      surfaceTintColor: Colors.transparent,
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
      backgroundColor: layeredCardColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        side: BorderSide(
          color:
              emphasizeLines ? borderColor : borderColor.withValues(alpha: 0.4),
        ),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: layeredCardColor,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: layeredCardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(cardRadius + 2),
        ),
        side: BorderSide(color: borderColor.withValues(alpha: 0.42)),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardRadius - 10),
          ),
        ),
        side: WidgetStateProperty.resolveWith(
          (states) => BorderSide(
            color: states.contains(WidgetState.selected)
                ? colorScheme.primary.withValues(alpha: 0.16)
                : borderColor.withValues(alpha: 0.32),
          ),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary.withValues(alpha: isDark ? 0.26 : 0.12);
          }
          return resolvedInputFillColor.withValues(alpha: isDark ? 0.72 : 0.82);
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.onSurfaceVariant;
        }),
        textStyle: WidgetStateProperty.all(
          textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: resolvedInputFillColor.withValues(alpha: isDark ? 0.76 : 0.9),
      labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      hintStyle: TextStyle(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.72),
      ),
      floatingLabelStyle: TextStyle(
        color: colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
      prefixIconColor: colorScheme.onSurfaceVariant,
      suffixIconColor: colorScheme.onSurfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(cardRadius - 6),
        borderSide: const BorderSide(
          color: Colors.transparent,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(cardRadius - 6),
        borderSide: const BorderSide(
          color: Colors.transparent,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(cardRadius - 6),
        borderSide: BorderSide(
          color: colorScheme.primary.withValues(alpha: 0.38),
          width: 1.2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(cardRadius - 6),
        borderSide: BorderSide(
          color: colorScheme.error.withValues(alpha: 0.34),
          width: 1.1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(cardRadius - 6),
        borderSide: BorderSide(
          color: colorScheme.error.withValues(alpha: 0.42),
          width: 1.2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: colorScheme.primary,
      selectionColor: colorScheme.primary.withValues(alpha: 0.24),
      selectionHandleColor: colorScheme.primary,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      elevation: 0,
      extendedPadding: const EdgeInsets.symmetric(horizontal: 18),
      extendedTextStyle: textTheme.labelLarge?.copyWith(
        color: colorScheme.onPrimary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius - 8),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        textStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius - 12),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.onSurface,
        side: BorderSide(color: borderColor.withValues(alpha: 0.42)),
        backgroundColor: resolvedInputFillColor.withValues(
          alpha: isDark ? 0.6 : 0.76,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        textStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius - 12),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.onSurface,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        textStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius - 10),
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: colorScheme.onSurfaceVariant,
        backgroundColor: layeredSurfaceColor.withValues(
          alpha: isDark ? 0.46 : 0.62,
        ),
        hoverColor: colorScheme.primary.withValues(alpha: 0.08),
        highlightColor: colorScheme.primary.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius - 8),
        ),
        padding: const EdgeInsets.all(12),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor:
          layeredSurfaceColor.withValues(alpha: isDark ? 0.5 : 0.74),
      selectedColor: colorScheme.secondaryContainer,
      secondarySelectedColor: colorScheme.secondaryContainer,
      deleteIconColor: colorScheme.onSurfaceVariant,
      labelStyle: textTheme.labelLarge?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      secondaryLabelStyle: TextStyle(color: colorScheme.onSecondaryContainer),
      side: BorderSide(color: borderColor.withValues(alpha: 0.38)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius - 10),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius - 6),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: layeredCardColor.withValues(alpha: isDark ? 0.86 : 0.8),
      height: 78,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      indicatorColor: colorScheme.secondaryContainer.withValues(alpha: 0.86),
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius - 4),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final color = states.contains(WidgetState.selected)
            ? colorScheme.onSurface
            : colorScheme.onSurfaceVariant;
        return textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w600,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final color = states.contains(WidgetState.selected)
            ? colorScheme.onSecondaryContainer
            : colorScheme.onSurfaceVariant;
        return IconThemeData(color: color);
      }),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: Colors.transparent,
      indicatorColor: colorScheme.secondaryContainer.withValues(alpha: 0.86),
      useIndicator: true,
      minWidth: 76,
      minExtendedWidth: 200,
      selectedIconTheme: IconThemeData(color: colorScheme.onSecondaryContainer),
      unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
      selectedLabelTextStyle: TextStyle(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelTextStyle: TextStyle(color: colorScheme.onSurfaceVariant),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: layeredCardColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius - 6),
        side: BorderSide(color: borderColor.withValues(alpha: 0.5)),
      ),
    ),
    listTileTheme: ListTileThemeData(
      dense: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius - 8),
      ),
      iconColor: colorScheme.onSurfaceVariant,
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      side: BorderSide(color: borderColor.withValues(alpha: 0.72)),
    ),
    switchTheme: SwitchThemeData(
      trackOutlineColor: WidgetStateProperty.all(
        borderColor.withValues(alpha: 0.4),
      ),
      thumbIcon: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Icon(Icons.check_rounded, size: 14);
        }
        return const Icon(Icons.close_rounded, size: 14);
      }),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: colorScheme.inverseSurface,
        borderRadius: BorderRadius.circular(cardRadius - 10),
      ),
      textStyle: textTheme.bodySmall?.copyWith(
        color: colorScheme.onInverseSurface,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      preferBelow: false,
    ),
  );
}
