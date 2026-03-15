import 'package:diary_mvp/features/diary/application/diary_controller.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/diary_card.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/diary_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TimelinePage extends ConsumerWidget {
  const TimelinePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(diaryControllerProvider);

    return DiaryShell(
      title: 'Timeline',
      child: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Failed to load timeline: $error')),
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(
                child: Text('No entries yet. Start with your first note.'));
          }
          return ListView.separated(
            itemCount: entries.length,
            separatorBuilder: (_, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) => DiaryCard(entry: entries[index]),
          );
        },
      ),
    );
  }
}
