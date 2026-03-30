import 'package:diary_mvp/app/localization/app_strings.dart';
import 'package:diary_mvp/features/diary/application/diary_controller.dart';
import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/diary_card.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/diary_shell.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/tag_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TimelinePage extends ConsumerWidget {
  const TimelinePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = context.strings;
    final entriesAsync = ref.watch(diaryControllerProvider);
    final selectedTags = ref.watch(selectedTagFilterProvider);
    final showTagFilters = ref.watch(tagLibraryControllerProvider).maybeWhen(
          data: (tags) => tags.isNotEmpty,
          loading: () => true,
          error: (_, __) => true,
          orElse: () => false,
        );

    return DiaryShell(
      title: strings.timelineNav,
      showAppBarTitle: false,
      child: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text(strings.failedToLoadTimeline(error))),
        data: (entries) => _TimelineList(
          entries: entries,
          selectedTags: selectedTags,
          showTagFilters: showTagFilters,
        ),
      ),
    );
  }
}

class _TimelineList extends StatelessWidget {
  const _TimelineList({
    required this.entries,
    required this.selectedTags,
    required this.showTagFilters,
  });

  final List<DiaryEntry> entries;
  final List<String> selectedTags;
  final bool showTagFilters;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final selectedTagKeys =
        selectedTags.map((tag) => tag.toLowerCase()).toSet();
    final filteredEntries = selectedTagKeys.isEmpty
        ? entries
        : entries
            .where(
              (entry) => entry.tags.any(
                (tag) => selectedTagKeys.contains(tag.toLowerCase()),
              ),
            )
            .toList(growable: false);

    return ListView(
      children: [
        if (showTagFilters) ...[
          const TagFilterBar(),
          const SizedBox(height: 20),
        ],
        if (filteredEntries.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              selectedTags.isEmpty
                  ? strings.noEntriesYet
                  : strings.noEntriesForTags(selectedTags),
            ),
          )
        else
          ...List.generate(filteredEntries.length, (index) {
            final entry = filteredEntries[index];
            return Padding(
              padding: EdgeInsets.only(
                  bottom: index == filteredEntries.length - 1 ? 0 : 16),
              child: DiaryCard(
                entry: entry,
                onEdit: () => _openEditor(context, entry),
                onTap: () => _openEditor(context, entry),
              ),
            );
          }),
      ],
    );
  }

  void _openEditor(BuildContext context, DiaryEntry entry) {
    context.push('/editor', extra: entry);
  }
}
