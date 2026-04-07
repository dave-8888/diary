import 'package:diary_mvp/app/localization/app_strings.dart';
import 'package:diary_mvp/features/diary/services/hidden_diary_settings.dart';
import 'package:diary_mvp/features/diary/services/password_settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<bool> ensureHiddenDiaryPasswordConfigured(
  BuildContext context,
  WidgetRef ref,
) async {
  final settings = await _readHiddenDiaryPasswordSettings(ref);
  if (settings.hasPassword) {
    return true;
  }
  if (!context.mounted) {
    return false;
  }

  final didSave = await showHiddenDiaryPasscodeDialog(
    context: context,
    hasPassword: false,
  );
  return didSave;
}

Future<bool> requestHiddenDiaryAccess(
  BuildContext context,
  WidgetRef ref,
) async {
  final settings = await _readHiddenDiaryPasswordSettings(ref);
  if (!context.mounted) {
    return false;
  }
  late final bool granted;
  if (settings.hasPassword) {
    granted = await showHiddenDiaryUnlockDialog(context: context);
  } else {
    granted = await showHiddenDiaryPasscodeDialog(
      context: context,
      hasPassword: false,
    );
  }
  if (!context.mounted) {
    return false;
  }

  if (granted) {
    ref.read(showHiddenDiariesProvider.notifier).state = true;
  }
  return granted;
}

Future<bool> showHiddenDiaryPasscodeDialog({
  required BuildContext context,
  required bool hasPassword,
}) async {
  final didSave = await showCupertinoDialog<bool>(
    context: context,
    builder: (dialogContext) =>
        _HiddenDiaryPasscodeDialog(hasPassword: hasPassword),
  );
  return didSave == true;
}

Future<bool> showHiddenDiaryUnlockDialog({
  required BuildContext context,
}) async {
  final didUnlock = await showCupertinoDialog<bool>(
    context: context,
    builder: (dialogContext) => const _HiddenDiaryUnlockDialog(),
  );
  return didUnlock == true;
}

Future<PasswordSettingsState> _readHiddenDiaryPasswordSettings(
  WidgetRef ref,
) async {
  final current =
      ref.read(hiddenDiaryPasswordSettingsControllerProvider).valueOrNull;
  if (current != null) {
    return current;
  }
  return ref.read(hiddenDiaryPasswordSettingsControllerProvider.future);
}

class _HiddenDiaryPasscodeDialog extends ConsumerStatefulWidget {
  const _HiddenDiaryPasscodeDialog({
    required this.hasPassword,
  });

  final bool hasPassword;

  @override
  ConsumerState<_HiddenDiaryPasscodeDialog> createState() =>
      _HiddenDiaryPasscodeDialogState();
}

class _HiddenDiaryPasscodeDialogState
    extends ConsumerState<_HiddenDiaryPasscodeDialog> {
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
            ? strings.changeHiddenDiaryPasscodeAction
            : strings.setHiddenDiaryPasscodeAction,
      ),
      content: Column(
        children: [
          const SizedBox(height: 12),
          if (widget.hasPassword) ...[
            _HiddenDiaryPasswordDialogField(
              controller: _currentController,
              labelText: strings.currentHiddenDiaryPasscodeLabel,
              hintText: strings.hiddenDiaryPasscodeHint,
              isVisible: _showCurrentPassword,
              onVisibilityChanged: () {
                setState(() {
                  _showCurrentPassword = !_showCurrentPassword;
                });
              },
              valueKey: const ValueKey('hidden-diary-passcode-current'),
              textInputAction: TextInputAction.next,
              autofocus: true,
              onChanged: _clearErrorIfNeeded,
              onSubmitted: (_) {},
            ),
            const SizedBox(height: 12),
          ],
          _HiddenDiaryPasswordDialogField(
            controller: _newController,
            labelText: strings.newHiddenDiaryPasscodeLabel,
            hintText: strings.hiddenDiaryPasscodeHint,
            isVisible: _showNewPassword,
            onVisibilityChanged: () {
              setState(() {
                _showNewPassword = !_showNewPassword;
              });
            },
            valueKey: const ValueKey('hidden-diary-passcode-new'),
            textInputAction: TextInputAction.next,
            autofocus: !widget.hasPassword,
            onChanged: _clearErrorIfNeeded,
            onSubmitted: (_) {},
          ),
          const SizedBox(height: 12),
          _HiddenDiaryPasswordDialogField(
            controller: _confirmController,
            labelText: strings.confirmHiddenDiaryPasscodeLabel,
            hintText: strings.hiddenDiaryPasscodeHint,
            isVisible: _showConfirmPassword,
            onVisibilityChanged: () {
              setState(() {
                _showConfirmPassword = !_showConfirmPassword;
              });
            },
            valueKey: const ValueKey('hidden-diary-passcode-confirm'),
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
          key: const ValueKey('hidden-diary-passcode-dialog-submit'),
          isDefaultAction: true,
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const CupertinoActivityIndicator()
              : Text(
                  widget.hasPassword
                      ? strings.changeHiddenDiaryPasscodeAction
                      : strings.setHiddenDiaryPasscodeAction,
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
      setState(() => _errorText = strings.hiddenDiaryPasscodeCannotBeEmpty);
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() => _errorText = strings.hiddenDiaryPasscodeMismatch);
      return;
    }

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    try {
      if (widget.hasPassword) {
        await ref
            .read(hiddenDiaryPasswordSettingsControllerProvider.notifier)
            .changePassword(
              currentPassword: currentPassword,
              newPassword: newPassword,
            );
      } else {
        await ref
            .read(hiddenDiaryPasswordSettingsControllerProvider.notifier)
            .setPassword(newPassword);
      }

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
                ? strings.currentHiddenDiaryPasscodeIncorrect
                : strings.hiddenDiaryPasscodeSaveFailed(error);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSaving = false;
        _errorText = strings.hiddenDiaryPasscodeSaveFailed(error);
      });
    }
  }
}

class _HiddenDiaryUnlockDialog extends ConsumerStatefulWidget {
  const _HiddenDiaryUnlockDialog();

  @override
  ConsumerState<_HiddenDiaryUnlockDialog> createState() =>
      _HiddenDiaryUnlockDialogState();
}

class _HiddenDiaryUnlockDialogState
    extends ConsumerState<_HiddenDiaryUnlockDialog> {
  late final TextEditingController _passwordController;
  bool _showPassword = false;
  bool _isUnlocking = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;

    return CupertinoAlertDialog(
      title: Text(strings.hiddenDiaryUnlockTitle),
      content: Column(
        children: [
          const SizedBox(height: 12),
          Text(strings.hiddenDiaryUnlockHint),
          const SizedBox(height: 12),
          _HiddenDiaryPasswordDialogField(
            controller: _passwordController,
            labelText: strings.hiddenDiaryPasscodeLabel,
            hintText: strings.hiddenDiaryPasscodeHint,
            isVisible: _showPassword,
            onVisibilityChanged: () {
              setState(() => _showPassword = !_showPassword);
            },
            valueKey: const ValueKey('hidden-diary-unlock-field'),
            textInputAction: TextInputAction.done,
            autofocus: true,
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
          onPressed:
              _isUnlocking ? null : () => Navigator.of(context).pop(false),
          child: Text(strings.cancelAction),
        ),
        CupertinoDialogAction(
          key: const ValueKey('hidden-diary-unlock-submit'),
          isDefaultAction: true,
          onPressed: _isUnlocking ? null : _submit,
          child: _isUnlocking
              ? const CupertinoActivityIndicator()
              : Text(strings.hiddenDiaryUnlockAction),
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
    final password = _passwordController.text;
    if (!isValidPassword(password)) {
      setState(() => _errorText = strings.hiddenDiaryPasscodeCannotBeEmpty);
      return;
    }

    setState(() {
      _isUnlocking = true;
      _errorText = null;
    });

    final isUnlocked = await ref
        .read(hiddenDiaryPasswordSettingsControllerProvider.notifier)
        .verifyInput(password);

    if (!mounted) {
      return;
    }

    if (!isUnlocked) {
      setState(() {
        _isUnlocking = false;
        _errorText = strings.hiddenDiaryUnlockFailed;
      });
      return;
    }

    Navigator.of(context).pop(true);
  }
}

class _HiddenDiaryPasswordDialogField extends StatelessWidget {
  const _HiddenDiaryPasswordDialogField({
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            labelText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 6),
        CupertinoTextField(
          key: valueKey,
          controller: controller,
          obscureText: !isVisible,
          autofocus: autofocus,
          keyboardType: TextInputType.visiblePassword,
          enableSuggestions: false,
          autocorrect: false,
          textInputAction: textInputAction,
          placeholder: hintText,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          suffix: CupertinoButton(
            padding: const EdgeInsets.only(right: 10),
            minimumSize: Size.zero,
            onPressed: onVisibilityChanged,
            child: Icon(
              isVisible ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
