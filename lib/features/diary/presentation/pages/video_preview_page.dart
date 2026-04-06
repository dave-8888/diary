import 'package:diary_mvp/app/localization/app_strings.dart';
import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/local_video_player.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class VideoPreviewPage extends StatelessWidget {
  const VideoPreviewPage({
    super.key,
    this.media,
    this.playerBuilder,
  });

  final DiaryMedia? media;
  final Widget Function(String path)? playerBuilder;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final video = media;
    final theme = Theme.of(context);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(strings.videoPreviewPageTitle),
      ),
      child: SafeArea(
        top: false,
        child: video == null
            ? Center(child: Text(strings.noVideoSelected))
            : LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 760;
                  final horizontalPadding = isWide ? 28.0 : 18.0;
                  final verticalPadding = isWide ? 24.0 : 16.0;
                  final metadataBlocks = [
                    _VideoMetadataItem(
                      label: strings.videoCapturedAtLabel,
                      value: _metadataValue(
                        strings,
                        value: video.capturedAt == null
                            ? null
                            : strings.formatDateTime(video.capturedAt!),
                      ),
                      labelStyle: theme.textTheme.labelLarge,
                      valueStyle: theme.textTheme.bodyLarge,
                    ),
                    _VideoMetadataItem(
                      label: strings.videoDurationLabel,
                      value: _metadataValue(
                        strings,
                        value: video.durationLabel,
                      ),
                      labelStyle: theme.textTheme.labelLarge,
                      valueStyle: theme.textTheme.bodyLarge,
                    ),
                    _VideoMetadataItem(
                      label: strings.videoCapturedLocationLabel,
                      value: _metadataValue(
                        strings,
                        value: video.location,
                      ),
                      labelStyle: theme.textTheme.labelLarge,
                      valueStyle: theme.textTheme.bodyLarge,
                    ),
                  ];

                  final detailContent = isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var index = 0;
                                index < metadataBlocks.length;
                                index++) ...[
                              Expanded(child: metadataBlocks[index]),
                              if (index != metadataBlocks.length - 1) ...[
                                const SizedBox(width: 18),
                                Container(
                                  width: 1,
                                  height: 56,
                                  color: theme.colorScheme.outlineVariant
                                      .withValues(alpha: 0.5),
                                ),
                                const SizedBox(width: 18),
                              ],
                            ],
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var index = 0;
                                index < metadataBlocks.length;
                                index++) ...[
                              metadataBlocks[index],
                              if (index != metadataBlocks.length - 1)
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 18),
                                  child: Divider(
                                    height: 1,
                                    color: theme.colorScheme.outlineVariant
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                            ],
                          ],
                        );
                  final detailCard = Card(
                    elevation: 0,
                    color: theme.colorScheme.surface.withValues(
                      alpha: theme.brightness == Brightness.dark ? 0.88 : 0.96,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha:
                              theme.brightness == Brightness.dark ? 0.4 : 0.65,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: detailContent,
                    ),
                  );

                  final previewPanel = DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(34),
                      color: theme.colorScheme.surface.withValues(
                        alpha:
                            theme.brightness == Brightness.dark ? 0.86 : 0.94,
                      ),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha:
                              theme.brightness == Brightness.dark ? 0.32 : 0.55,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: theme.brightness == Brightness.dark
                                ? 0.24
                                : 0.06,
                          ),
                          blurRadius: 26,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(isWide ? 14 : 10),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: isWide ? 1080 : 820,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(26),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: playerBuilder?.call(video.path) ??
                                  LocalVideoPlayer(path: video.path),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );

                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      verticalPadding,
                      horizontalPadding,
                      14,
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: const Alignment(0, 0.12),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: isWide ? 1180 : 860,
                                maxHeight: constraints.maxHeight * 0.8,
                              ),
                              child: SizedBox.expand(
                                child: previewPanel,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 920),
                            child: detailCard,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  String _metadataValue(
    AppStrings strings, {
    required String? value,
  }) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return strings.notProvided;
    }
    return normalized;
  }
}

class _VideoMetadataItem extends StatelessWidget {
  const _VideoMetadataItem({
    required this.label,
    required this.value,
    required this.labelStyle,
    required this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 6),
        Text(
          value,
          style: valueStyle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
