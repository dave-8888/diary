import 'package:diary_mvp/app/app_display_name.dart';
import 'package:diary_mvp/app/app_icon.dart';
import 'package:diary_mvp/app/cupertino_kit.dart';
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
import 'package:diary_mvp/features/diary/services/diary_list_settings.dart';
import 'package:diary_mvp/features/diary/services/password_settings.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
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
  late final TextEditingController _diaryAiBaseUrlController;
  late final TextEditingController _diaryAiModelController;
  late final TextEditingController _diaryAiApiKeyController;
  bool _appNameInitialized = false;
  bool _diaryAiConfigInitialized = false;
  bool _isSavingAppName = false;
  bool _isSavingDiaryAiConfig = false;
  bool _isResettingAppName = false;
  bool _isResettingDiaryAiConfig = false;
  bool _isDisablingPasscode = false;
  bool _isChangingIcon = false;
  bool _isSyncingBuildWindowIcon = false;
  bool _isResettingBuildWindowIcon = false;
  bool _isChangingTheme = false;
  bool _isChangingLanguage = false;
  bool _isResettingMoods = false;
  bool _isChangingDiaryListVisualMediaVisibility = false;
  bool _isChangingDiaryAiVisibility = false;
  bool _isChangingEmotionalCompanionVisibility = false;
  bool _isChangingProblemSuggestionVisibility = false;
  bool _isPasswordSectionExpanded = false;
  bool _isAppIdentitySectionExpanded = false;
  bool _isDiaryAiSectionExpanded = false;
  bool _isMoodLibrarySectionExpanded = false;
  bool _isMigrationSectionExpanded = false;
  bool _showDiaryAiApiKey = false;
  DiaryAiProviderPreset _selectedDiaryAiPreset =
      DiaryAiProviderPreset.dashScope;

  @override
  void initState() {
    super.initState();
    _appNameController = TextEditingController();
    _diaryAiBaseUrlController = TextEditingController();
    _diaryAiModelController = TextEditingController();
    _diaryAiApiKeyController = TextEditingController();
  }

  @override
  void dispose() {
    _appNameController.dispose();
    _diaryAiBaseUrlController.dispose();
    _diaryAiModelController.dispose();
    _diaryAiApiKeyController.dispose();
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
    final diaryAiConfigAsync = ref.watch(diaryAiConfigControllerProvider);
    final diaryAiConfig = diaryAiConfigAsync.valueOrNull ??
        DiaryAiProviderConfig.forPreset(DiaryAiProviderPreset.dashScope);
    final diaryListVisualMediaVisibilityAsync = ref.watch(
      diaryListVisualMediaVisibilityControllerProvider,
    );
    final diaryListShowVisualMedia =
        diaryListVisualMediaVisibilityAsync.valueOrNull ?? true;
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
    final passwordSettingsAsync = ref.watch(passwordSettingsControllerProvider);
    final passwordEnabled =
        passwordSettingsAsync.valueOrNull?.hasPassword ?? false;
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
    if (!_diaryAiConfigInitialized && diaryAiConfigAsync.hasValue) {
      _applyDiaryAiConfigForm(diaryAiConfigAsync.valueOrNull!);
      _diaryAiConfigInitialized = true;
    }

    return DiaryShell(
      title: strings.settingsTitle,
      showAppBarTitle: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                          (themePreset) => CupertinoPill(
                            selected: themePreset == selectedTheme,
                            onPressed: _isChangingTheme
                                ? null
                                : () => _changeTheme(themePreset),
                            icon:
                              _themeIcon(themePreset),
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
                          (language) => CupertinoPill(
                            selected: language == selectedLanguage,
                            onPressed: _isChangingLanguage
                                ? null
                                : () => _changeLanguage(language),
                            label: Text(strings.titleForLanguage(language)),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
                const SizedBox(height: 18),
                _buildSectionCard(
                  context: context,
                  icon: Icons.view_agenda_outlined,
                  title: strings.diaryListSettingsTitle,
                  subtitle: strings.diaryListSettingsHint,
                  child: _buildToggleSettingTile(
                    context: context,
                    title: strings.diaryListShowVisualMediaLabel,
                    helpText: strings.diaryListShowVisualMediaHint,
                    value: diaryListShowVisualMedia,
                    enabled: !_isChangingDiaryListVisualMediaVisibility,
                    onChanged: _changeDiaryListVisualMediaVisibility,
                  ),
                ),
                const SizedBox(height: 18),
                _buildExpandableSectionCard(
                  context: context,
                  icon: Icons.lock_outline_rounded,
                  title: strings.passwordSettingsTitle,
                  subtitle: strings.passwordSettingsHint,
                  summary: strings.passwordStatus(passwordEnabled),
                  expanded: _isPasswordSectionExpanded,
                  onExpandedChanged: (expanded) {
                    setState(() => _isPasswordSectionExpanded = expanded);
                  },
                  child: passwordSettingsAsync.when(
                    loading: () =>
                        const Center(child: CupertinoActivityIndicator()),
                    error: (error, stack) =>
                        Text(strings.passwordInitializationFailed(error)),
                    data: (settings) =>
                        _buildPasscodeSection(context, strings, settings),
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
                      CupertinoTextField(
                        controller: _appNameController,
                        placeholder: strings.appNameHint,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _saveAppName(),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          CupertinoActionButton(
                            onPressed: _isSavingAppName || _isResettingAppName
                                ? null
                                : _resetAppName,
                            isBusy: _isResettingAppName,
                            variant: CupertinoActionButtonVariant.outline,
                            label: strings.resetAppName,
                          ),
                          CupertinoActionButton(
                            onPressed: _isSavingAppName || _isResettingAppName
                                ? null
                                : _saveAppName,
                            isBusy: _isSavingAppName,
                            label: strings.saveAction,
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
                          CupertinoActionButton(
                            onPressed:
                                !supportsWindowIdentity || _isChangingIcon
                                    ? null
                                    : _pickCustomIcon,
                            isBusy: _isChangingIcon,
                            variant: CupertinoActionButtonVariant.tinted,
                            icon: Icons.image_search_outlined,
                            label: strings.pickWindowIcon,
                          ),
                          CupertinoActionButton(
                            onPressed: _isChangingIcon ? null : _resetIcon,
                            isBusy: _isChangingIcon,
                            variant: CupertinoActionButtonVariant.outline,
                            icon: Icons.restart_alt_outlined,
                            label: strings.resetAppIcon,
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
                            ContextTooltip(
                                message: strings.buildWindowIconHint),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            CupertinoActionButton(
                              onPressed: iconSelection.windowIconPath
                                          .trim()
                                          .isEmpty ||
                                      _isSyncingBuildWindowIcon ||
                                      _isResettingBuildWindowIcon
                                  ? null
                                  : () => _syncBuildWindowIcon(iconSelection),
                              isBusy: _isSyncingBuildWindowIcon,
                              icon: Icons.install_desktop_outlined,
                              label: strings.syncBuildWindowIcon,
                            ),
                            CupertinoActionButton(
                              onPressed: _isSyncingBuildWindowIcon ||
                                      _isResettingBuildWindowIcon
                                  ? null
                                  : _resetBuildWindowIcon,
                              isBusy: _isResettingBuildWindowIcon,
                              variant: CupertinoActionButtonVariant.outline,
                              icon: Icons.restart_alt_outlined,
                              label: strings.resetBuildWindowIcon,
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
                      '${strings.diaryAiVisibilityLabel}: ${diaryAiVisible ? strings.enabledLabel : strings.disabledLabel} · ${diaryAiConfig.preset.label} · ${diaryAiConfig.normalizedModel}',
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
                      Text(
                        strings.diaryAiCompatibilityHint,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        strings.diaryAiProviderLabel,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: DiaryAiProviderPreset.values
                            .map(
                              (preset) => CupertinoPill(
                                selected: preset == _selectedDiaryAiPreset,
                                onPressed: _isSavingDiaryAiConfig ||
                                        _isResettingDiaryAiConfig
                                    ? null
                                    : () => _selectDiaryAiPreset(preset),
                                label: Text(preset.label),
                              ),
                            )
                            .toList(growable: false),
                      ),
                      const SizedBox(height: 16),
                      CupertinoTextField(
                        key: const ValueKey('settings-diary-ai-base-url'),
                        controller: _diaryAiBaseUrlController,
                        placeholder:
                            '${strings.diaryAiBaseUrlLabel} · ${strings.diaryAiBaseUrlHint}',
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      CupertinoTextField(
                        key: const ValueKey('settings-diary-ai-model'),
                        controller: _diaryAiModelController,
                        placeholder:
                            '${strings.diaryAiModelLabel} · ${strings.diaryAiModelHint}',
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      CupertinoTextField(
                        key: const ValueKey('settings-diary-ai-api-key'),
                        controller: _diaryAiApiKeyController,
                        obscureText: !_showDiaryAiApiKey,
                        placeholder:
                            '${strings.diaryAiApiKeyLabel} · ${strings.diaryAiApiKeyHint}',
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        suffix: CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          onPressed: () {
                            setState(
                              () => _showDiaryAiApiKey = !_showDiaryAiApiKey,
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Icon(
                              _showDiaryAiApiKey
                                  ? CupertinoIcons.eye_slash
                                  : CupertinoIcons.eye,
                              size: 18,
                            ),
                          ),
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _saveDiaryAiConfig(),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        diaryAiEnvironmentApiKey.isNotEmpty ||
                                legacyDiaryAiEnvironmentApiKey.isNotEmpty
                            ? strings.usingDiaryAiEnvironmentApiKey
                            : strings.diaryAiApiKeyEnvironmentHint,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          CupertinoActionButton(
                            key: const ValueKey('settings-diary-ai-reset'),
                            onPressed: _isSavingDiaryAiConfig ||
                                    _isResettingDiaryAiConfig
                                ? null
                                : _resetDiaryAiConfig,
                            isBusy: _isResettingDiaryAiConfig,
                            variant: CupertinoActionButtonVariant.outline,
                            label: strings.resetDiaryAiConfig,
                          ),
                          CupertinoActionButton(
                            key: const ValueKey('settings-diary-ai-save'),
                            onPressed: _isSavingDiaryAiConfig ||
                                    _isResettingDiaryAiConfig
                                ? null
                                : _saveDiaryAiConfig,
                            isBusy: _isSavingDiaryAiConfig,
                            label: strings.saveAction,
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
                        const Center(child: CupertinoActivityIndicator()),
                    error: (error, stack) =>
                        Text(strings.failedToLoadMoods(error)),
                    data: (moods) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            CupertinoActionButton(
                              onPressed: () => _openMoodDialog(),
                              variant: CupertinoActionButtonVariant.tinted,
                              icon: Icons.add_rounded,
                              label: strings.addMood,
                            ),
                            CupertinoActionButton(
                              onPressed:
                                  _isResettingMoods ? null : _confirmResetMoods,
                              isBusy: _isResettingMoods,
                              variant: CupertinoActionButtonVariant.outline,
                              icon: Icons.restart_alt_outlined,
                              label: strings.restoreDefaultMoods,
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
                                    key: ValueKey(
                                        'mood-library-item-${mood.id}'),
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
                                                        ? strings
                                                            .defaultMoodBadge
                                                        : strings
                                                            .customMoodBadge,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              onPressed: () => _openMoodDialog(
                                                  existing: mood),
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
                    child: CupertinoActionButton(
                      onPressed: () => context.push('/migration'),
                      variant: CupertinoActionButtonVariant.outline,
                      icon: Icons.open_in_new_outlined,
                      label: strings.openMigrationPage,
                    ),
                  ),
                ),
              ],
            ),
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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SettingsSectionIcon(icon: icon),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              child,
            ],
          ),
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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SettingsSectionIcon(icon: icon),
                  const SizedBox(width: 14),
                  Expanded(
                    child: GestureDetector(
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
                            Text(
                              title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              subtitle,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                            if (summary.trim().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                summary,
                                maxLines: expanded ? 2 : 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    onPressed: () => onExpandedChanged(!expanded),
                    child: Icon(
                      expanded
                          ? CupertinoIcons.chevron_up
                          : CupertinoIcons.chevron_down,
                    ),
                  ),
                ],
              ),
              if (expanded) ...[
                const SizedBox(height: 18),
                child,
              ],
            ],
          ),
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
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.34),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ContextTooltip(message: helpText),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    helpText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildStatusChip(
                    context,
                    value ? strings.enabledLabel : strings.disabledLabel,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            CupertinoSwitch(
              value: value,
              onChanged: enabled ? onChanged : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasscodeSection(
    BuildContext context,
    AppStrings strings,
    PasswordSettingsState settings,
  ) {
    final hasPassword = settings.hasPassword;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.passwordSettingsHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            CupertinoActionButton(
              key: ValueKey(
                hasPassword
                    ? 'settings-change-passcode-button'
                    : 'settings-set-passcode-button',
              ),
              onPressed: _isDisablingPasscode
                  ? null
                  : () => _showPasscodeDialog(hasPassword: hasPassword),
              icon:
                  hasPassword ? Icons.edit_outlined : Icons.lock_outline_rounded,
              label: hasPassword
                  ? strings.changePasscodeAction
                  : strings.setPasscodeAction,
            ),
            if (hasPassword)
              CupertinoActionButton(
                onPressed: _isDisablingPasscode ? null : _disablePasscode,
                isBusy: _isDisablingPasscode,
                variant: CupertinoActionButtonVariant.outline,
                label: strings.disablePasscode,
              ),
          ],
        ),
      ],
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

  Future<void> _showPasscodeDialog({
    required bool hasPassword,
  }) async {
    final strings = context.strings;
    final didSave = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => _PasscodeDialog(hasPassword: hasPassword),
    );

    if (!mounted || didSave != true) {
      return;
    }

    context.showAppSnackBar(
      hasPassword ? strings.passcodeUpdated : strings.passcodeSaved,
      tone: AppSnackBarTone.success,
    );
  }

  Future<void> _disablePasscode() async {
    final strings = context.strings;
    final confirmed = await showCupertinoConfirmationDialog(
      context,
      title: strings.disablePasscodeTitle,
      message: strings.disablePasscodeMessage,
      cancelLabel: strings.cancelAction,
      confirmLabel: strings.confirmDisablePasscode,
      isDestructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }

    setState(() => _isDisablingPasscode = true);
    try {
      await ref
          .read(passwordSettingsControllerProvider.notifier)
          .disablePassword();
      ref.read(startupUnlockSessionControllerProvider.notifier).keepUnlocked();
      if (!mounted) return;
      setState(() => _isDisablingPasscode = false);
      context.showAppSnackBar(
        strings.passcodeDisabled,
        tone: AppSnackBarTone.success,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isDisablingPasscode = false);
      context.showAppSnackBar(
        strings.passcodeSaveFailed(error),
        tone: AppSnackBarTone.error,
      );
    }
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

  Future<void> _changeDiaryListVisualMediaVisibility(bool enabled) async {
    final strings = context.strings;
    setState(() => _isChangingDiaryListVisualMediaVisibility = true);
    try {
      await ref
          .read(diaryListVisualMediaVisibilityControllerProvider.notifier)
          .setEnabled(enabled);
      if (!mounted) return;
      setState(() => _isChangingDiaryListVisualMediaVisibility = false);
      context.showAppSnackBar(
        strings.diaryListShowVisualMediaUpdated,
        tone: AppSnackBarTone.success,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isChangingDiaryListVisualMediaVisibility = false);
      context.showAppSnackBar(
        strings.diaryListShowVisualMediaUpdateFailed(error),
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

  Future<void> _saveDiaryAiConfig() async {
    final strings = context.strings;
    setState(() => _isSavingDiaryAiConfig = true);
    try {
      final config = DiaryAiProviderConfig(
        presetId: _selectedDiaryAiPreset.id,
        baseUrl: _diaryAiBaseUrlController.text,
        model: _diaryAiModelController.text,
        apiKey: _diaryAiApiKeyController.text,
      );
      await ref.read(diaryAiConfigControllerProvider.notifier).save(config);
      if (!mounted) return;
      _applyDiaryAiConfigForm(config);
      setState(() => _isSavingDiaryAiConfig = false);
      context.showAppSnackBar(
        strings.diaryAiConfigUpdated,
        tone: AppSnackBarTone.success,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSavingDiaryAiConfig = false);
      context.showAppSnackBar(
        strings.diaryAiConfigUpdateFailed(error),
        tone: AppSnackBarTone.error,
      );
    }
  }

  Future<void> _resetDiaryAiConfig() async {
    final strings = context.strings;
    setState(() => _isResettingDiaryAiConfig = true);
    try {
      await ref.read(diaryAiConfigControllerProvider.notifier).reset();
      _applyDiaryAiConfigForm(
        DiaryAiProviderConfig.forPreset(DiaryAiProviderPreset.dashScope),
      );
      if (!mounted) return;
      setState(() => _isResettingDiaryAiConfig = false);
      context.showAppSnackBar(
        strings.diaryAiConfigReset,
        tone: AppSnackBarTone.success,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isResettingDiaryAiConfig = false);
      context.showAppSnackBar(
        strings.diaryAiConfigUpdateFailed(error),
        tone: AppSnackBarTone.error,
      );
    }
  }

  void _applyDiaryAiConfigForm(DiaryAiProviderConfig config) {
    _selectedDiaryAiPreset = config.preset;
    _diaryAiBaseUrlController.text = config.normalizedBaseUrl;
    _diaryAiModelController.text = config.normalizedModel;
    _diaryAiApiKeyController.text = config.normalizedApiKey ?? '';
    _diaryAiBaseUrlController.selection = TextSelection.collapsed(
      offset: _diaryAiBaseUrlController.text.length,
    );
    _diaryAiModelController.selection = TextSelection.collapsed(
      offset: _diaryAiModelController.text.length,
    );
    _diaryAiApiKeyController.selection = TextSelection.collapsed(
      offset: _diaryAiApiKeyController.text.length,
    );
  }

  void _selectDiaryAiPreset(DiaryAiProviderPreset preset) {
    setState(() {
      _selectedDiaryAiPreset = preset;
      if (preset != DiaryAiProviderPreset.custom) {
        _diaryAiBaseUrlController.text = preset.defaultBaseUrl;
        _diaryAiModelController.text = preset.defaultModel;
        _diaryAiBaseUrlController.selection = TextSelection.collapsed(
          offset: _diaryAiBaseUrlController.text.length,
        );
        _diaryAiModelController.selection = TextSelection.collapsed(
          offset: _diaryAiModelController.text.length,
        );
      }
    });
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

    final result = await showCupertinoDialog<DiaryMood>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(mood == null ? strings.addMood : strings.editMood),
        content: Column(
          children: [
            const SizedBox(height: 12),
            CupertinoTextField(
                controller: nameController,
                placeholder: '${strings.moodNameLabel} · ${strings.moodNameHint}',
                autofocus: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            const SizedBox(height: 12),
            CupertinoTextField(
                controller: emojiController,
                placeholder:
                    '${strings.moodEmojiLabel} · ${strings.moodEmojiHint}',
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(strings.cancelAction),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
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
    final confirmed = await showCupertinoConfirmationDialog(
      context,
      title: strings.restoreDefaultMoodsTitle,
      message: strings.restoreDefaultMoodsMessage,
      cancelLabel: strings.cancelAction,
      confirmLabel: strings.restoreDefaultMoods,
      isDestructive: true,
    );
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

class _SettingsSectionIcon extends StatelessWidget {
  const _SettingsSectionIcon({
    required this.icon,
  });

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.18),
            theme.colorScheme.secondary.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Icon(
          icon,
          size: 20,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _PasscodeDialog extends ConsumerStatefulWidget {
  const _PasscodeDialog({
    required this.hasPassword,
  });

  final bool hasPassword;

  @override
  ConsumerState<_PasscodeDialog> createState() => _PasscodeDialogState();
}

class _PasscodeDialogState extends ConsumerState<_PasscodeDialog> {
  late final TextEditingController _currentController;
  late final TextEditingController _newController;
  late final TextEditingController _confirmController;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  bool _isSaving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _currentController = TextEditingController();
    _newController = TextEditingController();
    _confirmController = TextEditingController();
  }

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;

    return CupertinoAlertDialog(
      title: Text(
        widget.hasPassword
            ? strings.changePasscodeAction
            : strings.setPasscodeAction,
      ),
      content: Column(
        children: [
          const SizedBox(height: 12),
          if (widget.hasPassword) ...[
            _PasswordDialogField(
              controller: _currentController,
              labelText: strings.currentPasscodeLabel,
              hintText: strings.passcodeHint,
              isVisible: _showCurrentPassword,
              onVisibilityChanged: () {
                setState(() {
                  _showCurrentPassword = !_showCurrentPassword;
                });
              },
              valueKey: const ValueKey('settings-passcode-current'),
              textInputAction: TextInputAction.next,
              autofocus: true,
              onChanged: _clearErrorIfNeeded,
              onSubmitted: (_) {},
            ),
            const SizedBox(height: 12),
          ],
          _PasswordDialogField(
            controller: _newController,
            labelText: strings.newPasscodeLabel,
            hintText: strings.passcodeHint,
            isVisible: _showNewPassword,
            onVisibilityChanged: () {
              setState(() {
                _showNewPassword = !_showNewPassword;
              });
            },
            valueKey: const ValueKey('settings-passcode-new'),
            textInputAction: TextInputAction.next,
            autofocus: !widget.hasPassword,
            onChanged: _clearErrorIfNeeded,
            onSubmitted: (_) {},
          ),
          const SizedBox(height: 12),
          _PasswordDialogField(
            controller: _confirmController,
            labelText: strings.confirmPasscodeLabel,
            hintText: strings.passcodeHint,
            isVisible: _showConfirmPassword,
            onVisibilityChanged: () {
              setState(() {
                _showConfirmPassword = !_showConfirmPassword;
              });
            },
            valueKey: const ValueKey('settings-passcode-confirm'),
            textInputAction: TextInputAction.done,
            onChanged: _clearErrorIfNeeded,
            onSubmitted: (_) => _submit(),
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ],
        ],
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: Text(strings.cancelAction),
        ),
        CupertinoDialogAction(
          key: const ValueKey('settings-passcode-dialog-submit'),
          isDefaultAction: true,
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const CupertinoActivityIndicator()
              : Text(
                  widget.hasPassword
                      ? strings.changePasscodeAction
                      : strings.setPasscodeAction,
                ),
        ),
      ],
    );
  }

  void _clearErrorIfNeeded(String _) {
    if (_errorText == null) {
      return;
    }
    setState(() => _errorText = null);
  }

  Future<void> _submit() async {
    final strings = context.strings;
    final currentPassword = _currentController.text;
    final newPassword = _newController.text;
    final confirmPassword = _confirmController.text;

    if (!isValidPassword(newPassword) ||
        !isValidPassword(confirmPassword) ||
        (widget.hasPassword && !isValidPassword(currentPassword))) {
      setState(() => _errorText = strings.passcodeCannotBeEmpty);
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() => _errorText = strings.passcodeMismatch);
      return;
    }

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    try {
      if (widget.hasPassword) {
        await ref
            .read(passwordSettingsControllerProvider.notifier)
            .changePassword(
              currentPassword: currentPassword,
              newPassword: newPassword,
            );
      } else {
        await ref
            .read(passwordSettingsControllerProvider.notifier)
            .setPassword(newPassword);
      }

      ref.read(startupUnlockSessionControllerProvider.notifier).keepUnlocked();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } on PasswordSettingsException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSaving = false;
        _errorText =
            error.failure == PasswordSettingsFailure.invalidCurrentPassword
                ? strings.currentPasscodeIncorrect
                : strings.passcodeSaveFailed(error);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSaving = false;
        _errorText = strings.passcodeSaveFailed(error);
      });
    }
  }
}

class _PasswordDialogField extends StatelessWidget {
  const _PasswordDialogField({
    required this.controller,
    required this.labelText,
    required this.hintText,
    required this.isVisible,
    required this.onVisibilityChanged,
    required this.valueKey,
    required this.textInputAction,
    required this.onChanged,
    required this.onSubmitted,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final bool isVisible;
  final VoidCallback onVisibilityChanged;
  final Key valueKey;
  final TextInputAction textInputAction;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      key: valueKey,
      controller: controller,
      obscureText: !isVisible,
      autofocus: autofocus,
      keyboardType: TextInputType.visiblePassword,
      enableSuggestions: false,
      autocorrect: false,
      textInputAction: textInputAction,
      placeholder: '$labelText · $hintText',
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      suffix: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        onPressed: onVisibilityChanged,
        child: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Icon(
            isVisible ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
            size: 18,
          ),
        ),
      ),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
    );
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
    final colorScheme = theme.colorScheme;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onTap,
      child: Container(
        width: 134,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.46),
            width: selected ? 1.6 : 1,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: selected
                ? [
                    colorScheme.primary.withValues(alpha: 0.18),
                    colorScheme.secondary.withValues(alpha: 0.08),
                  ]
                : [
                    (theme.cardTheme.color ?? colorScheme.surface)
                        .withValues(alpha: 0.92),
                    colorScheme.surface.withValues(alpha: 0.72),
                  ],
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                  ),
                ]
              : null,
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
