import 'dart:io';

import 'package:diary_mvp/app/app_display_name.dart';
import 'package:diary_mvp/app/app_icon.dart';
import 'package:diary_mvp/app/localization/app_strings.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

bool get supportsNativeWindowIdentityCustomization => Platform.isWindows;

class WindowIdentitySync extends ConsumerStatefulWidget {
  const WindowIdentitySync({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<WindowIdentitySync> createState() => _WindowIdentitySyncState();
}

class _WindowIdentitySyncState extends ConsumerState<WindowIdentitySync> {
  static const MethodChannel _channel = MethodChannel(
    'diary_mvp/window_identity',
  );

  String? _lastTitle;
  String? _lastIconKey;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final title = resolveAppDisplayName(
      strings: strings,
      customNameAsync: ref.watch(appDisplayNameControllerProvider),
    );
    final iconSelection = resolveAppIconSelection(
      ref.watch(appIconControllerProvider),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncWindowIdentity(title: title, iconSelection: iconSelection);
    });

    return widget.child;
  }

  Future<void> _syncWindowIdentity({
    required String title,
    required AppIconSelection iconSelection,
  }) async {
    if (!mounted || !supportsNativeWindowIdentityCustomization) {
      return;
    }

    final normalizedIconPath = iconSelection.windowIconPath.trim();
    final normalizedIconKey =
        normalizedIconPath.isEmpty ? null : iconSelection.cacheKey;
    if (_lastTitle == title && _lastIconKey == normalizedIconKey) {
      return;
    }

    _lastTitle = title;
    _lastIconKey = normalizedIconKey;

    try {
      await _channel.invokeMethod<void>('applyWindowIdentity', {
        'title': title,
        'iconPath': normalizedIconPath,
      });
    } catch (_) {
      // Keep startup resilient if the native platform doesn't support updates.
    }
  }
}
