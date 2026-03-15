import 'dart:math';

import 'package:diary_mvp/app/localization/app_strings.dart';
import 'package:diary_mvp/core/storage/local_storage_service.dart';
import 'package:diary_mvp/features/diary/application/diary_controller.dart';
import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
import 'package:diary_mvp/features/diary/presentation/models/captured_media_result.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/audio_attachment_tile.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/diary_shell.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/image_media_grid.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/mood_selector.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/video_attachment_card.dart';
import 'package:diary_mvp/features/diary/services/transcription_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

class EditorPage extends ConsumerStatefulWidget {
  const EditorPage({super.key});

  @override
  ConsumerState<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends ConsumerState<EditorPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _locationController = TextEditingController();
  final _uuid = const Uuid();
  final AudioRecorder _audioRecorder = AudioRecorder();

  DiaryMood _mood = DiaryMood.calm;
  final List<DiaryMedia> _media = [];

  bool _isSaving = false;
  bool _isRecording = false;
  bool _isTranscribing = false;
  DateTime? _recordingStartedAt;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _locationController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final imageMedia =
        _media.where((item) => item.type == MediaType.image).toList();
    final videoMedia =
        _media.where((item) => item.type == MediaType.video).toList();
    final audioMedia =
        _media.where((item) => item.type == MediaType.audio).toList();
    final otherMedia = _media
        .where((item) =>
            item.type != MediaType.audio &&
            item.type != MediaType.image &&
            item.type != MediaType.video)
        .toList();

    return DiaryShell(
      title: strings.newEntry,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final showVideoSidebar = constraints.maxWidth >= 1080;
              final mainSections = _buildMainSections(
                context: context,
                strings: strings,
                imageMedia: imageMedia,
                audioMedia: audioMedia,
                otherMedia: otherMedia,
              );

              if (!showVideoSidebar) {
                return ListView(
                  children: [
                    ...mainSections,
                    const SizedBox(height: 24),
                    _buildVideoSection(context, strings, videoMedia),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ListView(children: mainSections),
                  ),
                  const SizedBox(width: 24),
                  SizedBox(
                    width: 320,
                    child: ListView(
                      children: [
                        _buildVideoSection(context, strings, videoMedia),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMainSections({
    required BuildContext context,
    required AppStrings strings,
    required List<DiaryMedia> imageMedia,
    required List<DiaryMedia> audioMedia,
    required List<DiaryMedia> otherMedia,
  }) {
    return [
      Text(
        strings.whatHappenedToday,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 20),
      TextField(
        controller: _titleController,
        decoration: InputDecoration(
          labelText: strings.titleLabel,
          hintText: strings.titleHint,
        ),
      ),
      const SizedBox(height: 24),
      Text(
        strings.mediaToolbar,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          FilledButton.tonalIcon(
            onPressed: _pickImages,
            icon: const Icon(Icons.image_outlined),
            label: Text(strings.importImage),
          ),
          FilledButton.tonalIcon(
            onPressed: _takePhoto,
            icon: const Icon(Icons.camera_alt_outlined),
            label: Text(strings.takePhoto),
          ),
          FilledButton.tonalIcon(
            onPressed: _recordVideo,
            icon: const Icon(Icons.videocam_outlined),
            label: Text(strings.recordVideo),
          ),
          FilledButton.tonalIcon(
            onPressed: _isRecording ? _stopRecording : _startRecording,
            icon: Icon(
              _isRecording ? Icons.stop_circle_outlined : Icons.mic_none,
            ),
            label: Text(
              _isRecording ? strings.stopRecording : strings.startRecording,
            ),
          ),
          FilledButton.tonalIcon(
            onPressed: _isTranscribing ? null : _transcribeLatestAudio,
            icon: const Icon(Icons.subtitles_outlined),
            label: Text(
              _isTranscribing
                  ? strings.transcribing
                  : strings.transcribeLatestAudio,
            ),
          ),
        ],
      ),
      if (imageMedia.isNotEmpty) ...[
        const SizedBox(height: 16),
        ImageMediaGrid(
          media: imageMedia,
          onDeleted: (media) => setState(() => _media.remove(media)),
        ),
      ],
      const SizedBox(height: 16),
      TextField(
        controller: _contentController,
        maxLines: 10,
        decoration: InputDecoration(
          labelText: strings.contentLabel,
          hintText: strings.contentHint,
        ),
      ),
      if (audioMedia.isNotEmpty || otherMedia.isNotEmpty) ...[
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (audioMedia.isNotEmpty)
              ...audioMedia.map(
                (media) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AudioAttachmentTile(
                    media: media,
                    onDeleted: () => setState(() => _media.remove(media)),
                  ),
                ),
              ),
            if (otherMedia.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: otherMedia
                    .map(
                      (media) => Chip(
                        avatar: Icon(_iconForMedia(media.type), size: 18),
                        label: Text(_mediaLabel(media)),
                        onDeleted: () => setState(() => _media.remove(media)),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ],
      const SizedBox(height: 16),
      TextField(
        controller: _locationController,
        decoration: InputDecoration(
          labelText: strings.locationLabel,
          hintText: strings.locationHint,
        ),
      ),
      const SizedBox(height: 24),
      Text(
        strings.mood,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 12),
      MoodSelector(
        value: _mood,
        onChanged: (mood) => setState(() => _mood = mood),
      ),
      const SizedBox(height: 32),
      Align(
        alignment: Alignment.centerRight,
        child: FilledButton.icon(
          onPressed: _isSaving ? null : _save,
          icon: const Icon(Icons.save_outlined),
          label: Text(_isSaving ? strings.saving : strings.saveEntry),
        ),
      ),
    ];
  }

  Widget _buildVideoSection(
    BuildContext context,
    AppStrings strings,
    List<DiaryMedia> videoMedia,
  ) {
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
              strings.videoSidebarHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (videoMedia.isNotEmpty) const SizedBox(height: 16),
            if (videoMedia.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: Text(
                  strings.recordVideo,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              )
            else
              ...videoMedia.map(
                (media) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: VideoAttachmentCard(
                    media: media,
                    onTap: () => _openVideoPreview(media),
                    onDeleted: () => setState(() => _media.remove(media)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImages() async {
    final strings = context.strings;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: false,
    );
    if (result == null) return;

    final storage = ref.read(localStorageServiceProvider);
    final added = <DiaryMedia>[];

    for (final file in result.files) {
      final sourcePath = file.path;
      if (sourcePath == null) continue;
      final savedPath = await storage.copyImageToAppStorage(sourcePath);
      added.add(
        DiaryMedia(
          id: _uuid.v4(),
          type: MediaType.image,
          path: savedPath,
        ),
      );
    }

    if (!mounted) return;
    if (added.isNotEmpty) {
      setState(() => _media.addAll(added));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.importedImages(added.length))),
      );
    }
  }

  Future<void> _takePhoto() => _captureWithCamera(mode: 'photo');

  Future<void> _recordVideo() => _captureWithCamera(mode: 'video');

  Future<void> _captureWithCamera({
    required String mode,
  }) async {
    final strings = context.strings;
    final result = await context.push<CapturedMediaResult>(
      mode == 'video' ? '/camera?mode=video' : '/camera',
    );
    if (!mounted || result == null) return;

    setState(() {
      _media.add(
        DiaryMedia(
          id: _uuid.v4(),
          type: result.type,
          path: result.path,
          durationLabel: result.durationLabel,
        ),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.type == MediaType.video
              ? strings.videoImported
              : strings.photoImported,
        ),
      ),
    );
  }

  Future<void> _startRecording() async {
    final strings = context.strings;
    if (!await _audioRecorder.hasPermission()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.microphonePermissionDenied)),
      );
      return;
    }

    final storage = ref.read(localStorageServiceProvider);
    final outputPath = await storage.createAudioRecordingPath();
    await _audioRecorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: outputPath,
    );

    if (!mounted) return;
    setState(() {
      _isRecording = true;
      _recordingStartedAt = DateTime.now();
    });
  }

  Future<void> _stopRecording() async {
    final strings = context.strings;
    final outputPath = await _audioRecorder.stop();
    final startedAt = _recordingStartedAt;

    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _recordingStartedAt = null;
    });

    if (outputPath == null) return;

    final seconds = startedAt == null
        ? 0
        : max(0, DateTime.now().difference(startedAt).inSeconds);
    setState(() {
      _media.add(
        DiaryMedia(
          id: _uuid.v4(),
          type: MediaType.audio,
          path: outputPath,
          durationLabel: _formatDuration(seconds),
        ),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.audioRecordingSaved)),
    );
  }

  Future<void> _transcribeLatestAudio() async {
    final strings = context.strings;
    final latestAudio = _findLatestAudio();
    if (latestAudio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.pleaseRecordAudioFirst)),
      );
      return;
    }

    setState(() => _isTranscribing = true);
    final service = ref.read(transcriptionServiceProvider);
    final result = await service.transcribe(latestAudio.path);

    if (!mounted) return;
    setState(() => _isTranscribing = false);

    if (!result.ok || result.text == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_transcriptionFailureMessage(strings, result))),
      );
      return;
    }

    final prefix = _contentController.text.trim().isEmpty ? '' : '\n\n';
    _contentController.text = '${_contentController.text}$prefix${result.text}';
    _contentController.selection =
        TextSelection.collapsed(offset: _contentController.text.length);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.transcriptionInserted)),
    );
  }

  DiaryMedia? _findLatestAudio() {
    for (var index = _media.length - 1; index >= 0; index--) {
      final item = _media[index];
      if (item.type == MediaType.audio) return item;
    }
    return null;
  }

  Future<void> _save() async {
    final strings = context.strings;
    setState(() => _isSaving = true);
    await ref.read(diaryControllerProvider.notifier).addEntry(
          title: _titleController.text,
          content: _contentController.text,
          mood: _mood,
          location: _locationController.text,
          media: List<DiaryMedia>.from(_media),
        );

    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.entrySaved)),
    );
    context.go('/timeline');
  }

  void _openVideoPreview(DiaryMedia media) {
    context.push('/video-preview', extra: media);
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

  String _mediaLabel(DiaryMedia media) {
    final strings = context.strings;
    final name = p.basename(media.path);
    return strings.mediaLabel(media, baseName: name);
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _transcriptionFailureMessage(
    AppStrings strings,
    TranscriptionResult result,
  ) {
    switch (result.failure) {
      case TranscriptionFailure.apiKeyMissing:
        return strings.apiKeyMissing;
      case TranscriptionFailure.fileNotFound:
        return strings.audioFileMissing;
      case TranscriptionFailure.requestFailed:
        return strings.transcriptionRequestFailed(result.statusCode);
      case TranscriptionFailure.emptyResponse:
      case null:
        return strings.noTranscriptionText;
    }
  }
}
