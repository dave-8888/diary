import 'package:diary_mvp/app/localization/app_strings.dart';
import 'package:diary_mvp/features/diary/services/password_settings.dart';
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

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            margin: const EdgeInsets.all(24),
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
                  TextField(
                    key: const ValueKey('startup-passcode-field'),
                    controller: _passwordController,
                    obscureText: !_showPassword,
                    autofocus: true,
                    keyboardType: TextInputType.visiblePassword,
                    enableSuggestions: false,
                    autocorrect: false,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: strings.passcodeLabel,
                      hintText: strings.passcodeHint,
                      errorText: _errorText,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() => _showPassword = !_showPassword);
                        },
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                    onSubmitted: (_) => _unlock(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isUnlocking ? null : _unlock,
                      child: _isUnlocking
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(strings.unlockAction),
                    ),
                  ),
                ],
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
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
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
    return Scaffold(
      body: Center(
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
