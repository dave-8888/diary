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
    final aiAnalysis = entry.aiAnalysis;
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
        ImageMediaGrid(
          media: imageMedia,
          minColumns: 2,
          maxColumns: 3,
          targetTileWidth: 190,
          constrainToTargetWidth: true,
          onPreviewRequested: (media) =>
              context.push('/image-preview', extra: media),
        ),
      ],
      if (entry.content.trim().isNotEmpty) ...[
        const SizedBox(height: 20),
        SelectableText(
          entry.content,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
      if (aiAnalysis != null && !aiAnalysis.isEmpty) ...[
        const SizedBox(height: 20),
        _AiAnalysisSection(aiAnalysis: aiAnalysis),
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

class _AiAnalysisSection extends StatelessWidget {
  const _AiAnalysisSection({
    required this.aiAnalysis,
  });

  final DiaryEntryAiAnalysis aiAnalysis;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final theme = Theme.of(context);
    final suggestedTags = aiAnalysis.suggestedTags
        .map((tag) => tag.startsWith('#') ? tag : '#$tag')
        .toList(growable: false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.diaryAiToolsTitle,
              style: theme.textTheme.titleLarge,
            ),
            if (aiAnalysis.overviewText.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              _AiReadonlyBlock(
                title: strings.aiOverviewSectionTitle,
                child: SelectableText(
                  aiAnalysis.overviewText.trim(),
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
              ),
            ],
            if (suggestedTags.isNotEmpty) ...[
              const SizedBox(height: 14),
              _AiReadonlyBlock(
                title: strings.aiSuggestedTagsLabel,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: suggestedTags
                      .map((tag) => Chip(label: Text(tag)))
                      .toList(growable: false),
                ),
              ),
            ],
            if (aiAnalysis.emotionalSupportText?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 14),
              _AiReadonlyBlock(
                title: strings.emotionalCompanionSectionTitle,
                child: SelectableText(
                  aiAnalysis.emotionalSupportText!.trim(),
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
              ),
            ],
            if (aiAnalysis.questionSuggestionText?.trim().isNotEmpty ==
                true) ...[
              const SizedBox(height: 14),
              _AiReadonlyBlock(
                title: strings.problemSuggestionSectionTitle,
                child: SelectableText(
                  aiAnalysis.questionSuggestionText!.trim(),
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AiReadonlyBlock extends StatelessWidget {
  const _AiReadonlyBlock({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
