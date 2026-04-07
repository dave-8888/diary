import 'package:diary_mvp/app/localization/app_strings.dart';
import 'package:diary_mvp/app/themed_snackbar.dart';
import 'package:diary_mvp/features/diary/application/diary_controller.dart';
import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/diary_shell.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/entry_readonly_view.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/hidden_diary_password_dialogs.dart';
import 'package:diary_mvp/features/diary/services/hidden_diary_settings.dart';
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
  bool _isCheckingHiddenAccess = false;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _isCheckingHiddenAccess =
        (entry?.isHidden ?? false) && !ref.read(showHiddenDiariesProvider);
    if (_isCheckingHiddenAccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _ensureHiddenDiaryAccess();
      });
    }
  }

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
      child: _isCheckingHiddenAccess
          ? const Center(child: CupertinoActivityIndicator())
          : entry == null
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

  Future<void> _ensureHiddenDiaryAccess() async {
    final entry = widget.entry;
    if (entry == null || !entry.isHidden) {
      if (mounted) {
        setState(() => _isCheckingHiddenAccess = false);
      }
      return;
    }
    if (ref.read(showHiddenDiariesProvider)) {
      if (mounted) {
        setState(() => _isCheckingHiddenAccess = false);
      }
      return;
    }

    final granted = await requestHiddenDiaryAccess(context, ref);
    if (!mounted) {
      return;
    }

    if (!granted) {
      setState(() => _isCheckingHiddenAccess = false);
      _closeProtectedPreview();
      return;
    }

    setState(() => _isCheckingHiddenAccess = false);
  }

  void _closeProtectedPreview() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    context.go('/trash');
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
