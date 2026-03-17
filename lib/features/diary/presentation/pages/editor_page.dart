import 'dart:math';

import 'package:diary_mvp/app/localization/app_strings.dart';
import 'package:diary_mvp/app/themed_snackbar.dart';
import 'package:diary_mvp/core/storage/local_storage_service.dart';
import 'package:diary_mvp/features/diary/application/diary_controller.dart';
import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
import 'package:diary_mvp/features/diary/presentation/models/captured_media_result.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/audio_attachment_tile.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/diary_shell.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/image_media_grid.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/mood_selector.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/video_attachment_card.dart';
import 'package:diary_mvp/features/diary/services/diary_ai_service.dart';
import 'package:diary_mvp/features/diary/services/diary_ai_settings.dart';
import 'package:diary_mvp/features/diary/services/export_service.dart';
import 'package:diary_mvp/features/diary/services/location_service.dart';
import 'package:diary_mvp/features/diary/services/transcription_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

class EditorPage extends ConsumerStatefulWidget {
  const EditorPage({
    super.key,
    this.entry,
  });

  final DiaryEntry? entry;

  @override
  ConsumerState<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends ConsumerState<EditorPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _locationController = TextEditingController();
  final _tagController = TextEditingController();
  final _uuid = const Uuid();
  final AudioRecorder _audioRecorder = AudioRecorder();

  String _moodId = DiaryMood.defaultSelectionId;
  final List<DiaryMedia> _media = [];
  final List<String> _tags = [];

  bool _isSaving = false;
  bool _isDeleting = false;
  bool _isExporting = false;
  bool _isRecording = false;
  bool _isTranscribing = false;
  bool _isAnalyzingAi = false;
  bool _isLocating = false;
  bool _isManagingTags = false;
  DateTime? _recordingStartedAt;
  DiaryAiSuggestion? _aiSuggestion;

  bool get _isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    if (entry == null) return;

    _titleController.text = entry.title;
    _contentController.text = entry.content;
    _locationController.text = entry.location ?? '';
    _moodId = entry.mood.id;
    _media.addAll(entry.media);
    _tags.addAll(entry.tags);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _locationController.dispose();
    _tagController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final tagLibraryAsync = ref.watch(tagLibraryControllerProvider);
    final moodLibraryAsync = ref.watch(moodLibraryControllerProvider);
    final showDiaryAiSection =
        ref.watch(diaryAiVisibilityControllerProvider).valueOrNull ?? true;
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
      title: _isEditing ? strings.editEntry : strings.newEntry,
      showAppBarTitle: false,
      actions: [
        if (_isEditing)
          IconButton(
            onPressed: _isSaving || _isDeleting || _isExporting
                ? null
                : _confirmDelete,
            tooltip: strings.deleteEntry,
            icon: _isDeleting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline),
          ),
      ],
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
                moodLibraryAsync: moodLibraryAsync,
              );
              final aiSection = showDiaryAiSection
                  ? _buildAiSection(
                      context,
                      strings,
                      moodLibraryAsync,
                    )
                  : null;

              if (!showVideoSidebar) {
                return ListView(
                  children: [
                    ...mainSections,
                    if (aiSection != null) ...[
                      const SizedBox(height: 24),
                      aiSection,
                    ],
                    const SizedBox(height: 24),
                    _buildTagSection(context, strings, tagLibraryAsync),
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
                        if (aiSection != null) ...[
                          aiSection,
                          const SizedBox(height: 16),
                        ],
                        _buildTagSection(context, strings, tagLibraryAsync),
                        const SizedBox(height: 16),
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
    required AsyncValue<List<DiaryMood>> moodLibraryAsync,
  }) {
    return [
      _buildEditorHeader(context, strings),
      const SizedBox(height: 18),
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
          suffixIcon: _isLocating
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  onPressed:
                      _isSaving || _isDeleting ? null : _fillCurrentLocation,
                  tooltip: strings.useCurrentLocation,
                  icon: const Icon(Icons.my_location_outlined),
                ),
        ),
      ),
      const SizedBox(height: 24),
      Text(
        strings.mood,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 12),
      moodLibraryAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Text(strings.failedToLoadMoods(error)),
        data: (moods) {
          final availableMoods = moods.isEmpty ? DiaryMood.values : moods;
          final currentMood = _resolveMoodFromLibrary(availableMoods);
          return MoodSelector(
            moods: availableMoods,
            valueId: currentMood.id,
            onChanged: (mood) => setState(() => _moodId = mood.id),
          );
        },
      ),
    ];
  }

  Widget _buildEditorHeader(BuildContext context, AppStrings strings) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final actionButtons = _buildHeaderActionButtons(context, strings);

        if (constraints.maxWidth < 760) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.whatHappenedToday,
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 14),
              actionButtons,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                strings.whatHappenedToday,
                style: theme.textTheme.headlineMedium,
              ),
            ),
            const SizedBox(width: 20),
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: actionButtons,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeaderActionButtons(BuildContext context, AppStrings strings) {
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        FilledButton.tonalIcon(
          onPressed:
              _isSaving || _isDeleting || _isExporting ? null : _exportEntry,
          icon: _isExporting
              ? _buttonProgressIndicator(
                  color: colorScheme.onSecondaryContainer,
                )
              : const Icon(Icons.file_download_outlined),
          label: Text(
            _isExporting ? strings.exportingEntry : strings.exportEntry,
          ),
        ),
        FilledButton.icon(
          onPressed: _isSaving || _isDeleting || _isExporting ? null : _save,
          icon: _isSaving || _isDeleting
              ? _buttonProgressIndicator(color: colorScheme.onPrimary)
              : const Icon(Icons.save_outlined),
          label: Text(
            _isDeleting
                ? strings.deleting
                : _isSaving
                    ? strings.saving
                    : (_isEditing ? strings.updateEntry : strings.saveEntry),
          ),
        ),
      ],
    );
  }

  Widget _buttonProgressIndicator({
    required Color color,
  }) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: color,
      ),
    );
  }

  Widget _buildAiSection(
    BuildContext context,
    AppStrings strings,
    AsyncValue<List<DiaryMood>> moodLibraryAsync,
  ) {
    final suggestion = _aiSuggestion;
    final availableMoods = moodLibraryAsync.valueOrNull ?? DiaryMood.values;
    final showEmotionalCompanion =
        ref.watch(emotionalCompanionVisibilityControllerProvider).valueOrNull ??
            true;
    final detectedMood = suggestion == null
        ? null
        : _resolveAiMood(availableMoods, suggestion.moodId);

    return _buildSidebarCard(
      context: context,
      icon: Icons.auto_awesome_outlined,
      title: strings.diaryAiToolsTitle,
      subtitle: strings.diaryAiToolsHint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed:
                  _isAnalyzingAi || _isSaving || _isDeleting || _isExporting
                      ? null
                      : _analyzeWithAi,
              icon: _isAnalyzingAi
                  ? _buttonProgressIndicator(
                      color: Theme.of(context).colorScheme.onPrimary,
                    )
                  : const Icon(Icons.auto_fix_high_outlined),
              label: Text(
                _isAnalyzingAi
                    ? strings.analyzingDiaryWithAi
                    : strings.analyzeDiaryWithAi,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (suggestion == null)
            _buildSidebarEmptyState(
              context,
              icon: Icons.lightbulb_outline,
              message: strings.noAiSuggestionYet,
            )
          else ...[
            _buildAiResultBlock(
              context,
              label: strings.aiGeneratedTitleLabel,
              child: Text(
                suggestion.title.trim().isEmpty
                    ? strings.aiGeneratedTitleEmpty
                    : suggestion.title,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 14),
            _buildAiResultBlock(
              context,
              label: strings.aiSummaryLabel,
              child: Text(
                suggestion.summary.trim().isEmpty
                    ? strings.aiSummaryEmpty
                    : suggestion.summary,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.45,
                    ),
              ),
            ),
            const SizedBox(height: 14),
            _buildAiResultBlock(
              context,
              label: strings.aiDetectedMoodLabel,
              child: Text(
                detectedMood == null
                    ? strings.defaultMoodLabel(DiaryMood.neutralId)
                    : strings.moodLabel(detectedMood),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 14),
            _buildAiResultBlock(
              context,
              label: strings.aiSuggestedTagsLabel,
              child: suggestion.tags.isEmpty
                  ? Text(
                      strings.aiNoTagsSuggested,
                      style: Theme.of(context).textTheme.bodyMedium,
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: suggestion.tags
                          .map(
                            (tag) => Chip(
                              avatar: const Icon(Icons.label_outline, size: 18),
                              label: Text(_normalizeTag(tag) ?? tag),
                            ),
                          )
                          .toList(growable: false),
                    ),
            ),
            if (showEmotionalCompanion) ...[
              const SizedBox(height: 18),
              Text(
                strings.emotionalCompanionSectionTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              if (_isCompanionEmpty(suggestion))
                _buildSidebarEmptyState(
                  context,
                  icon: Icons.favorite_outline,
                  message: strings.emotionalCompanionEmpty,
                )
              else ...[
                _buildAiResultBlock(
                  context,
                  label: strings.emotionCategoryLabel,
                  child: Text(
                    suggestion.emotionCategory.trim().isEmpty
                        ? strings.moodLabel(
                            detectedMood ?? DiaryMood.neutral,
                          )
                        : suggestion.emotionCategory,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 14),
                _buildAiResultBlock(
                  context,
                  label: strings.companionStyleLabel,
                  child: Text(
                    suggestion.companionStyle.trim().isEmpty
                        ? strings.notProvided
                        : suggestion.companionStyle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 14),
                _buildAiResultBlock(
                  context,
                  label: strings.comfortReplyLabel,
                  child: Text(
                    suggestion.comfortReply.trim().isEmpty
                        ? strings.notProvided
                        : suggestion.comfortReply,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.45,
                        ),
                  ),
                ),
                const SizedBox(height: 14),
                _buildAiResultBlock(
                  context,
                  label: strings.priorityFeedbackLabel,
                  child: Text(
                    suggestion.priorityFeedback.trim().isEmpty
                        ? strings.noPriorityFeedback
                        : suggestion.priorityFeedback,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.45,
                        ),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.tonalIcon(
                  onPressed: _applyAllAiSuggestions,
                  icon: const Icon(Icons.done_all_outlined),
                  label: Text(strings.applyAllAiSuggestions),
                ),
                OutlinedButton.icon(
                  onPressed:
                      suggestion.title.trim().isEmpty ? null : _applyAiTitle,
                  icon: const Icon(Icons.title_outlined),
                  label: Text(strings.applyAiTitle),
                ),
                OutlinedButton.icon(
                  onPressed: _applyAiMood,
                  icon: const Icon(Icons.mood_outlined),
                  label: Text(strings.applyAiMood),
                ),
                OutlinedButton.icon(
                  onPressed: suggestion.tags.isEmpty ? null : _applyAiTags,
                  icon: const Icon(Icons.sell_outlined),
                  label: Text(strings.applyAiTags),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAiResultBlock(
    BuildContext context, {
    required String label,
    required Widget child,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: child,
          ),
        ),
      ],
    );
  }

  Widget _buildTagSection(
    BuildContext context,
    AppStrings strings,
    AsyncValue<List<String>> tagLibraryAsync,
  ) {
    return _buildSidebarCard(
      context: context,
      icon: Icons.sell_outlined,
      title: strings.tagsLabel,
      subtitle: strings.tagSidebarHint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _tagController,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _createTagFromInput(),
                  decoration: InputDecoration(
                    labelText: strings.tagsLabel,
                    hintText: strings.tagHint,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.tonalIcon(
                onPressed: _isManagingTags ? null : _createTagFromInput,
                icon: _isManagingTags
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_rounded),
                label: Text(strings.addTag),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            strings.selectedTagsLabel,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          if (_tags.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags
                  .map(
                    (tag) => Chip(
                      label: Text(tag),
                      onDeleted: () => setState(() => _tags.remove(tag)),
                    ),
                  )
                  .toList(),
            )
          else
            _buildSidebarEmptyState(
              context,
              icon: Icons.label_outline,
              message: strings.noSelectedTags,
            ),
          const SizedBox(height: 18),
          Text(
            strings.tagLibraryLabel,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          tagLibraryAsync.when(
            loading: () => const Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (error, stack) => Text(strings.failedToLoadTags(error)),
            data: (tags) {
              if (tags.isEmpty) {
                return _buildSidebarEmptyState(
                  context,
                  icon: Icons.inventory_2_outlined,
                  message: strings.noTagsYet,
                );
              }

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tags
                    .map(
                      (tag) => InputChip(
                        selected: _hasTag(tag),
                        onSelected: _isManagingTags
                            ? null
                            : (_) => setState(() => _toggleTag(tag)),
                        onDeleted: _isManagingTags
                            ? null
                            : () => _confirmDeleteLibraryTag(tag),
                        deleteIcon: const Icon(Icons.delete_outline, size: 18),
                        deleteButtonTooltipMessage:
                            strings.removeTagFromLibrary,
                        label: Text(tag),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVideoSection(
    BuildContext context,
    AppStrings strings,
    List<DiaryMedia> videoMedia,
  ) {
    return _buildSidebarCard(
      context: context,
      icon: Icons.video_library_outlined,
      title: strings.videoSidebarTitle,
      subtitle: strings.videoSidebarHint,
      child: videoMedia.isEmpty
          ? _buildSidebarEmptyState(
              context,
              icon: Icons.videocam_outlined,
              message: strings.recordVideo,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: videoMedia
                  .map(
                    (media) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: VideoAttachmentCard(
                        media: media,
                        onTap: () => _openVideoPreview(media),
                        onDeleted: () => setState(() => _media.remove(media)),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Widget _buildSidebarCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(
              height: 1,
              color: theme.colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarEmptyState(
    BuildContext context, {
    required IconData icon,
    required String message,
  }) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.35,
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
      context.showAppSnackBar(
        strings.importedImages(added.length),
        tone: AppSnackBarTone.success,
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

    context.showAppSnackBar(
      result.type == MediaType.video
          ? strings.videoImported
          : strings.photoImported,
      tone: AppSnackBarTone.success,
    );
  }

  Future<void> _startRecording() async {
    final strings = context.strings;
    if (!await _audioRecorder.hasPermission()) {
      if (!mounted) return;
      context.showAppSnackBar(
        strings.microphonePermissionDenied,
        tone: AppSnackBarTone.warning,
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

    context.showAppSnackBar(
      strings.audioRecordingSaved,
      tone: AppSnackBarTone.success,
    );
  }

  Future<void> _transcribeLatestAudio() async {
    final strings = context.strings;
    final latestAudio = _findLatestAudio();
    if (latestAudio == null) {
      context.showAppSnackBar(
        strings.pleaseRecordAudioFirst,
        tone: AppSnackBarTone.warning,
      );
      return;
    }

    setState(() => _isTranscribing = true);
    final service = ref.read(transcriptionServiceProvider);
    final result = await service.transcribe(latestAudio.path);

    if (!mounted) return;
    setState(() => _isTranscribing = false);

    if (!result.ok || result.text == null) {
      context.showAppSnackBar(
        _transcriptionFailureMessage(strings, result),
        tone: AppSnackBarTone.error,
      );
      return;
    }

    final prefix = _contentController.text.trim().isEmpty ? '' : '\n\n';
    _contentController.text = '${_contentController.text}$prefix${result.text}';
    _contentController.selection =
        TextSelection.collapsed(offset: _contentController.text.length);

    context.showAppSnackBar(
      strings.transcriptionInserted,
      tone: AppSnackBarTone.success,
    );
  }

  Future<void> _analyzeWithAi() async {
    final strings = context.strings;
    final moods =
        ref.read(moodLibraryControllerProvider).valueOrNull ?? DiaryMood.values;
    final includeEmotionalCompanion =
        ref.read(emotionalCompanionVisibilityControllerProvider).valueOrNull ??
            true;

    setState(() => _isAnalyzingAi = true);
    final result = await ref.read(diaryAiServiceProvider).analyzeEntry(
          draft: _buildDraftEntry(),
          availableMoods: moods,
          preferChinese: strings.isChinese,
          includeEmotionalCompanion: includeEmotionalCompanion,
        );

    if (!mounted) return;
    setState(() {
      _isAnalyzingAi = false;
      if (result.ok) {
        _aiSuggestion = result.suggestion;
      }
    });

    if (!result.ok || result.suggestion == null) {
      context.showAppSnackBar(
        _diaryAiFailureMessage(strings, result),
        tone: AppSnackBarTone.error,
      );
      return;
    }

    context.showAppSnackBar(
      strings.aiAnalysisReady,
      tone: AppSnackBarTone.success,
    );
  }

  DiaryMedia? _findLatestAudio() {
    for (var index = _media.length - 1; index >= 0; index--) {
      final item = _media[index];
      if (item.type == MediaType.audio) return item;
    }
    return null;
  }

  Future<void> _createTagFromInput() async {
    final normalized = _normalizeTag(_tagController.text);
    _tagController.clear();
    if (normalized == null) return;
    final alreadySelected = _hasTag(normalized);

    setState(() {
      _isManagingTags = true;
      if (!alreadySelected) {
        _tags.add(normalized);
      }
    });

    final strings = context.strings;
    try {
      await ref.read(tagLibraryControllerProvider.notifier).saveTag(normalized);
      if (!mounted) return;
      setState(() => _isManagingTags = false);
      context.showAppSnackBar(
        strings.tagAdded,
        tone: AppSnackBarTone.success,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isManagingTags = false;
        if (!alreadySelected) {
          _tags.removeWhere(
            (tag) => tag.toLowerCase() == normalized.toLowerCase(),
          );
        }
      });
      context.showAppSnackBar(
        strings.tagSaveFailed(error),
        tone: AppSnackBarTone.error,
      );
    }
  }

  Future<void> _fillCurrentLocation() async {
    final strings = context.strings;
    setState(() => _isLocating = true);

    final result =
        await ref.read(locationServiceProvider).lookupCurrentLocation(
              locale: Localizations.localeOf(context),
            );

    if (!mounted) return;
    setState(() => _isLocating = false);

    if (result.ok && result.locationText != null) {
      _locationController.text = result.locationText!;
      _locationController.selection = TextSelection.collapsed(
        offset: _locationController.text.length,
      );
      context.showAppSnackBar(
        strings.locationUpdated,
        tone: AppSnackBarTone.success,
      );
      return;
    }

    context.showAppSnackBar(
      _locationFailureMessage(strings, result),
      tone: AppSnackBarTone.error,
    );
  }

  Future<void> _save() async {
    final strings = context.strings;
    setState(() => _isSaving = true);
    final controller = ref.read(diaryControllerProvider.notifier);
    final media = List<DiaryMedia>.from(_media);
    final tags = List<String>.from(_tags);
    final mood = _resolveMoodFromLibrary(
      ref.read(moodLibraryControllerProvider).valueOrNull ?? DiaryMood.values,
    );

    try {
      if (_isEditing) {
        await controller.updateEntry(
          entry: widget.entry!,
          title: _titleController.text,
          content: _contentController.text,
          mood: mood,
          location: _locationController.text,
          tags: tags,
          media: media,
        );
      } else {
        await controller.addEntry(
          title: _titleController.text,
          content: _contentController.text,
          mood: mood,
          location: _locationController.text,
          tags: tags,
          media: media,
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      context.showAppSnackBar(
        strings.entrySaveFailed(error),
        tone: AppSnackBarTone.error,
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isSaving = false);
    context.showAppSnackBar(
      _isEditing ? strings.entryUpdated : strings.entrySaved,
      tone: AppSnackBarTone.success,
    );
    context.go('/timeline');
  }

  Future<void> _confirmDelete() async {
    final entry = widget.entry;
    if (entry == null) return;

    final strings = context.strings;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(strings.deleteEntryConfirmTitle),
            content: Text(strings.deleteEntryConfirmMessage(entry.title)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(strings.cancelAction),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(strings.confirmDelete),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !mounted) return;
    await _deleteEntry();
  }

  Future<void> _deleteEntry() async {
    final entry = widget.entry;
    if (entry == null) return;

    final strings = context.strings;
    final draftEntry = _buildDraftEntry();
    final entryToTrash = entry.copyWith(
      title: draftEntry.title.trim().isEmpty ? entry.title : draftEntry.title,
      content: draftEntry.content,
      mood: draftEntry.mood,
      location: draftEntry.location,
      tags: draftEntry.tags,
      media: draftEntry.media,
    );
    setState(() => _isDeleting = true);

    try {
      await ref
          .read(diaryControllerProvider.notifier)
          .moveEntryToTrash(entryToTrash);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      context.showAppSnackBar(
        strings.deleteEntryFailed(error),
        tone: AppSnackBarTone.error,
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isDeleting = false);
    context.showAppSnackBar(
      strings.entryDeleted,
      tone: AppSnackBarTone.success,
    );
    context.go('/trash');
  }

  Future<void> _exportEntry() async {
    final strings = context.strings;
    final destinationRootPath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: strings.selectExportFolder,
    );
    if (!mounted || destinationRootPath == null) {
      if (mounted) {
        context.showAppSnackBar(
          strings.exportFolderNotSelected,
          tone: AppSnackBarTone.warning,
        );
      }
      return;
    }

    setState(() => _isExporting = true);
    try {
      final result = await ref.read(diaryExportServiceProvider).exportEntry(
            entry: _buildDraftEntry(),
            destinationRootPath: destinationRootPath,
            strings: strings,
          );
      if (!mounted) return;
      setState(() => _isExporting = false);
      context.showAppSnackBar(
        strings.entryExported(result.directoryPath),
        tone: AppSnackBarTone.success,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isExporting = false);
      context.showAppSnackBar(
        strings.entryExportFailed(error),
        tone: AppSnackBarTone.error,
      );
    }
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

  String _diaryAiFailureMessage(
    AppStrings strings,
    DiaryAiResult result,
  ) {
    switch (result.failure) {
      case DiaryAiFailure.apiKeyMissing:
        return strings.diaryAiApiKeyMissing;
      case DiaryAiFailure.insufficientInput:
        return strings.diaryAiInputRequired;
      case DiaryAiFailure.requestFailed:
        return strings.diaryAiRequestFailed(result.statusCode);
      case DiaryAiFailure.invalidResponse:
      case null:
        return strings.diaryAiInvalidResponse;
    }
  }

  String _locationFailureMessage(
    AppStrings strings,
    LocationLookupResult result,
  ) {
    switch (result.failure) {
      case LocationLookupFailure.serviceDisabled:
        return strings.locationServiceDisabled;
      case LocationLookupFailure.permissionDenied:
        return strings.locationPermissionDenied;
      case LocationLookupFailure.permissionDeniedForever:
        return strings.locationPermissionDeniedForever;
      case LocationLookupFailure.positionUnavailable:
      case null:
        return strings.locationLookupFailed(result.error);
    }
  }

  Future<void> _confirmDeleteLibraryTag(String tag) async {
    final strings = context.strings;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(strings.deleteTagConfirmTitle),
            content: Text(strings.deleteTagConfirmMessage(tag)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(strings.cancelAction),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(strings.confirmDeleteTag),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !mounted) return;

    setState(() => _isManagingTags = true);
    try {
      await ref.read(tagLibraryControllerProvider.notifier).deleteTag(tag);
      if (!mounted) return;
      setState(() {
        _isManagingTags = false;
        _tags.removeWhere((item) => item.toLowerCase() == tag.toLowerCase());
      });
      context.showAppSnackBar(
        strings.tagDeleted,
        tone: AppSnackBarTone.success,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isManagingTags = false);
      context.showAppSnackBar(
        strings.deleteTagFailed(error),
        tone: AppSnackBarTone.error,
      );
    }
  }

  bool _hasTag(String tag) {
    return _tags.any((item) => item.toLowerCase() == tag.toLowerCase());
  }

  void _applyAllAiSuggestions() {
    final appliedTitle = _applySuggestedTitle();
    final appliedMood = _applySuggestedMood();
    final appliedTags = _applySuggestedTags();

    if (!appliedTitle && !appliedMood && !appliedTags) return;

    context.showAppSnackBar(
      context.strings.aiSuggestionsApplied,
      tone: AppSnackBarTone.success,
    );
  }

  void _applyAiTitle() {
    if (!_applySuggestedTitle()) return;
    context.showAppSnackBar(
      context.strings.aiTitleApplied,
      tone: AppSnackBarTone.success,
    );
  }

  void _applyAiMood() {
    if (!_applySuggestedMood()) return;
    context.showAppSnackBar(
      context.strings.aiMoodApplied,
      tone: AppSnackBarTone.success,
    );
  }

  void _applyAiTags() {
    if (!_applySuggestedTags()) return;
    context.showAppSnackBar(
      context.strings.aiTagsApplied,
      tone: AppSnackBarTone.success,
    );
  }

  void _toggleTag(String tag) {
    if (_hasTag(tag)) {
      _tags.removeWhere((item) => item.toLowerCase() == tag.toLowerCase());
    } else {
      _tags.add(tag);
    }
  }

  String? _normalizeTag(String rawTag) {
    final trimmed = rawTag.trim();
    if (trimmed.isEmpty) return null;
    return trimmed.startsWith('#') ? trimmed : '#$trimmed';
  }

  DiaryEntry _buildDraftEntry() {
    final entry = widget.entry;
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final location = _locationController.text.trim();

    return DiaryEntry(
      id: entry?.id ?? _uuid.v4(),
      title: title,
      content: content,
      mood: _resolveMoodFromLibrary(
        ref.read(moodLibraryControllerProvider).valueOrNull ?? DiaryMood.values,
      ),
      createdAt: entry?.createdAt ?? DateTime.now(),
      location: location.isEmpty ? null : location,
      trashedAt: entry?.trashedAt,
      tags: List<String>.unmodifiable(_tags),
      media: List<DiaryMedia>.unmodifiable(_media),
    );
  }

  DiaryMood _resolveMoodFromLibrary(List<DiaryMood> moods) {
    for (final mood in moods) {
      if (mood.id == _moodId) return mood;
    }
    return DiaryMood.byId(_moodId) ?? DiaryMood.calm;
  }

  bool _applySuggestedTitle() {
    final suggestion = _aiSuggestion;
    final nextTitle = suggestion?.title.trim() ?? '';
    if (nextTitle.isEmpty) return false;

    _titleController.text = nextTitle;
    _titleController.selection =
        TextSelection.collapsed(offset: _titleController.text.length);
    return true;
  }

  bool _applySuggestedMood() {
    final suggestion = _aiSuggestion;
    if (suggestion == null) return false;

    final moods =
        ref.read(moodLibraryControllerProvider).valueOrNull ?? DiaryMood.values;
    final mood = _resolveAiMood(moods, suggestion.moodId);
    if (mood == null) return false;

    setState(() => _moodId = mood.id);
    return true;
  }

  bool _applySuggestedTags() {
    final suggestion = _aiSuggestion;
    if (suggestion == null || suggestion.tags.isEmpty) return false;

    var applied = false;
    setState(() {
      for (final rawTag in suggestion.tags) {
        final normalized = _normalizeTag(rawTag);
        if (normalized == null || _hasTag(normalized)) continue;
        _tags.add(normalized);
        applied = true;
      }
    });
    return applied;
  }

  DiaryMood? _resolveAiMood(List<DiaryMood> moods, String rawMoodId) {
    for (final mood in moods) {
      if (mood.id == rawMoodId) return mood;
    }
    return DiaryMood.byId(rawMoodId) ?? DiaryMood.byId(DiaryMood.neutralId);
  }

  bool _isCompanionEmpty(DiaryAiSuggestion suggestion) {
    return suggestion.emotionCategory.trim().isEmpty &&
        suggestion.comfortReply.trim().isEmpty &&
        suggestion.companionStyle.trim().isEmpty &&
        suggestion.priorityFeedback.trim().isEmpty;
  }
}
