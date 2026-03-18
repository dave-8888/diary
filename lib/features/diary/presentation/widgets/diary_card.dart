import 'package:diary_mvp/app/localization/app_strings.dart';
import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/entry_list_preview.dart';
import 'package:flutter/material.dart';

class DiaryCard extends StatelessWidget {
  const DiaryCard({
    super.key,
    required this.entry,
    this.onEdit,
    this.onTap,
  });

  final DiaryEntry entry;
  final VoidCallback? onEdit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final trailingActions = <Widget>[
      if (entry.location != null)
        Chip(
          label: Text(entry.location!),
          avatar: const Icon(Icons.place_outlined, size: 18),
        ),
      if (onEdit != null)
        IconButton(
          onPressed: onEdit,
          tooltip: strings.editEntry,
          icon: const Icon(Icons.edit_outlined),
        ),
    ];

    final body = Padding(
      padding: const EdgeInsets.all(20),
      child: EntryListPreview(
        entry: entry,
        leading: Text(
          entry.mood.emoji,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        trailing: trailingActions.isEmpty
            ? null
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: trailingActions,
              ),
      ),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? body
          : InkWell(
              onTap: onTap,
              child: body,
            ),
    );
  }
}
