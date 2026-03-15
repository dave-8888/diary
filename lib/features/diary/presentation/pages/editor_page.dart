import 'dart:math';

import 'package:diary_mvp/core/storage/local_storage_service.dart';
import 'package:diary_mvp/features/diary/application/diary_controller.dart';
import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/diary_shell.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/mood_selector.dart';
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
    return DiaryShell(
      title: 'New Entry',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: ListView(
            children: [
              Text('What happened today?',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 20),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'For example: Afternoon in the park',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contentController,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  hintText:
                      'Write down what happened, how you felt, and what you want to remember...',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'For example: Home / Office / Shanghai',
                ),
              ),
              const SizedBox(height: 24),
              Text('Mood', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              MoodSelector(
                value: _mood,
                onChanged: (mood) => setState(() => _mood = mood),
              ),
              const SizedBox(height: 24),
              Text('Media toolbar',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('Import image'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _isRecording ? _stopRecording : _startRecording,
                    icon: Icon(_isRecording
                        ? Icons.stop_circle_outlined
                        : Icons.mic_none),
                    label: Text(
                        _isRecording ? 'Stop recording' : 'Start recording'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _isTranscribing ? null : _transcribeLatestAudio,
                    icon: const Icon(Icons.subtitles_outlined),
                    label: Text(_isTranscribing
                        ? 'Transcribing...'
                        : 'Transcribe latest audio'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_media.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _media
                      .map(
                        (media) => Chip(
                          avatar: Icon(_iconForMedia(media.type), size: 18),
                          label: Text(_mediaLabel(media)),
                          onDeleted: () => setState(() => _media.remove(media)),
                        ),
                      )
                      .toList(),
                ),
              const SizedBox(height: 32),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(_isSaving ? 'Saving...' : 'Save entry'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImages() async {
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
        SnackBar(content: Text('Imported ${added.length} image file(s).')),
      );
    }
  }

  Future<void> _startRecording() async {
    if (!await _audioRecorder.hasPermission()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission denied.')),
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
      const SnackBar(content: Text('Audio recording saved.')),
    );
  }

  Future<void> _transcribeLatestAudio() async {
    final latestAudio = _findLatestAudio();
    if (latestAudio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please record audio first.')),
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
        SnackBar(content: Text(result.message)),
      );
      return;
    }

    final prefix = _contentController.text.trim().isEmpty ? '' : '\n\n';
    _contentController.text = '${_contentController.text}$prefix${result.text}';
    _contentController.selection =
        TextSelection.collapsed(offset: _contentController.text.length);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Transcription inserted into entry content.')),
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
      const SnackBar(content: Text('Entry saved to local SQLite.')),
    );
    context.go('/timeline');
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
    final name = p.basename(media.path);
    switch (media.type) {
      case MediaType.image:
        return 'Image: $name';
      case MediaType.audio:
        final duration =
            media.durationLabel == null ? '' : ' (${media.durationLabel})';
        return 'Audio$duration: $name';
      case MediaType.video:
        return 'Video: $name';
    }
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
