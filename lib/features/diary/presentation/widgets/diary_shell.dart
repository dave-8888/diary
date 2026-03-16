import 'package:diary_mvp/app/localization/app_locale.dart';
import 'package:diary_mvp/app/localization/app_strings.dart';
import 'package:diary_mvp/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DiaryShell extends ConsumerWidget {
  const DiaryShell({
    super.key,
    required this.title,
    required this.child,
    this.floatingActionButton,
    this.actions = const [],
  });

  final String title;
  final Widget child;
  final Widget? floatingActionButton;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = context.strings;
    final selectedLanguage = ref.watch(appLanguageProvider);
    final selectedTheme = resolveThemePreset(
      ref.watch(appThemeControllerProvider),
    );
    final location = GoRouterState.of(context).uri.toString();
    final selectedIndex = _indexForLocation(location);
    final appBarActions = [
      ...actions,
      PopupMenuButton<DiaryThemePreset>(
        tooltip: strings.theme,
        initialValue: selectedTheme,
        icon: const Icon(Icons.palette_outlined),
        onSelected: (theme) {
          ref.read(appThemeControllerProvider.notifier).setTheme(theme);
        },
        itemBuilder: (context) => DiaryThemePreset.values
            .map(
              (theme) => PopupMenuItem<DiaryThemePreset>(
                value: theme,
                child: Row(
                  children: [
                    Icon(_iconForTheme(theme), size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text(strings.titleForTheme(theme))),
                  ],
                ),
              ),
            )
            .toList(),
      ),
      PopupMenuButton<AppLanguage>(
        tooltip: strings.language,
        initialValue: selectedLanguage,
        icon: const Icon(Icons.language),
        onSelected: (language) {
          ref.read(appLanguageProvider.notifier).setLanguage(language);
        },
        itemBuilder: (context) => AppLanguage.values
            .map(
              (language) => PopupMenuItem<AppLanguage>(
                value: language,
                child: Text(strings.titleForLanguage(language)),
              ),
            )
            .toList(),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 860) {
          return Scaffold(
            appBar: AppBar(
              title: Text(title),
              centerTitle: false,
              backgroundColor: Colors.transparent,
              actions: appBarActions,
            ),
            floatingActionButton: floatingActionButton,
            body: _ThemedShellBackground(
              themePreset: selectedTheme,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: child,
                ),
              ),
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) => _goToIndex(context, index),
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  label: strings.homeNav,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.edit_note_outlined),
                  label: strings.writeNav,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.timeline_outlined),
                  label: strings.timelineNav,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.delete_outline),
                  label: strings.trashNav,
                ),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            centerTitle: false,
            backgroundColor: Colors.transparent,
            actions: appBarActions,
          ),
          floatingActionButton: floatingActionButton,
          body: _ThemedShellBackground(
            themePreset: selectedTheme,
            child: Row(
              children: [
                NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) => _goToIndex(context, index),
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    NavigationRailDestination(
                      icon: const Icon(Icons.home_outlined),
                      selectedIcon: const Icon(Icons.home),
                      label: Text(strings.homeNav),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.edit_note_outlined),
                      selectedIcon: const Icon(Icons.edit_note),
                      label: Text(strings.writeNav),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.timeline_outlined),
                      selectedIcon: const Icon(Icons.timeline),
                      label: Text(strings.timelineNav),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.delete_outline),
                      selectedIcon: const Icon(Icons.delete),
                      label: Text(strings.trashNav),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: child,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  int _indexForLocation(String location) {
    if (location.startsWith('/editor')) return 1;
    if (location.startsWith('/timeline')) return 2;
    if (location.startsWith('/trash')) return 3;
    return 0;
  }

  void _goToIndex(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/editor');
        break;
      case 2:
        context.go('/timeline');
        break;
      case 3:
        context.go('/trash');
        break;
    }
  }

  IconData _iconForTheme(DiaryThemePreset theme) {
    switch (theme) {
      case DiaryThemePreset.daylight:
        return Icons.wb_sunny_outlined;
      case DiaryThemePreset.night:
        return Icons.dark_mode_outlined;
      case DiaryThemePreset.cyberpunk:
        return Icons.bolt_outlined;
      case DiaryThemePreset.hacker:
        return Icons.memory_outlined;
      case DiaryThemePreset.spaceLines:
        return Icons.rocket_launch_outlined;
    }
  }
}

class _ThemedShellBackground extends StatelessWidget {
  const _ThemedShellBackground({
    required this.themePreset,
    required this.child,
  });

  final DiaryThemePreset themePreset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final decoration = _backgroundDecoration(theme);
    final painter = _backgroundPainter(theme);

    if (decoration == null && painter == null) {
      return child;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        if (decoration != null) DecoratedBox(decoration: decoration),
        if (painter != null) CustomPaint(painter: painter),
        child,
      ],
    );
  }

  Decoration? _backgroundDecoration(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    switch (themePreset) {
      case DiaryThemePreset.daylight:
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.scaffoldBackgroundColor,
              colorScheme.primaryContainer.withValues(alpha: 0.72),
              theme.scaffoldBackgroundColor,
            ],
            stops: const [0, 0.38, 1],
          ),
        );
      case DiaryThemePreset.night:
        return BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.85, -0.9),
            radius: 1.5,
            colors: [
              colorScheme.primary.withValues(alpha: 0.18),
              theme.scaffoldBackgroundColor,
              const Color(0xFF091019),
            ],
            stops: const [0, 0.45, 1],
          ),
        );
      case DiaryThemePreset.cyberpunk:
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF080111),
              Color(0xFF170A2B),
              Color(0xFF090312),
            ],
          ),
        );
      case DiaryThemePreset.hacker:
        return const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.95),
            radius: 1.8,
            colors: [
              Color(0xFF0A170A),
              Color(0xFF041004),
              Color(0xFF020502),
            ],
            stops: [0, 0.42, 1],
          ),
        );
      case DiaryThemePreset.spaceLines:
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFF8FAFF),
              theme.scaffoldBackgroundColor,
            ],
          ),
        );
    }
  }

  CustomPainter? _backgroundPainter(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    switch (themePreset) {
      case DiaryThemePreset.daylight:
        return _DaylightBackgroundPainter(
          primary: colorScheme.primary.withValues(alpha: 0.1),
          secondary: colorScheme.secondary.withValues(alpha: 0.12),
          line: colorScheme.outlineVariant.withValues(alpha: 0.3),
        );
      case DiaryThemePreset.night:
        return _NightBackgroundPainter(
          glow: colorScheme.primary.withValues(alpha: 0.2),
          line: colorScheme.outlineVariant.withValues(alpha: 0.45),
          star: colorScheme.secondary.withValues(alpha: 0.34),
        );
      case DiaryThemePreset.cyberpunk:
        return _CyberpunkBackgroundPainter(
          primary: colorScheme.primary.withValues(alpha: 0.32),
          secondary: colorScheme.secondary.withValues(alpha: 0.28),
          line: colorScheme.primary.withValues(alpha: 0.16),
        );
      case DiaryThemePreset.hacker:
        return _HackerBackgroundPainter(
          primary: colorScheme.primary.withValues(alpha: 0.24),
          secondary: colorScheme.secondary.withValues(alpha: 0.18),
          line: colorScheme.primary.withValues(alpha: 0.08),
        );
      case DiaryThemePreset.spaceLines:
        return _SpaceLinesBackgroundPainter(
          primary: colorScheme.primary.withValues(alpha: 0.14),
          secondary: colorScheme.outlineVariant.withValues(alpha: 0.52),
          star: colorScheme.secondary.withValues(alpha: 0.22),
        );
    }
  }
}

class _DaylightBackgroundPainter extends CustomPainter {
  const _DaylightBackgroundPainter({
    required this.primary,
    required this.secondary,
    required this.line,
  });

  final Color primary;
  final Color secondary;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    final sun = Paint()..color = primary;
    canvas.drawCircle(Offset(size.width - 80, 70), 96, sun);
    canvas.drawCircle(
        Offset(size.width - 110, 86), 56, Paint()..color = secondary);

    final linePaint = Paint()
      ..color = line
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;

    for (double y = size.height * 0.62; y < size.height; y += 42) {
      canvas.drawArc(
        Rect.fromLTWH(-size.width * 0.05, y, size.width * 0.7, 120),
        4.0,
        1.5,
        false,
        linePaint,
      );
    }

    final beamPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          primary.withValues(alpha: 0),
          primary.withValues(alpha: 0.26),
          primary.withValues(alpha: 0),
        ],
      ).createShader(
          Rect.fromLTWH(size.width - 220, 0, 200, size.height * 0.5));
    canvas.drawRect(
      Rect.fromLTWH(size.width - 220, 0, 200, size.height * 0.5),
      beamPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DaylightBackgroundPainter oldDelegate) {
    return oldDelegate.primary != primary ||
        oldDelegate.secondary != secondary ||
        oldDelegate.line != line;
  }
}

class _NightBackgroundPainter extends CustomPainter {
  const _NightBackgroundPainter({
    required this.glow,
    required this.line,
    required this.star,
  });

  final Color glow;
  final Color line;
  final Color star;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      const Offset(92, 82),
      58,
      Paint()..color = glow,
    );
    canvas.drawCircle(
      const Offset(102, 74),
      28,
      Paint()..color = line.withValues(alpha: 0.85),
    );

    final arcPaint = Paint()
      ..color = line
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width * 0.82, size.height * 0.22),
        radius: size.shortestSide * 0.28,
      ),
      2.8,
      2.1,
      false,
      arcPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width * 0.14, size.height * 0.88),
        radius: size.shortestSide * 0.22,
      ),
      4.9,
      1.7,
      false,
      arcPaint,
    );

    final stars = <Offset>[
      const Offset(180, 54),
      Offset(size.width * 0.28, 90),
      Offset(size.width * 0.55, 42),
      Offset(size.width * 0.74, 76),
      Offset(size.width * 0.88, 116),
      Offset(size.width * 0.62, size.height * 0.72),
      Offset(size.width * 0.24, size.height * 0.68),
      Offset(size.width * 0.86, size.height * 0.82),
    ];

    for (final point in stars) {
      canvas.drawCircle(point, 1.7, Paint()..color = star);
      canvas.drawLine(
        Offset(point.dx - 4, point.dy),
        Offset(point.dx + 4, point.dy),
        Paint()
          ..color = star.withValues(alpha: 0.45)
          ..strokeWidth = 0.9,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NightBackgroundPainter oldDelegate) {
    return oldDelegate.glow != glow ||
        oldDelegate.line != line ||
        oldDelegate.star != star;
  }
}

class _CyberpunkBackgroundPainter extends CustomPainter {
  const _CyberpunkBackgroundPainter({
    required this.primary,
    required this.secondary,
    required this.line,
  });

  final Color primary;
  final Color secondary;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    final diagonalPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          secondary.withValues(alpha: 0),
          secondary,
          primary.withValues(alpha: 0),
        ],
      ).createShader(
          Rect.fromLTWH(size.width * 0.52, -20, 220, size.height * 0.6));
    final diagonalPath = Path()
      ..moveTo(size.width * 0.58, 0)
      ..lineTo(size.width * 0.78, 0)
      ..lineTo(size.width * 0.52, size.height * 0.42)
      ..lineTo(size.width * 0.32, size.height * 0.42)
      ..close();
    canvas.drawPath(diagonalPath, diagonalPaint);

    final gridPaint = Paint()
      ..color = line
      ..strokeWidth = 1;
    for (double y = size.height * 0.7; y < size.height; y += 20) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(
        Offset(x, size.height * 0.7),
        Offset(size.width * 0.5 + (x - size.width * 0.5) * 1.3, size.height),
        Paint()
          ..color = line.withValues(alpha: 0.75)
          ..strokeWidth = 1,
      );
    }

    final neonBar = Paint()
      ..color = primary.withValues(alpha: 0.6)
      ..strokeWidth = 2.2;
    canvas.drawLine(
      const Offset(34, 62),
      Offset(size.width * 0.28, 62),
      neonBar,
    );
    canvas.drawLine(
      Offset(size.width - 160, size.height - 50),
      Offset(size.width - 34, size.height - 50),
      Paint()
        ..color = secondary.withValues(alpha: 0.6)
        ..strokeWidth = 2.2,
    );
  }

  @override
  bool shouldRepaint(covariant _CyberpunkBackgroundPainter oldDelegate) {
    return oldDelegate.primary != primary ||
        oldDelegate.secondary != secondary ||
        oldDelegate.line != line;
  }
}

class _HackerBackgroundPainter extends CustomPainter {
  const _HackerBackgroundPainter({
    required this.primary,
    required this.secondary,
    required this.line,
  });

  final Color primary;
  final Color secondary;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    final scanLine = Paint()
      ..color = line
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 14) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), scanLine);
    }

    final columns = <double>[
      size.width * 0.08,
      size.width * 0.19,
      size.width * 0.31,
      size.width * 0.74,
      size.width * 0.86,
    ];
    for (final x in columns) {
      final columnPaint = Paint()
        ..color = secondary.withValues(alpha: 0.26)
        ..strokeWidth = 2;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height * 0.56),
        columnPaint,
      );
      for (double y = 18; y < size.height * 0.5; y += 26) {
        canvas.drawRect(
          Rect.fromLTWH(x - 7, y, 14, 8),
          Paint()..color = primary.withValues(alpha: 0.2),
        );
      }
    }

    final frame = Paint()
      ..color = primary.withValues(alpha: 0.42)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    canvas.drawRect(
      Rect.fromLTWH(18, 18, size.width - 36, size.height - 36),
      frame,
    );
  }

  @override
  bool shouldRepaint(covariant _HackerBackgroundPainter oldDelegate) {
    return oldDelegate.primary != primary ||
        oldDelegate.secondary != secondary ||
        oldDelegate.line != line;
  }
}

class _SpaceLinesBackgroundPainter extends CustomPainter {
  const _SpaceLinesBackgroundPainter({
    required this.primary,
    required this.secondary,
    required this.star,
  });

  final Color primary;
  final Color secondary;
  final Color star;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = secondary.withValues(alpha: 0.36)
      ..strokeWidth = 1;
    const gridSpacing = 52.0;

    for (double x = 28; x < size.width; x += gridSpacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }

    for (double y = 32; y < size.height; y += gridSpacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    final orbitPaint = Paint()
      ..color = primary
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width * 0.1, size.height * 0.18),
        radius: size.shortestSide * 0.34,
      ),
      -0.35,
      2.6,
      false,
      orbitPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width * 0.92, size.height * 0.84),
        radius: size.shortestSide * 0.27,
      ),
      2.5,
      2.7,
      false,
      orbitPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width * 0.78, size.height * 0.12),
        radius: size.shortestSide * 0.18,
      ),
      2.2,
      2.15,
      false,
      orbitPaint,
    );

    final bracketPaint = Paint()
      ..color = primary.withValues(alpha: 0.78)
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.square;
    _drawCornerBracket(canvas, const Offset(26, 24), bracketPaint,
        flipX: false);
    _drawCornerBracket(
      canvas,
      Offset(size.width - 26, 24),
      bracketPaint,
      flipX: true,
    );
    _drawCornerBracket(
      canvas,
      Offset(26, size.height - 24),
      bracketPaint,
      flipX: false,
      flipY: true,
    );

    final starPaint = Paint()..color = star;
    final stars = <Offset>[
      Offset(size.width * 0.18, size.height * 0.22),
      Offset(size.width * 0.28, size.height * 0.12),
      Offset(size.width * 0.42, size.height * 0.31),
      Offset(size.width * 0.62, size.height * 0.17),
      Offset(size.width * 0.74, size.height * 0.28),
      Offset(size.width * 0.83, size.height * 0.11),
      Offset(size.width * 0.58, size.height * 0.68),
      Offset(size.width * 0.21, size.height * 0.74),
      Offset(size.width * 0.86, size.height * 0.72),
    ];

    for (final point in stars) {
      canvas.drawCircle(point, 1.65, starPaint);
      canvas.drawLine(
        Offset(point.dx - 4, point.dy),
        Offset(point.dx + 4, point.dy),
        Paint()
          ..color = star.withValues(alpha: 0.5)
          ..strokeWidth = 0.9,
      );
    }
  }

  void _drawCornerBracket(
    Canvas canvas,
    Offset anchor,
    Paint paint, {
    required bool flipX,
    bool flipY = false,
  }) {
    final horizontalDirection = flipX ? -1.0 : 1.0;
    final verticalDirection = flipY ? -1.0 : 1.0;

    canvas.drawLine(
      anchor,
      anchor.translate(44 * horizontalDirection, 0),
      paint,
    );
    canvas.drawLine(
      anchor,
      anchor.translate(0, 44 * verticalDirection),
      paint,
    );
    canvas.drawLine(
      anchor.translate(0, 14 * verticalDirection),
      anchor.translate(22 * horizontalDirection, 14 * verticalDirection),
      Paint()
        ..color = paint.color
        ..strokeCap = paint.strokeCap
        ..strokeWidth = 1.1,
    );
  }

  @override
  bool shouldRepaint(covariant _SpaceLinesBackgroundPainter oldDelegate) {
    return oldDelegate.primary != primary ||
        oldDelegate.secondary != secondary ||
        oldDelegate.star != star;
  }
}
