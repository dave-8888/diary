import 'package:diary_mvp/app/cupertino_kit.dart';
import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/entry_list_preview.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diary_mvp/features/diary/services/diary_list_settings.dart';

class DiaryCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final showVisualMedia = ref
            .watch(diaryListVisualMediaVisibilityControllerProvider)
            .valueOrNull ??
        true;
    final trailingActions = <Widget>[
      if (entry.location != null)
        CupertinoPill(
          icon: Icons.place_outlined,
          label: Text(entry.location!),
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
      padding: const EdgeInsets.all(20),
      child: EntryListPreview(
        entry: entry,
        showVisualMedia: showVisualMedia,
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

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(
              alpha: colorScheme.brightness == Brightness.dark ? 0.22 : 0.06,
            ),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Card(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (theme.cardTheme.color ?? colorScheme.surface).withValues(
                  alpha: 0.92,
                ),
                colorScheme.primary.withValues(
                  alpha:
                      colorScheme.brightness == Brightness.dark ? 0.08 : 0.04,
                ),
                (theme.cardTheme.color ?? colorScheme.surface).withValues(
                  alpha: 0.98,
                ),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 20,
                right: 20,
                child: Container(
                  height: 1.4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary.withValues(alpha: 0),
                        colorScheme.primary.withValues(alpha: 0.45),
                        colorScheme.secondary.withValues(alpha: 0.18),
                      ],
                    ),
                  ),
                ),
              ),
              onTap == null
                  ? body
                  : GestureDetector(
                      onTap: onTap,
                      behavior: HitTestBehavior.opaque,
                      child: body,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
