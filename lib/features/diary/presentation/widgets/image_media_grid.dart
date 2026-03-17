import 'dart:io';

import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
import 'package:flutter/material.dart';

class ImageMediaGrid extends StatelessWidget {
  const ImageMediaGrid({
    super.key,
    required this.media,
    this.onDeleted,
    this.onPreviewRequested,
    this.minColumns = 2,
    this.maxColumns = 2,
    this.targetTileWidth = 180,
    this.crossAxisSpacing = 12,
    this.mainAxisSpacing = 12,
    this.childAspectRatio = 1.08,
    this.constrainToTargetWidth = false,
  })  : assert(minColumns > 0),
        assert(maxColumns >= minColumns);

  final List<DiaryMedia> media;
  final ValueChanged<DiaryMedia>? onDeleted;
  final ValueChanged<DiaryMedia>? onPreviewRequested;
  final int minColumns;
  final int maxColumns;
  final double targetTileWidth;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double childAspectRatio;
  final bool constrainToTargetWidth;

  @override
  Widget build(BuildContext context) {
    if (media.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : _targetGridWidth(maxColumns);
        final columnCount = _resolveCrossAxisCount(availableWidth);

        final grid = GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: media.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnCount,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisSpacing: mainAxisSpacing,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (context, index) {
            final item = media[index];
            return _ImageMediaTile(
              key: ValueKey('image-media-tile-${item.id}'),
              media: item,
              onDeleted: onDeleted == null ? null : () => onDeleted!(item),
              onPreviewRequested: onPreviewRequested == null
                  ? null
                  : () => onPreviewRequested!(item),
            );
          },
        );

        if (!constrainToTargetWidth) {
          return grid;
        }

        final constrainedWidth = availableWidth.isFinite
            ? availableWidth
                .clamp(0.0, _targetGridWidth(columnCount))
                .toDouble()
            : _targetGridWidth(columnCount);

        return Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constrainedWidth),
            child: grid,
          ),
        );
      },
    );
  }

  int _resolveCrossAxisCount(double availableWidth) {
    final estimatedColumns = ((availableWidth + crossAxisSpacing) /
            (targetTileWidth + crossAxisSpacing))
        .floor();
    return estimatedColumns.clamp(minColumns, maxColumns).toInt();
  }

  double _targetGridWidth(int columns) {
    return (columns * targetTileWidth) + ((columns - 1) * crossAxisSpacing);
  }
}

class _ImageMediaTile extends StatelessWidget {
  const _ImageMediaTile({
    super.key,
    required this.media,
    this.onDeleted,
    this.onPreviewRequested,
  });

  final DiaryMedia media;
  final VoidCallback? onDeleted;
  final VoidCallback? onPreviewRequested;

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
                      Colors.black.withValues(alpha: 0.02),
                      Colors.black.withValues(alpha: 0.14),
                    ],
                  ),
                ),
              ),
            ),
            if (onPreviewRequested != null)
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onPreviewRequested,
                    child: const SizedBox.expand(),
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
