import 'package:diary_mvp/app/localization/app_strings.dart';
import 'package:diary_mvp/app/themed_snackbar.dart';
import 'package:diary_mvp/features/diary/application/diary_controller.dart';
import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/diary_shell.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/entry_readonly_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TrashPreviewPage extends ConsumerStatefulWidget {
  const TrashPreviewPage({
    super.key,
    this.entry,
  });

  final DiaryEntry? entry;

  @override
  ConsumerState<TrashPreviewPage> createState() => _TrashPreviewPageState();
}

class _TrashPreviewPageState extends ConsumerState<TrashPreviewPage> {
  bool _isRestoring = false;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final entry = widget.entry;

    return DiaryShell(
      title: strings.previewEntry,
      actions: [
        if (entry != null)
          IconButton(
            onPressed: _isRestoring ? null : _restoreEntry,
            tooltip: strings.restoreFromTrash,
            icon: _isRestoring
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.restore_outlined),
          ),
      ],
      child: entry == null
          ? Center(child: Text(strings.noEntriesYet))
          : ListView(
              children: [
                EntryReadonlyView(
                  entry: entry,
                  showTrashedInfo: true,
                ),
              ],
            ),
    );
  }

  Future<void> _restoreEntry() async {
    final entry = widget.entry;
    if (entry == null) return;

    final strings = context.strings;
    setState(() => _isRestoring = true);
    try {
      await ref
          .read(trashDiaryControllerProvider.notifier)
          .restoreEntries([entry]);
      if (!mounted) return;
      setState(() => _isRestoring = false);
      context.showAppSnackBar(
        strings.restoredEntries(1),
        tone: AppSnackBarTone.success,
      );
      context.go('/trash');
    } catch (error) {
      if (!mounted) return;
      setState(() => _isRestoring = false);
      context.showAppSnackBar(
        strings.restoreFailed(error),
        tone: AppSnackBarTone.error,
      );
    }
  }
}
