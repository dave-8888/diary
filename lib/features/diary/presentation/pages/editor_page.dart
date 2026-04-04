import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:diary_mvp/app/cupertino_kit.dart';
import 'package:diary_mvp/app/context_tooltip.dart';
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
import 'package:diary_mvp/features/diary/services/diary_ai_service.dart';
import 'package:diary_mvp/features/diary/services/diary_ai_settings.dart';
import 'package:diary_mvp/features/diary/services/export_service.dart';
import 'package:diary_mvp/features/diary/services/location_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _EditorPageState extends ConsumerState<EditorPage>
    with WidgetsBindingObserver {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _locationController = TextEditingController();
  final _tagController = TextEditingController();
  final _titleFocusNode = FocusNode();
  final _contentFocusNode = FocusNode();
  final _locationFocusNode = FocusNode();
  final _tagFocusNode = FocusNode();
  final _titleUndoController = UndoHistoryController();
  final _contentUndoController = UndoHistoryController();
  final _locationUndoController = UndoHistoryController();
  final _tagUndoController = UndoHistoryController();
  final _uuid = const Uuid();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final Map<TextEditingController, List<TextEditingValue>> _textHistory =
      <TextEditingController, List<TextEditingValue>>{};
  final Map<TextEditingController, int> _textHistoryIndex =
      <TextEditingController, int>{};

  String _moodId = DiaryMood.defaultSelectionId;
  final List<DiaryMedia> _media = [];
  final List<String> _tags = [];
  DiaryEntry? _activeEntry;

  bool _isSaving = false;
  bool _isDeleting = false;
  bool _isExporting = false;
  bool _isRecording = false;
  bool _isAnalyzingAi = false;
  bool _isLocating = false;
  bool _isAiExpanded = false;
  bool _allowNextPop = false;
  bool _isApplyingTextUndo = false;
  DateTime? _recordingStartedAt;
  DiaryEntryAiAnalysis? _aiSuggestion;
  late DateTime _draftCreatedAt;
  late String _lastSavedSignature;

  bool get _isEditing => _activeEntry != null;
  bool get _hasUnsavedChanges =>
      _currentDraftSignature() != _lastSavedSignature;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _activeEntry = widget.entry;
    final entry = _activeEntry;
    _draftCreatedAt = entry?.createdAt ?? DateTime.now();
    if (entry != null) {
      _titleController.text = entry.title;
      _contentController.text = entry.content;
      _locationController.text = entry.location ?? '';
      _moodId = entry.mood.id;
      _media.addAll(entry.media);
      _tags.addAll(entry.tags);
      _aiSuggestion = entry.aiAnalysis;
      _isAiExpanded = entry.aiAnalysis != null;
    }
    _initializeTextHistory();
    _lastSavedSignature = _currentDraftSignature();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _titleController.dispose();
    _contentController.dispose();
    _locationController.dispose();
    _tagController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    _locationFocusNode.dispose();
    _tagFocusNode.dispose();
    _titleUndoController.dispose();
    _contentUndoController.dispose();
    _locationUndoController.dispose();
    _tagUndoController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final moodLibraryAsync = ref.watch(moodLibraryControllerProvider);
    final showDiaryAiSection =
        ref.watch(diaryAiVisibilityControllerProvider).valueOrNull ?? true;
    final visualMedia = _media
        .where((item) =>
            item.type == MediaType.image || item.type == MediaType.video)
        .toList();
    final audioMedia =
        _media.where((item) => item.type == MediaType.audio).toList();
    final otherMedia = _media
        .where((item) =>
            item.type != MediaType.audio &&
            item.type != MediaType.image &&
            item.type != MediaType.video)
        .toList();

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyS, control: true):
            _handleSaveShortcut,
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true):
            _handleSaveShortcut,
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true):
            _handleUndoShortcut,
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true):
            _handleUndoShortcut,
      },
      child: PopScope<Object?>(
        canPop: _allowNextPop ||
            !_hasUnsavedChanges ||
            _isSaving ||
            _isDeleting ||
            _isExporting,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop || _allowNextPop) {
            return;
          }

          final shouldLeave = await _confirmLeaveEditor();
          if (!shouldLeave || !context.mounted) {
            return;
          }

          setState(() => _allowNextPop = true);
          Navigator.of(context).pop(result);
        },
        child: Focus(
          autofocus: true,
          child: DiaryShell(
            title: _isEditing ? strings.editEntry : strings.newEntry,
            showAppBarTitle: false,
            floatingActionButton: CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              onPressed:
                  _isSaving || _isDeleting || _isExporting ? null : _save,
              child: Builder(
                builder: (context) {
                  final theme = Theme.of(context);
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(
                        alpha: _isSaving || _isDeleting || _isExporting ? 0.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.24),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _isSaving
                              ? _buttonProgressIndicator(
                                  color: theme.colorScheme.onPrimary,
                                )
                              : Icon(
                                  CupertinoIcons.check_mark,
                                  size: 18,
                                  color: theme.colorScheme.onPrimary,
                                ),
                          const SizedBox(width: 8),
                          Text(
                            _isSaving
                                ? strings.saving
                                : (_isEditing
                                      ? strings.updateEntry
                                      : strings.saveEntry),
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            compactBodyPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            expandedBodyPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            onNavigateRequest: _handleNavigationRequest,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final horizontalInset =
                    _editorHorizontalInset(constraints.maxWidth);
                final contentWidth =
                    max(0.0, constraints.maxWidth - (horizontalInset * 2));
                final showSidebar = contentWidth >= 1100;
                final sidebarWidth = _editorSidebarWidth(contentWidth);
                final sidebarGap = _editorSidebarGap(contentWidth);
                final mainSections = _buildMainSections(
                  context: context,
                  strings: strings,
                  visualMedia: visualMedia,
                  audioMedia: audioMedia,
                  otherMedia: otherMedia,
                  moodLibraryAsync: moodLibraryAsync,
                  prioritizeMedia: !showSidebar,
                );
                final aiSection = showDiaryAiSection
                    ? _buildAiSection(
                        context,
                        strings,
                      )
                    : null;

                if (!showSidebar) {
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalInset),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...mainSections,
                          if (aiSection != null) ...[
                            const SizedBox(height: 20),
                            aiSection,
                          ],
                          const SizedBox(height: 20),
                          _buildTagSection(context, strings),
                        ],
                      ),
                    ),
                  );
                }

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalInset),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: mainSections,
                          ),
                        ),
                      ),
                      SizedBox(width: sidebarGap),
                      SizedBox(
                        width: sidebarWidth,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (aiSection != null) ...[
                                aiSection,
                                const SizedBox(height: 16),
                              ],
                              _buildTagSection(context, strings),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMainSections({
    required BuildContext context,
    required AppStrings strings,
    required List<DiaryMedia> visualMedia,
    required List<DiaryMedia> audioMedia,
    required List<DiaryMedia> otherMedia,
    required AsyncValue<List<DiaryMood>> moodLibraryAsync,
    required bool prioritizeMedia,
  }) {
    final headerSection = _buildEditorHeader(context, strings);
    final mediaSection = _buildSectionCard(
      context: context,
      title: null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              CupertinoActionButton(
                onPressed: _pickImages,
                variant: CupertinoActionButtonVariant.tinted,
                icon: Icons.image_outlined,
                label: strings.importImage,
              ),
              CupertinoActionButton(
                onPressed: _takePhoto,
                variant: CupertinoActionButtonVariant.tinted,
                icon: Icons.camera_alt_outlined,
                label: strings.takePhoto,
              ),
              CupertinoActionButton(
                onPressed: _recordVideo,
                variant: CupertinoActionButtonVariant.tinted,
                icon: Icons.videocam_outlined,
                label: strings.recordVideo,
              ),
              CupertinoActionButton(
                onPressed: _isRecording ? _stopRecording : _startRecording,
                variant: CupertinoActionButtonVariant.tinted,
                icon: _isRecording ? Icons.stop_circle_outlined : Icons.mic_none,
                label:
                    _isRecording ? strings.stopRecording : strings.startRecording,
              ),
            ],
          ),
          if (visualMedia.isNotEmpty) ...[
            const SizedBox(height: 14),
            ImageMediaGrid(
              media: visualMedia,
              minColumns: 2,
              maxColumns: 4,
              targetTileWidth: 170,
              childAspectRatio: 1,
              constrainToTargetWidth: true,
              onPreviewRequested: _openVisualMediaPreview,
              onDeleted: (media) => setState(() => _media.remove(media)),
            ),
          ],
          if (audioMedia.isNotEmpty || otherMedia.isNotEmpty) ...[
            const SizedBox(height: 14),
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
                          (media) => _buildRemovablePill(
                            context,
                            icon: _iconForMedia(media.type),
                            label: _mediaLabel(media),
                            onDeleted: () => setState(() => _media.remove(media)),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
    final writingSection = _buildSectionCard(
      context: context,
      title: strings.titleLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CupertinoTextField(
            controller: _titleController,
            focusNode: _titleFocusNode,
            undoController: _titleUndoController,
            placeholder: strings.titleHint,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
          const SizedBox(height: 14),
          CupertinoTextField(
            controller: _contentController,
            focusNode: _contentFocusNode,
            undoController: _contentUndoController,
            maxLines: 12,
            placeholder: strings.contentHint,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ],
      ),
    );
    final detailsSection = _buildSectionCard(
      context: context,
      title: strings.locationLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CupertinoTextField(
            controller: _locationController,
            focusNode: _locationFocusNode,
            undoController: _locationUndoController,
            placeholder: strings.locationHint,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            suffix: _isLocating
                ? const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: CupertinoActivityIndicator(),
                  )
                : CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    onPressed:
                        _isSaving || _isDeleting ? null : _fillCurrentLocation,
                    child: const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(Icons.my_location_outlined, size: 18),
                    ),
                  ),
          ),
          const SizedBox(height: 18),
          Text(
            strings.mood,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          moodLibraryAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: CupertinoActivityIndicator(),
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
        ],
      ),
    );
    final orderedSections = prioritizeMedia
        ? <Widget>[mediaSection, headerSection, writingSection, detailsSection]
        : <Widget>[headerSection, mediaSection, writingSection, detailsSection];

    return [
      for (var index = 0; index < orderedSections.length; index++) ...[
        if (index > 0)
          SizedBox(height: prioritizeMedia && index == 1 ? 10 : 14),
        orderedSections[index],
      ],
    ];
  }

  @override
  Future<ui.AppExitResponse> didRequestAppExit() async {
    final shouldExit = await _confirmLeaveEditor();
    return shouldExit ? ui.AppExitResponse.exit : ui.AppExitResponse.cancel;
  }

  Future<bool> _handleNavigationRequest(String location) async {
    if (location.startsWith('/editor')) {
      return true;
    }
    return _confirmLeaveEditor();
  }

  Future<bool> _confirmLeaveEditor() async {
    if (!_hasUnsavedChanges || _isSaving || _isDeleting || _isExporting) {
      return true;
    }

    final strings = context.strings;
    final shouldLeave = await showCupertinoConfirmationDialog(
      context,
      title: strings.unsavedChangesTitle,
      message: strings.unsavedChangesMessage,
      cancelLabel: strings.stayOnPage,
      confirmLabel: strings.leaveWithoutSaving,
      isDestructive: true,
    );

    return shouldLeave;
  }

  void _handleSaveShortcut() {
    if (_isSaving || _isDeleting || _isExporting) {
      return;
    }
    _save();
  }

  void _handleUndoShortcut() {
    final controller = _focusedTextController;
    if (controller == null) {
      return;
    }

    final history = _textHistory[controller];
    final index = _textHistoryIndex[controller];
    if (history == null || index == null || index <= 0) {
      return;
    }

    _isApplyingTextUndo = true;
    final nextIndex = index - 1;
    _textHistoryIndex[controller] = nextIndex;
    controller.value = history[nextIndex];
    _isApplyingTextUndo = false;
  }

  TextEditingController? get _focusedTextController {
    if (_titleFocusNode.hasFocus) {
      return _titleController;
    }
    if (_contentFocusNode.hasFocus) {
      return _contentController;
    }
    if (_locationFocusNode.hasFocus) {
      return _locationController;
    }
    if (_tagFocusNode.hasFocus) {
      return _tagController;
    }
    return null;
  }

  void _initializeTextHistory() {
    _registerTextHistory(_titleController);
    _registerTextHistory(_contentController);
    _registerTextHistory(_locationController);
    _registerTextHistory(_tagController);
  }

  void _registerTextHistory(TextEditingController controller) {
    _textHistory[controller] = <TextEditingValue>[controller.value];
    _textHistoryIndex[controller] = 0;
    controller.addListener(() => _recordTextHistory(controller));
  }

  void _recordTextHistory(TextEditingController controller) {
    if (_isApplyingTextUndo) {
      return;
    }

    final history = _textHistory[controller];
    final index = _textHistoryIndex[controller];
    if (history == null || index == null) {
      return;
    }

    final value = controller.value;
    if (history[index] == value) {
      return;
    }

    if (index < history.length - 1) {
      history.removeRange(index + 1, history.length);
    }

    history.add(value);
    _textHistoryIndex[controller] = history.length - 1;
  }

  Widget _buildEditorHeader(BuildContext context, AppStrings strings) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentMood = _resolveMoodFromLibrary(
      ref.read(moodLibraryControllerProvider).valueOrNull ?? DiaryMood.values,
    );
    final createdAtText =
        '${strings.createdAtLabel} · ${strings.formatDateTime(_draftCreatedAt)}';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withValues(
                alpha: colorScheme.brightness == Brightness.dark ? 0.2 : 0.12,
              ),
              theme.cardTheme.color ?? colorScheme.surface,
              colorScheme.secondary.withValues(
                alpha: colorScheme.brightness == Brightness.dark ? 0.14 : 0.08,
              ),
            ],
            stops: const [0, 0.58, 1],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final actionButtons = _buildHeaderActionButtons(context);
              final titleBlock = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderInfoChip(
                    context,
                    icon: _isEditing
                        ? Icons.edit_note_outlined
                        : Icons.add_box_outlined,
                    label: _isEditing ? strings.editEntry : strings.newEntry,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    strings.whatHappenedToday,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 26,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    createdAtText,
                    key: const ValueKey('editor-created-at-label'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildHeaderInfoChip(
                        context,
                        icon: Icons.favorite_outline,
                        label: strings.moodStatusLabel(currentMood),
                      ),
                      if (_hasUnsavedChanges)
                        _buildHeaderInfoChip(
                          context,
                          icon: Icons.bolt_outlined,
                          label: strings.unsavedChangesTitle,
                        ),
                      if (_media.isNotEmpty)
                        _buildHeaderInfoChip(
                          context,
                          icon: Icons.perm_media_outlined,
                          label: _media.length.toString(),
                        ),
                      if (_tags.isNotEmpty)
                        _buildHeaderInfoChip(
                          context,
                          icon: Icons.sell_outlined,
                          label: '#${_tags.length}',
                        ),
                    ],
                  ),
                ],
              );

              if (constraints.maxWidth < 760) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleBlock,
                    const SizedBox(height: 12),
                    actionButtons,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: titleBlock),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: actionButtons,
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

  Widget _buildHeaderActionButtons(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isBusy = _isSaving || _isDeleting || _isExporting;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _buildHeaderActionIconButton(
          context,
          onTap: isBusy ? null : _exportEntry,
          backgroundColor:
              colorScheme.secondaryContainer.withValues(alpha: 0.78),
          foregroundColor: colorScheme.onSecondaryContainer,
          child: _isExporting
              ? _buttonProgressIndicator(
                  color: colorScheme.onSecondaryContainer,
                )
              : const Icon(Icons.file_download_outlined),
        ),
        if (_isEditing)
          _buildHeaderActionIconButton(
            context,
            onTap: isBusy ? null : _confirmDelete,
            backgroundColor: colorScheme.surface.withValues(alpha: 0.52),
            foregroundColor: colorScheme.error,
            borderColor: colorScheme.error.withValues(alpha: 0.45),
            child: _isDeleting
                ? _buttonProgressIndicator(color: colorScheme.error)
                : const Icon(Icons.delete_outline),
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
      child: CupertinoActivityIndicator(
        color: color,
      ),
    );
  }

  Widget _buildHeaderInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.34),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderActionIconButton(
    BuildContext context, {
    required VoidCallback? onTap,
    required Widget child,
    required Color backgroundColor,
    required Color foregroundColor,
    Color? borderColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: onTap == null
              ? backgroundColor.withValues(alpha: 0.42)
              : backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: borderColor == null ? null : Border.all(color: borderColor),
        ),
        child: IconTheme(
          data: IconThemeData(color: foregroundColor, size: 22),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildAiSection(
    BuildContext context,
    AppStrings strings,
  ) {
    final suggestion = _aiSuggestion;
    final hasAiSuggestion = suggestion != null && !suggestion.isEmpty;
    final aiSuggestion = hasAiSuggestion ? suggestion : null;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final showEmotionalCompanion =
        ref.watch(emotionalCompanionVisibilityControllerProvider).valueOrNull ??
            true;
    final showProblemSuggestions =
        ref.watch(problemSuggestionVisibilityControllerProvider).valueOrNull ??
            true;
    final suggestedTags = aiSuggestion == null
        ? const <String>[]
        : _normalizedAiTags(aiSuggestion);

    return _buildCollapsibleCard(
      context: context,
      title: strings.diaryAiToolsTitle,
      helpText: strings.diaryAiToolsHint,
      summary: aiSuggestion?.analyzedAt == null
          ? null
          : strings.aiAnalyzedAtLabel(aiSuggestion!.analyzedAt!),
      titleStyle: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 19,
      ),
      expanded: _isAiExpanded,
      onExpandedChanged: (expanded) {
        setState(() => _isAiExpanded = expanded);
      },
      headerAction: CupertinoActionButton(
        onPressed: _isAnalyzingAi || _isSaving || _isDeleting || _isExporting
            ? null
            : _analyzeWithAi,
        isBusy: _isAnalyzingAi,
        variant: CupertinoActionButtonVariant.tinted,
        icon: Icons.auto_fix_high_outlined,
        label: _isAnalyzingAi
            ? strings.analyzingDiaryWithAi
            : hasAiSuggestion
                ? strings.reanalyzeDiaryWithAi
                : strings.analyzeDiaryWithAi,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (aiSuggestion != null) ...[
            _buildAiTextSection(
              context,
              title: strings.aiOverviewSectionTitle,
              value: aiSuggestion.overviewText.trim().isEmpty
                  ? strings.aiSummaryEmpty
                  : aiSuggestion.overviewText,
            ),
            if (showEmotionalCompanion &&
                !_isAiSectionTextEmpty(aiSuggestion.emotionalSupportText)) ...[
              const SizedBox(height: 12),
              _buildAiTextSection(
                context,
                title: strings.emotionalCompanionSectionTitle,
                value: aiSuggestion.emotionalSupportText!,
              ),
            ],
            if (showProblemSuggestions &&
                !_isAiSectionTextEmpty(
                    aiSuggestion.questionSuggestionText)) ...[
              const SizedBox(height: 12),
              _buildAiTextSection(
                context,
                title: strings.problemSuggestionSectionTitle,
                value: aiSuggestion.questionSuggestionText!,
              ),
            ],
            const SizedBox(height: 12),
            _buildAiTagSection(
              context,
              strings,
              colorScheme: colorScheme,
              suggestedTags: suggestedTags,
            ),
          ] else ...[
            Text(
              strings.diaryAiToolsHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTagSection(
    BuildContext context,
    AppStrings strings,
  ) {
    return _buildSectionCard(
      context: context,
      title: strings.tagsLabel,
      helpText: strings.tagSidebarHint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CupertinoTextField(
            key: const ValueKey('editor-tag-input'),
            controller: _tagController,
            focusNode: _tagFocusNode,
            undoController: _tagUndoController,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _createTagFromInput(),
            placeholder: strings.tagHint,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
          const SizedBox(height: 18),
          Text(
            strings.selectedTagsLabel,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 12),
          if (_tags.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _tags
                  .map(
                    (tag) => _buildSelectedTagChip(
                      context,
                      tag: tag,
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
        ],
      ),
    );
  }

  Widget _buildCollapsibleCard({
    required BuildContext context,
    required String title,
    String? helpText,
    String? summary,
    required bool expanded,
    required ValueChanged<bool> onExpandedChanged,
    Widget? headerAction,
    TextStyle? titleStyle,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final resolvedTitleStyle = titleStyle ??
        theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withValues(
                alpha: colorScheme.brightness == Brightness.dark ? 0.08 : 0.04,
              ),
              theme.cardTheme.color ?? colorScheme.surface,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final stackHeaderAction =
                      headerAction != null && constraints.maxWidth < 460;
                  final titleArea = GestureDetector(
                    onTap: () => onExpandedChanged(!expanded),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 2,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: resolvedTitleStyle,
                                ),
                              ),
                              if (helpText != null) ...[
                                const SizedBox(width: 4),
                                ContextTooltip(message: helpText),
                              ],
                            ],
                          ),
                          if (summary != null && summary.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              summary.trim(),
                              maxLines: expanded ? 2 : 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );

                  if (stackHeaderAction) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: titleArea),
                            IconButton(
                              onPressed: () => onExpandedChanged(!expanded),
                              icon: Icon(
                                expanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: headerAction,
                        ),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: titleArea),
                      IconButton(
                        onPressed: () => onExpandedChanged(!expanded),
                        icon: Icon(
                          expanded ? Icons.expand_less : Icons.expand_more,
                        ),
                      ),
                      if (headerAction != null) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Align(
                            alignment: Alignment.topRight,
                            child: headerAction,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
              if (expanded) ...[
                const SizedBox(height: 16),
                child,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    String? title,
    String? helpText,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withValues(
                alpha: colorScheme.brightness == Brightness.dark ? 0.08 : 0.04,
              ),
              theme.cardTheme.color ?? colorScheme.surface,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null || helpText != null) ...[
                Row(
                  children: [
                    if (title != null)
                      Flexible(
                        child: Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    if (helpText != null) ...[
                      const SizedBox(width: 4),
                      ContextTooltip(message: helpText),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAiTextPanel(
    BuildContext context, {
    required String value,
  }) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.34),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: SelectableText(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildAiTextSection(
    BuildContext context, {
    required String title,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        _buildAiTextPanel(
          context,
          value: value,
        ),
      ],
    );
  }

  Widget _buildAiTagSection(
    BuildContext context,
    AppStrings strings, {
    required ColorScheme colorScheme,
    required List<String> suggestedTags,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.aiSuggestedTagsLabel,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        if (suggestedTags.isEmpty)
          Text(
            strings.aiNoTagsSuggested,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestedTags
                .map(
                  (tag) => _buildAiSuggestedTagChip(
                    context,
                    tag: tag,
                  ),
                )
                .toList(growable: false),
          ),
      ],
    );
  }

  Widget _buildAiSuggestedTagChip(
    BuildContext context, {
    required String tag,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selected = _hasTag(tag);

    return CupertinoPill(
      selected: selected,
      onPressed: () => setState(() => _toggleTag(tag)),
      label: Text(
        tag,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          color: selected ? colorScheme.primary : null,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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

  Widget _buildSelectedTagChip(
    BuildContext context, {
    required String tag,
    required VoidCallback onDeleted,
  }) {
    return _buildRemovablePill(
      context,
      label: tag,
      onDeleted: onDeleted,
    );
  }

  Widget _buildRemovablePill(
    BuildContext context, {
    required String label,
    required VoidCallback onDeleted,
    IconData? icon,
  }) {
    final theme = Theme.of(context);

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onDeleted,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 15,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.close_rounded, size: 14),
            ],
          ),
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
          capturedAt: result.capturedAt,
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

  Future<void> _analyzeWithAi() async {
    final strings = context.strings;
    final includeEmotionalCompanion =
        ref.read(emotionalCompanionVisibilityControllerProvider).valueOrNull ??
            true;
    final includeProblemSuggestions =
        ref.read(problemSuggestionVisibilityControllerProvider).valueOrNull ??
            true;

    setState(() => _isAnalyzingAi = true);
    final result = await ref.read(diaryAiServiceProvider).analyzeEntry(
          draft: _buildDraftEntry(),
          preferChinese: strings.isChinese,
          includeEmotionalCompanion: includeEmotionalCompanion,
          includeProblemSuggestions: includeProblemSuggestions,
        );

    if (!mounted) return;
    setState(() {
      _isAnalyzingAi = false;
      if (result.ok) {
        _aiSuggestion = result.suggestion?.copyWith(
          analyzedAt: DateTime.now(),
        );
        _isAiExpanded = true;
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

  Future<void> _createTagFromInput() async {
    final normalized = _normalizeTag(_tagController.text);
    _tagController.clear();
    if (normalized == null) return;

    setState(() {
      if (!_hasTag(normalized)) {
        _tags.add(normalized);
      }
    });
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
    final wasEditing = _isEditing;
    setState(() => _isSaving = true);
    final controller = ref.read(diaryControllerProvider.notifier);
    final media = List<DiaryMedia>.from(_media);
    final tags = List<String>.from(_tags);
    final mood = _resolveMoodFromLibrary(
      ref.read(moodLibraryControllerProvider).valueOrNull ?? DiaryMood.values,
    );

    try {
      final savedEntry = wasEditing
          ? await controller.updateEntry(
              entry: _activeEntry!,
              title: _titleController.text,
              content: _contentController.text,
              mood: mood,
              location: _locationController.text,
              tags: tags,
              media: media,
              aiAnalysis: _aiSuggestion,
            )
          : await controller.addEntry(
              title: _titleController.text,
              content: _contentController.text,
              mood: mood,
              location: _locationController.text,
              tags: tags,
              media: media,
              aiAnalysis: _aiSuggestion,
            );

      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _activeEntry = savedEntry;
        _draftCreatedAt = savedEntry.createdAt;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      context.showAppSnackBar(
        strings.entrySaveFailed(error),
        tone: AppSnackBarTone.error,
      );
      return;
    }

    _lastSavedSignature = _currentDraftSignature();
    context.showAppSnackBar(
      wasEditing ? strings.entryUpdated : strings.entrySaved,
      tone: AppSnackBarTone.success,
    );
  }

  Future<void> _confirmDelete() async {
    final entry = _activeEntry;
    if (entry == null) return;

    final strings = context.strings;
    final confirmed = await showCupertinoConfirmationDialog(
      context,
      title: strings.deleteEntryConfirmTitle,
      message: strings.deleteEntryConfirmMessage(entry.title),
      cancelLabel: strings.cancelAction,
      confirmLabel: strings.confirmDelete,
      isDestructive: true,
    );

    if (!confirmed || !mounted) return;
    await _deleteEntry();
  }

  Future<void> _deleteEntry() async {
    final entry = _activeEntry;
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
      aiAnalysis: draftEntry.aiAnalysis,
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

  void _openVisualMediaPreview(DiaryMedia media) {
    if (media.type == MediaType.video) {
      _openVideoPreview(media);
      return;
    }
    _openImagePreview(media);
  }

  void _openImagePreview(DiaryMedia media) {
    context.push('/image-preview', extra: media);
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

  String _currentDraftSignature() {
    return jsonEncode({
      'title': _titleController.text.trim(),
      'content': _contentController.text.trim(),
      'location': _locationController.text.trim(),
      'mood_id': _moodId,
      'tags': List<String>.from(_tags),
      'media': _media
          .map(
            (item) => {
              'id': item.id,
              'type': item.type.name,
              'path': item.path,
              'duration_label': item.durationLabel,
              'captured_at': item.capturedAt?.millisecondsSinceEpoch,
            },
          )
          .toList(growable: false),
      'ai_analysis': _aiSuggestion == null
          ? null
          : {
              'overview_text': _aiSuggestion!.overviewText,
              'suggested_tags': _aiSuggestion!.suggestedTags,
              'emotional_support_text': _aiSuggestion!.emotionalSupportText,
              'question_suggestion_text': _aiSuggestion!.questionSuggestionText,
              'analyzed_at': _aiSuggestion!.analyzedAt?.millisecondsSinceEpoch,
            },
    });
  }

  String _diaryAiFailureMessage(
    AppStrings strings,
    DiaryAiResult result,
  ) {
    switch (result.failure) {
      case DiaryAiFailure.apiKeyMissing:
        return strings.diaryAiApiKeyMissing;
      case DiaryAiFailure.configurationInvalid:
        return strings.diaryAiConfigInvalid;
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

  bool _hasTag(String tag) {
    return _tags.any((item) => item.toLowerCase() == tag.toLowerCase());
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

  List<String> _normalizedAiTags(DiaryEntryAiAnalysis suggestion) {
    final normalized = <String>[];
    final seen = <String>{};

    for (final rawTag in suggestion.suggestedTags) {
      final tag = _normalizeTag(rawTag);
      if (tag == null) continue;
      final key = tag.toLowerCase();
      if (seen.add(key)) {
        normalized.add(tag);
      }
    }

    return List.unmodifiable(normalized);
  }

  bool _isAiSectionTextEmpty(String? value) {
    return value == null || value.trim().isEmpty;
  }

  DiaryEntry _buildDraftEntry() {
    final entry = _activeEntry;
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
      createdAt: _draftCreatedAt,
      location: location.isEmpty ? null : location,
      trashedAt: entry?.trashedAt,
      tags: List<String>.unmodifiable(_tags),
      media: List<DiaryMedia>.unmodifiable(_media),
      aiAnalysis: _aiSuggestion,
    );
  }

  DiaryMood _resolveMoodFromLibrary(List<DiaryMood> moods) {
    for (final mood in moods) {
      if (mood.id == _moodId) return mood;
    }
    return DiaryMood.byId(_moodId) ?? DiaryMood.calm;
  }

  double _editorHorizontalInset(double width) {
    if (width >= 1500) return 14;
    if (width >= 1280) return 8;
    if (width >= 1100) return 4;
    return 0;
  }

  double _editorSidebarWidth(double width) {
    return (width * 0.25).clamp(280.0, 320.0).toDouble();
  }

  double _editorSidebarGap(double width) {
    if (width >= 1450) return 24;
    if (width >= 1280) return 20;
    return 16;
  }
}
