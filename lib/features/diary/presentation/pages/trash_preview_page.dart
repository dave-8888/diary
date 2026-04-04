import 'package:diary_mvp/app/localization/app_strings.dart';
import 'package:diary_mvp/app/themed_snackbar.dart';
import 'package:diary_mvp/features/diary/application/diary_controller.dart';
import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/diary_shell.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/entry_readonly_view.dart';
import 'package:flutter/cupertino.dart';
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
      showAppBarTitle: false,
      actions: [
        if (entry != null)
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            onPressed: _isRestoring ? null : _restoreEntry,
            child: _isRestoring
                ? const CupertinoActivityIndicator()
                : const Icon(CupertinoIcons.arrow_uturn_left),
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
