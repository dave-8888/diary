import 'package:diary_mvp/app/context_tooltip.dart';
import 'package:diary_mvp/app/localization/app_strings.dart';
import 'package:diary_mvp/app/themed_snackbar.dart';
import 'package:diary_mvp/core/storage/local_storage_service.dart';
import 'package:diary_mvp/features/diary/application/diary_controller.dart';
import 'package:diary_mvp/features/diary/data/diary_repository.dart';
import 'package:diary_mvp/features/diary/data/local/diary_database.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/diary_shell.dart';
import 'package:diary_mvp/features/diary/services/migration_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MigrationPage extends ConsumerStatefulWidget {
  const MigrationPage({super.key});

  @override
  ConsumerState<MigrationPage> createState() => _MigrationPageState();
}

class _MigrationPageState extends ConsumerState<MigrationPage> {
  bool _isExporting = false;
  bool _isImporting = false;
  String? _dataRootPath;

  @override
  void initState() {
    super.initState();
    _loadDataRootPath();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;

    return DiaryShell(
      title: strings.migrationTitle,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: ListView(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.currentDataLocation,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 10),
                      SelectableText(_dataRootPath ?? '...'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildActionCard(
                context: context,
                icon: Icons.upload_file_outlined,
                title: strings.exportMigrationPackage,
                hint: strings.exportMigrationHint,
                buttonLabel: _isExporting
                    ? strings.exportingMigrationPackage
                    : strings.exportMigrationPackage,
                onPressed: _isImporting || _isExporting ? null : _exportPackage,
                isBusy: _isExporting,
              ),
              const SizedBox(height: 16),
              _buildActionCard(
                context: context,
                icon: Icons.download_for_offline_outlined,
                title: strings.importMigrationPackage,
                hint: strings.importMigrationHint,
                buttonLabel: _isImporting
                    ? strings.importingMigrationPackage
                    : strings.importMigrationPackage,
                onPressed: _isImporting || _isExporting ? null : _importPackage,
                isBusy: _isImporting,
                isDanger: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String hint,
    required String buttonLabel,
    required VoidCallback? onPressed,
    required bool isBusy,
    bool isDanger = false,
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
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ContextTooltip(message: hint),
              ],
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onPressed,
              icon: isBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(icon),
              style: isDanger
                  ? FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.errorContainer,
                      foregroundColor: theme.colorScheme.onErrorContainer,
                    )
                  : null,
              label: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadDataRootPath() async {
    final path =
        await ref.read(diaryMigrationServiceProvider).appDataRootPath();
    if (!mounted) return;
    setState(() => _dataRootPath = path);
  }

  Future<void> _exportPackage() async {
    final strings = context.strings;
    final destinationRootPath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: strings.selectMigrationExportFolder,
    );
    if (!mounted || destinationRootPath == null) {
      if (mounted) {
        context.showAppSnackBar(
          strings.migrationFolderNotSelected,
          tone: AppSnackBarTone.warning,
        );
      }
      return;
    }

    setState(() => _isExporting = true);
    try {
      final repository = ref.read(diaryRepositoryProvider);
      final activeEntries = await repository.listEntries();
      final trashedEntries = await repository.listTrashedEntries();
      final tags = await repository.listTagLibrary();
      final moods = await repository.listMoodLibrary();
      final result =
          await ref.read(diaryMigrationServiceProvider).exportPackage(
                destinationRootPath: destinationRootPath,
                activeEntries: activeEntries,
                trashedEntries: trashedEntries,
                tagLibrary: tags,
                moodLibrary: moods,
              );

      if (!mounted) return;
      setState(() => _isExporting = false);
      context.showAppSnackBar(
        strings.migrationExported(result.directoryPath, result.entryCount),
        tone: AppSnackBarTone.success,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isExporting = false);
      context.showAppSnackBar(
        strings.migrationExportFailed(error),
        tone: AppSnackBarTone.error,
      );
    }
  }

  Future<void> _importPackage() async {
    final strings = context.strings;
    final sourceDirectoryPath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: strings.selectMigrationImportFolder,
    );
    if (!mounted || sourceDirectoryPath == null) {
      if (mounted) {
        context.showAppSnackBar(
          strings.migrationFolderNotSelected,
          tone: AppSnackBarTone.warning,
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(strings.importMigrationConfirmTitle),
            content: Text(strings.importMigrationConfirmMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(strings.cancelAction),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(strings.confirmImportMigration),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;

    setState(() => _isImporting = true);
    try {
      final result =
          await ref.read(diaryMigrationServiceProvider).importPackage(
                sourceDirectoryPath: sourceDirectoryPath,
                currentDatabase: ref.read(diaryDatabaseProvider),
                storage: ref.read(localStorageServiceProvider),
              );
      _refreshAfterImport();

      if (!mounted) return;
      setState(() => _isImporting = false);
      context.showAppSnackBar(
        strings.migrationImported(result.entryCount),
        tone: AppSnackBarTone.success,
      );
      context.go('/');
    } catch (error) {
      _refreshAfterImport();

      if (!mounted) return;
      setState(() => _isImporting = false);
      context.showAppSnackBar(
        strings.migrationImportFailed(error),
        tone: AppSnackBarTone.error,
      );
    }
  }

  void _refreshAfterImport() {
    ref.invalidate(diaryDatabaseProvider);
    ref.invalidate(diaryRepositoryProvider);
    ref.invalidate(diaryControllerProvider);
    ref.invalidate(trashDiaryControllerProvider);
    ref.invalidate(tagLibraryControllerProvider);
    ref.invalidate(moodLibraryControllerProvider);
    ref.read(selectedTagFilterProvider.notifier).state = null;
  }
}
