import 'package:diary_mvp/app/app_icon.dart';
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
    this.showAppBarTitle = true,
    this.compactBodyPadding,
    this.expandedBodyPadding,
    this.onNavigateRequest,
  });

  final String title;
  final Widget child;
  final Widget? floatingActionButton;
  final List<Widget> actions;
  final bool showAppBarTitle;
  final EdgeInsetsGeometry? compactBodyPadding;
  final EdgeInsetsGeometry? expandedBodyPadding;
  final Future<bool> Function(String location)? onNavigateRequest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = context.strings;
    final selectedTheme = resolveThemePreset(
      ref.watch(appThemeControllerProvider),
    );
    final selectedIcon = resolveAppIconSelection(
      ref.watch(appIconControllerProvider),
    );
    final location = GoRouterState.of(context).uri.toString();
    final selectedIndex = _primaryIndexForLocation(location);
    final isSettingsPage = location.startsWith('/settings');

    return LayoutBuilder(
      builder: (context, constraints) {
        final useCompactLayout = constraints.maxWidth < 860;
        final appBarActions = [
          ...actions,
          if (useCompactLayout && !isSettingsPage)
            IconButton(
              onPressed: () => _openSettings(context, compact: true),
              tooltip: strings.settingsTooltip,
              icon: const Icon(Icons.settings_outlined),
            ),
        ];
        final shouldShowAppBar = showAppBarTitle || appBarActions.isNotEmpty;

        if (useCompactLayout) {
          return Scaffold(
            appBar: shouldShowAppBar
                ? AppBar(
                    title: showAppBarTitle
                        ? _AppBarTitle(
                            pageTitle: title,
                            iconSelection: selectedIcon,
                          )
                        : null,
                    centerTitle: false,
                    backgroundColor: Colors.transparent,
                    actions: appBarActions,
                  )
                : null,
            floatingActionButton: floatingActionButton,
            body: _ThemedShellBackground(
              themePreset: selectedTheme,
              child: SafeArea(
                child: Padding(
                  padding: compactBodyPadding ?? const EdgeInsets.all(16),
                  child: child,
                ),
              ),
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: selectedIndex ?? 0,
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
          appBar: shouldShowAppBar
              ? AppBar(
                  title: showAppBarTitle
                      ? _AppBarTitle(
                          pageTitle: title,
                          iconSelection: selectedIcon,
                        )
                      : null,
                  centerTitle: false,
                  backgroundColor: Colors.transparent,
                  actions: appBarActions,
                )
              : null,
          floatingActionButton: floatingActionButton,
          body: _ThemedShellBackground(
            themePreset: selectedTheme,
            child: Row(
              children: [
                SizedBox(
                  width: 92,
                  child: SafeArea(
                    child: Column(
                      children: [
                        Expanded(
                          child: NavigationRail(
                            selectedIndex: selectedIndex,
                            onDestinationSelected: (index) =>
                                _goToIndex(context, index),
                            groupAlignment: -1,
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
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 18),
                          child: _RailFooterAction(
                            icon: isSettingsPage
                                ? Icons.settings
                                : Icons.settings_outlined,
                            label: strings.settingsTitle,
                            selected: isSettingsPage,
                            onTap: () => _openSettings(context, compact: false),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: SafeArea(
                    child: Padding(
                      padding: expandedBodyPadding ?? const EdgeInsets.all(20),
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

  int? _primaryIndexForLocation(String location) {
    if (location.startsWith('/settings')) return null;
    if (location.startsWith('/editor')) return 1;
    if (location.startsWith('/timeline')) return 2;
    if (location.startsWith('/trash')) return 3;
    return 0;
  }

  Future<void> _openSettings(
    BuildContext context, {
    required bool compact,
  }) async {
    if (!await _canNavigate(context, '/settings')) {
      return;
    }
    if (!context.mounted) {
      return;
    }
    if (compact) {
      context.push('/settings');
      return;
    }
    context.go('/settings');
  }

  Future<void> _goToIndex(BuildContext context, int index) async {
    final destination = switch (index) {
      0 => '/',
      1 => '/editor',
      2 => '/timeline',
      3 => '/trash',
      _ => '/',
    };

    if (!await _canNavigate(context, destination)) {
      return;
    }
    if (!context.mounted) {
      return;
    }

    switch (index) {
      case 0:
        context.go(destination);
        break;
      case 1:
        context.go(destination);
        break;
      case 2:
        context.go(destination);
        break;
      case 3:
        context.go(destination);
        break;
    }
  }

  Future<bool> _canNavigate(BuildContext context, String location) async {
    final callback = onNavigateRequest;
    if (callback == null) {
      return true;
    }
    return callback(location);
  }
}

class _AppBarTitle extends StatelessWidget {
  const _AppBarTitle({
    required this.pageTitle,
    required this.iconSelection,
  });

  final String pageTitle;
  final AppIconSelection iconSelection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        AppIconBadge(
          selection: iconSelection,
          size: 28,
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            pageTitle,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _RailFooterAction extends StatelessWidget {
  const _RailFooterAction({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final foregroundColor = selected
        ? colorScheme.onSecondaryContainer
        : colorScheme.onSurfaceVariant;

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: selected
            ? colorScheme.secondaryContainer.withValues(alpha: 0.72)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: foregroundColor),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: foregroundColor,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
      case DiaryThemePreset.girlPink:
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF6FB),
              Color(0xFFFFE8F3),
              Color(0xFFFFFBFE),
            ],
          ),
        );
      case DiaryThemePreset.barbieShockPink:
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFE8F6),
              Color(0xFFFFD2EC),
              Color(0xFFFFF6FB),
            ],
          ),
        );
      case DiaryThemePreset.kidPink:
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF9EF),
              Color(0xFFFFF1F7),
              Color(0xFFFFFEFB),
            ],
          ),
        );
      case DiaryThemePreset.happyBoy:
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF4FBFF),
              Color(0xFFE9F5FF),
              Color(0xFFFFFCF2),
            ],
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
      case DiaryThemePreset.girlPink:
        return _GirlPinkBackgroundPainter(
          primary: colorScheme.primary.withValues(alpha: 0.16),
          secondary: colorScheme.secondary.withValues(alpha: 0.26),
          line: colorScheme.outlineVariant.withValues(alpha: 0.36),
        );
      case DiaryThemePreset.barbieShockPink:
        return _BarbieShockBackgroundPainter(
          primary: colorScheme.primary.withValues(alpha: 0.28),
          secondary: colorScheme.secondary.withValues(alpha: 0.24),
          line: colorScheme.primary.withValues(alpha: 0.12),
        );
      case DiaryThemePreset.kidPink:
        return _KidPinkBackgroundPainter(
          primary: colorScheme.primary.withValues(alpha: 0.18),
          secondary: colorScheme.secondary.withValues(alpha: 0.24),
          line: colorScheme.outlineVariant.withValues(alpha: 0.28),
        );
      case DiaryThemePreset.happyBoy:
        return _HappyBoyBackgroundPainter(
          primary: colorScheme.primary.withValues(alpha: 0.2),
          secondary: colorScheme.secondary.withValues(alpha: 0.24),
          line: colorScheme.outlineVariant.withValues(alpha: 0.28),
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

class _GirlPinkBackgroundPainter extends CustomPainter {
  const _GirlPinkBackgroundPainter({
    required this.primary,
    required this.secondary,
    required this.line,
  });

  final Color primary;
  final Color secondary;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    final bloomPaint = Paint()..color = secondary;
    canvas.drawCircle(
      Offset(size.width - 92, 84),
      92,
      bloomPaint,
    );
    canvas.drawCircle(
      Offset(size.width - 128, 66),
      44,
      Paint()..color = primary.withValues(alpha: 0.58),
    );

    final ribbonPaint = Paint()
      ..color = line
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final ribbon = Path()
      ..moveTo(-24, size.height * 0.34)
      ..quadraticBezierTo(
        size.width * 0.16,
        size.height * 0.22,
        size.width * 0.3,
        size.height * 0.3,
      )
      ..quadraticBezierTo(
        size.width * 0.46,
        size.height * 0.38,
        size.width * 0.62,
        size.height * 0.28,
      )
      ..quadraticBezierTo(
        size.width * 0.82,
        size.height * 0.16,
        size.width + 24,
        size.height * 0.25,
      );
    canvas.drawPath(ribbon, ribbonPaint);

    final lowerRibbon = Path()
      ..moveTo(size.width * 0.12, size.height)
      ..quadraticBezierTo(
        size.width * 0.3,
        size.height * 0.82,
        size.width * 0.48,
        size.height * 0.9,
      )
      ..quadraticBezierTo(
        size.width * 0.7,
        size.height * 0.98,
        size.width * 0.92,
        size.height * 0.82,
      );
    canvas.drawPath(lowerRibbon, ribbonPaint);

    for (final point in <Offset>[
      const Offset(42, 54),
      const Offset(96, 96),
      Offset(size.width * 0.78, size.height * 0.62),
      Offset(size.width * 0.56, size.height * 0.78),
    ]) {
      _drawSparkle(
        canvas,
        point,
        Paint()
          ..color = primary.withValues(alpha: 0.5)
          ..strokeWidth = 1.1
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawSparkle(Canvas canvas, Offset center, Paint paint) {
    canvas.drawLine(
      center.translate(-5, 0),
      center.translate(5, 0),
      paint,
    );
    canvas.drawLine(
      center.translate(0, -5),
      center.translate(0, 5),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _GirlPinkBackgroundPainter oldDelegate) {
    return oldDelegate.primary != primary ||
        oldDelegate.secondary != secondary ||
        oldDelegate.line != line;
  }
}

class _BarbieShockBackgroundPainter extends CustomPainter {
  const _BarbieShockBackgroundPainter({
    required this.primary,
    required this.secondary,
    required this.line,
  });

  final Color primary;
  final Color secondary;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.56, -10, size.width * 0.32, size.height),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            primary.withValues(alpha: 0),
            primary.withValues(alpha: 0.42),
            primary.withValues(alpha: 0),
          ],
        ).createShader(
          Rect.fromLTWH(size.width * 0.56, -10, size.width * 0.32, size.height),
        ),
    );

    final slashPaint = Paint()
      ..color = secondary
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (double offset = -120; offset < size.width + 120; offset += 58) {
      canvas.drawLine(
        Offset(offset, size.height * 0.18),
        Offset(offset + 88, size.height * 0.02),
        slashPaint,
      );
    }

    final framePaint = Paint()
      ..color = line
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(18, 18, size.width - 36, size.height - 36),
        const Radius.circular(24),
      ),
      framePaint,
    );

    canvas.drawCircle(
      Offset(size.width - 54, 44),
      9,
      Paint()..color = primary.withValues(alpha: 0.6),
    );
    canvas.drawCircle(
      Offset(size.width - 82, 44),
      5,
      Paint()..color = secondary.withValues(alpha: 0.72),
    );
  }

  @override
  bool shouldRepaint(covariant _BarbieShockBackgroundPainter oldDelegate) {
    return oldDelegate.primary != primary ||
        oldDelegate.secondary != secondary ||
        oldDelegate.line != line;
  }
}

class _KidPinkBackgroundPainter extends CustomPainter {
  const _KidPinkBackgroundPainter({
    required this.primary,
    required this.secondary,
    required this.line,
  });

  final Color primary;
  final Color secondary;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    final bubblePaint = Paint()..color = primary;
    for (final circle in <(Offset, double)>[
      (const Offset(58, 66), 34),
      (Offset(size.width - 92, 84), 48),
      (Offset(size.width * 0.78, size.height * 0.74), 26),
    ]) {
      canvas.drawCircle(circle.$1, circle.$2, bubblePaint);
    }

    final confettiPaint = Paint()
      ..color = secondary
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (final point in <Offset>[
      const Offset(124, 54),
      Offset(size.width * 0.28, 94),
      Offset(size.width * 0.58, 52),
      Offset(size.width * 0.86, 132),
      Offset(size.width * 0.34, size.height * 0.76),
      Offset(size.width * 0.7, size.height * 0.88),
    ]) {
      canvas.drawLine(
        point.translate(-6, -3),
        point.translate(6, 3),
        confettiPaint,
      );
    }

    final doodlePaint = Paint()
      ..color = line
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final doodle = Path()
      ..moveTo(18, size.height * 0.58)
      ..quadraticBezierTo(
        size.width * 0.22,
        size.height * 0.48,
        size.width * 0.34,
        size.height * 0.6,
      )
      ..quadraticBezierTo(
        size.width * 0.48,
        size.height * 0.72,
        size.width * 0.68,
        size.height * 0.54,
      )
      ..quadraticBezierTo(
        size.width * 0.84,
        size.height * 0.42,
        size.width - 18,
        size.height * 0.5,
      );
    canvas.drawPath(doodle, doodlePaint);
  }

  @override
  bool shouldRepaint(covariant _KidPinkBackgroundPainter oldDelegate) {
    return oldDelegate.primary != primary ||
        oldDelegate.secondary != secondary ||
        oldDelegate.line != line;
  }
}

class _HappyBoyBackgroundPainter extends CustomPainter {
  const _HappyBoyBackgroundPainter({
    required this.primary,
    required this.secondary,
    required this.line,
  });

  final Color primary;
  final Color secondary;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    final stripePaint = Paint()
      ..color = primary
      ..strokeWidth = 20;
    for (double x = -60; x < size.width + 60; x += 86) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + 54, size.height * 0.42),
        stripePaint,
      );
    }

    canvas.drawCircle(
      const Offset(74, 78),
      42,
      Paint()..color = secondary.withValues(alpha: 0.72),
    );

    final orbitPaint = Paint()
      ..color = line
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width * 0.82, size.height * 0.2),
        radius: size.shortestSide * 0.18,
      ),
      2.8,
      2.2,
      false,
      orbitPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width * 0.22, size.height * 0.84),
        radius: size.shortestSide * 0.24,
      ),
      5.1,
      1.7,
      false,
      orbitPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _HappyBoyBackgroundPainter oldDelegate) {
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
