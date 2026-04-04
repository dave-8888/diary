import 'package:diary_mvp/app/app_display_name.dart';
import 'package:diary_mvp/app/localization/app_strings.dart';
import 'package:diary_mvp/features/diary/application/diary_controller.dart';
import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/diary_card.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/diary_shell.dart';
import 'package:flutter/cupertino.dart';
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
      floatingActionButton: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        onPressed: () => context.go('/editor'),
        child: Builder(
          builder: (context) {
            final theme = Theme.of(context);
            return DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.24),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.add,
                      size: 18,
                      color: theme.colorScheme.onPrimary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      strings.newEntry,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      child: entriesAsync.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
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
                  ? CupertinoIcons.clear_circled
                  : CupertinoIcons.add,
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
    final bounds = _resolveSelectableBounds();
    final initialDate = _clampDate(
      _selectedDay ??
          _selectedRange?.start ??
          _latestEntryDate ??
          DateTime.now(),
      bounds,
    );
    final cupertinoPicked = await _showCupertinoDayPicker(
      context,
      initialDate: initialDate,
      firstDate: bounds.firstDate,
      lastDate: bounds.lastDate,
    );
    if (!mounted || cupertinoPicked == null) return;
    setState(() {
      _filterMode = _CalendarFilterMode.day;
      _selectedDay = DateUtils.dateOnly(cupertinoPicked);
      _selectedRange = null;
    });
  }

  Future<void> _pickRange(BuildContext context) async {
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
    final picked = await _showCupertinoRangePicker(
      context,
      initialDateRange: initialDateRange,
      firstDate: bounds.firstDate,
      lastDate: bounds.lastDate,
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

  Future<DateTime?> _showCupertinoDayPicker(
    BuildContext context, {
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) {
    final strings = context.strings;
    return showCupertinoModalPopup<DateTime>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.18),
      builder: (popupContext) {
        var pendingDate = DateUtils.dateOnly(initialDate);
        return _CupertinoPickerSheet(
          title: strings.pickDate,
          cancelLabel: strings.cancelAction,
          confirmLabel: strings.saveAction,
          onCancel: () => Navigator.of(popupContext).pop(),
          onConfirm: () => Navigator.of(popupContext).pop(pendingDate),
          child: SizedBox(
            height: 216,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              initialDateTime: pendingDate,
              minimumDate: firstDate,
              maximumDate: lastDate,
              onDateTimeChanged: (value) {
                pendingDate = DateUtils.dateOnly(value);
              },
            ),
          ),
        );
      },
    );
  }

  Future<DateTimeRange?> _showCupertinoRangePicker(
    BuildContext context, {
    required DateTimeRange initialDateRange,
    required DateTime firstDate,
    required DateTime lastDate,
  }) {
    final strings = context.strings;
    final isChinese = strings.locale.languageCode.toLowerCase().startsWith('zh');
    return showCupertinoModalPopup<DateTimeRange>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.18),
      builder: (popupContext) {
        var startDate = DateUtils.dateOnly(initialDateRange.start);
        var endDate = DateUtils.dateOnly(initialDateRange.end);
        var activeField = _CupertinoRangeField.start;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final activeDate = activeField == _CupertinoRangeField.start
                ? startDate
                : endDate;

            return _CupertinoPickerSheet(
              title: strings.pickDateRange,
              cancelLabel: strings.cancelAction,
              confirmLabel: strings.saveAction,
              onCancel: () => Navigator.of(popupContext).pop(),
              onConfirm: () => Navigator.of(popupContext).pop(
                DateTimeRange(start: startDate, end: endDate),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _CupertinoRangeFieldButton(
                          label: isChinese ? '开始日期' : 'Start',
                          value: _formatCalendarSelectionDate(strings, startDate),
                          selected: activeField == _CupertinoRangeField.start,
                          onTap: () => setModalState(() {
                            activeField = _CupertinoRangeField.start;
                          }),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _CupertinoRangeFieldButton(
                          label: isChinese ? '结束日期' : 'End',
                          value: _formatCalendarSelectionDate(strings, endDate),
                          selected: activeField == _CupertinoRangeField.end,
                          onTap: () => setModalState(() {
                            activeField = _CupertinoRangeField.end;
                          }),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 216,
                    child: CupertinoDatePicker(
                      key: ValueKey<String>(
                        '${activeField.name}-${activeDate.toIso8601String()}',
                      ),
                      mode: CupertinoDatePickerMode.date,
                      initialDateTime: activeDate,
                      minimumDate: firstDate,
                      maximumDate: lastDate,
                      onDateTimeChanged: (value) {
                        final normalized = DateUtils.dateOnly(value);
                        setModalState(() {
                          if (activeField == _CupertinoRangeField.start) {
                            startDate = normalized;
                            if (startDate.isAfter(endDate)) {
                              endDate = startDate;
                            }
                          } else {
                            endDate = normalized;
                            if (endDate.isBefore(startDate)) {
                              startDate = endDate;
                            }
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
                  _FilterActionPill(
                    label: Text(strings.viewAll),
                    selected: mode == _CalendarFilterMode.all,
                    onTap: onSelectAll,
                  ),
                  _FilterActionPill(
                    label: Text(strings.pickDate),
                    selected: mode == _CalendarFilterMode.day,
                    onTap: onPickDay,
                  ),
                  _FilterActionPill(
                    label: Text(strings.pickDateRange),
                    selected: mode == _CalendarFilterMode.range,
                    onTap: onPickRange,
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
                    icon: CupertinoIcons.calendar,
                  ),
                  _CountPill(
                    label: strings.matchedEntryCountLabel(matchCount),
                    icon: CupertinoIcons.book,
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
                  CupertinoIcons.book_circle,
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
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              onPressed: onPressed,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        buttonIcon,
                        size: 18,
                        color: theme.colorScheme.onPrimary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        buttonLabel,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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

enum _CupertinoRangeField { start, end }

class _FilterActionPill extends StatelessWidget {
  const _FilterActionPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Widget label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary.withValues(alpha: 0.12)
              : colorScheme.surface.withValues(alpha: 0.58),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? colorScheme.primary.withValues(alpha: 0.18)
                : colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: DefaultTextStyle.merge(
            style: theme.textTheme.labelLarge?.copyWith(
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ) ??
                TextStyle(
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
            child: label,
          ),
        ),
      ),
    );
  }
}

class _CupertinoPickerSheet extends StatelessWidget {
  const _CupertinoPickerSheet({
    required this.title,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.onCancel,
    required this.onConfirm,
    required this.child,
  });

  final String title;
  final String cancelLabel;
  final String confirmLabel;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: CupertinoPopupSurface(
            isSurfacePainted: false,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.cardTheme.color ?? theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.32),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          onPressed: onCancel,
                          child: Text(cancelLabel),
                        ),
                        Expanded(
                          child: Text(
                            title,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          onPressed: onConfirm,
                          child: Text(confirmLabel),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    child,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CupertinoRangeFieldButton extends StatelessWidget {
  const _CupertinoRangeFieldButton({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary.withValues(alpha: 0.12)
              : colorScheme.surface.withValues(alpha: 0.58),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? colorScheme.primary.withValues(alpha: 0.18)
                : colorScheme.outlineVariant.withValues(alpha: 0.32),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
