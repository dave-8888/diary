import 'package:diary_mvp/app/app_display_name.dart';
import 'package:diary_mvp/app/app_icon.dart';
import 'package:diary_mvp/app/context_tooltip.dart';
import 'package:diary_mvp/app/localization/app_locale.dart';
import 'package:diary_mvp/app/localization/app_strings.dart';
import 'package:diary_mvp/app/themed_snackbar.dart';
import 'package:diary_mvp/app/theme.dart';
import 'package:diary_mvp/app/window_identity.dart';
import 'package:diary_mvp/app/windows_build_identity_service.dart';
import 'package:diary_mvp/features/diary/application/diary_controller.dart';
import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/diary_shell.dart';
import 'package:diary_mvp/features/diary/services/diary_ai_settings.dart';
import 'package:diary_mvp/features/diary/services/transcription_settings.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late final TextEditingController _appNameController;
  late final TextEditingController _diaryAiApiKeyController;
  late final TextEditingController _apiKeyController;
  bool _appNameInitialized = false;
  bool _diaryAiApiKeyInitialized = false;
  bool _apiKeyInitialized = false;
  bool _isSavingAppName = false;
  bool _isSavingDiaryAiApiKey = false;
  bool _isSavingApiKey = false;
  bool _isResettingAppName = false;
  bool _isResettingDiaryAiApiKey = false;
  bool _isResettingApiKey = false;
  bool _isChangingIcon = false;
  bool _isSyncingBuildWindowIcon = false;
  bool _isResettingBuildWindowIcon = false;
  bool _isChangingTheme = false;
  bool _isChangingLanguage = false;
  bool _isResettingMoods = false;
  bool _isChangingDiaryAiVisibility = false;
  bool _isChangingEmotionalCompanionVisibility = false;
  bool _isChangingProblemSuggestionVisibility = false;
  bool _isAppIdentitySectionExpanded = false;
  bool _isDiaryAiSectionExpanded = false;
  bool _isMoodLibrarySectionExpanded = false;
  bool _isTranscriptionSectionExpanded = false;
  bool _isMigrationSectionExpanded = false;
  bool _showDiaryAiApiKey = false;
  bool _showApiKey = false;

  @override
  void initState() {
    super.initState();
    _appNameController = TextEditingController();
    _diaryAiApiKeyController = TextEditingController();
    _apiKeyController = TextEditingController();
  }

  @override
  void dispose() {
    _appNameController.dispose();
    _diaryAiApiKeyController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final customAppNameAsync = ref.watch(appDisplayNameControllerProvider);
    final currentAppName = resolveAppDisplayName(
      strings: strings,
      customNameAsync: customAppNameAsync,
    );
    final diaryAiApiKeyAsync = ref.watch(diaryAiApiKeyControllerProvider);
    final diaryAiVisibilityAsync =
        ref.watch(diaryAiVisibilityControllerProvider);
    final diaryAiVisible = diaryAiVisibilityAsync.valueOrNull ?? true;
    final emotionalCompanionVisibilityAsync = ref.watch(
      emotionalCompanionVisibilityControllerProvider,
    );
    final emotionalCompanionVisible =
        emotionalCompanionVisibilityAsync.valueOrNull ?? true;
    final problemSuggestionVisibilityAsync = ref.watch(
      problemSuggestionVisibilityControllerProvider,
    );
    final problemSuggestionVisible =
        problemSuggestionVisibilityAsync.valueOrNull ?? true;
    final apiKeyAsync = ref.watch(transcriptionApiKeyControllerProvider);
    final iconSelection =
        resolveAppIconSelection(ref.watch(appIconControllerProvider));
    final iconPreset = iconSelection.preset;
    final canSyncBuildWindowIcon =
        ref.read(windowsBuildIdentityServiceProvider).canSyncBuildIcon;
    final selectedTheme = resolveThemePreset(
      ref.watch(appThemeControllerProvider),
    );
    final selectedLanguage = resolveAppLanguage(
      ref.watch(appLanguageProvider),
    );
    final moodLibraryAsync = ref.watch(moodLibraryControllerProvider);
    final supportsWindowIdentity = supportsNativeWindowIdentityCustomization;

    if (!_appNameInitialized && customAppNameAsync.hasValue) {
      _appNameController.text =
          customAppNameAsync.valueOrNull ?? currentAppName;
      _appNameController.selection = TextSelection.collapsed(
        offset: _appNameController.text.length,
      );
      _appNameInitialized = true;
    }
    if (!_diaryAiApiKeyInitialized && diaryAiApiKeyAsync.hasValue) {
      _diaryAiApiKeyController.text = diaryAiApiKeyAsync.valueOrNull ?? '';
      _diaryAiApiKeyController.selection = TextSelection.collapsed(
        offset: _diaryAiApiKeyController.text.length,
      );
      _diaryAiApiKeyInitialized = true;
    }
    if (!_apiKeyInitialized && apiKeyAsync.hasValue) {
      _apiKeyController.text = apiKeyAsync.valueOrNull ?? '';
      _apiKeyController.selection = TextSelection.collapsed(
        offset: _apiKeyController.text.length,
      );
      _apiKeyInitialized = true;
    }

    return DiaryShell(
      title: strings.settingsTitle,
      showAppBarTitle: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: ListView(
            children: [
              _buildSectionCard(
                context: context,
                icon: Icons.palette_outlined,
                title: strings.theme,
                subtitle: strings.themeSettingsHint,
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: DiaryThemePreset.values
                      .map(
                        (themePreset) => ChoiceChip(
                          selected: themePreset == selectedTheme,
                          onSelected: _isChangingTheme
                              ? null
                              : (_) => _changeTheme(themePreset),
                          avatar: Icon(
                            _themeIcon(themePreset),
                            size: 18,
                          ),
                          label: Text(strings.titleForTheme(themePreset)),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
              const SizedBox(height: 18),
              _buildSectionCard(
                context: context,
                icon: Icons.language_outlined,
                title: strings.language,
                subtitle: strings.languageSettingsHint,
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: AppLanguage.values
                      .map(
                        (language) => ChoiceChip(
                          selected: language == selectedLanguage,
                          onSelected: _isChangingLanguage
                              ? null
                              : (_) => _changeLanguage(language),
                          label: Text(strings.titleForLanguage(language)),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
              const SizedBox(height: 18),
              _buildExpandableSectionCard(
                context: context,
                icon: Icons.badge_outlined,
                title: strings.appIdentityTitle,
                subtitle: strings.appIdentityHint,
                summary: currentAppName,
                expanded: _isAppIdentitySectionExpanded,
                onExpandedChanged: (expanded) {
                  setState(() => _isAppIdentitySectionExpanded = expanded);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          strings.appNameLabel,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(width: 4),
                        ContextTooltip(message: strings.appNameDesktopHint),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _appNameController,
                      decoration: InputDecoration(
                        hintText: strings.appNameHint,
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _saveAppName(),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        OutlinedButton(
                          onPressed: _isSavingAppName || _isResettingAppName
                              ? null
                              : _resetAppName,
                          child: _isResettingAppName
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(strings.resetAppName),
                        ),
                        FilledButton(
                          onPressed: _isSavingAppName || _isResettingAppName
                              ? null
                              : _saveAppName,
                          child: _isSavingAppName
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(strings.saveAction),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Text(
                          strings.appIconTitle,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(width: 4),
                        ContextTooltip(message: strings.appIconHint),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: AppIconPreset.values
                          .map(
                            (preset) => _IconOptionCard(
                              preset: preset,
                              label: strings.titleForAppIcon(preset),
                              selected: iconSelection.isPreset &&
                                  preset == iconPreset,
                              onTap: _isChangingIcon
                                  ? null
                                  : () => _selectIcon(preset),
                            ),
                          )
                          .toList(growable: false),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: !supportsWindowIdentity || _isChangingIcon
                              ? null
                              : _pickCustomIcon,
                          icon: _isChangingIcon
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.image_search_outlined),
                          label: Text(strings.pickWindowIcon),
                        ),
                        OutlinedButton.icon(
                          onPressed: _isChangingIcon ? null : _resetIcon,
                          icon: _isChangingIcon
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.restart_alt_outlined),
                          label: Text(strings.resetAppIcon),
                        ),
                      ],
                    ),
                    if (canSyncBuildWindowIcon) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            strings.windowIconTitle,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(width: 4),
                          ContextTooltip(message: strings.buildWindowIconHint),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton.icon(
                            onPressed:
                                iconSelection.windowIconPath.trim().isEmpty ||
                                        _isSyncingBuildWindowIcon ||
                                        _isResettingBuildWindowIcon
                                    ? null
                                    : () => _syncBuildWindowIcon(iconSelection),
                            icon: _isSyncingBuildWindowIcon
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.install_desktop_outlined),
                            label: Text(strings.syncBuildWindowIcon),
                          ),
                          OutlinedButton.icon(
                            onPressed: _isSyncingBuildWindowIcon ||
                                    _isResettingBuildWindowIcon
                                ? null
                                : _resetBuildWindowIcon,
                            icon: _isResettingBuildWindowIcon
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.restart_alt_outlined),
                            label: Text(strings.resetBuildWindowIcon),
                          ),
                        ],
                      ),
                    ],
                    if (!supportsWindowIdentity) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            strings.windowIconTitle,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(width: 4),
                          ContextTooltip(
                            message: strings.windowIconPlatformHint,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _buildExpandableSectionCard(
                context: context,
                icon: Icons.auto_awesome_outlined,
                title: strings.diaryAiSettingsTitle,
                subtitle: strings.diaryAiSettingsHint,
                summary:
                    '${strings.diaryAiVisibilityLabel}: ${diaryAiVisible ? strings.enabledLabel : strings.disabledLabel}',
                expanded: _isDiaryAiSectionExpanded,
                onExpandedChanged: (expanded) {
                  setState(() => _isDiaryAiSectionExpanded = expanded);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildToggleSettingTile(
                      context: context,
                      title: strings.diaryAiVisibilityLabel,
                      helpText: strings.diaryAiVisibilityHint,
                      value: diaryAiVisible,
                      enabled: !_isChangingDiaryAiVisibility,
                      onChanged: _changeDiaryAiVisibility,
                    ),
                    const SizedBox(height: 16),
                    _buildToggleSettingTile(
                      context: context,
                      title: strings.emotionalCompanionLabel,
                      helpText: strings.emotionalCompanionHint,
                      value: emotionalCompanionVisible,
                      enabled: !_isChangingEmotionalCompanionVisibility,
                      onChanged: _changeEmotionalCompanionVisibility,
                    ),
                    const SizedBox(height: 16),
                    _buildToggleSettingTile(
                      context: context,
                      title: strings.problemSuggestionLabel,
                      helpText: strings.problemSuggestionHint,
                      value: problemSuggestionVisible,
                      enabled: !_isChangingProblemSuggestionVisibility,
                      onChanged: _changeProblemSuggestionVisibility,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _diaryAiApiKeyController,
                      obscureText: !_showDiaryAiApiKey,
                      decoration: InputDecoration(
                        labelText: strings.aliyunApiKeyLabel,
                        hintText: strings.aliyunApiKeyHint,
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(
                              () => _showDiaryAiApiKey = !_showDiaryAiApiKey,
                            );
                          },
                          icon: Icon(
                            _showDiaryAiApiKey
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _saveDiaryAiApiKey(),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      diaryAiEnvironmentApiKey.isNotEmpty
                          ? strings.usingDiaryAiEnvironmentApiKey
                          : strings.diaryAiApiKeyEnvironmentHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        OutlinedButton(
                          onPressed: _isSavingDiaryAiApiKey ||
                                  _isResettingDiaryAiApiKey
                              ? null
                              : _resetDiaryAiApiKey,
                          child: _isResettingDiaryAiApiKey
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(strings.resetApiKey),
                        ),
                        FilledButton(
                          onPressed: _isSavingDiaryAiApiKey ||
                                  _isResettingDiaryAiApiKey
                              ? null
                              : _saveDiaryAiApiKey,
                          child: _isSavingDiaryAiApiKey
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(strings.saveAction),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _buildExpandableSectionCard(
                context: context,
                icon: Icons.key_outlined,
                title: strings.transcriptionSettingsTitle,
                subtitle: strings.transcriptionSettingsHint,
                summary: transcriptionEnvironmentApiKey.isNotEmpty
                    ? strings.usingEnvironmentApiKey
                    : strings.apiKeyEnvironmentHint,
                expanded: _isTranscriptionSectionExpanded,
                onExpandedChanged: (expanded) {
                  setState(() => _isTranscriptionSectionExpanded = expanded);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _apiKeyController,
                      obscureText: !_showApiKey,
                      decoration: InputDecoration(
                        labelText: strings.openAiApiKeyLabel,
                        hintText: strings.openAiApiKeyHint,
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() => _showApiKey = !_showApiKey);
                          },
                          icon: Icon(
                            _showApiKey
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _saveApiKey(),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      transcriptionEnvironmentApiKey.isNotEmpty
                          ? strings.usingEnvironmentApiKey
                          : strings.apiKeyEnvironmentHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        OutlinedButton(
                          onPressed: _isSavingApiKey || _isResettingApiKey
                              ? null
                              : _resetApiKey,
                          child: _isResettingApiKey
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(strings.resetApiKey),
                        ),
                        FilledButton(
                          onPressed: _isSavingApiKey || _isResettingApiKey
                              ? null
                              : _saveApiKey,
                          child: _isSavingApiKey
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(strings.saveAction),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _buildExpandableSectionCard(
                context: context,
                icon: Icons.emoji_emotions_outlined,
                title: strings.moodLibraryTitle,
                subtitle: strings.moodLibraryHint,
                summary: '',
                expanded: _isMoodLibrarySectionExpanded,
                onExpandedChanged: (expanded) {
                  setState(() => _isMoodLibrarySectionExpanded = expanded);
                },
                child: moodLibraryAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) =>
                      Text(strings.failedToLoadMoods(error)),
                  data: (moods) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: () => _openMoodDialog(),
                            icon: const Icon(Icons.add_rounded),
                            label: Text(strings.addMood),
                          ),
                          OutlinedButton.icon(
                            onPressed:
                                _isResettingMoods ? null : _confirmResetMoods,
                            icon: _isResettingMoods
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.restart_alt_outlined),
                            label: Text(strings.restoreDefaultMoods),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      if (moods.isEmpty)
                        Text(strings.moodLibraryEmpty)
                      else
                        Wrap(
                          key: const ValueKey('mood-library-wrap'),
                          spacing: 12,
                          runSpacing: 12,
                          children: moods
                              .map(
                                (mood) => ConstrainedBox(
                                  key: ValueKey('mood-library-item-${mood.id}'),
                                  constraints: const BoxConstraints(
                                    minWidth: 160,
                                    maxWidth: 280,
                                  ),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outlineVariant
                                            .withValues(alpha: 0.7),
                                      ),
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerLowest,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            mood.emoji,
                                            style: const TextStyle(
                                              fontSize: 24,
                                              height: 1,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  strings.moodLabel(mood),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleSmall,
                                                ),
                                                const SizedBox(height: 8),
                                                _buildStatusChip(
                                                  context,
                                                  mood.isDefault
                                                      ? strings.defaultMoodBadge
                                                      : strings.customMoodBadge,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            onPressed: () =>
                                                _openMoodDialog(existing: mood),
                                            tooltip: strings.editMood,
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _buildExpandableSectionCard(
                context: context,
                icon: Icons.import_export_outlined,
                title: strings.migrationTitle,
                subtitle: strings.migrationHint,
                summary: strings.currentDataLocation,
                expanded: _isMigrationSectionExpanded,
                onExpandedChanged: (expanded) {
                  setState(() => _isMigrationSectionExpanded = expanded);
                },
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/migration'),
                    icon: const Icon(Icons.open_in_new_outlined),
                    label: Text(strings.openMigrationPage),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                ContextTooltip(message: subtitle),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableSectionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String summary,
    required bool expanded,
    required ValueChanged<bool> onExpandedChanged,
    required Widget child,
  }) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => onExpandedChanged(!expanded),
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
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              ContextTooltip(message: subtitle),
                            ],
                          ),
                          if (summary.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              summary,
                              maxLines: expanded ? 2 : 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => onExpandedChanged(!expanded),
                  icon: Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                  ),
                ),
              ],
            ),
            if (expanded) ...[
              const SizedBox(height: 16),
              child,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildToggleSettingTile({
    required BuildContext context,
    required String title,
    required String helpText,
    required bool value,
    required bool enabled,
    required ValueChanged<bool> onChanged,
  }) {
    final strings = context.strings;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusChip(
                    context,
                    value ? strings.enabledLabel : strings.disabledLabel,
                  ),
                  const SizedBox(width: 4),
                  ContextTooltip(message: helpText),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Switch.adaptive(
              value: value,
              onChanged: enabled ? onChanged : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String label) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Future<void> _saveAppName() async {
    final strings = context.strings;
    setState(() => _isSavingAppName = true);
    try {
      await ref
          .read(appDisplayNameControllerProvider.notifier)
          .save(_appNameController.text);
      if (!mounted) return;
      setState(() => _isSavingAppName = false);
      context.showAppSnackBar(
        strings.appNameUpdated,
        tone: AppSnackBarTone.success,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSavingAppName = false);
      context.showAppSnackBar(
        strings.appNameUpdateFailed(error),
        tone: AppSnackBarTone.error,
      );
    }
  }

  Future<void> _changeTheme(DiaryThemePreset preset) async {
    final strings = context.strings;
    setState(() => _isChangingTheme = true);
    try {
      await ref.read(appThemeControllerProvider.notifier).setTheme(preset);
      if (!mounted) return;
      setState(() => _isChangingTheme = false);
      context.showAppSnackBar(
        strings.themeUpdated,
        tone: AppSnackBarTone.success,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isChangingTheme = false);
      context.showAppSnackBar(
        strings.themeUpdateFailed(error),
        tone: AppSnackBarTone.error,
      );
    }
  }

  Future<void> _changeLanguage(AppLanguage language) async {
    final strings = context.strings;
    setState(() => _isChangingLanguage = true);
    try {
      await ref.read(appLanguageProvider.notifier).setLanguage(language);
      if (!mounted) return;
      setState(() => _isChangingLanguage = false);
      context.showAppSnackBar(
        strings.languageUpdated,
        tone: AppSnackBarTone.success,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isChangingLanguage = false);
      context.showAppSnackBar(
        strings.languageUpdateFailed(error),
        tone: AppSnackBarTone.error,
      );
    }
  }

  Future<void> _resetAppName() async {
    final strings = context.strings;
    setState(() => _isResettingAppName = true);
    try {
      await ref.read(appDisplayNameControllerProvider.notifier).reset();
      _appNameController.text = strings.appTitle;
      if (!mounted) return;
      setState(() => _isResettingAppName = false);
      context.showAppSnackBar(
        strings.appNameReset,
        tone: AppSnackBarTone.success,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isResettingAppName = false);
      context.showAppSnackBar(
        strings.appNameUpdateFailed(error),
        tone: AppSnackBarTone.error,
      );
    }
  }

  Future<void> _changeDiaryAiVisibility(bool enabled) async {
    final strings = context.strings;
    setState(() => _isChangingDiaryAiVisibility = true);
    try {
      await ref
          .read(diaryAiVisibilityControllerProvider.notifier)
          .setEnabled(enabled);
      if (!mounted) return;
      setState(() => _isChangingDiaryAiVisibility = false);
      context.showAppSnackBar(
        strings.diaryAiVisibilityUpdated,
        tone: AppSnackBarTone.success,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isChangingDiaryAiVisibility = false);
      context.showAppSnackBar(
        strings.diaryAiVisibilityUpdateFailed(error),
        tone: AppSnackBarTone.error,
      );
    }
  }

  Future<void> _changeEmotionalCompanionVisibility(bool enabled) async {
    final strings = context.strings;
    setState(() => _isChangingEmotionalCompanionVisibility = true);
    try {
      await ref
          .read(emotionalCompanionVisibilityControllerProvider.notifier)
          .setEnabled(enabled);
      if (!mounted) return;
      setState(() => _isChangingEmotionalCompanionVisibility = false);
      context.showAppSnackBar(
        strings.emotionalCompanionUpdated,
        tone: AppSnackBarTone.success,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isChangingEmotionalCompanionVisibility = false);
      context.showAppSnackBar(
        strings.emotionalCompanionUpdateFailed(error),
        tone: AppSnackBarTone.error,
      );
    }
  }

  Future<void> _changeProblemSuggestionVisibility(bool enabled) async {
    final strings = context.strings;
    setState(() => _isChangingProblemSuggestionVisibility = true);
    try {
      await ref
          .read(problemSuggestionVisibilityControllerProvider.notifier)
          .setEnabled(enabled);
      if (!mounted) return;
      setState(() => _isChangingProblemSuggestionVisibility = false);
      context.showAppSnackBar(
        strings.problemSuggestionUpdated,
        tone: AppSnackBarTone.success,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isChangingProblemSuggestionVisibility = false);
      context.showAppSnackBar(
        strings.problemSuggestionUpdateFailed(error),
        tone: AppSnackBarTone.error,
      );
    }
  }

  Future<void> _saveDiaryAiApiKey() async {
    final strings = context.strings;
    setState(() => _isSavingDiaryAiApiKey = true);
    try {
      await ref
          .read(diaryAiApiKeyControllerProvider.notifier)
          .save(_diaryAiApiKeyController.text);
      if (!mounted) return;
      setState(() => _isSavingDiaryAiApiKey = false);
      context.showAppSnackBar(
        strings.diaryAiApiKeyUpdated,
        tone: AppSnackBarTone.success,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSavingDiaryAiApiKey = false);
      context.showAppSnackBar(
        strings.diaryAiApiKeyUpdateFailed(error),
        tone: AppSnackBarTone.error,
      );
    }
  }

  Future<void> _resetDiaryAiApiKey() async {
    final strings = context.strings;
    setState(() => _isResettingDiaryAiApiKey = true);
    try {
      await ref.read(diaryAiApiKeyControllerProvider.notifier).reset();
      _diaryAiApiKeyController.clear();
      if (!mounted) return;
      setState(() => _isResettingDiaryAiApiKey = false);
      context.showAppSnackBar(
        strings.diaryAiApiKeyReset,
        tone: AppSnackBarTone.success,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isResettingDiaryAiApiKey = false);
      context.showAppSnackBar(
        strings.diaryAiApiKeyUpdateFailed(error),
        tone: AppSnackBarTone.error,
      );
    }
  }

  Future<void> _saveApiKey() async {
    final strings = context.strings;
    setState(() => _isSavingApiKey = true);
    try {
      await ref
          .read(transcriptionApiKeyControllerProvider.notifier)
          .save(_apiKeyController.text);
      if (!mounted) return;
      setState(() => _isSavingApiKey = false);
      context.showAppSnackBar(
        strings.apiKeyUpdated,
        tone: AppSnackBarTone.success,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSavingApiKey = false);
      context.showAppSnackBar(
        strings.apiKeyUpdateFailed(error),
        tone: AppSnackBarTone.error,
      );
    }
  }

  Future<void> _resetApiKey() async {
    final strings = context.strings;
    setState(() => _isResettingApiKey = true);
    try {
      await ref.read(transcriptionApiKeyControllerProvider.notifier).reset();
      _apiKeyController.clear();
      if (!mounted) return;
      setState(() => _isResettingApiKey = false);
      context.showAppSnackBar(
        strings.apiKeyReset,
        tone: AppSnackBarTone.success,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isResettingApiKey = false);
      context.showAppSnackBar(
        strings.apiKeyUpdateFailed(error),
        tone: AppSnackBarTone.error,
      );
    }
  }

  Future<void> _selectIcon(AppIconPreset preset) async {
    final strings = context.strings;
    setState(() => _isChangingIcon = true);
    try {
      await ref.read(appIconControllerProvider.notifier).setPreset(preset);
      if (!mounted) return;
      setState(() => _isChangingIcon = false);
      context.showAppSnackBar(
        strings.appIconUpdated,
        tone: AppSnackBarTone.success,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isChangingIcon = false);
      context.showAppSnackBar(
        strings.appIconUpdateFailed(error),
        tone: AppSnackBarTone.error,
      );
    }
  }

  Future<void> _resetIcon() async {
    final strings = context.strings;
    setState(() => _isChangingIcon = true);
    try {
      await ref.read(appIconControllerProvider.notifier).reset();
      if (!mounted) return;
      setState(() => _isChangingIcon = false);
      context.showAppSnackBar(
        strings.appIconReset,
        tone: AppSnackBarTone.success,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isChangingIcon = false);
      context.showAppSnackBar(
        strings.appIconUpdateFailed(error),
        tone: AppSnackBarTone.error,
      );
    }
  }

  Future<void> _pickCustomIcon() async {
    final strings = context.strings;
    setState(() => _isChangingIcon = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp', 'bmp'],
      );

      if (!mounted) return;

      final selectedPath = result != null && result.files.isNotEmpty
          ? result.files.first.path
          : null;
      if (selectedPath == null || selectedPath.trim().isEmpty) {
        setState(() => _isChangingIcon = false);
        return;
      }

      await ref.read(appIconControllerProvider.notifier).setCustomImage(
            selectedPath,
          );

      if (!mounted) return;
      setState(() => _isChangingIcon = false);
      context.showAppSnackBar(
        strings.appIconUpdated,
        tone: AppSnackBarTone.success,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isChangingIcon = false);
      context.showAppSnackBar(
        strings.appIconUpdateFailed(error),
        tone: AppSnackBarTone.error,
      );
    }
  }

  Future<void> _syncBuildWindowIcon(AppIconSelection selection) async {
    final strings = context.strings;
    setState(() => _isSyncingBuildWindowIcon = true);

    try {
      await ref
          .read(windowsBuildIdentityServiceProvider)
          .applyBuildIcon(selection);
      if (!mounted) return;
      setState(() => _isSyncingBuildWindowIcon = false);
      context.showAppSnackBar(
        strings.buildWindowIconApplied,
        tone: AppSnackBarTone.success,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSyncingBuildWindowIcon = false);
      context.showAppSnackBar(
        strings.buildWindowIconFailed(error),
        tone: AppSnackBarTone.error,
      );
    }
  }

  Future<void> _resetBuildWindowIcon() async {
    final strings = context.strings;
    setState(() => _isResettingBuildWindowIcon = true);

    try {
      await ref.read(windowsBuildIdentityServiceProvider).resetBuildIcon();
      if (!mounted) return;
      setState(() => _isResettingBuildWindowIcon = false);
      context.showAppSnackBar(
        strings.buildWindowIconReset,
        tone: AppSnackBarTone.success,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isResettingBuildWindowIcon = false);
      context.showAppSnackBar(
        strings.buildWindowIconFailed(error),
        tone: AppSnackBarTone.error,
      );
    }
  }

  Future<void> _openMoodDialog({
    DiaryMood? existing,
  }) async {
    final strings = context.strings;
    final mood = existing;
    final nameController = TextEditingController(
      text: mood == null ? '' : strings.moodLabel(mood),
    );
    final emojiController = TextEditingController(text: mood?.emoji ?? '');

    final result = await showDialog<DiaryMood>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(mood == null ? strings.addMood : strings.editMood),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: strings.moodNameLabel,
                  hintText: strings.moodNameHint,
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emojiController,
                decoration: InputDecoration(
                  labelText: strings.moodEmojiLabel,
                  hintText: strings.moodEmojiHint,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(strings.cancelAction),
          ),
          FilledButton(
            onPressed: () {
              final label = nameController.text.trim();
              final emoji = emojiController.text.trim();
              if (emoji.isEmpty) return;
              if (mood == null && label.isEmpty) return;
              if (mood != null && !mood.isDefault && label.isEmpty) return;
              final normalizedLabel = mood == null
                  ? label
                  : (mood.isDefault &&
                          label == strings.defaultMoodLabel(mood.id))
                      ? ''
                      : label;
              Navigator.of(dialogContext).pop(
                mood?.copyWith(
                      label: normalizedLabel,
                      emoji: emoji,
                    ) ??
                    DiaryMood(
                      id: '',
                      label: normalizedLabel,
                      emoji: emoji,
                    ),
              );
            },
            child: Text(strings.saveAction),
          ),
        ],
      ),
    );

    nameController.dispose();
    emojiController.dispose();

    if (result == null) return;

    try {
      if (existing == null) {
        await ref.read(moodLibraryControllerProvider.notifier).createMood(
              label: result.label,
              emoji: result.emoji,
            );
      } else {
        await ref.read(moodLibraryControllerProvider.notifier).saveMood(result);
      }
      if (!mounted) return;
      context.showAppSnackBar(
        existing == null ? strings.moodCreated : strings.moodSaved,
        tone: AppSnackBarTone.success,
      );
    } catch (error) {
      if (!mounted) return;
      context.showAppSnackBar(
        strings.moodSaveFailed(error),
        tone: AppSnackBarTone.error,
      );
    }
  }

  Future<void> _confirmResetMoods() async {
    final strings = context.strings;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(strings.restoreDefaultMoodsTitle),
            content: Text(strings.restoreDefaultMoodsMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(strings.cancelAction),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(strings.restoreDefaultMoods),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;

    setState(() => _isResettingMoods = true);
    try {
      await ref.read(moodLibraryControllerProvider.notifier).resetToDefaults();
      if (!mounted) return;
      setState(() => _isResettingMoods = false);
      context.showAppSnackBar(
        strings.moodsReset,
        tone: AppSnackBarTone.success,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isResettingMoods = false);
      context.showAppSnackBar(
        strings.moodResetFailed(error),
        tone: AppSnackBarTone.error,
      );
    }
  }

  IconData _themeIcon(DiaryThemePreset theme) {
    switch (theme) {
      case DiaryThemePreset.daylight:
        return Icons.wb_sunny_outlined;
      case DiaryThemePreset.girlPink:
        return Icons.favorite_border;
      case DiaryThemePreset.barbieShockPink:
        return Icons.auto_awesome;
      case DiaryThemePreset.kidPink:
        return Icons.toys_outlined;
      case DiaryThemePreset.happyBoy:
        return Icons.sports_basketball_outlined;
      case DiaryThemePreset.night:
        return Icons.dark_mode_outlined;
      case DiaryThemePreset.cyberpunk:
        return Icons.bolt_outlined;
      case DiaryThemePreset.hacker:
        return Icons.memory_outlined;
      case DiaryThemePreset.spaceLines:
        return Icons.rocket_launch_outlined;
    }
  }
}

class _IconOptionCard extends StatelessWidget {
  const _IconOptionCard({
    required this.preset,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final AppIconPreset preset;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: 134,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
            width: selected ? 1.6 : 1,
          ),
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : theme.cardTheme.color ?? theme.colorScheme.surface,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIconBadge(preset: preset, size: 52),
            const SizedBox(height: 10),
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
