import 'package:diary_mvp/app/localization/app_strings.dart';
import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/audio_attachment_tile.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/image_media_grid.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/video_attachment_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

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
    final dateText = strings.formatDateTime(entry.createdAt);
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
    final hasContent = entry.content.trim().isNotEmpty;
    final hasMetaChips = entry.tags.isNotEmpty || otherMedia.isNotEmpty;
    final hasMainBody = imageMedia.isNotEmpty ||
        hasContent ||
        hasMetaChips ||
        audioMedia.isNotEmpty;

    final body = Padding(
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useVideoSideRail = constraints.maxWidth >= 860 &&
              videoMedia.isNotEmpty &&
              hasMainBody;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    entry.mood.emoji,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateText,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (entry.location != null)
                    Chip(
                      label: Text(entry.location!),
                      avatar: const Icon(Icons.place_outlined, size: 18),
                    )
                  else if (onEdit != null)
                    IconButton(
                      onPressed: onEdit,
                      tooltip: strings.editEntry,
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  if (entry.location != null && onEdit != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: onEdit,
                      tooltip: strings.editEntry,
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              if (useVideoSideRail)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildMainBody(
                        context,
                        imageMedia,
                        audioMedia,
                        otherMedia,
                        hasContent,
                        hasMetaChips,
                      ),
                    ),
                    const SizedBox(width: 18),
                    SizedBox(
                      width: 240,
                      child: _buildVideoColumn(context, videoMedia),
                    ),
                  ],
                )
              else ...[
                _buildMainBody(
                  context,
                  imageMedia,
                  audioMedia,
                  otherMedia,
                  hasContent,
                  hasMetaChips,
                ),
                if (videoMedia.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildVideoColumn(context, videoMedia),
                ],
              ],
            ],
          );
        },
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

  Widget _buildMainBody(
    BuildContext context,
    List<DiaryMedia> imageMedia,
    List<DiaryMedia> audioMedia,
    List<DiaryMedia> otherMedia,
    bool hasContent,
    bool hasMetaChips,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (imageMedia.isNotEmpty) ...[
          ImageMediaGrid(media: imageMedia),
          const SizedBox(height: 16),
        ],
        if (hasContent)
          Text(
            entry.content,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        if (hasContent && hasMetaChips) const SizedBox(height: 16),
        if (hasMetaChips)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...entry.tags.map((tag) => Chip(label: Text(tag))),
              ...otherMedia.map(
                (media) => Chip(
                  avatar: Icon(_iconForMedia(media.type), size: 18),
                  label: Text(_labelForMedia(context, media)),
                ),
              ),
            ],
          ),
        if (audioMedia.isNotEmpty) ...[
          const SizedBox(height: 16),
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

  Widget _buildVideoColumn(BuildContext context, List<DiaryMedia> videoMedia) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: videoMedia
          .map(
            (media) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: VideoAttachmentCard(
                media: media,
                onTap: () => context.push('/video-preview', extra: media),
              ),
            ),
          )
          .toList(),
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

  String _labelForMedia(BuildContext context, DiaryMedia media) {
    final strings = context.strings;
    final baseName = p.basename(media.path);
    return strings.mediaLabel(media, baseName: baseName);
  }
}
