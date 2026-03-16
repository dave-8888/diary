import 'package:diary_mvp/app/app_display_name.dart';
import 'package:diary_mvp/app/localization/app_strings.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/diary_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AppNamePage extends ConsumerStatefulWidget {
  const AppNamePage({super.key});

  @override
  ConsumerState<AppNamePage> createState() => _AppNamePageState();
}

class _AppNamePageState extends ConsumerState<AppNamePage> {
  late final TextEditingController _controller;
  bool _initialized = false;
  bool _isSaving = false;
  bool _isResetting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final customAppNameAsync = ref.watch(appDisplayNameControllerProvider);
    final currentName = resolveAppDisplayName(
      strings: strings,
      customNameAsync: customAppNameAsync,
    );

    if (!_initialized) {
      _controller.text = customAppNameAsync.valueOrNull ?? currentName;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
      _initialized = true;
    }

    return DiaryShell(
      title: strings.renameAppTitle,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.renameAppTooltip,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    strings.appNameHint,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _controller,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: strings.appNameLabel,
                      hintText: strings.appNameHint,
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _save(),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: _isSaving || _isResetting ? null : _reset,
                        child: _isResetting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(strings.resetAppName),
                      ),
                      FilledButton(
                        onPressed: _isSaving || _isResetting ? null : _save,
                        child: _isSaving
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
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final strings = context.strings;
    setState(() => _isSaving = true);

    try {
      await ref
          .read(appDisplayNameControllerProvider.notifier)
          .save(_controller.text);
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.appNameUpdated)),
      );
      context.pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.appNameUpdateFailed(error))),
      );
    }
  }

  Future<void> _reset() async {
    final strings = context.strings;
    setState(() => _isResetting = true);

    try {
      await ref.read(appDisplayNameControllerProvider.notifier).reset();
      if (!mounted) return;
      setState(() => _isResetting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.appNameReset)),
      );
      context.pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _isResetting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.appNameUpdateFailed(error))),
      );
    }
  }
}
