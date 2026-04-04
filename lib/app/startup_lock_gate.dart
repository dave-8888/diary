import 'package:diary_mvp/app/localization/app_strings.dart';
import 'package:diary_mvp/features/diary/services/password_settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppStartupLockGate extends ConsumerWidget {
  const AppStartupLockGate({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = context.strings;
    final passwordSettingsAsync = ref.watch(passwordSettingsControllerProvider);
    final sessionAsync = ref.watch(startupUnlockSessionControllerProvider);

    return passwordSettingsAsync.when(
      loading: () => _buildLockedOverlay(
        child: child,
        overlay: const _LockLoadingView(),
      ),
      error: (error, stackTrace) => _buildLockedOverlay(
        child: child,
        overlay: _LockErrorView(
          message: strings.passwordInitializationFailed(error),
        ),
      ),
      data: (settings) {
        if (!settings.hasPassword) {
          return child;
        }

        return sessionAsync.when(
          loading: () => _buildLockedOverlay(
            child: child,
            overlay: const _LockLoadingView(),
          ),
          error: (error, stackTrace) => _buildLockedOverlay(
            child: child,
            overlay: _LockErrorView(
              message: strings.passwordInitializationFailed(error),
            ),
          ),
          data: (isUnlocked) {
            if (isUnlocked) {
              return child;
            }
            return _buildLockedOverlay(
              child: child,
              overlay: const _StartupLockScreen(),
            );
          },
        );
      },
    );
  }

  Widget _buildLockedOverlay({
    required Widget child,
    required Widget overlay,
  }) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Offstage(
          offstage: true,
          child: child,
        ),
        Positioned.fill(
          child: Overlay(
            key: _overlayKeyFor(overlay),
            initialEntries: [
              OverlayEntry(
                builder: (context) => overlay,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Key _overlayKeyFor(Widget overlay) {
    if (overlay is _LockErrorView) {
      return ValueKey<String>('lock-error:${overlay.message}');
    }
    return ValueKey<String>('lock-overlay:${overlay.runtimeType}');
  }
}

class _StartupLockScreen extends ConsumerStatefulWidget {
  const _StartupLockScreen();

  @override
  ConsumerState<_StartupLockScreen> createState() => _StartupLockScreenState();
}

class _StartupLockScreenState extends ConsumerState<_StartupLockScreen> {
  late final TextEditingController _passwordController;
  bool _isUnlocking = false;
  bool _showPassword = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController()
      ..addListener(() {
        if (_errorText == null) {
          return;
        }

        setState(() => _errorText = null);
      });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return CupertinoPageScaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.cardTheme.color ?? colorScheme.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.34),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.unlockAppTitle,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      strings.unlockAppHint,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    CupertinoTextField(
                      key: const ValueKey('startup-passcode-field'),
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      autofocus: true,
                      keyboardType: TextInputType.visiblePassword,
                      enableSuggestions: false,
                      autocorrect: false,
                      textInputAction: TextInputAction.done,
                      placeholder: strings.passcodeHint,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        decoration: TextDecoration.none,
                      ),
                      placeholderStyle: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.58,
                        ),
                        decoration: TextDecoration.none,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      suffix: CupertinoButton(
                        padding: const EdgeInsets.only(right: 10),
                        minimumSize: Size.zero,
                        onPressed: () {
                          setState(() => _showPassword = !_showPassword);
                        },
                        child: Icon(
                          _showPassword
                              ? CupertinoIcons.eye_slash
                              : CupertinoIcons.eye,
                          color: colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                      onSubmitted: (_) => _unlock(),
                    ),
                    if (_errorText != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _errorText!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        onPressed: _isUnlocking ? null : _unlock,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(
                              alpha: _isUnlocking ? 0.5 : 1,
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Center(
                              child: _isUnlocking
                                  ? CupertinoActivityIndicator(
                                      color: colorScheme.onPrimary,
                                    )
                                  : Text(
                                      strings.unlockAction,
                                      style:
                                          theme.textTheme.labelLarge?.copyWith(
                                        color: colorScheme.onPrimary,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _unlock() async {
    final strings = context.strings;
    final password = _passwordController.text;
    if (!isValidPassword(password)) {
      setState(() => _errorText = strings.passcodeCannotBeEmpty);
      return;
    }

    setState(() => _isUnlocking = true);
    final isUnlocked = await ref
        .read(startupUnlockSessionControllerProvider.notifier)
        .unlock(password);

    if (!mounted) {
      return;
    }

    if (!isUnlocked) {
      setState(() {
        _isUnlocking = false;
        _errorText = strings.unlockFailed;
      });
      return;
    }

    setState(() => _isUnlocking = false);
  }
}

class _LockLoadingView extends StatelessWidget {
  const _LockLoadingView();

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      child: Center(
        child: CupertinoActivityIndicator(),
      ),
    );
  }
}

class _LockErrorView extends StatelessWidget {
  const _LockErrorView({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
