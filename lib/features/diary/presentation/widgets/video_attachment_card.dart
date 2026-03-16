import 'package:diary_mvp/app/localization/app_strings.dart';
import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/local_video_player.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class VideoAttachmentCard extends StatefulWidget {
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
  State<VideoAttachmentCard> createState() => _VideoAttachmentCardState();
}

class _VideoAttachmentCardState extends State<VideoAttachmentCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final theme = Theme.of(context);
    final media = widget.media;
    final baseName = p.basename(media.path);
    final overlayTop = _isHovered ? 0.22 : 0.12;
    final overlayBottom = _isHovered ? 0.44 : 0.28;

    return AnimatedScale(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      scale: _isHovered ? 1.01 : 1,
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: widget.onTap,
          onHover: (value) => setState(() => _isHovered = value),
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: _isHovered
                    ? theme.colorScheme.primary.withValues(alpha: 0.45)
                    : theme.colorScheme.outlineVariant,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.surfaceContainerHighest,
                  theme.colorScheme.surface,
                ],
              ),
              boxShadow: [
                if (_isHovered)
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(alpha: 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
              ],
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
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(22),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: overlayTop),
                                Colors.black.withValues(alpha: overlayBottom),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (media.durationLabel != null)
                        Positioned(
                          left: 12,
                          bottom: 12,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.68),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              child: Text(
                                media.durationLabel!,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      Center(
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          scale: _isHovered ? 1.08 : 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(
                                alpha: _isHovered ? 0.32 : 0.22,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(10),
                              child: Icon(
                                Icons.play_circle_fill_rounded,
                                size: 58,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (widget.onDeleted != null)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: IconButton.filledTonal(
                            onPressed: widget.onDeleted,
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
      ),
    );
  }
}
