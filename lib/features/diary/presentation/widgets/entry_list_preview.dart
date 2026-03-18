import 'dart:io';

import 'package:diary_mvp/app/localization/app_strings.dart';
import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/audio_attachment_tile.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/local_video_player.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

const double _compactMediaTileSize = 128;
const double _compactMediaGap = 8;

class EntryListPreview extends StatelessWidget {
  const EntryListPreview({
    super.key,
    required this.entry,
    this.leading,
    this.trailing,
    this.extraChips = const <Widget>[],
  });

  final DiaryEntry entry;
  final Widget? leading;
  final Widget? trailing;
  final List<Widget> extraChips;

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

    final previewTiles = <Widget>[
      if (imageMedia.isNotEmpty)
        _CompactImagePreviewTile(
          key: ValueKey('entry-compact-image-${imageMedia.first.id}'),
          media: imageMedia.first,
        ),
      if (videoMedia.isNotEmpty)
        _CompactVideoPreviewTile(
          key: ValueKey('entry-compact-video-${videoMedia.first.id}'),
          media: videoMedia.first,
        ),
    ];
    final previewHeight = previewTiles.isEmpty
        ? 0.0
        : (previewTiles.length * _compactMediaTileSize) +
            ((previewTiles.length - 1) * _compactMediaGap);
    final contentMaxLines = previewTiles.isEmpty
        ? 4
        : _resolveContentMaxLines(
            contentStyle: contentStyle,
            previewHeight: previewHeight,
          );

    final detailChips = <Widget>[
      ...extraChips,
      ...otherMedia.map(
        (media) => Chip(
          avatar: Icon(_iconForMedia(media.type), size: 18),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: _compactMediaTileSize,
                child: Column(
                  children: [
                    for (var index = 0;
                        index < previewTiles.length;
                        index++) ...[
                      if (index > 0) const SizedBox(height: _compactMediaGap),
                      previewTiles[index],
                    ],
                  ],
                ),
              ),
              if (contentText.isNotEmpty) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    contentText,
                    key: ValueKey('entry-content-preview-${entry.id}'),
                    maxLines: contentMaxLines,
                    overflow: TextOverflow.ellipsis,
                    style: contentStyle,
                  ),
                ),
              ],
            ],
          ),
        ] else if (contentText.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            contentText,
            key: ValueKey('entry-content-preview-${entry.id}'),
            maxLines: contentMaxLines,
            overflow: TextOverflow.ellipsis,
            style: contentStyle,
          ),
        ],
        if (entry.tags.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: entry.tags.map((tag) => Chip(label: Text(tag))).toList(),
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

class _CompactImagePreviewTile extends StatelessWidget {
  const _CompactImagePreviewTile({
    super.key,
    required this.media,
  });

  final DiaryMedia media;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _CompactMediaFrame(
      child: Image.file(
        File(media.path),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => ColoredBox(
          color: theme.colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.broken_image_outlined,
            size: 32,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _CompactVideoPreviewTile extends StatelessWidget {
  const _CompactVideoPreviewTile({
    super.key,
    required this.media,
  });

  final DiaryMedia media;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fileExists = File(media.path).existsSync();

    return _CompactMediaFrame(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (fileExists)
            IgnorePointer(
              child: LocalVideoPlayer(
                path: media.path,
                showControls: false,
                fit: BoxFit.cover,
              ),
            )
          else
            ColoredBox(
              color: theme.colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.videocam_off_outlined,
                size: 30,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.08),
                  Colors.black.withValues(alpha: 0.32),
                ],
              ),
            ),
          ),
          Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.28),
                shape: BoxShape.circle,
              ),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(
                  Icons.play_arrow_rounded,
                  size: 28,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          if (media.durationLabel != null)
            Positioned(
              left: 8,
              bottom: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.68),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    media.durationLabel!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CompactMediaFrame extends StatelessWidget {
  const _CompactMediaFrame({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(18);

    return SizedBox.square(
      dimension: _compactMediaTileSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: child,
        ),
      ),
    );
  }
}
