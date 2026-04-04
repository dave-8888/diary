import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class LocalVideoPlayer extends StatefulWidget {
  const LocalVideoPlayer({
    super.key,
    required this.path,
    this.autoplay = false,
    this.showControls = true,
    this.fit = BoxFit.contain,
  });

  final String path;
  final bool autoplay;
  final bool showControls;
  final BoxFit fit;

  @override
  State<LocalVideoPlayer> createState() => _LocalVideoPlayerState();
}

class _LocalVideoPlayerState extends State<LocalVideoPlayer> {
  late Player _player;
  late VideoController _videoController;
  late Future<void> _loadFuture;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void didUpdateWidget(covariant LocalVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _player.dispose();
      _initializePlayer();
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ColoredBox(
            color: Colors.black,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snapshot.error.toString(),
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        if (snapshot.connectionState != ConnectionState.done) {
          return const ColoredBox(
            color: Colors.black,
            child: Center(child: CupertinoActivityIndicator()),
          );
        }

        return ColoredBox(
          color: Colors.black,
          child: Video(
            controller: _videoController,
            fit: widget.fit,
            controls:
                widget.showControls ? AdaptiveVideoControls : NoVideoControls,
          ),
        );
      },
    );
  }

  void _initializePlayer() {
    _player = Player();
    _videoController = VideoController(_player);
    _loadFuture = _openVideo();
  }

  Future<void> _openVideo() async {
    await _player.open(
      Media(Uri.file(widget.path).toString()),
      play: widget.autoplay,
    );
    await _videoController.waitUntilFirstFrameRendered;
  }
}
