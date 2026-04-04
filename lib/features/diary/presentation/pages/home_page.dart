import 'package:diary_mvp/app/app_display_name.dart';
import 'package:diary_mvp/app/localization/app_strings.dart';
import 'package:diary_mvp/features/diary/application/diary_controller.dart';
import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/diary_card.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/diary_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = context.strings;
    final entriesAsync = ref.watch(diaryControllerProvider);
    final customAppNameAsync = ref.watch(appDisplayNameControllerProvider);
    final appTitle = resolveAppDisplayName(
      strings: strings,
      customNameAsync: customAppNameAsync,
    );

    return DiaryShell(
      title: appTitle,
      showAppBarTitle: false,
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
        data: (entries) => _HomeList(entries: entries),
      ),
    );
  }
}

enum _CalendarFilterMode { all, day, range }

class _HomeList extends StatefulWidget {
  const _HomeList({
    required this.entries,
  });

  final List<DiaryEntry> entries;

  @override
  State<_HomeList> createState() => _HomeListState();
}

class _HomeListState extends State<_HomeList> {
  _CalendarFilterMode _filterMode = _CalendarFilterMode.all;
  DateTime? _selectedDay;
  DateTimeRange? _selectedRange;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final entries = widget.entries;
    final latest = entries.isNotEmpty ? entries.first : null;
    final filteredEntries = _filteredEntries;
    final hasEntries = entries.isNotEmpty;
    final hasActiveFilter = _hasActiveFilter;
    final emptyTitle =
        hasEntries ? _emptyStateTitle(strings) : strings.noEntriesYet;
    final emptyDescription =
        hasEntries ? strings.calendarFilterEmptyHint : strings.firstEntryPrompt;
    final emptyButtonLabel =
        hasEntries ? strings.clearDateFilter : strings.newEntry;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HomeHero(
            latest: latest,
            entryCount: entries.length,
          ),
          const SizedBox(height: 18),
          _CalendarFilterCard(
            mode: _filterMode,
            selectionLabel: _selectionLabel(strings),
            matchCount: filteredEntries.length,
            hasActiveFilter: hasActiveFilter,
            hasDaySelection: _selectedDay != null,
            hasRangeSelection: _selectedRange != null,
            onSelectAll: _clearFilter,
            onPickDay: () => _pickDay(context),
            onPickRange: () => _pickRange(context),
          ),
          const SizedBox(height: 22),
          _SectionHeader(
            title: _sectionTitle(strings),
            trailing: _CountPill(
              label: strings.entryCountLabel(filteredEntries.length),
            ),
          ),
          const SizedBox(height: 14),
          if (filteredEntries.isEmpty)
            _EmptyStateCard(
              title: emptyTitle,
              description: emptyDescription,
              buttonLabel: emptyButtonLabel,
              buttonIcon: hasEntries
                  ? Icons.filter_alt_off_outlined
                  : Icons.add_rounded,
              onPressed:
                  hasEntries ? _clearFilter : () => context.go('/editor'),
            )
          else
            ...filteredEntries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: DiaryCard(
                  entry: entry,
                  onEdit: () => _openEditor(context, entry),
                  onTap: () => _openEditor(context, entry),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<DiaryEntry> get _filteredEntries {
    switch (_filterMode) {
      case _CalendarFilterMode.all:
        return widget.entries;
      case _CalendarFilterMode.day:
        final selectedDay = _selectedDay;
        if (selectedDay == null) return widget.entries;
        return widget.entries
            .where((entry) => DateUtils.isSameDay(entry.createdAt, selectedDay))
            .toList(growable: false);
      case _CalendarFilterMode.range:
        final selectedRange = _selectedRange;
        if (selectedRange == null) return widget.entries;
        final start = DateUtils.dateOnly(selectedRange.start);
        final end = DateUtils.dateOnly(selectedRange.end);
        return widget.entries.where((entry) {
          final entryDay = DateUtils.dateOnly(entry.createdAt);
          return !entryDay.isBefore(start) && !entryDay.isAfter(end);
        }).toList(growable: false);
    }
  }

  bool get _hasActiveFilter {
    return (_filterMode == _CalendarFilterMode.day && _selectedDay != null) ||
        (_filterMode == _CalendarFilterMode.range && _selectedRange != null);
  }

  void _openEditor(BuildContext context, DiaryEntry entry) {
    context.push('/editor', extra: entry);
  }

  Future<void> _pickDay(BuildContext context) async {
    final strings = context.strings;
    final bounds = _resolveSelectableBounds();
    final initialDate = _clampDate(
      _selectedDay ??
          _selectedRange?.start ??
          _latestEntryDate ??
          DateTime.now(),
      bounds,
    );
    final picked = await showDatePicker(
      context: context,
      locale: strings.locale,
      initialDate: initialDate,
      firstDate: bounds.firstDate,
      lastDate: bounds.lastDate,
    );
    if (!mounted || picked == null) return;
    setState(() {
      _filterMode = _CalendarFilterMode.day;
      _selectedDay = DateUtils.dateOnly(picked);
      _selectedRange = null;
    });
  }

  Future<void> _pickRange(BuildContext context) async {
    final strings = context.strings;
    final bounds = _resolveSelectableBounds();
    final fallbackEnd = _clampDate(
      _selectedDay ?? _latestEntryDate ?? DateTime.now(),
      bounds,
    );
    var fallbackStart = fallbackEnd.subtract(const Duration(days: 6));
    if (fallbackStart.isBefore(bounds.firstDate)) {
      fallbackStart = bounds.firstDate;
    }
    final currentRange = _selectedRange;
    final initialDateRange = currentRange == null
        ? DateTimeRange(start: fallbackStart, end: fallbackEnd)
        : DateTimeRange(
            start: _clampDate(currentRange.start, bounds),
            end: _clampDate(currentRange.end, bounds),
          );
    final picked = await showDateRangePicker(
      context: context,
      locale: strings.locale,
      firstDate: bounds.firstDate,
      lastDate: bounds.lastDate,
      initialDateRange: initialDateRange,
    );
    if (!mounted || picked == null) return;
    setState(() {
      _filterMode = _CalendarFilterMode.range;
      _selectedRange = DateTimeRange(
        start: DateUtils.dateOnly(picked.start),
        end: DateUtils.dateOnly(picked.end),
      );
      _selectedDay = null;
    });
  }

  void _clearFilter() {
    setState(() {
      _filterMode = _CalendarFilterMode.all;
      _selectedDay = null;
      _selectedRange = null;
    });
  }

  String _selectionLabel(AppStrings strings) {
    if (_filterMode == _CalendarFilterMode.day && _selectedDay != null) {
      return strings.formatDay(_selectedDay!);
    }
    if (_filterMode == _CalendarFilterMode.range && _selectedRange != null) {
      return strings.dateRangeLabel(
        _selectedRange!.start,
        _selectedRange!.end,
      );
    }
    return strings.allDatesLabel;
  }

  String _sectionTitle(AppStrings strings) {
    if (_filterMode == _CalendarFilterMode.day && _selectedDay != null) {
      return strings.entriesForDate(_selectedDay!);
    }
    if (_filterMode == _CalendarFilterMode.range && _selectedRange != null) {
      return strings.entriesForRange(
        _selectedRange!.start,
        _selectedRange!.end,
      );
    }
    return strings.recentEntries;
  }

  String _emptyStateTitle(AppStrings strings) {
    if (_filterMode == _CalendarFilterMode.day && _selectedDay != null) {
      return strings.noEntriesForDate(_selectedDay!);
    }
    if (_filterMode == _CalendarFilterMode.range && _selectedRange != null) {
      return strings.noEntriesForRange(
        _selectedRange!.start,
        _selectedRange!.end,
      );
    }
    return strings.noEntriesYet;
  }

  DateTime? get _latestEntryDate {
    if (widget.entries.isEmpty) return null;
    return DateUtils.dateOnly(widget.entries.first.createdAt);
  }

  _SelectableDateBounds _resolveSelectableBounds() {
    final now = DateUtils.dateOnly(DateTime.now());
    var firstDate = DateTime(now.year - 10, 1, 1);
    var lastDate = DateTime(now.year + 1, 12, 31);

    for (final entry in widget.entries) {
      final entryDay = DateUtils.dateOnly(entry.createdAt);
      if (entryDay.isBefore(firstDate)) {
        firstDate = entryDay;
      }
      if (entryDay.isAfter(lastDate)) {
        lastDate = entryDay;
      }
    }

    return _SelectableDateBounds(
      firstDate: firstDate,
      lastDate: lastDate,
    );
  }

  DateTime _clampDate(DateTime value, _SelectableDateBounds bounds) {
    final normalized = DateUtils.dateOnly(value);
    if (normalized.isBefore(bounds.firstDate)) {
      return bounds.firstDate;
    }
    if (normalized.isAfter(bounds.lastDate)) {
      return bounds.lastDate;
    }
    return normalized;
  }
}

class _HomeHero extends StatelessWidget {
  const _HomeHero({
    required this.latest,
    required this.entryCount,
  });

  final DiaryEntry? latest;
  final int entryCount;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final latestDateLabel = latest == null
        ? strings.noEntriesYet
        : strings.formatDateTime(latest!.createdAt);
    final latestTags = latest?.tags.length ?? 0;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withValues(
                alpha: colorScheme.brightness == Brightness.dark ? 0.22 : 0.12,
              ),
              theme.cardTheme.color ?? colorScheme.surface,
              colorScheme.secondary.withValues(
                alpha: colorScheme.brightness == Brightness.dark ? 0.16 : 0.08,
              ),
            ],
            stops: const [0, 0.56, 1],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -56,
              right: -24,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.22),
                      blurRadius: 70,
                      spreadRadius: 18,
                    ),
                  ],
                ),
                child: const SizedBox(width: 180, height: 180),
              ),
            ),
            Positioned(
              left: 28,
              right: 28,
              bottom: 26,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.32),
                    ),
                  ),
                ),
                child: const SizedBox(height: 1),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CountPill(
                    label: strings.dayHeading(DateTime.now()),
                    icon: Icons.wb_twilight_outlined,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    strings.latestSummary(latest),
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontSize: 30,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    latestDateLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _HeroMetric(
                        icon: Icons.menu_book_outlined,
                        label: entryCount.toString(),
                      ),
                      if (latest != null)
                        _HeroMetric(
                          icon: Icons.favorite_outline,
                          label: strings.moodStatusLabel(latest!.mood),
                        ),
                      if (latest != null)
                        _HeroMetric(
                          icon: Icons.sell_outlined,
                          label: latestTags == 0
                              ? strings.tagsLabel
                              : '${strings.tagsLabel} $latestTags',
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: () => context.go('/editor'),
                        icon: const Icon(Icons.add_rounded),
                        label: Text(strings.newEntry),
                      ),
                      if (latest != null)
                        OutlinedButton.icon(
                          onPressed: () =>
                              context.push('/editor', extra: latest),
                          icon: const Icon(Icons.edit_outlined),
                          label: Text(strings.editEntry),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarFilterCard extends StatelessWidget {
  const _CalendarFilterCard({
    required this.mode,
    required this.selectionLabel,
    required this.matchCount,
    required this.hasActiveFilter,
    required this.hasDaySelection,
    required this.hasRangeSelection,
    required this.onSelectAll,
    required this.onPickDay,
    required this.onPickRange,
  });

  final _CalendarFilterMode mode;
  final String selectionLabel;
  final int matchCount;
  final bool hasActiveFilter;
  final bool hasDaySelection;
  final bool hasRangeSelection;
  final VoidCallback onSelectAll;
  final VoidCallback onPickDay;
  final VoidCallback onPickRange;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.secondary.withValues(
                alpha: colorScheme.brightness == Brightness.dark ? 0.16 : 0.08,
              ),
              theme.cardTheme.color ?? colorScheme.surface,
              colorScheme.primary.withValues(
                alpha: colorScheme.brightness == Brightness.dark ? 0.14 : 0.06,
              ),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.calendar_month_outlined,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.calendarViewTitle,
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          strings.calendarViewHint,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ChoiceChip(
                    label: Text(strings.viewAll),
                    selected: mode == _CalendarFilterMode.all,
                    onSelected: (_) => onSelectAll(),
                  ),
                  ChoiceChip(
                    label: Text(strings.singleDateFilter),
                    selected: mode == _CalendarFilterMode.day,
                    onSelected: (_) => onPickDay(),
                  ),
                  ChoiceChip(
                    label: Text(strings.rangeFilter),
                    selected: mode == _CalendarFilterMode.range,
                    onSelected: (_) => onPickRange(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _CountPill(
                    label: selectionLabel,
                    icon: Icons.event_outlined,
                  ),
                  _CountPill(
                    label: strings.matchedEntryCountLabel(matchCount),
                    icon: Icons.menu_book_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: onPickDay,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(
                      hasDaySelection ? strings.changeDate : strings.pickDate,
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: onPickRange,
                    icon: const Icon(Icons.date_range_outlined),
                    label: Text(
                      hasRangeSelection
                          ? strings.changeDateRange
                          : strings.pickDateRange,
                    ),
                  ),
                  if (hasActiveFilter)
                    TextButton.icon(
                      onPressed: onSelectAll,
                      icon: const Icon(Icons.filter_alt_off_outlined),
                      label: Text(strings.clearDateFilter),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleLarge,
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.54),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.36),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({
    required this.label,
    this.icon,
  });

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: theme.textTheme.labelLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
    this.buttonIcon = Icons.add_rounded,
  });

  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback onPressed;
  final IconData buttonIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Icon(
                  Icons.auto_stories_outlined,
                  size: 28,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onPressed,
              icon: Icon(buttonIcon),
              label: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectableDateBounds {
  const _SelectableDateBounds({
    required this.firstDate,
    required this.lastDate,
  });

  final DateTime firstDate;
  final DateTime lastDate;
}
