import 'package:diary_mvp/app/cupertino_kit.dart';
import 'package:diary_mvp/app/localization/app_strings.dart';
import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/entry_list_preview.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:diary_mvp/features/diary/services/diary_list_settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DiaryCard extends ConsumerWidget {
  const DiaryCard({
    super.key,
    required this.entry,
    this.onEdit,
    this.onTap,
    this.onToggleHidden,
  });

  final DiaryEntry entry;
  final VoidCallback? onEdit;
  final VoidCallback? onTap;
  final VoidCallback? onToggleHidden;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = context.strings;
    final theme = Theme.of(context);
    final showVisualMedia = ref
            .watch(diaryListVisualMediaVisibilityControllerProvider)
            .valueOrNull ??
        true;
    final trailingActions = <Widget>[
      if (entry.isHidden)
        CupertinoPill(
          icon: Icons.visibility_off_outlined,
          label: Text(strings.hiddenDiaryBadge),
        ),
      if (entry.location != null)
        CupertinoPill(
          icon: Icons.place_outlined,
          label: Text(entry.location!),
        ),
      if (onToggleHidden != null)
        CupertinoButton(
          key: ValueKey<String>('entry-toggle-hidden-${entry.id}'),
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          onPressed: onToggleHidden,
          child: Icon(
            entry.isHidden
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
      if (onEdit != null)
        CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          onPressed: onEdit,
          child: const Icon(CupertinoIcons.pencil),
        ),
    ];

    final body = Padding(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      child: EntryListPreview(
        entry: entry,
        showVisualMedia: showVisualMedia,
        leading: Text(
          entry.mood.emoji,
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 28,
            height: 1,
          ),
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
