import 'package:diary_mvp/app/cupertino_kit.dart';
import 'package:diary_mvp/app/localization/app_strings.dart';
import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/audio_attachment_tile.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/image_media_grid.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

const double _compactMediaTileSize = 128;
const double _compactMediaMinTileSize = 96;
const double _compactMediaGap = 8;
const double _compactLayoutBreakpoint = 680;

class EntryListPreview extends StatelessWidget {
  const EntryListPreview({
    super.key,
    required this.entry,
    this.leading,
    this.trailing,
    this.extraChips = const <Widget>[],
    this.showVisualMedia = true,
  });

  final DiaryEntry entry;
  final Widget? leading;
  final Widget? trailing;
  final List<Widget> extraChips;
  final bool showVisualMedia;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final theme = Theme.of(context);
    final imageMedia =
        entry.media.where((item) => item.type == MediaType.image).toList();
    final videoMedia =
        entry.media.where((item) => item.type == MediaType.video).toList();
    final audioMedia =
        entry.media.where((item) => item.type == MediaType.audio).toList();
    final otherMedia = entry.media
        .where((item) =>
            item.type != MediaType.audio &&
            item.type != MediaType.image &&
            item.type != MediaType.video)
        .toList();
    final titleText =
        entry.title.trim().isEmpty ? strings.untitledEntry : entry.title;
    final contentText = entry.content.trim();
    final contentStyle = theme.textTheme.bodyMedium?.copyWith(height: 1.45);

    final previewTiles = showVisualMedia
        ? <_CompactPreviewSpec>[
            if (imageMedia.isNotEmpty)
              _CompactPreviewSpec(
                key: ValueKey('entry-compact-image-${imageMedia.first.id}'),
                media: imageMedia.first,
              ),
            if (videoMedia.isNotEmpty)
              _CompactPreviewSpec(
                key: ValueKey('entry-compact-video-${videoMedia.first.id}'),
                media: videoMedia.first,
                videoTimestampStyle: VideoTimestampStyle.day,
              ),
          ]
        : const <_CompactPreviewSpec>[];
    final detailChips = <Widget>[
      ...extraChips,
      ...otherMedia.map(
        (media) => CupertinoPill(
          icon: _iconForMedia(media.type),
          label: Text(_labelForMedia(strings, media)),
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titleText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    strings.formatDateTime(entry.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 12),
              Flexible(
                child: Align(
                  alignment: Alignment.topRight,
                  child: trailing!,
                ),
              ),
            ],
          ],
        ),
        if (previewTiles.isNotEmpty) ...[
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isStacked = constraints.maxWidth < _compactLayoutBreakpoint;
              final stripMetrics = _resolveMediaStripMetrics(
                availableWidth: constraints.maxWidth,
                tileCount: previewTiles.length,
                stacked: isStacked,
              );
              final previewStrip = SizedBox(
                key: ValueKey('entry-media-strip-${entry.id}'),
                width: stripMetrics.width,
                child: Row(
                  key: ValueKey('entry-media-row-${entry.id}'),
                  children: [
                    for (var index = 0;
                        index < previewTiles.length;
                        index++) ...[
                      if (index > 0) SizedBox(width: stripMetrics.gap),
                      _CompactMediaPreviewTile(
                        media: previewTiles[index].media,
                        videoTimestampStyle:
                            previewTiles[index].videoTimestampStyle,
                        dimension: stripMetrics.tileSize,
                        key: previewTiles[index].key,
                      ),
                    ],
                  ],
                ),
              );
              final contentPreview = contentText.isEmpty
                  ? null
                  : Text(
                      contentText,
                      key: ValueKey('entry-content-preview-${entry.id}'),
                      maxLines: isStacked
                          ? 4
                          : _resolveContentMaxLines(
                              contentStyle: contentStyle,
                              previewHeight: stripMetrics.tileSize,
                            ),
                      overflow: TextOverflow.ellipsis,
                      style: contentStyle,
                    );

              if (contentPreview == null) {
                return previewStrip;
              }

              if (isStacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    previewStrip,
                    const SizedBox(height: 12),
                    contentPreview,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  previewStrip,
                  const SizedBox(width: 16),
                  Expanded(child: contentPreview),
                ],
              );
            },
          ),
        ] else if (contentText.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            contentText,
            key: ValueKey('entry-content-preview-${entry.id}'),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: contentStyle,
          ),
        ],
        if (entry.tags.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: entry.tags
                .map((tag) => CupertinoPill(label: Text(tag)))
                .toList(),
          ),
        ],
        if (detailChips.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: detailChips,
          ),
        ],
        if (audioMedia.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...audioMedia.map(
            (media) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AudioAttachmentTile(media: media),
            ),
          ),
        ],
      ],
    );
  }

  int _resolveContentMaxLines({
    required TextStyle? contentStyle,
    required double previewHeight,
  }) {
    final fontSize = contentStyle?.fontSize ?? 14;
    final lineHeightFactor = contentStyle?.height ?? 1.4;
    final effectiveLineHeight = fontSize * lineHeightFactor;
    if (effectiveLineHeight <= 0) return 4;

    return (previewHeight / effectiveLineHeight).floor().clamp(3, 10).toInt();
  }

  _MediaStripMetrics _resolveMediaStripMetrics({
    required double availableWidth,
    required int tileCount,
    required bool stacked,
  }) {
    final targetWidth = (tileCount * _compactMediaTileSize) +
        ((tileCount - 1) * _compactMediaGap);
    if (tileCount <= 0) {
      return const _MediaStripMetrics(
        width: 0,
        tileSize: _compactMediaTileSize,
        gap: _compactMediaGap,
      );
    }

    if (!stacked) {
      return _MediaStripMetrics(
        width: targetWidth,
        tileSize: _compactMediaTileSize,
        gap: _compactMediaGap,
      );
    }

    final maxUsableWidth =
        availableWidth.isFinite ? availableWidth : targetWidth;
    final availableForTiles =
        maxUsableWidth - ((tileCount - 1) * _compactMediaGap);
    final tileSize = (availableForTiles / tileCount)
        .clamp(_compactMediaMinTileSize, _compactMediaTileSize)
        .toDouble();
    final width = (tileSize * tileCount) + ((tileCount - 1) * _compactMediaGap);
    return _MediaStripMetrics(
      width: width,
      tileSize: tileSize,
      gap: _compactMediaGap,
    );
  }

  IconData _iconForMedia(MediaType type) {
    switch (type) {
      case MediaType.image:
        return Icons.image_outlined;
      case MediaType.audio:
        return Icons.mic_none;
      case MediaType.video:
        return Icons.videocam_outlined;
    }
  }

  String _labelForMedia(AppStrings strings, DiaryMedia media) {
    return strings.mediaLabel(
      media,
      baseName: p.basename(media.path),
    );
  }
}

class _CompactMediaPreviewTile extends StatelessWidget {
  const _CompactMediaPreviewTile({
    super.key,
    required this.media,
    this.videoTimestampStyle = VideoTimestampStyle.dateTime,
    this.dimension = _compactMediaTileSize,
  });

  final DiaryMedia media;
  final VideoTimestampStyle videoTimestampStyle;
  final double dimension;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: dimension,
      child: VisualMediaTile(
        media: media,
        density: MediaTileDensity.compact,
        showHoverEffects: false,
        videoTimestampStyle: videoTimestampStyle,
      ),
    );
  }
}

class _CompactPreviewSpec {
  const _CompactPreviewSpec({
    required this.key,
    required this.media,
    this.videoTimestampStyle = VideoTimestampStyle.dateTime,
  });

  final Key key;
  final DiaryMedia media;
  final VideoTimestampStyle videoTimestampStyle;
}

class _MediaStripMetrics {
  const _MediaStripMetrics({
    required this.width,
    required this.tileSize,
    required this.gap,
  });

  final double width;
  final double tileSize;
  final double gap;
}
