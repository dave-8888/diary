import 'package:diary_mvp/app/localization/app_strings.dart';
import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/local_video_player.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class VideoPreviewPage extends StatelessWidget {
  const VideoPreviewPage({
    super.key,
    this.media,
  });

  final DiaryMedia? media;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final video = media;
    final capturedAtText = video?.capturedAt == null
        ? null
        : strings.formatDateTime(video!.capturedAt!);

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
                  final detailCard = Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            strings.previewVideo,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          if (capturedAtText != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              capturedAtText,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                          if (video.durationLabel != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              video.durationLabel!,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );

                  final player = ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: LocalVideoPlayer(path: video.path),
                    ),
                  );

                  if (constraints.maxWidth >= 1024) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: player),
                          const SizedBox(width: 24),
                          SizedBox(
                            width: 280,
                            child: detailCard,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      player,
                      const SizedBox(height: 20),
                      detailCard,
                    ],
                  );
                },
              ),
      ),
    );
  }
}
