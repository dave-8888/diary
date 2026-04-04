import 'package:diary_mvp/app/cupertino_kit.dart';
import 'package:diary_mvp/app/localization/app_strings.dart';
import 'package:diary_mvp/app/context_tooltip.dart';
import 'package:diary_mvp/app/themed_snackbar.dart';
import 'package:diary_mvp/features/diary/application/diary_controller.dart';
import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/diary_shell.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/entry_list_preview.dart';
import 'package:diary_mvp/features/diary/services/diary_list_settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TrashPage extends ConsumerStatefulWidget {
  const TrashPage({super.key});

  @override
  ConsumerState<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends ConsumerState<TrashPage> {
  final Set<String> _selectedIds = <String>{};
  bool _isRestoring = false;
  bool _isClearing = false;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final showVisualMedia = ref
            .watch(diaryListVisualMediaVisibilityControllerProvider)
            .valueOrNull ??
        true;
    final trashAsync = ref.watch(trashDiaryControllerProvider);

    return DiaryShell(
      title: strings.trashNav,
      showAppBarTitle: false,
      child: trashAsync.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (error, stack) =>
            Center(child: Text(strings.failedToLoadTrash(error))),
        data: (entries) {
          _selectedIds.removeWhere(
            (id) => !entries.any((entry) => entry.id == id),
          );

          if (entries.isEmpty) {
            return Center(child: Text(strings.trashEmpty));
          }

          final selectedCount = _selectedIds.length;
          final allSelected = selectedCount == entries.length;

          return ListView(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        strings.trashNav,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      ContextTooltip(message: strings.trashedEntryHint),
                      CupertinoPill(
                        label: Text(strings.selectedEntries(selectedCount)),
                      ),
                      CupertinoActionButton(
                        onPressed:
                            _isRestoring || _isClearing || selectedCount == 0
                                ? null
                                : () => _restoreEntries(
                                      entries
                                          .where(
                                            (entry) =>
                                            _selectedIds.contains(entry.id),
                                          )
                                          .toList(growable: false),
                                    ),
                        isBusy: _isRestoring,
                        icon: Icons.restore_outlined,
                        label: strings.restoreSelected,
                      ),
                      CupertinoActionButton(
                        onPressed: () => setState(() {
                          if (allSelected) {
                            _selectedIds.clear();
                          } else {
                            _selectedIds
                              ..clear()
                              ..addAll(entries.map((entry) => entry.id));
                          }
                        }),
                        variant: CupertinoActionButtonVariant.outline,
                        label: allSelected
                            ? strings.clearSelection
                            : strings.selectAll,
                      ),
                      CupertinoActionButton(
                        onPressed: _isRestoring || _isClearing
                            ? null
                            : () => _confirmAndClearTrash(entries),
                        isBusy: _isClearing,
                        variant: CupertinoActionButtonVariant.tinted,
                        destructive: true,
                        icon: Icons.delete_sweep_outlined,
                        label: strings.clearTrash,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TrashEntryCard(
                    entry: entry,
                    showVisualMedia: showVisualMedia,
                    selected: _selectedIds.contains(entry.id),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedIds.add(entry.id);
                        } else {
                          _selectedIds.remove(entry.id);
                        }
                      });
                    },
                    onPreview: () =>
                        context.push('/trash/preview', extra: entry),
                    onRestore: _isRestoring || _isClearing
                        ? null
                        : () => _restoreEntries([entry]),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _restoreEntries(List<DiaryEntry> entries) async {
    if (entries.isEmpty) return;

    final strings = context.strings;
    setState(() => _isRestoring = true);
    try {
      await ref
          .read(trashDiaryControllerProvider.notifier)
          .restoreEntries(entries);
      if (!mounted) return;
      setState(() {
        _isRestoring = false;
        _selectedIds.removeAll(entries.map((entry) => entry.id));
      });
      context.showAppSnackBar(
        strings.restoredEntries(entries.length),
        tone: AppSnackBarTone.success,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isRestoring = false);
      context.showAppSnackBar(
        strings.restoreFailed(error),
        tone: AppSnackBarTone.error,
      );
    }
  }

  Future<void> _confirmAndClearTrash(List<DiaryEntry> entries) async {
    if (entries.isEmpty) return;

    final strings = context.strings;
    final confirmed = await showCupertinoConfirmationDialog(
      context,
      title: strings.clearTrashConfirmTitle,
      message: strings.clearTrashConfirmMessage(entries.length),
      cancelLabel: strings.cancelAction,
      confirmLabel: strings.confirmClearTrash,
      isDestructive: true,
    );

    if (!confirmed || !mounted) return;

    setState(() => _isClearing = true);
    try {
      await ref.read(trashDiaryControllerProvider.notifier).clearTrash(entries);
      if (!mounted) return;
      setState(() {
        _isClearing = false;
        _selectedIds.clear();
      });
      context.showAppSnackBar(
        strings.trashCleared(entries.length),
        tone: AppSnackBarTone.success,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isClearing = false);
      context.showAppSnackBar(
        strings.clearTrashFailed(error),
        tone: AppSnackBarTone.error,
      );
    }
  }
}

class _TrashEntryCard extends StatelessWidget {
  const _TrashEntryCard({
    required this.entry,
    required this.showVisualMedia,
    required this.selected,
    required this.onSelected,
    required this.onPreview,
    required this.onRestore,
  });

  final DiaryEntry entry;
  final bool showVisualMedia;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final VoidCallback onPreview;
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final theme = Theme.of(context);
    final detailChips = <Widget>[
      CupertinoPill(
        leading: Text(entry.mood.emoji),
        label: Text(strings.moodLabel(entry.mood)),
      ),
      if (entry.trashedAt != null)
        CupertinoPill(
          icon: Icons.delete_outline,
          label: Text(strings.trashedAtLabel(entry.trashedAt!)),
        ),
    ];

    return Card(
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        onTap: onPreview,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                onPressed: () => onSelected(!selected),
                child: Icon(
                  selected
                      ? CupertinoIcons.check_mark_circled_solid
                      : CupertinoIcons.circle,
                  size: 24,
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: EntryListPreview(
                  entry: entry,
                  extraChips: detailChips,
                  showVisualMedia: showVisualMedia,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  SizedBox(
                    width: 136,
                    child: CupertinoActionButton(
                      onPressed: onPreview,
                      expand: true,
                      variant: CupertinoActionButtonVariant.outline,
                      icon: Icons.visibility_outlined,
                      label: strings.previewEntry,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 136,
                    child: CupertinoActionButton(
                      onPressed: onRestore,
                      expand: true,
                      icon: Icons.restore_outlined,
                      label: strings.restoreEntry,
                    ),
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
