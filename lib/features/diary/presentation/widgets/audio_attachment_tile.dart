import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:diary_mvp/app/localization/app_strings.dart';
import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class AudioAttachmentTile extends StatefulWidget {
  const AudioAttachmentTile({
    super.key,
    required this.media,
    this.onDeleted,
  });

  final DiaryMedia media;
  final VoidCallback? onDeleted;

  @override
  State<AudioAttachmentTile> createState() => _AudioAttachmentTileState();
}

class _AudioAttachmentTileState extends State<AudioAttachmentTile> {
  late final AudioPlayer _player;
  late final StreamSubscription<PlayerState> _playerStateSubscription;
  late final StreamSubscription<Duration> _positionSubscription;
  late final StreamSubscription<Duration> _durationSubscription;
  late final StreamSubscription<void> _completionSubscription;

  PlayerState _playerState = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isLoading = false;
  Object? _playbackError;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _playerStateSubscription = _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _playerState = state);
    });
    _positionSubscription = _player.onPositionChanged.listen((position) {
      if (!mounted) return;
      setState(() => _position = position);
    });
    _durationSubscription = _player.onDurationChanged.listen((duration) {
      if (!mounted) return;
      setState(() => _duration = duration);
    });
    _completionSubscription = _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _playerState = PlayerState.stopped;
        _position = Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    _playerStateSubscription.cancel();
    _positionSubscription.cancel();
    _durationSubscription.cancel();
    _completionSubscription.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final baseName = p.basename(widget.media.path);
    final progress = _duration.inMilliseconds <= 0
        ? null
        : (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0);
    final statusText = _statusText(strings);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: _isLoading ? null : _togglePlayback,
                tooltip: _playerState == PlayerState.playing
                    ? strings.pauseAudio
                    : strings.playAudio,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _playerState == PlayerState.playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.mediaLabel(widget.media, baseName: baseName),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusText,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (widget.onDeleted != null)
                IconButton(
                  onPressed: widget.onDeleted,
                  icon: const Icon(Icons.delete_outline),
                ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 6,
                value: progress,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _togglePlayback() async {
    setState(() {
      _isLoading = true;
      _playbackError = null;
    });

    try {
      switch (_playerState) {
        case PlayerState.playing:
          await _player.pause();
          break;
        case PlayerState.paused:
          await _player.resume();
          break;
        case PlayerState.stopped:
        case PlayerState.completed:
          await _player.play(DeviceFileSource(widget.media.path));
          break;
        case PlayerState.disposed:
          break;
      }
    } catch (error) {
      if (mounted) {
        setState(() => _playbackError = error);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _statusText(AppStrings strings) {
    if (_playbackError != null) {
      return strings.playbackFailed(_playbackError!);
    }

    final durationText = _duration > Duration.zero
        ? '${_format(_position)} / ${_format(_duration)}'
        : widget.media.durationLabel;

    switch (_playerState) {
      case PlayerState.playing:
        return _joinStatus(strings.audioPlaying, durationText);
      case PlayerState.paused:
        return _joinStatus(strings.audioPaused, durationText);
      case PlayerState.stopped:
      case PlayerState.completed:
      case PlayerState.disposed:
        return _joinStatus(
            strings.audioReady, widget.media.durationLabel ?? durationText);
    }
  }

  String _joinStatus(String left, String? right) {
    if (right == null || right.isEmpty) return left;
    return '$left - $right';
  }

  String _format(Duration value) {
    final totalSeconds = value.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
