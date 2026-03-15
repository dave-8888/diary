import 'package:diary_mvp/app/localization/app_strings.dart';
import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/audio_attachment_tile.dart';
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
    final audioMedia =
        entry.media.where((item) => item.type == MediaType.audio).toList();
    final otherMedia =
        entry.media.where((item) => item.type != MediaType.audio).toList();

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
            Text(
              entry.content,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
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
