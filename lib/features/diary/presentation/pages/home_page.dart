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
        data: (entries) => _HomeList(
          entries: entries,
          selectedTag: selectedTag,
          showTagFilters: showTagFilters,
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

    return ListView(
      children: [
        _CompactSummaryCard(
          latest: latest,
          entryCount: filteredEntries.length,
          selectedTag: selectedTag,
        ),
        const SizedBox(height: 16),
        if (showTagFilters) ...[
          const TagFilterBar(),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            Text(
              strings.recentEntries,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            if (entries.length > 3)
              TextButton(
                onPressed: () => context.go('/timeline'),
                child: Text(strings.viewAll),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (filteredEntries.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              selectedTag == null
                  ? strings.noEntriesYet
                  : strings.noEntriesForTag(selectedTag!),
            ),
          )
        else
          ...filteredEntries.take(3).map(
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
    );
  }

  void _openEditor(BuildContext context, DiaryEntry entry) {
    context.push('/editor', extra: entry);
  }
}

class _CompactSummaryCard extends StatelessWidget {
  const _CompactSummaryCard({
    required this.latest,
    required this.entryCount,
    required this.selectedTag,
  });

  final DiaryEntry? latest;
  final int entryCount;
  final String? selectedTag;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.dayHeading(DateTime.now()),
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              strings.latestSummary(latest),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SummaryChip(
                  icon: Icons.menu_book_outlined,
                  label: strings.entryCountLabel(entryCount),
                ),
                _SummaryChip(
                  icon: Icons.sell_outlined,
                  label: strings.tagStatusLabel(selectedTag),
                ),
                if (latest != null)
                  _SummaryChip(
                    icon: Icons.favorite_border,
                    label: strings.moodStatusLabel(latest!.mood),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
