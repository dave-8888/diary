import 'package:diary_mvp/app/app_display_name.dart';
import 'package:diary_mvp/app/localization/app_strings.dart';
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
          onPressed: () => _showRenameDialog(
            context: context,
            ref: ref,
            initialValue: customAppNameAsync.valueOrNull ?? appTitle,
            hasCustomName:
                (customAppNameAsync.valueOrNull?.trim().isNotEmpty ?? false),
          ),
          tooltip: strings.renameAppTooltip,
          icon: const Icon(Icons.drive_file_rename_outline),
        ),
        IconButton(
          onPressed: () => context.push('/migration'),
          tooltip: strings.migrationTitle,
          icon: const Icon(Icons.import_export_outlined),
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
        ),
      ),
    );
  }

  Future<void> _showRenameDialog({
    required BuildContext context,
    required WidgetRef ref,
    required String initialValue,
    required bool hasCustomName,
  }) async {
    final strings = context.strings;
    final controller = TextEditingController(text: initialValue);

    final result = await showDialog<_RenameAppResult>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.renameAppTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: strings.appNameLabel,
            hintText: strings.appNameHint,
          ),
          onSubmitted: (_) => Navigator.of(dialogContext).pop(
            _RenameAppResult.save(controller.text),
          ),
        ),
        actions: [
          if (hasCustomName)
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(
                const _RenameAppResult.reset(),
              ),
              child: Text(strings.resetAppName),
            ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(strings.cancelAction),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(
              _RenameAppResult.save(controller.text),
            ),
            child: Text(strings.saveAction),
          ),
        ],
      ),
    );

    controller.dispose();
    if (result == null || !context.mounted) return;

    try {
      if (result.resetToDefault) {
        await ref.read(appDisplayNameControllerProvider.notifier).reset();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.appNameReset)),
        );
        return;
      }

      await ref
          .read(appDisplayNameControllerProvider.notifier)
          .save(result.value ?? '');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.appNameUpdated)),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.appNameUpdateFailed(error))),
      );
    }
  }
}

class _HomeList extends StatelessWidget {
  const _HomeList({
    required this.entries,
    required this.selectedTag,
    required this.showTagFilters,
  });

  final List<DiaryEntry> entries;
  final String? selectedTag;
  final bool showTagFilters;

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
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.dayHeading(DateTime.now()),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                summaryText,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                detailText,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
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

class _RenameAppResult {
  const _RenameAppResult.save(this.value) : resetToDefault = false;
  const _RenameAppResult.reset()
      : value = null,
        resetToDefault = true;

  final String? value;
  final bool resetToDefault;
}
