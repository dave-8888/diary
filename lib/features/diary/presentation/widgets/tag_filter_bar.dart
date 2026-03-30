import 'package:diary_mvp/app/localization/app_strings.dart';
import 'package:diary_mvp/features/diary/application/diary_controller.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/tag_multi_select_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TagFilterBar extends ConsumerWidget {
  const TagFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = context.strings;
    final selectedTags = ref.watch(selectedTagFilterProvider);
    final tagLibraryAsync = ref.watch(tagLibraryControllerProvider);

    return tagLibraryAsync.when(
      loading: () => const Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (error, stack) => Text(strings.failedToLoadTags(error)),
      data: (tags) {
        if (tags.isEmpty) {
          return const SizedBox.shrink();
        }

        return TagMultiSelectDropdown(
          labelText: strings.filterByTag,
          hintText: strings.allTags,
          searchHintText: strings.searchTags,
          clearSelectionText: strings.clearSelection,
          noResultsText: strings.noMatchingTags,
          emptyOptionsText: strings.noTagsYet,
          options: tags,
          selectedValues: selectedTags,
          onSelectionChanged: (next) =>
              ref.read(selectedTagFilterProvider.notifier).state = next,
        );
      },
    );
  }
}
