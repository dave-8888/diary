import 'package:diary_mvp/app/app_display_name.dart';
import 'package:diary_mvp/app/localization/app_strings.dart';
import 'package:diary_mvp/features/diary/application/diary_controller.dart';
import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/diary_card.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/diary_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
    final filteredEntries = _filteredEntries;
    final hasEntries = entries.isNotEmpty;
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
          _CalendarFilterCard(
            mode: _filterMode,
            selectionLabel: _selectionLabel(strings),
            matchCount: filteredEntries.length,
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
      initialEntryMode: DatePickerEntryMode.inputOnly,
      builder: _buildExpandedDatePickerDialog,
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
      initialEntryMode: DatePickerEntryMode.inputOnly,
      builder: _buildExpandedDatePickerDialog,
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
      return _formatCalendarSelectionDate(strings, _selectedDay!);
    }
    if (_filterMode == _CalendarFilterMode.range && _selectedRange != null) {
      return _formatCalendarSelectionRange(
        strings,
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

  String _formatCalendarSelectionDate(AppStrings strings, DateTime date) {
    final normalized = DateUtils.dateOnly(date);
    final now = DateUtils.dateOnly(DateTime.now());
    final pattern = normalized.year == now.year ? 'MM-dd' : 'yyyy-MM-dd';
    return DateFormat(pattern, strings.locale.languageCode).format(normalized);
  }

  String _formatCalendarSelectionRange(
    AppStrings strings,
    DateTime start,
    DateTime end,
  ) {
    final startLabel = _formatCalendarSelectionDate(strings, start);
    final endLabel = _formatCalendarSelectionDate(strings, end);
    if (DateUtils.isSameDay(start, end)) {
      return startLabel;
    }
    return '$startLabel - $endLabel';
  }

  Widget _buildExpandedDatePickerDialog(BuildContext context, Widget? child) {
    if (child == null) {
      return const SizedBox.shrink();
    }

    final inheritedTheme = Theme.of(context);
    final screenSize = MediaQuery.sizeOf(context);
    final shouldExpand = screenSize.width >= 540 && screenSize.height >= 420;
    final portraitWidth = screenSize.width < screenSize.height
        ? screenSize.width
        : screenSize.height;
    final portraitHeight = screenSize.width < screenSize.height
        ? screenSize.height
        : screenSize.width;

    final themedChild = Theme(
      data: inheritedTheme.copyWith(
        datePickerTheme: inheritedTheme.datePickerTheme.copyWith(
          headerForegroundColor: Colors.transparent,
          headerHeadlineStyle: const TextStyle(fontSize: 0, height: 0.01),
          rangePickerHeaderForegroundColor: Colors.transparent,
          rangePickerHeaderHeadlineStyle: const TextStyle(
            fontSize: 0,
            height: 0.01,
          ),
        ),
      ),
      child: child,
    );

    final compactDesktopChild = MediaQuery(
      data: MediaQuery.of(context).copyWith(
        size: Size(portraitWidth, portraitHeight),
      ),
      child: SizedBox(
        height: 164,
        child: themedChild,
      ),
    );

    if (!shouldExpand) {
      return themedChild;
    }

    return Center(
      child: Transform.scale(
        scale: 1.12,
        child: compactDesktopChild,
      ),
    );
  }
}

class _CalendarFilterCard extends StatelessWidget {
  const _CalendarFilterCard({
    required this.mode,
    required this.selectionLabel,
    required this.matchCount,
    required this.onSelectAll,
    required this.onPickDay,
    required this.onPickRange,
  });

  final _CalendarFilterMode mode;
  final String selectionLabel;
  final int matchCount;
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
                    label: Text(strings.pickDate),
                    selected: mode == _CalendarFilterMode.day,
                    onSelected: (_) => onPickDay(),
                  ),
                  ChoiceChip(
                    label: Text(strings.pickDateRange),
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
