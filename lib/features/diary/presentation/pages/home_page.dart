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
    final entriesAsync = ref.watch(diaryControllerProvider);

    return DiaryShell(
      title: 'Diary',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/editor'),
        icon: const Icon(Icons.add),
        label: const Text('New Entry'),
      ),
      child: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Failed to load entries: $error'),
        ),
        data: (entries) => _HomeList(entries: entries),
      ),
    );
  }
}

class _HomeList extends StatelessWidget {
  const _HomeList({required this.entries});

  final List<DiaryEntry> entries;

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final latest = entries.isNotEmpty ? entries.first : null;

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
              Text('Today · $today',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Text(
                latest == null
                    ? 'Start capturing today with words, mood, and voice.'
                    : '${latest.mood.emoji} ${latest.mood.label} · ${latest.title}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                latest?.content ??
                    'The MVP is ready for your first diary entry.',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Text('Recent entries',
                style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            TextButton(
              onPressed: () => context.go('/timeline'),
              child: const Text('View all'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...entries.take(3).map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DiaryCard(entry: entry),
              ),
            ),
      ],
    );
  }
}
