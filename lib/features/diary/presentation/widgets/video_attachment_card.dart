import 'package:diary_mvp/app/localization/app_strings.dart';
import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/local_video_player.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class VideoAttachmentCard extends StatelessWidget {
  const VideoAttachmentCard({
    super.key,
    required this.media,
    required this.onTap,
    this.onDeleted,
  });

  final DiaryMedia media;
  final VoidCallback onTap;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final theme = Theme.of(context);
    final baseName = p.basename(media.path);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: theme.colorScheme.outlineVariant),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.surfaceContainerHighest,
                theme.colorScheme.surface,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(22),
                      ),
                      child: IgnorePointer(
                        child: LocalVideoPlayer(
                          path: media.path,
                          showControls: false,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(22),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.12),
                              Colors.black.withOpacity(0.28),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Center(
                      child: Icon(
                        Icons.play_circle_fill_rounded,
                        size: 58,
                        color: Colors.white,
                      ),
                    ),
                    if (onDeleted != null)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: IconButton.filledTonal(
                          onPressed: onDeleted,
                          tooltip: MaterialLocalizations.of(context)
                              .deleteButtonTooltip,
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.mediaLabel(media, baseName: baseName),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      strings.tapToPreviewVideo,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
