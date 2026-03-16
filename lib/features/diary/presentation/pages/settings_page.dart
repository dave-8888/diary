import 'package:diary_mvp/app/app_display_name.dart';
import 'package:diary_mvp/app/app_icon.dart';
import 'package:diary_mvp/app/localization/app_locale.dart';
import 'package:diary_mvp/app/localization/app_strings.dart';
import 'package:diary_mvp/app/theme.dart';
import 'package:diary_mvp/features/diary/application/diary_controller.dart';
import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/diary_shell.dart';
import 'package:diary_mvp/features/diary/services/transcription_settings.dart';
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
  late final TextEditingController _apiKeyController;
  bool _appNameInitialized = false;
  bool _apiKeyInitialized = false;
  bool _isSavingAppName = false;
  bool _isSavingApiKey = false;
  bool _isResettingAppName = false;
  bool _isResettingApiKey = false;
  bool _isChangingIcon = false;
  bool _isChangingTheme = false;
  bool _isChangingLanguage = false;
  bool _isResettingMoods = false;
  bool _showApiKey = false;

  @override
  void initState() {
    super.initState();
    _appNameController = TextEditingController();
    _apiKeyController = TextEditingController();
  }

  @override
  void dispose() {
    _appNameController.dispose();
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
    final apiKeyAsync = ref.watch(transcriptionApiKeyControllerProvider);
    final iconPreset =
        resolveAppIconPreset(ref.watch(appIconControllerProvider));
    final selectedTheme = resolveThemePreset(
      ref.watch(appThemeControllerProvider),
    );
    final selectedLanguage = resolveAppLanguage(
      ref.watch(appLanguageProvider),
    );
    final moodLibraryAsync = ref.watch(moodLibraryControllerProvider);

    if (!_appNameInitialized && customAppNameAsync.hasValue) {
      _appNameController.text =
          customAppNameAsync.valueOrNull ?? currentAppName;
      _appNameController.selection = TextSelection.collapsed(
        offset: _appNameController.text.length,
      );
      _appNameInitialized = true;
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
              _buildSectionCard(
                context: context,
                icon: Icons.badge_outlined,
                title: strings.appIdentityTitle,
                subtitle: strings.appIdentityHint,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _appNameController,
                      decoration: InputDecoration(
                        labelText: strings.appNameLabel,
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
                    Text(
                      strings.appIconTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      strings.appIconHint,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
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
                              selected: preset == iconPreset,
                              onTap: _isChangingIcon
                                  ? null
                                  : () => _selectIcon(preset),
                            ),
                          )
                          .toList(growable: false),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _isChangingIcon ? null : _resetIcon,
                      icon: _isChangingIcon
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.restart_alt_outlined),
                      label: Text(strings.resetAppIcon),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _buildSectionCard(
                context: context,
                icon: Icons.key_outlined,
                title: strings.transcriptionSettingsTitle,
                subtitle: strings.transcriptionSettingsHint,
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
              _buildSectionCard(
                context: context,
                icon: Icons.emoji_emotions_outlined,
                title: strings.moodLibraryTitle,
                subtitle: strings.moodLibraryHint,
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
                        ...moods.map(
                          (mood) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                                side: BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                              leading: Text(
                                mood.emoji,
                                style: const TextStyle(fontSize: 24, height: 1),
                              ),
                              title: Text(strings.moodLabel(mood)),
                              subtitle: Text(
                                mood.isDefault
                                    ? strings.defaultMoodBadge
                                    : strings.customMoodBadge,
                              ),
                              trailing: IconButton(
                                onPressed: () =>
                                    _openMoodDialog(existing: mood),
                                tooltip: strings.editMood,
                                icon: const Icon(Icons.edit_outlined),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _buildSectionCard(
                context: context,
                icon: Icons.import_export_outlined,
                title: strings.migrationTitle,
                subtitle: strings.migrationHint,
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
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
                      Text(title, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            child,
          ],
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.appNameUpdated)),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSavingAppName = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.appNameUpdateFailed(error))),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.themeUpdated)),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isChangingTheme = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.themeUpdateFailed(error))),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.languageUpdated)),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isChangingLanguage = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.languageUpdateFailed(error))),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.appNameReset)),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isResettingAppName = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.appNameUpdateFailed(error))),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.apiKeyUpdated)),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSavingApiKey = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.apiKeyUpdateFailed(error))),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.apiKeyReset)),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isResettingApiKey = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.apiKeyUpdateFailed(error))),
      );
    }
  }

  Future<void> _selectIcon(AppIconPreset preset) async {
    final strings = context.strings;
    setState(() => _isChangingIcon = true);
    try {
      await ref.read(appIconControllerProvider.notifier).setIcon(preset);
      if (!mounted) return;
      setState(() => _isChangingIcon = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.appIconUpdated)),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isChangingIcon = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.appIconUpdateFailed(error))),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.appIconReset)),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isChangingIcon = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.appIconUpdateFailed(error))),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(existing == null ? strings.moodCreated : strings.moodSaved),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.moodSaveFailed(error))),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.moodsReset)),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isResettingMoods = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.moodResetFailed(error))),
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
