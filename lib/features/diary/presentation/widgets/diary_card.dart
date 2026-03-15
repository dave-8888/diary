import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

class DiaryCard extends StatelessWidget {
  const DiaryCard({
    super.key,
    required this.entry,
  });

  final DiaryEntry entry;

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('yyyy-MM-dd HH:mm').format(entry.createdAt);

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
                ...entry.media.map(
                  (media) => Chip(
                    avatar: Icon(_iconForMedia(media.type), size: 18),
                    label: Text(_labelForMedia(media)),
                  ),
                ),
              ],
            ),
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

  String _labelForMedia(DiaryMedia media) {
    final baseName = p.basename(media.path);
    switch (media.type) {
      case MediaType.image:
        return 'Image: $baseName';
      case MediaType.audio:
        return media.durationLabel == null
            ? 'Audio: $baseName'
            : 'Audio ${media.durationLabel}: $baseName';
      case MediaType.video:
        return 'Video: $baseName';
    }
  }
}
