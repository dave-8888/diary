import 'package:diary_mvp/app/app_display_name.dart';
import 'package:diary_mvp/app/localization/app_strings.dart';
import 'package:diary_mvp/app/themed_snackbar.dart';
import 'package:diary_mvp/features/diary/application/diary_controller.dart';
import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/diary_card.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/diary_shell.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/hidden_diary_password_dialogs.dart';
import 'package:diary_mvp/features/diary/services/hidden_diary_settings.dart';
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
    final showHiddenDiaries = ref.watch(showHiddenDiariesProvider);
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
                border: Border.all(
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.16),
                    blurRadius: 12,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
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
        data: (entries) => _HomeList(
          entries: showHiddenDiaries
              ? entries
              : entries
                  .where((entry) => !entry.isHidden)
                  .toList(growable: false),
          showHiddenDiaries: showHiddenDiaries,
        ),
      ),
    );
  }
}

enum _CalendarFilterMode { all, day, range }

enum _CalendarQuickPreset { none, today, last7Days, thisMonth }

class _HomeList extends ConsumerStatefulWidget {
  const _HomeList({
    required this.entries,
    required this.showHiddenDiaries,
  });

  final List<DiaryEntry> entries;
  final bool showHiddenDiaries;

  @override
  ConsumerState<_HomeList> createState() => _HomeListState();
}

class _HomeListState extends ConsumerState<_HomeList> {
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
    final listSpacing = MediaQuery.sizeOf(context).width < 720 ? 16.0 : 18.0;
    final entrySectionTitle = _sectionTitle(strings);
    final entryListContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (filteredEntries.isEmpty)
          _EmptyStateCard(
            title: emptyTitle,
            description: emptyDescription,
            buttonLabel: emptyButtonLabel,
            buttonIcon:
                hasEntries ? CupertinoIcons.clear_circled : CupertinoIcons.add,
            onPressed: hasEntries ? _clearFilter : () => context.go('/editor'),
          )
        else
          for (var index = 0; index < filteredEntries.length; index++) ...[
            DiaryCard(
              entry: filteredEntries[index],
              onEdit: () => _openEditor(context, filteredEntries[index]),
              onTap: () => _openEditor(context, filteredEntries[index]),
              onToggleHidden: () => _toggleEntryHidden(filteredEntries[index]),
            ),
            if (index != filteredEntries.length - 1)
              SizedBox(height: listSpacing),
          ],
      ],
    );
    final entryCountPill = _CountPill(
      key: const ValueKey<String>('home-entry-count-pill'),
      label: strings.entryCountLabel(filteredEntries.length),
    );
    final compactFilterPanel = SizedBox(
      key: const ValueKey<String>('home-calendar-filter-panel'),
      child: _CalendarFilterCard(
        mode: _filterMode,
        selectionLabel: _selectionLabel(strings),
        matchCount: filteredEntries.length,
        showHiddenDiaries: widget.showHiddenDiaries,
        onSelectAll: _clearFilter,
        onPickDay: () => _pickDay(context),
        onPickRange: () => _pickRange(context),
        onShowHiddenChanged: _handleShowHiddenChanged,
      ),
    );
    final entryListPanel = Column(
      key: const ValueKey<String>('home-entry-list-panel'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: entrySectionTitle,
          trailing: null,
        ),
        const SizedBox(height: 18),
        entryListContent,
      ],
    );
    final sidebar = _HomeSidebar(
      key: const ValueKey<String>('home-right-sidebar'),
      totalEntriesCount: entries.length,
      matchCount: filteredEntries.length,
      selectionLabel: _selectionLabel(strings),
      mode: _filterMode,
      activeQuickPreset: _activeQuickPreset,
      onSelectAll: _clearFilter,
      onSelectToday: _selectToday,
      onSelectLast7Days: _selectLast7Days,
      onSelectThisMonth: _selectThisMonth,
      onPickDay: () => _pickDay(context),
      onPickRange: () => _pickRange(context),
      showHiddenDiaries: widget.showHiddenDiaries,
      onShowHiddenChanged: _handleShowHiddenChanged,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideLayout = constraints.maxWidth > 960;
        if (!isWideLayout) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  compactFilterPanel,
                  const SizedBox(height: 36),
                  _SectionHeader(
                    title: entrySectionTitle,
                    trailing: entryCountPill,
                  ),
                  const SizedBox(height: 18),
                  entryListContent,
                ],
              ),
            ),
          );
        }

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    key: const ValueKey<String>('home-entry-scroll-view'),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 36),
                      child: entryListPanel,
                    ),
                  ),
                ),
                const SizedBox(width: 28),
                SizedBox(
                  width: 320,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: sidebar,
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

  Future<void> _handleShowHiddenChanged(bool enabled) async {
    if (!enabled) {
      ref.read(showHiddenDiariesProvider.notifier).state = false;
      return;
    }

    await requestHiddenDiaryAccess(context, ref);
  }

  Future<void> _toggleEntryHidden(DiaryEntry entry) async {
    final strings = context.strings;
    final nextIsHidden = !entry.isHidden;

    if (nextIsHidden) {
      final configured =
          await ensureHiddenDiaryPasswordConfigured(context, ref);
      if (!configured || !mounted) {
        return;
      }
    }

    try {
      await ref.read(diaryControllerProvider.notifier).setEntryHidden(
            entry: entry,
            isHidden: nextIsHidden,
          );
      if (!mounted) {
        return;
      }
      context.showAppSnackBar(
        nextIsHidden
            ? strings.diaryHiddenUpdated
            : strings.diaryUnhiddenUpdated,
        tone: AppSnackBarTone.success,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      context.showAppSnackBar(
        strings.hiddenDiaryUpdateFailed(error),
        tone: AppSnackBarTone.error,
      );
    }
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

  void _selectToday() {
    final today = DateUtils.dateOnly(DateTime.now());
    setState(() {
      _filterMode = _CalendarFilterMode.day;
      _selectedDay = today;
      _selectedRange = null;
    });
  }

  void _selectLast7Days() {
    final today = DateUtils.dateOnly(DateTime.now());
    setState(() {
      _filterMode = _CalendarFilterMode.range;
      _selectedRange = DateTimeRange(
        start: today.subtract(const Duration(days: 6)),
        end: today,
      );
      _selectedDay = null;
    });
  }

  void _selectThisMonth() {
    final today = DateUtils.dateOnly(DateTime.now());
    setState(() {
      _filterMode = _CalendarFilterMode.range;
      _selectedRange = DateTimeRange(
        start: DateTime(today.year, today.month),
        end: today,
      );
      _selectedDay = null;
    });
  }

  _CalendarQuickPreset get _activeQuickPreset {
    final today = DateUtils.dateOnly(DateTime.now());
    if (_filterMode == _CalendarFilterMode.day &&
        _selectedDay != null &&
        DateUtils.isSameDay(_selectedDay, today)) {
      return _CalendarQuickPreset.today;
    }
    if (_filterMode == _CalendarFilterMode.range && _selectedRange != null) {
      final start = DateUtils.dateOnly(_selectedRange!.start);
      final end = DateUtils.dateOnly(_selectedRange!.end);
      if (_matchesRange(
        start: start,
        end: end,
        expectedStart: today.subtract(const Duration(days: 6)),
        expectedEnd: today,
      )) {
        return _CalendarQuickPreset.last7Days;
      }
      if (_matchesRange(
        start: start,
        end: end,
        expectedStart: DateTime(today.year, today.month),
        expectedEnd: today,
      )) {
        return _CalendarQuickPreset.thisMonth;
      }
    }
    return _CalendarQuickPreset.none;
  }

  bool _matchesRange({
    required DateTime start,
    required DateTime end,
    required DateTime expectedStart,
    required DateTime expectedEnd,
  }) {
    return DateUtils.isSameDay(start, expectedStart) &&
        DateUtils.isSameDay(end, expectedEnd);
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

  String? _sectionTitle(AppStrings strings) {
    if (_filterMode == _CalendarFilterMode.day && _selectedDay != null) {
      return strings.entriesForDate(_selectedDay!);
    }
    if (_filterMode == _CalendarFilterMode.range && _selectedRange != null) {
      return strings.entriesForRange(
        _selectedRange!.start,
        _selectedRange!.end,
      );
    }
    return null;
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
    final isChinese =
        strings.locale.languageCode.toLowerCase().startsWith('zh');
    return showCupertinoModalPopup<DateTimeRange>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.18),
      builder: (popupContext) {
        var startDate = DateUtils.dateOnly(initialDateRange.start);
        var endDate = DateUtils.dateOnly(initialDateRange.end);
        var activeField = _CupertinoRangeField.start;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final activeDate =
                activeField == _CupertinoRangeField.start ? startDate : endDate;

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
                          label:
                              isChinese ? '\u5f00\u59cb\u65e5\u671f' : 'Start',
                          value:
                              _formatCalendarSelectionDate(strings, startDate),
                          selected: activeField == _CupertinoRangeField.start,
                          onTap: () => setModalState(() {
                            activeField = _CupertinoRangeField.start;
                          }),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _CupertinoRangeFieldButton(
                          label: isChinese ? '\u7ed3\u675f\u65e5\u671f' : 'End',
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
    required this.showHiddenDiaries,
    required this.onSelectAll,
    required this.onPickDay,
    required this.onPickRange,
    required this.onShowHiddenChanged,
  });

  final _CalendarFilterMode mode;
  final String selectionLabel;
  final int matchCount;
  final bool showHiddenDiaries;
  final VoidCallback onSelectAll;
  final VoidCallback onPickDay;
  final VoidCallback onPickRange;
  final ValueChanged<bool> onShowHiddenChanged;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              selectionLabel,
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                height: 1.12,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              strings.matchedEntryCountLabel(matchCount),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
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
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.showHiddenDiariesLabel,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        strings.showHiddenDiariesHint,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                CupertinoSwitch(
                  key: const ValueKey<String>('home-show-hidden-switch'),
                  value: showHiddenDiaries,
                  onChanged: onShowHiddenChanged,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeSidebar extends StatelessWidget {
  const _HomeSidebar({
    super.key,
    required this.totalEntriesCount,
    required this.matchCount,
    required this.selectionLabel,
    required this.mode,
    required this.activeQuickPreset,
    required this.onSelectAll,
    required this.onSelectToday,
    required this.onSelectLast7Days,
    required this.onSelectThisMonth,
    required this.onPickDay,
    required this.onPickRange,
    required this.showHiddenDiaries,
    required this.onShowHiddenChanged,
  });

  final int totalEntriesCount;
  final int matchCount;
  final String selectionLabel;
  final _CalendarFilterMode mode;
  final _CalendarQuickPreset activeQuickPreset;
  final VoidCallback onSelectAll;
  final VoidCallback onSelectToday;
  final VoidCallback onSelectLast7Days;
  final VoidCallback onSelectThisMonth;
  final VoidCallback onPickDay;
  final VoidCallback onPickRange;
  final bool showHiddenDiaries;
  final ValueChanged<bool> onShowHiddenChanged;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final modeLabel = _modeLabel(strings);
    final dayActionLabel =
        mode == _CalendarFilterMode.day ? strings.changeDate : strings.pickDate;
    final rangeActionLabel = mode == _CalendarFilterMode.range
        ? strings.changeDateRange
        : strings.pickDateRange;
    final quickFilterButtons = [
      _SidebarQuickFilterChip(
        key: const ValueKey<String>('home-quick-filter-all'),
        label: strings.viewAll,
        icon: CupertinoIcons.square_grid_2x2,
        selected: mode == _CalendarFilterMode.all,
        onTap: onSelectAll,
      ),
      _SidebarQuickFilterChip(
        key: const ValueKey<String>('home-quick-filter-today'),
        label: strings.today,
        icon: CupertinoIcons.sun_max,
        selected: activeQuickPreset == _CalendarQuickPreset.today,
        onTap: onSelectToday,
      ),
      _SidebarQuickFilterChip(
        key: const ValueKey<String>('home-quick-filter-last-7-days'),
        label: strings.last7Days,
        icon: CupertinoIcons.clock,
        selected: activeQuickPreset == _CalendarQuickPreset.last7Days,
        onTap: onSelectLast7Days,
      ),
      _SidebarQuickFilterChip(
        key: const ValueKey<String>('home-quick-filter-this-month'),
        label: strings.thisMonth,
        icon: CupertinoIcons.calendar_badge_plus,
        selected: activeQuickPreset == _CalendarQuickPreset.thisMonth,
        onTap: onSelectThisMonth,
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.browseOverviewTitle,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 10),
                _SidebarStatusChip(
                  icon: _modeIcon(),
                  label: modeLabel,
                ),
                const SizedBox(height: 14),
                Text(
                  selectionLabel,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    letterSpacing: -0.7,
                  ),
                ),
                const SizedBox(height: 14),
                _SidebarSectionLabel(label: strings.currentScopeTitle),
                const SizedBox(height: 8),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: _SidebarMetricTile(
                            key:
                                const ValueKey<String>('home-entry-count-pill'),
                            title: strings.totalEntriesTitle,
                            value: '$totalEntriesCount',
                            emphasized: false,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 46,
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                        Expanded(
                          child: _SidebarMetricTile(
                            key:
                                const ValueKey<String>('home-match-count-pill'),
                            title: strings.matchedEntriesTitle,
                            value: '$matchCount',
                            emphasized: true,
                            compact: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _SidebarSectionLabel(label: strings.quickFiltersTitle),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: quickFilterButtons,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          key: const ValueKey<String>('home-calendar-filter-panel'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SidebarSectionLabel(label: strings.customFiltersTitle),
                const SizedBox(height: 14),
                _SidebarFilterOption(
                  title: dayActionLabel,
                  subtitle: mode == _CalendarFilterMode.day
                      ? selectionLabel
                      : strings.singleDateFilter,
                  icon: CupertinoIcons.calendar_today,
                  selected: mode == _CalendarFilterMode.day,
                  onTap: onPickDay,
                ),
                const SizedBox(height: 10),
                _SidebarFilterOption(
                  title: rangeActionLabel,
                  subtitle: mode == _CalendarFilterMode.range
                      ? selectionLabel
                      : strings.rangeFilter,
                  icon: CupertinoIcons.calendar,
                  selected: mode == _CalendarFilterMode.range,
                  onTap: onPickRange,
                ),
                const SizedBox(height: 16),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.24),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                strings.showHiddenDiariesLabel,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                strings.showHiddenDiariesHint,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        CupertinoSwitch(
                          key:
                              const ValueKey<String>('home-show-hidden-switch'),
                          value: showHiddenDiaries,
                          onChanged: onShowHiddenChanged,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _modeLabel(AppStrings strings) {
    switch (mode) {
      case _CalendarFilterMode.all:
        return strings.allDatesLabel;
      case _CalendarFilterMode.day:
        return strings.singleDateFilter;
      case _CalendarFilterMode.range:
        return strings.rangeFilter;
    }
  }

  IconData _modeIcon() {
    switch (mode) {
      case _CalendarFilterMode.all:
        return CupertinoIcons.square_grid_2x2;
      case _CalendarFilterMode.day:
        return CupertinoIcons.calendar_today;
      case _CalendarFilterMode.range:
        return CupertinoIcons.calendar;
    }
  }
}

class _SidebarStatusChip extends StatelessWidget {
  const _SidebarStatusChip({
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
        color: colorScheme.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarSectionLabel extends StatelessWidget {
  const _SidebarSectionLabel({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Text(
      label,
      style: theme.textTheme.labelLarge?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _SidebarQuickFilterChip extends StatelessWidget {
  const _SidebarQuickFilterChip({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
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
              ? colorScheme.primary.withValues(alpha: 0.1)
              : colorScheme.surface.withValues(alpha: 0.24),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? colorScheme.primary.withValues(alpha: 0.18)
                : colorScheme.outlineVariant.withValues(alpha: 0.24),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: selected ? colorScheme.primary : colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarMetricTile extends StatelessWidget {
  const _SidebarMetricTile({
    super.key,
    required this.title,
    required this.value,
    required this.emphasized,
    this.compact = false,
  });

  final String title;
  final String value;
  final bool emphasized;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Padding(
        padding: EdgeInsets.only(left: compact ? 12 : 0, right: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: (compact
                      ? theme.textTheme.headlineMedium
                      : theme.textTheme.headlineSmall)
                  ?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: emphasized ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: emphasized
                    ? colorScheme.primary.withValues(alpha: 0.88)
                    : colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarFilterOption extends StatelessWidget {
  const _SidebarFilterOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
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
              ? colorScheme.primary.withValues(alpha: 0.1)
              : colorScheme.surface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected
                ? colorScheme.primary.withValues(alpha: 0.18)
                : colorScheme.outlineVariant.withValues(alpha: 0.24),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: selected
                      ? colorScheme.primary.withValues(alpha: 0.16)
                      : colorScheme.surface.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    icon,
                    size: 18,
                    color: selected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: selected
                            ? colorScheme.primary.withValues(alpha: 0.84)
                            : colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected
                    ? CupertinoIcons.check_mark_circled_solid
                    : CupertinoIcons.chevron_right,
                size: selected ? 20 : 16,
                color: selected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
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
    this.title,
    this.trailing,
  });

  final String? title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompact = MediaQuery.sizeOf(context).width < 720;
    final title = this.title;
    final hasTitle = title != null && title.trim().isNotEmpty;

    if (!hasTitle) {
      if (trailing == null) {
        return const SizedBox.shrink();
      }
      return Align(
        alignment: Alignment.centerRight,
        child: trailing,
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: isCompact ? 26 : 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.8,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({
    super.key,
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
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
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.book_circle,
                  size: 32,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.8,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  onPressed: onPressed,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color:
                            theme.colorScheme.primary.withValues(alpha: 0.18),
                      ),
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
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            buttonLabel,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.primary,
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
              ? colorScheme.primary.withValues(alpha: 0.08)
              : colorScheme.surface.withValues(alpha: 0.36),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? colorScheme.primary.withValues(alpha: 0.14)
                : colorScheme.outlineVariant.withValues(alpha: 0.24),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: DefaultTextStyle.merge(
            style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
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
                  color:
                      theme.colorScheme.outlineVariant.withValues(alpha: 0.32),
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
                  color: selected ? colorScheme.primary : colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
