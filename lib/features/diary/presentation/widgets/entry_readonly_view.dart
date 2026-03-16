import 'package:diary_mvp/app/localization/app_strings.dart';
import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/audio_attachment_tile.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/image_media_grid.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/video_attachment_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EntryReadonlyView extends StatelessWidget {
  const EntryReadonlyView({
    super.key,
    required this.entry,
    this.showTrashedInfo = false,
  });

  final DiaryEntry entry;
  final bool showTrashedInfo;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final imageMedia =
        entry.media.where((item) => item.type == MediaType.image).toList();
    final audioMedia =
        entry.media.where((item) => item.type == MediaType.audio).toList();
    final videoMedia =
        entry.media.where((item) => item.type == MediaType.video).toList();

    final mainSections = [
      Text(
        entry.title,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          Chip(
            avatar: Text(entry.mood.emoji),
            label: Text(strings.moodLabel(entry.mood)),
          ),
          Chip(
            avatar: const Icon(Icons.schedule_outlined, size: 18),
            label: Text(strings.formatDateTime(entry.createdAt)),
          ),
          if (entry.location != null)
            Chip(
              avatar: const Icon(Icons.place_outlined, size: 18),
              label: Text(entry.location!),
            ),
          if (showTrashedInfo && entry.trashedAt != null)
            Chip(
              avatar: const Icon(Icons.delete_outline, size: 18),
              label: Text(strings.trashedAtLabel(entry.trashedAt!)),
            ),
        ],
      ),
      if (entry.tags.isNotEmpty) ...[
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: entry.tags.map((tag) => Chip(label: Text(tag))).toList(),
        ),
      ],
      if (imageMedia.isNotEmpty) ...[
        const SizedBox(height: 20),
        ImageMediaGrid(media: imageMedia),
      ],
      if (entry.content.trim().isNotEmpty) ...[
        const SizedBox(height: 20),
        SelectableText(
          entry.content,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
      if (audioMedia.isNotEmpty) ...[
        const SizedBox(height: 20),
        ...audioMedia.map(
          (media) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AudioAttachmentTile(media: media),
          ),
        ),
      ],
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (videoMedia.isEmpty || constraints.maxWidth < 1080) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...mainSections,
              if (videoMedia.isNotEmpty) ...[
                const SizedBox(height: 20),
                _VideoSection(videoMedia: videoMedia),
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: mainSections,
              ),
            ),
            const SizedBox(width: 24),
            SizedBox(
              width: 320,
              child: _VideoSection(videoMedia: videoMedia),
            ),
          ],
        );
      },
    );
  }
}

class _VideoSection extends StatelessWidget {
  const _VideoSection({
    required this.videoMedia,
  });

  final List<DiaryMedia> videoMedia;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.videoSidebarTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              strings.tapToPreviewVideo,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            ...videoMedia.map(
              (media) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: VideoAttachmentCard(
                  media: media,
                  onTap: () => context.push('/video-preview', extra: media),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
