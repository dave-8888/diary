import 'dart:io';

import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
import 'package:flutter/material.dart';

class ImageMediaGrid extends StatelessWidget {
  const ImageMediaGrid({
    super.key,
    required this.media,
    this.onDeleted,
  });

  final List<DiaryMedia> media;
  final ValueChanged<DiaryMedia>? onDeleted;

  @override
  Widget build(BuildContext context) {
    if (media.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: media.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.08,
      ),
      itemBuilder: (context, index) {
        final item = media[index];
        return _ImageMediaTile(
          media: item,
          onDeleted: onDeleted == null ? null : () => onDeleted!(item),
        );
      },
    );
  }
}

class _ImageMediaTile extends StatelessWidget {
  const _ImageMediaTile({
    required this.media,
    this.onDeleted,
  });

  final DiaryMedia media;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(20);
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(media.path),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => ColoredBox(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.broken_image_outlined,
                  size: 36,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.02),
                      Colors.black.withOpacity(0.14),
                    ],
                  ),
                ),
              ),
            ),
            if (onDeleted != null)
              Positioned(
                top: 10,
                right: 10,
                child: IconButton.filledTonal(
                  onPressed: onDeleted,
                  tooltip:
                      MaterialLocalizations.of(context).deleteButtonTooltip,
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
