import 'dart:io';

import 'package:diary_mvp/app/localization/app_strings.dart';
import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/local_video_player.dart';
import 'package:flutter/material.dart';

enum VideoTimestampStyle {
  dateTime,
  day,
}

enum MediaTileDensity {
  regular,
  compact,
}

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
    this.videoTimestampStyle = VideoTimestampStyle.dateTime,
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
  final VideoTimestampStyle videoTimestampStyle;

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
            return VisualMediaTile(
              key: ValueKey('${item.type.name}-media-tile-${item.id}'),
              media: item,
              onDeleted: onDeleted == null ? null : () => onDeleted!(item),
              onTap: onPreviewRequested == null
                  ? null
                  : () => onPreviewRequested!(item),
              videoTimestampStyle: videoTimestampStyle,
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

class VisualMediaTile extends StatefulWidget {
  const VisualMediaTile({
    super.key,
    required this.media,
    this.onTap,
    this.onDeleted,
    this.videoTimestampStyle = VideoTimestampStyle.dateTime,
    this.density = MediaTileDensity.regular,
    this.showHoverEffects = true,
    this.borderRadius,
  });

  final DiaryMedia media;
  final VoidCallback? onTap;
  final VoidCallback? onDeleted;
  final VideoTimestampStyle videoTimestampStyle;
  final MediaTileDensity density;
  final bool showHoverEffects;
  final BorderRadius? borderRadius;

  @override
  State<VisualMediaTile> createState() => _VisualMediaTileState();
}

class _VisualMediaTileState extends State<VisualMediaTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = widget.borderRadius ?? _defaultBorderRadius();
    final showHoverEffects = widget.showHoverEffects;

    final tile = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(
          color: _isHovered && showHoverEffects
              ? theme.colorScheme.primary.withValues(alpha: 0.45)
              : theme.colorScheme.outlineVariant,
        ),
        boxShadow: [
          if (_isHovered && showHoverEffects)
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.12),
              blurRadius: widget.density == MediaTileDensity.compact ? 12 : 18,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildBackground(theme),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(
                        alpha: _isHovered && showHoverEffects ? 0.18 : 0.08,
                      ),
                      Colors.black.withValues(
                        alpha: _isHovered && showHoverEffects ? 0.36 : 0.22,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (widget.media.type == MediaType.video) ...[
              _buildVideoTimestamp(context),
              _buildVideoDuration(theme),
              _buildPlayOverlay(),
            ],
            if (widget.onTap != null || widget.onDeleted != null)
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTapUp: (details) {
                        if (_isDeleteTapZone(
                          localPosition: details.localPosition,
                          size: constraints.biggest,
                        )) {
                          widget.onDeleted?.call();
                          return;
                        }
                        widget.onTap?.call();
                      },
                      child: MouseRegion(
                        cursor: widget.onTap != null
                            ? SystemMouseCursors.click
                            : MouseCursor.defer,
                        child: const SizedBox.expand(),
                      ),
                    );
                  },
                ),
              ),
            if (widget.onDeleted != null)
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: widget.onDeleted,
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox.square(
                    dimension:
                        widget.density == MediaTileDensity.compact ? 48 : 56,
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: _overlayInset,
                          right: _overlayInset,
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface
                                .withValues(alpha: 0.82),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.34),
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(
                              widget.density == MediaTileDensity.compact
                                  ? 6
                                  : 8,
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: widget.density == MediaTileDensity.compact
                                  ? 18
                                  : 20,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    return MouseRegion(
      onEnter:
          showHoverEffects ? (_) => setState(() => _isHovered = true) : null,
      onExit:
          showHoverEffects ? (_) => setState(() => _isHovered = false) : null,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        scale: _isHovered && showHoverEffects ? 1.01 : 1,
        child: tile,
      ),
    );
  }

  Widget _buildBackground(ThemeData theme) {
    switch (widget.media.type) {
      case MediaType.image:
        return Image.file(
          File(widget.media.path),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => ColoredBox(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.broken_image_outlined,
              size: widget.density == MediaTileDensity.compact ? 32 : 36,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        );
      case MediaType.video:
        final fileExists = File(widget.media.path).existsSync();
        if (!fileExists) {
          return ColoredBox(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.videocam_off_outlined,
              size: widget.density == MediaTileDensity.compact ? 30 : 36,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          );
        }

        return IgnorePointer(
          child: LocalVideoPlayer(
            path: widget.media.path,
            showControls: false,
            fit: BoxFit.cover,
          ),
        );
      case MediaType.audio:
        return ColoredBox(
          color: theme.colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.mic_none,
            size: widget.density == MediaTileDensity.compact ? 30 : 36,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        );
    }
  }

  Widget _buildVideoTimestamp(BuildContext context) {
    final timestamp = _videoTimestampText(context);
    if (timestamp == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: _overlayInset,
      left: _overlayInset,
      right: widget.onDeleted != null ? 56 : _overlayInset,
      child: Text(
        timestamp,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: _overlayTextStyle(Theme.of(context)),
      ),
    );
  }

  Widget _buildVideoDuration(ThemeData theme) {
    final duration = widget.media.durationLabel;
    if (duration == null || duration.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: _overlayInset,
      right: _overlayInset,
      bottom: _overlayInset,
      child: Text(
        duration,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: _overlayTextStyle(theme),
      ),
    );
  }

  Widget _buildPlayOverlay() {
    final iconSize = widget.density == MediaTileDensity.compact ? 28.0 : 58.0;
    final padding = widget.density == MediaTileDensity.compact ? 8.0 : 10.0;

    return Center(
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        scale: _isHovered && widget.showHoverEffects ? 1.08 : 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(
              alpha: _isHovered && widget.showHoverEffects ? 0.28 : 0.18,
            ),
            shape: BoxShape.circle,
          ),
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Icon(
              widget.density == MediaTileDensity.compact
                  ? Icons.play_arrow_rounded
                  : Icons.play_circle_fill_rounded,
              size: iconSize,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  String? _videoTimestampText(BuildContext context) {
    final capturedAt = widget.media.capturedAt;
    if (capturedAt == null) {
      return null;
    }

    final strings = context.strings;
    switch (widget.videoTimestampStyle) {
      case VideoTimestampStyle.dateTime:
        return strings.formatDateTime(capturedAt);
      case VideoTimestampStyle.day:
        return strings.formatDay(capturedAt);
    }
  }

  TextStyle? _overlayTextStyle(ThemeData theme) {
    final baseStyle = widget.density == MediaTileDensity.compact
        ? theme.textTheme.labelSmall
        : theme.textTheme.labelMedium;
    return baseStyle?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w600,
      shadows: const [
        Shadow(
          color: Color(0x99000000),
          blurRadius: 8,
          offset: Offset(0, 1),
        ),
      ],
    );
  }

  BorderRadius _defaultBorderRadius() {
    final radius = widget.density == MediaTileDensity.compact ? 18.0 : 20.0;
    return BorderRadius.circular(radius);
  }

  double get _overlayInset {
    return widget.density == MediaTileDensity.compact ? 8 : 12;
  }

  bool _isDeleteTapZone({
    required Offset localPosition,
    required Size size,
  }) {
    if (widget.onDeleted == null) {
      return false;
    }

    final zoneExtent = widget.density == MediaTileDensity.compact ? 44.0 : 52.0;
    return localPosition.dx >= size.width - zoneExtent &&
        localPosition.dy <= zoneExtent;
  }
}
