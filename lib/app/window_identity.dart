import 'dart:io';

import 'package:diary_mvp/app/app_display_name.dart';
import 'package:diary_mvp/app/app_icon.dart';
import 'package:diary_mvp/app/localization/app_strings.dart';
import 'package:diary_mvp/app/macos_build_identity_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

bool get supportsNativeWindowIdentityCustomization =>
    Platform.isWindows ||
    Platform.isMacOS ||
    Platform.environment.containsKey('FLUTTER_TEST');

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
  String? _lastBuildIconKey;
  bool? _lastPreferDarkFrame;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final preferDarkFrame = Theme.of(context).brightness == Brightness.dark;
    final title = resolveAppDisplayName(
      strings: strings,
      customNameAsync: ref.watch(appDisplayNameControllerProvider),
    );
    final iconSelection = resolveAppIconSelection(
      ref.watch(appIconControllerProvider),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncWindowIdentity(
        title: title,
        iconSelection: iconSelection,
        preferDarkFrame: preferDarkFrame,
      );
      _syncMacOSBuildIcon(iconSelection: iconSelection);
    });

    return widget.child;
  }

  Future<void> _syncWindowIdentity({
    required String title,
    required AppIconSelection iconSelection,
    required bool preferDarkFrame,
  }) async {
    if (!mounted || !supportsNativeWindowIdentityCustomization) {
      return;
    }

    final normalizedIconPath = iconSelection.windowIconPath.trim();
    final normalizedIconKey =
        normalizedIconPath.isEmpty ? null : iconSelection.cacheKey;
    final titleChanged = _lastTitle != title;
    final iconChanged = _lastIconKey != normalizedIconKey;
    final frameChanged = _lastPreferDarkFrame != preferDarkFrame;
    if (!titleChanged && !iconChanged && !frameChanged) {
      return;
    }

    try {
      final arguments = <String, Object?>{
        'title': title,
        'iconPath': normalizedIconPath,
        'preferDarkFrame': preferDarkFrame,
      };

      await _channel.invokeMethod<void>('applyWindowIdentity', arguments);
      _lastTitle = title;
      _lastIconKey = normalizedIconKey;
      _lastPreferDarkFrame = preferDarkFrame;
    } catch (_) {
      // Keep startup resilient if the native platform doesn't support updates.
    }
  }

  Future<void> _syncMacOSBuildIcon({
    required AppIconSelection iconSelection,
  }) async {
    if (!mounted || !Platform.isMacOS) {
      return;
    }

    final normalizedIconPath = iconSelection.windowIconPath.trim();
    final normalizedIconKey =
        normalizedIconPath.isEmpty ? null : iconSelection.cacheKey;
    if (normalizedIconKey == null || _lastBuildIconKey == normalizedIconKey) {
      return;
    }

    final service = ref.read(macosBuildIdentityServiceProvider);
    if (!service.canSyncBuildIcon) {
      return;
    }

    try {
      await service.applyBuildIcon(iconSelection);
      _lastBuildIconKey = normalizedIconKey;
    } catch (_) {
      // Keep startup resilient if the build resources can't be updated here.
    }
  }
}
