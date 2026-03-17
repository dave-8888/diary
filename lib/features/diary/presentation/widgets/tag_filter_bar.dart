import 'package:diary_mvp/app/localization/app_strings.dart';
import 'package:diary_mvp/features/diary/application/diary_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TagFilterBar extends ConsumerWidget {
  const TagFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = context.strings;
    final selectedTag = ref.watch(selectedTagFilterProvider);
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

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              selected: selectedTag == null,
              onSelected: (_) =>
                  ref.read(selectedTagFilterProvider.notifier).state = null,
              label: Text(strings.allTags),
            ),
            ...tags.map(
              (tag) => ChoiceChip(
                selected: selectedTag == tag,
                onSelected: (_) => ref
                    .read(selectedTagFilterProvider.notifier)
                    .state = selectedTag == tag ? null : tag,
                label: Text(tag),
              ),
            ),
          ],
        );
      },
    );
  }
}
