import 'dart:async';

import 'package:diary_mvp/app/theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppSnackBarTone {
  success,
  info,
  warning,
  error,
}

OverlayEntry? _activeToastEntry;

extension AppSnackBarContext on BuildContext {
  void showAppSnackBar(
    String message, {
    AppSnackBarTone tone = AppSnackBarTone.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.maybeOf(this, rootOverlay: true);
    if (overlay == null) return;

    _activeToastEntry?.remove();
    _activeToastEntry = null;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _CupertinoToastOverlay(
        message: message,
        tone: tone,
        duration: duration,
        onDismissed: () {
          if (_activeToastEntry == entry) {
            _activeToastEntry = null;
          }
          entry.remove();
        },
      ),
    );

    _activeToastEntry = entry;
    overlay.insert(entry);
  }
}

class _CupertinoToastOverlay extends StatefulWidget {
  const _CupertinoToastOverlay({
    required this.message,
    required this.tone,
    required this.duration,
    required this.onDismissed,
  });

  final String message;
  final AppSnackBarTone tone;
  final Duration duration;
  final VoidCallback onDismissed;

  @override
  State<_CupertinoToastOverlay> createState() => _CupertinoToastOverlayState();
}

class _CupertinoToastOverlayState extends State<_CupertinoToastOverlay> {
  Timer? _hideTimer;
  Timer? _removeTimer;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _visible = true);
    });

    _hideTimer = Timer(widget.duration, _dismiss);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _removeTimer?.cancel();
    super.dispose();
  }

  void _dismiss() {
    if (!_visible) {
      widget.onDismissed();
      return;
    }

    setState(() => _visible = false);
    _removeTimer = Timer(
      const Duration(milliseconds: 220),
      widget.onDismissed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Positioned.fill(
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                offset: _visible ? Offset.zero : const Offset(0, -0.12),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  opacity: _visible ? 1 : 0,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: buildAppSnackBar(
                      context,
                      message: widget.message,
                      tone: widget.tone,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget buildAppSnackBar(
  BuildContext context, {
  required String message,
  AppSnackBarTone tone = AppSnackBarTone.info,
}) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final themeAsync = ProviderScope.containerOf(context, listen: false).read(
    appThemeControllerProvider,
  );
  final preset = resolveThemePreset(themeAsync);
  final palette = _paletteForTheme(preset);
  final toneColor = _toneColor(tone, colorScheme, theme.brightness);
  final iconBackground = _mixColor(palette.panelColor, toneColor, 0.2);
  final borderColor = _mixColor(palette.borderColor, toneColor, 0.32);

  return CupertinoPopupSurface(
    isSurfacePainted: false,
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.gradientColors,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: palette.shadowColor,
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(
                  _iconForTone(tone),
                  size: 18,
                  color: toneColor,
                ),
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
                  height: 1.32,
                ),
              ),
            ),
          ],
        ),
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
  });

  final List<Color> gradientColors;
  final Color panelColor;
  final Color borderColor;
  final Color textColor;
  final Color shadowColor;
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
      return CupertinoIcons.check_mark_circled_solid;
    case AppSnackBarTone.info:
      return CupertinoIcons.info_circle_fill;
    case AppSnackBarTone.warning:
      return CupertinoIcons.exclamationmark_triangle_fill;
    case AppSnackBarTone.error:
      return CupertinoIcons.xmark_circle_fill;
  }
}

Color _mixColor(Color base, Color accent, double amount) {
  return Color.lerp(base, accent, amount) ?? accent;
}
