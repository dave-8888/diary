import 'package:diary_mvp/app/app_display_name.dart';
import 'package:diary_mvp/app/localization/app_strings.dart';
import 'package:diary_mvp/app/theme.dart';
import 'package:diary_mvp/features/diary/application/diary_controller.dart';
import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/diary_card.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/diary_shell.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/tag_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = context.strings;
    final entriesAsync = ref.watch(diaryControllerProvider);
    final selectedTag = ref.watch(selectedTagFilterProvider);
    final customAppNameAsync = ref.watch(appDisplayNameControllerProvider);
    final selectedTheme = resolveThemePreset(
      ref.watch(appThemeControllerProvider),
    );
    final showTagFilters = ref.watch(tagLibraryControllerProvider).maybeWhen(
          data: (tags) => tags.isNotEmpty,
          loading: () => true,
          error: (_, __) => true,
          orElse: () => false,
        );
    final appTitle = resolveAppDisplayName(
      strings: strings,
      customNameAsync: customAppNameAsync,
    );

    return DiaryShell(
      title: appTitle,
      actions: [
        IconButton(
          onPressed: () => context.push('/settings'),
          tooltip: strings.settingsTooltip,
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/editor'),
        icon: const Icon(Icons.add),
        label: Text(strings.newEntry),
      ),
      child: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(strings.failedToLoadEntries(error)),
        ),
        data: (entries) => _HomeList(
          entries: entries,
          selectedTag: selectedTag,
          showTagFilters: showTagFilters,
          themePreset: selectedTheme,
        ),
      ),
    );
  }
}

class _HomeList extends StatelessWidget {
  const _HomeList({
    required this.entries,
    required this.selectedTag,
    required this.showTagFilters,
    required this.themePreset,
  });

  final List<DiaryEntry> entries;
  final String? selectedTag;
  final bool showTagFilters;
  final DiaryThemePreset themePreset;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final filteredEntries = selectedTag == null
        ? entries
        : entries
            .where(
              (entry) => entry.tags.any(
                (tag) => tag.toLowerCase() == selectedTag!.toLowerCase(),
              ),
            )
            .toList(growable: false);
    final latest = filteredEntries.isNotEmpty ? filteredEntries.first : null;
    final summaryText = selectedTag == null
        ? strings.latestSummary(latest)
        : strings.filteredByTag(selectedTag!);
    final detailText = latest?.content ??
        (selectedTag == null
            ? strings.firstEntryPrompt
            : strings.noEntriesForTag(selectedTag!));

    return ListView(
      children: [
        _OverviewHero(
          latest: latest,
          entryCount: filteredEntries.length,
          selectedTag: selectedTag,
          summaryText: summaryText,
          detailText: detailText,
          themePreset: themePreset,
        ),
        const SizedBox(height: 24),
        if (showTagFilters) ...[
          const TagFilterBar(),
          const SizedBox(height: 20),
        ],
        Row(
          children: [
            Text(
              strings.recentEntries,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Spacer(),
            TextButton(
              onPressed: () => context.go('/timeline'),
              child: Text(strings.viewAll),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (filteredEntries.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              selectedTag == null
                  ? strings.noEntriesYet
                  : strings.noEntriesForTag(selectedTag!),
            ),
          )
        else
          ...filteredEntries.take(3).map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: DiaryCard(
                    entry: entry,
                    onEdit: () => _openEditor(context, entry),
                    onTap: () => _openEditor(context, entry),
                  ),
                ),
              ),
      ],
    );
  }

  void _openEditor(BuildContext context, DiaryEntry entry) {
    context.push('/editor', extra: entry);
  }
}

class _OverviewHero extends StatelessWidget {
  const _OverviewHero({
    required this.latest,
    required this.entryCount,
    required this.selectedTag,
    required this.summaryText,
    required this.detailText,
    required this.themePreset,
  });

  final DiaryEntry? latest;
  final int entryCount;
  final String? selectedTag;
  final String summaryText;
  final String detailText;
  final DiaryThemePreset themePreset;

  @override
  Widget build(BuildContext context) {
    switch (themePreset) {
      case DiaryThemePreset.daylight:
        return _DaylightHero(
          latest: latest,
          entryCount: entryCount,
          selectedTag: selectedTag,
          summaryText: summaryText,
          detailText: detailText,
        );
      case DiaryThemePreset.night:
        return _NightHero(
          latest: latest,
          entryCount: entryCount,
          selectedTag: selectedTag,
          summaryText: summaryText,
          detailText: detailText,
        );
      case DiaryThemePreset.cyberpunk:
        return _CyberpunkHero(
          latest: latest,
          entryCount: entryCount,
          selectedTag: selectedTag,
          summaryText: summaryText,
          detailText: detailText,
        );
      case DiaryThemePreset.hacker:
        return _HackerHero(
          latest: latest,
          entryCount: entryCount,
          selectedTag: selectedTag,
          summaryText: summaryText,
          detailText: detailText,
        );
      case DiaryThemePreset.spaceLines:
        return _SpaceLogHero(
          latest: latest,
          entryCount: entryCount,
          selectedTag: selectedTag,
          summaryText: summaryText,
          detailText: detailText,
        );
    }
  }
}

class _HeroHeaderBadge extends StatelessWidget {
  const _HeroHeaderBadge({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.iconColor,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: iconColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              letterSpacing: 1.0,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetricChip extends StatelessWidget {
  const _HeroMetricChip({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.textColor,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetricWrap extends StatelessWidget {
  const _HeroMetricWrap({
    required this.latest,
    required this.entryCount,
    required this.selectedTag,
    required this.chipBackground,
    required this.chipBorder,
    required this.chipIcon,
    required this.chipText,
  });

  final DiaryEntry? latest;
  final int entryCount;
  final String? selectedTag;
  final Color chipBackground;
  final Color chipBorder;
  final Color chipIcon;
  final Color chipText;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _HeroMetricChip(
          icon: Icons.menu_book_outlined,
          label: strings.entryCountLabel(entryCount),
          backgroundColor: chipBackground,
          borderColor: chipBorder,
          iconColor: chipIcon,
          textColor: chipText,
        ),
        _HeroMetricChip(
          icon: Icons.sell_outlined,
          label: strings.tagStatusLabel(selectedTag),
          backgroundColor: chipBackground,
          borderColor: chipBorder,
          iconColor: chipIcon,
          textColor: chipText,
        ),
        if (latest != null)
          _HeroMetricChip(
            icon: Icons.favorite_border,
            label: strings.moodStatusLabel(latest!.mood),
            backgroundColor: chipBackground,
            borderColor: chipBorder,
            iconColor: chipIcon,
            textColor: chipText,
          ),
      ],
    );
  }
}

class _DaylightHero extends StatelessWidget {
  const _DaylightHero({
    required this.latest,
    required this.entryCount,
    required this.selectedTag,
    required this.summaryText,
    required this.detailText,
  });

  final DiaryEntry? latest;
  final int entryCount;
  final String? selectedTag;
  final String summaryText;
  final String detailText;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final surface = theme.cardTheme.color ?? Colors.white;

    return Container(
      constraints: const BoxConstraints(minHeight: 220),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.92),
            surface,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -28,
            right: -16,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const SizedBox(width: 180, height: 180),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _HeroHeaderBadge(
                      label:
                          strings.heroLabelForTheme(DiaryThemePreset.daylight),
                      icon: Icons.wb_sunny_outlined,
                      backgroundColor: Colors.white.withValues(alpha: 0.72),
                      borderColor: colorScheme.primary.withValues(alpha: 0.14),
                      textColor: colorScheme.primary,
                      iconColor: colorScheme.primary,
                    ),
                    const Spacer(),
                    Icon(
                      Icons.waves_outlined,
                      size: 20,
                      color: colorScheme.primary.withValues(alpha: 0.72),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  strings.dayHeading(DateTime.now()),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  summaryText,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.14,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  detailText,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 18),
                _HeroMetricWrap(
                  latest: latest,
                  entryCount: entryCount,
                  selectedTag: selectedTag,
                  chipBackground: Colors.white.withValues(alpha: 0.82),
                  chipBorder:
                      colorScheme.outlineVariant.withValues(alpha: 0.68),
                  chipIcon: colorScheme.primary,
                  chipText: colorScheme.onSurface,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NightHero extends StatelessWidget {
  const _NightHero({
    required this.latest,
    required this.entryCount,
    required this.selectedTag,
    required this.summaryText,
    required this.detailText,
  });

  final DiaryEntry? latest;
  final int entryCount;
  final String? selectedTag;
  final String summaryText;
  final String detailText;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      constraints: const BoxConstraints(minHeight: 228),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF172333),
            Color(0xFF101927),
            Color(0xFF0C1420),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.74),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _NightHeroPainter(
                glow: colorScheme.primary.withValues(alpha: 0.16),
                line: colorScheme.outlineVariant.withValues(alpha: 0.44),
                star: colorScheme.secondary.withValues(alpha: 0.3),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _HeroHeaderBadge(
                      label: strings.heroLabelForTheme(DiaryThemePreset.night),
                      icon: Icons.dark_mode_outlined,
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      borderColor: colorScheme.primary.withValues(alpha: 0.2),
                      textColor: colorScheme.primary,
                      iconColor: colorScheme.primary,
                    ),
                    const Spacer(),
                    Icon(
                      Icons.bedtime_outlined,
                      size: 18,
                      color: colorScheme.secondary.withValues(alpha: 0.9),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  strings.dayHeading(DateTime.now()),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  summaryText,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                    height: 1.12,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  detailText,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.82),
                  ),
                ),
                const SizedBox(height: 18),
                _HeroMetricWrap(
                  latest: latest,
                  entryCount: entryCount,
                  selectedTag: selectedTag,
                  chipBackground: Colors.white.withValues(alpha: 0.05),
                  chipBorder: colorScheme.outlineVariant.withValues(alpha: 0.7),
                  chipIcon: colorScheme.primary,
                  chipText: colorScheme.onSurface,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CyberpunkHero extends StatelessWidget {
  const _CyberpunkHero({
    required this.latest,
    required this.entryCount,
    required this.selectedTag,
    required this.summaryText,
    required this.detailText,
  });

  final DiaryEntry? latest;
  final int entryCount;
  final String? selectedTag;
  final String summaryText;
  final String detailText;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      constraints: const BoxConstraints(minHeight: 228),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF12061F),
            Color(0xFF180A2A),
            Color(0xFF0A0311),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.secondary.withValues(alpha: 0.44),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.secondary.withValues(alpha: 0.16),
            blurRadius: 26,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _CyberpunkHeroPainter(
                primary: colorScheme.primary.withValues(alpha: 0.34),
                secondary: colorScheme.secondary.withValues(alpha: 0.28),
                line: colorScheme.primary.withValues(alpha: 0.18),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _HeroHeaderBadge(
                      label:
                          strings.heroLabelForTheme(DiaryThemePreset.cyberpunk),
                      icon: Icons.bolt_outlined,
                      backgroundColor:
                          colorScheme.primary.withValues(alpha: 0.1),
                      borderColor: colorScheme.primary.withValues(alpha: 0.24),
                      textColor: colorScheme.primary,
                      iconColor: colorScheme.primary,
                    ),
                    const Spacer(),
                    Container(
                      width: 48,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primary,
                            colorScheme.secondary,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  strings.dayHeading(DateTime.now()),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.18,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  summaryText,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1.08,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  detailText,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.86),
                  ),
                ),
                const SizedBox(height: 18),
                _HeroMetricWrap(
                  latest: latest,
                  entryCount: entryCount,
                  selectedTag: selectedTag,
                  chipBackground: Colors.black.withValues(alpha: 0.16),
                  chipBorder: colorScheme.primary.withValues(alpha: 0.26),
                  chipIcon: colorScheme.primary,
                  chipText: colorScheme.onSurface,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HackerHero extends StatelessWidget {
  const _HackerHero({
    required this.latest,
    required this.entryCount,
    required this.selectedTag,
    required this.summaryText,
    required this.detailText,
  });

  final DiaryEntry? latest;
  final int entryCount;
  final String? selectedTag;
  final String summaryText;
  final String detailText;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      constraints: const BoxConstraints(minHeight: 228),
      decoration: BoxDecoration(
        color: const Color(0xFF040804),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.34),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _HackerHeroPainter(
                primary: colorScheme.primary.withValues(alpha: 0.18),
                line: colorScheme.primary.withValues(alpha: 0.12),
                frame: colorScheme.secondary.withValues(alpha: 0.12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _HeroHeaderBadge(
                      label: strings.heroLabelForTheme(DiaryThemePreset.hacker),
                      icon: Icons.memory_outlined,
                      backgroundColor:
                          colorScheme.primary.withValues(alpha: 0.07),
                      borderColor: colorScheme.primary.withValues(alpha: 0.22),
                      textColor: colorScheme.primary,
                      iconColor: colorScheme.primary,
                    ),
                    const Spacer(),
                    Text(
                      '>_',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  strings.dayHeading(DateTime.now()),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  summaryText,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  detailText,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.82),
                    letterSpacing: 0.12,
                  ),
                ),
                const SizedBox(height: 18),
                _HeroMetricWrap(
                  latest: latest,
                  entryCount: entryCount,
                  selectedTag: selectedTag,
                  chipBackground: colorScheme.primary.withValues(alpha: 0.06),
                  chipBorder: colorScheme.primary.withValues(alpha: 0.18),
                  chipIcon: colorScheme.primary,
                  chipText: colorScheme.onSurface,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpaceLogHero extends StatelessWidget {
  const _SpaceLogHero({
    required this.latest,
    required this.entryCount,
    required this.selectedTag,
    required this.summaryText,
    required this.detailText,
  });

  final DiaryEntry? latest;
  final int entryCount;
  final String? selectedTag;
  final String summaryText;
  final String detailText;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final outline = colorScheme.outlineVariant;
    final surface = theme.cardTheme.color ?? colorScheme.surface;

    return Container(
      constraints: const BoxConstraints(minHeight: 228),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: outline, width: 1.35),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.07),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _SpaceLogHeroPainter(
                primary: colorScheme.primary.withValues(alpha: 0.18),
                secondary: outline.withValues(alpha: 0.88),
                accent: colorScheme.secondary.withValues(alpha: 0.2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.24),
                        ),
                      ),
                      child: Text(
                        strings.spaceLogLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.rocket_launch_outlined,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  strings.dayHeading(DateTime.now()),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.24,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  summaryText,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.12,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Text(
                    detailText,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _SpaceMetricChip(
                      icon: Icons.menu_book_outlined,
                      label: strings.entryCountLabel(entryCount),
                    ),
                    _SpaceMetricChip(
                      icon: Icons.sell_outlined,
                      label: strings.tagStatusLabel(selectedTag),
                    ),
                    if (latest != null)
                      _SpaceMetricChip(
                        icon: Icons.favorite_border,
                        label: strings.moodStatusLabel(latest!.mood),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpaceMetricChip extends StatelessWidget {
  const _SpaceMetricChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.9),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _NightHeroPainter extends CustomPainter {
  const _NightHeroPainter({
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
      const Offset(76, 64),
      48,
      Paint()..color = glow,
    );
    canvas.drawCircle(
      const Offset(84, 58),
      22,
      Paint()..color = line.withValues(alpha: 0.92),
    );
    final wave = Paint()
      ..color = line.withValues(alpha: 0.45)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromLTWH(size.width * 0.62, 22, 180, 120),
      2.8,
      2.4,
      false,
      wave,
    );
    for (final point in <Offset>[
      const Offset(146, 44),
      Offset(size.width * 0.36, 54),
      Offset(size.width * 0.54, 34),
      Offset(size.width * 0.82, 80),
      Offset(size.width * 0.9, 48),
    ]) {
      canvas.drawCircle(point, 1.6, Paint()..color = star);
    }
  }

  @override
  bool shouldRepaint(covariant _NightHeroPainter oldDelegate) {
    return oldDelegate.glow != glow ||
        oldDelegate.line != line ||
        oldDelegate.star != star;
  }
}

class _CyberpunkHeroPainter extends CustomPainter {
  const _CyberpunkHeroPainter({
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
      Rect.fromLTWH(size.width * 0.63, 0, size.width * 0.37, size.height),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary.withValues(alpha: 0),
            primary.withValues(alpha: 0.22),
            secondary.withValues(alpha: 0),
          ],
        ).createShader(
          Rect.fromLTWH(size.width * 0.63, 0, size.width * 0.37, size.height),
        ),
    );

    final linePaint = Paint()
      ..color = line
      ..strokeWidth = 1;
    for (double y = size.height * 0.72; y < size.height; y += 16) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
    canvas.drawLine(
      const Offset(24, 42),
      Offset(size.width * 0.44, 42),
      Paint()
        ..color = primary.withValues(alpha: 0.72)
        ..strokeWidth = 2.1,
    );
    canvas.drawLine(
      Offset(size.width - 120, 76),
      Offset(size.width - 24, 76),
      Paint()
        ..color = secondary.withValues(alpha: 0.72)
        ..strokeWidth = 2.1,
    );
  }

  @override
  bool shouldRepaint(covariant _CyberpunkHeroPainter oldDelegate) {
    return oldDelegate.primary != primary ||
        oldDelegate.secondary != secondary ||
        oldDelegate.line != line;
  }
}

class _HackerHeroPainter extends CustomPainter {
  const _HackerHeroPainter({
    required this.primary,
    required this.line,
    required this.frame,
  });

  final Color primary;
  final Color line;
  final Color frame;

  @override
  void paint(Canvas canvas, Size size) {
    for (double y = 0; y < size.height; y += 12) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..color = line
          ..strokeWidth = 1,
      );
    }
    for (final x in <double>[
      size.width * 0.1,
      size.width * 0.18,
      size.width * 0.74,
      size.width * 0.82,
    ]) {
      canvas.drawLine(
        Offset(x, 18),
        Offset(x, size.height - 18),
        Paint()
          ..color = primary.withValues(alpha: 0.16)
          ..strokeWidth = 1.6,
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(18, 18, size.width - 36, size.height - 36),
      Paint()
        ..color = frame
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );
  }

  @override
  bool shouldRepaint(covariant _HackerHeroPainter oldDelegate) {
    return oldDelegate.primary != primary ||
        oldDelegate.line != line ||
        oldDelegate.frame != frame;
  }
}

class _SpaceLogHeroPainter extends CustomPainter {
  const _SpaceLogHeroPainter({
    required this.primary,
    required this.secondary,
    required this.accent,
  });

  final Color primary;
  final Color secondary;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final horizontalLine = Paint()
      ..color = secondary.withValues(alpha: 0.55)
      ..strokeWidth = 1;
    final verticalLine = Paint()
      ..color = secondary.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    for (double y = 34; y < size.height; y += 36) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), horizontalLine);
    }

    for (double x = 48; x < size.width; x += 88) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), verticalLine);
    }

    final orbit = Paint()
      ..color = primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width * 0.88, size.height * 0.18),
        radius: size.shortestSide * 0.22,
      ),
      2.4,
      2.5,
      false,
      orbit,
    );
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width * 0.16, size.height * 0.9),
        radius: size.shortestSide * 0.26,
      ),
      4.9,
      2.1,
      false,
      orbit,
    );

    final accentPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width - 54, 34),
      5,
      accentPaint,
    );

    final bracket = Paint()
      ..color = primary.withValues(alpha: 0.74)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.square;
    _drawBracket(canvas, const Offset(18, 18), bracket, false, false);
    _drawBracket(
      canvas,
      Offset(size.width - 18, size.height - 18),
      bracket,
      true,
      true,
    );
  }

  void _drawBracket(
    Canvas canvas,
    Offset anchor,
    Paint paint,
    bool flipX,
    bool flipY,
  ) {
    final dx = flipX ? -1.0 : 1.0;
    final dy = flipY ? -1.0 : 1.0;
    canvas.drawLine(anchor, anchor.translate(24 * dx, 0), paint);
    canvas.drawLine(anchor, anchor.translate(0, 24 * dy), paint);
  }

  @override
  bool shouldRepaint(covariant _SpaceLogHeroPainter oldDelegate) {
    return oldDelegate.primary != primary ||
        oldDelegate.secondary != secondary ||
        oldDelegate.accent != accent;
  }
}
