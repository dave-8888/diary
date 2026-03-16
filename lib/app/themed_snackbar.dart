import 'package:diary_mvp/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppSnackBarTone {
  success,
  info,
  warning,
  error,
}

extension AppSnackBarContext on BuildContext {
  void showAppSnackBar(
    String message, {
    AppSnackBarTone tone = AppSnackBarTone.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = ScaffoldMessenger.maybeOf(this);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      buildAppSnackBar(
        this,
        message: message,
        tone: tone,
        duration: duration,
      ),
    );
  }
}

SnackBar buildAppSnackBar(
  BuildContext context, {
  required String message,
  AppSnackBarTone tone = AppSnackBarTone.info,
  Duration duration = const Duration(seconds: 3),
}) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final themeAsync = ProviderScope.containerOf(context, listen: false).read(
    appThemeControllerProvider,
  );
  final preset = resolveThemePreset(themeAsync);
  final palette = _paletteForTheme(preset);
  final toneColor = _toneColor(tone, colorScheme, theme.brightness);
  final iconColor = _mixColor(toneColor, palette.textColor, 0.08);
  final iconBackground = _mixColor(palette.panelColor, toneColor, 0.22);
  final borderColor = _mixColor(palette.borderColor, toneColor, 0.34);

  return SnackBar(
    duration: duration,
    behavior: SnackBarBehavior.floating,
    backgroundColor: Colors.transparent,
    elevation: 0,
    margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
    padding: EdgeInsets.zero,
    content: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.gradientColors,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: palette.shadowColor,
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 72,
            decoration: BoxDecoration(
              color: toneColor,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(20),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: toneColor.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Icon(
                      _iconForTone(tone),
                      size: 20,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: palette.textColor,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    palette.themeIcon,
                    size: 18,
                    color: palette.iconTint,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _SnackBarPalette {
  const _SnackBarPalette({
    required this.gradientColors,
    required this.panelColor,
    required this.borderColor,
    required this.textColor,
    required this.shadowColor,
    required this.iconTint,
    required this.themeIcon,
  });

  final List<Color> gradientColors;
  final Color panelColor;
  final Color borderColor;
  final Color textColor;
  final Color shadowColor;
  final Color iconTint;
  final IconData themeIcon;
}

_SnackBarPalette _paletteForTheme(DiaryThemePreset preset) {
  switch (preset) {
    case DiaryThemePreset.daylight:
      return const _SnackBarPalette(
        gradientColors: [
          Color(0xFFFFFBF6),
          Color(0xFFF2FBFB),
        ],
        panelColor: Color(0xFFF8FEFE),
        borderColor: Color(0xFF8CBEC1),
        textColor: Color(0xFF24464B),
        shadowColor: Color(0x1F28666E),
        iconTint: Color(0xFF28666E),
        themeIcon: Icons.wb_sunny_outlined,
      );
    case DiaryThemePreset.girlPink:
      return const _SnackBarPalette(
        gradientColors: [
          Color(0xFFFFFCFE),
          Color(0xFFFFEAF4),
        ],
        panelColor: Color(0xFFFFF7FB),
        borderColor: Color(0xFFE2A7C4),
        textColor: Color(0xFF4C233A),
        shadowColor: Color(0x1FD46BA7),
        iconTint: Color(0xFFD46BA7),
        themeIcon: Icons.favorite_border,
      );
    case DiaryThemePreset.barbieShockPink:
      return const _SnackBarPalette(
        gradientColors: [
          Color(0xFFFF3FA4),
          Color(0xFFFF7BC4),
        ],
        panelColor: Color(0xFFFF5CB4),
        borderColor: Color(0x66FFFFFF),
        textColor: Colors.white,
        shadowColor: Color(0x33FF1493),
        iconTint: Colors.white,
        themeIcon: Icons.auto_awesome,
      );
    case DiaryThemePreset.kidPink:
      return const _SnackBarPalette(
        gradientColors: [
          Color(0xFFFFFDF6),
          Color(0xFFFFEDF7),
        ],
        panelColor: Color(0xFFFFFBF1),
        borderColor: Color(0xFFF3C4D7),
        textColor: Color(0xFF5A3346),
        shadowColor: Color(0x1FFF7DB8),
        iconTint: Color(0xFFFF7DB8),
        themeIcon: Icons.toys_outlined,
      );
    case DiaryThemePreset.happyBoy:
      return const _SnackBarPalette(
        gradientColors: [
          Color(0xFFF7FCFF),
          Color(0xFFE7F4FF),
        ],
        panelColor: Color(0xFFF5FBFF),
        borderColor: Color(0xFFBDD8F3),
        textColor: Color(0xFF173B57),
        shadowColor: Color(0x1F2395FF),
        iconTint: Color(0xFF2395FF),
        themeIcon: Icons.sports_basketball_outlined,
      );
    case DiaryThemePreset.night:
      return const _SnackBarPalette(
        gradientColors: [
          Color(0xFF1B2433),
          Color(0xFF101826),
        ],
        panelColor: Color(0xFF182131),
        borderColor: Color(0xFF35506F),
        textColor: Color(0xFFEAF1FF),
        shadowColor: Color(0x33000000),
        iconTint: Color(0xFF8ED3FF),
        themeIcon: Icons.dark_mode_outlined,
      );
    case DiaryThemePreset.cyberpunk:
      return const _SnackBarPalette(
        gradientColors: [
          Color(0xFF160A24),
          Color(0xFF241038),
        ],
        panelColor: Color(0xFF180C2C),
        borderColor: Color(0x66FF47A6),
        textColor: Color(0xFFF8EDFF),
        shadowColor: Color(0x33000000),
        iconTint: Color(0xFF00F6FF),
        themeIcon: Icons.bolt_outlined,
      );
    case DiaryThemePreset.hacker:
      return const _SnackBarPalette(
        gradientColors: [
          Color(0xFF081008),
          Color(0xFF041004),
        ],
        panelColor: Color(0xFF0A120A),
        borderColor: Color(0xFF245C2A),
        textColor: Color(0xFFB9FFB3),
        shadowColor: Color(0x33000000),
        iconTint: Color(0xFF5CFF6A),
        themeIcon: Icons.memory_outlined,
      );
    case DiaryThemePreset.spaceLines:
      return const _SnackBarPalette(
        gradientColors: [
          Color(0xFFFDFEFF),
          Color(0xFFF1F6FF),
        ],
        panelColor: Color(0xFFF8FBFF),
        borderColor: Color(0xFFC8D4E8),
        textColor: Color(0xFF142033),
        shadowColor: Color(0x1F4A63FF),
        iconTint: Color(0xFF4A63FF),
        themeIcon: Icons.rocket_launch_outlined,
      );
  }
}

Color _toneColor(
  AppSnackBarTone tone,
  ColorScheme colorScheme,
  Brightness brightness,
) {
  switch (tone) {
    case AppSnackBarTone.success:
      return colorScheme.primary;
    case AppSnackBarTone.info:
      return colorScheme.secondary;
    case AppSnackBarTone.warning:
      return brightness == Brightness.dark
          ? const Color(0xFFFFC857)
          : const Color(0xFFC97A00);
    case AppSnackBarTone.error:
      return colorScheme.error;
  }
}

IconData _iconForTone(AppSnackBarTone tone) {
  switch (tone) {
    case AppSnackBarTone.success:
      return Icons.check_circle_outline_rounded;
    case AppSnackBarTone.info:
      return Icons.info_outline_rounded;
    case AppSnackBarTone.warning:
      return Icons.warning_amber_rounded;
    case AppSnackBarTone.error:
      return Icons.error_outline_rounded;
  }
}

Color _mixColor(Color base, Color accent, double amount) {
  return Color.lerp(base, accent, amount) ?? accent;
}
