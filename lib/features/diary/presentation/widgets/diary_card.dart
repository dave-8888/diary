import 'package:diary_mvp/app/localization/app_strings.dart';
import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/audio_attachment_tile.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/image_media_grid.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class DiaryCard extends StatelessWidget {
  const DiaryCard({
    super.key,
    required this.entry,
  });

  final DiaryEntry entry;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final dateText = strings.formatDateTime(entry.createdAt);
    final imageMedia =
        entry.media.where((item) => item.type == MediaType.image).toList();
    final audioMedia =
        entry.media.where((item) => item.type == MediaType.audio).toList();
    final otherMedia = entry.media
        .where((item) =>
            item.type != MediaType.audio && item.type != MediaType.image)
        .toList();
    final hasContent = entry.content.trim().isNotEmpty;
    final hasMetaChips = entry.tags.isNotEmpty || otherMedia.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
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
                      Text(entry.title,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(dateText,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                if (entry.location != null)
                  Chip(
                    label: Text(entry.location!),
                    avatar: const Icon(Icons.place_outlined, size: 18),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (imageMedia.isNotEmpty) ...[
              ImageMediaGrid(media: imageMedia),
              const SizedBox(height: 16),
            ],
            if (hasContent) ...[
              Text(
                entry.content,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
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
        ),
      ),
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
