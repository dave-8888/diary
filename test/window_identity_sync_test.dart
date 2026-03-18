import 'package:diary_mvp/app/app_display_name.dart';
import 'package:diary_mvp/app/app_icon.dart';
import 'package:diary_mvp/app/localization/app_strings.dart';
import 'package:diary_mvp/app/window_identity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('diary_mvp/window_identity');

  testWidgets('sync sends preferDarkFrame and updates with theme changes',
      (tester) async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });

    final mode = ValueNotifier<ThemeMode>(ThemeMode.light);
    final fakeDisplayName = _FakeAppDisplayNameController('Diary Test');
    final fakeIcon = _FakeAppIconController(
      const AppIconSelection(
        mode: AppIconMode.preset,
        preset: AppIconPreset.orbital,
        windowIconPath: r'C:\icons\window_icon.png',
        revision: 1,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDisplayNameControllerProvider.overrideWith(() => fakeDisplayName),
          appIconControllerProvider.overrideWith(() => fakeIcon),
        ],
        child: _ThemeHost(mode: mode),
      ),
    );
    await tester.pumpAndSettle();

    final firstCall = calls.last;
    final firstArguments = firstCall.arguments! as Map<Object?, Object?>;
    expect(firstCall.method, 'applyWindowIdentity');
    expect(firstArguments['title'], 'Diary Test');
    expect(firstArguments['iconPath'], r'C:\icons\window_icon.png');
    expect(firstArguments['preferDarkFrame'], false);

    mode.value = ThemeMode.dark;
    await tester.pumpAndSettle();

    final secondCall = calls.last;
    final secondArguments = secondCall.arguments! as Map<Object?, Object?>;
    expect(secondCall.method, 'applyWindowIdentity');
    expect(secondArguments['preferDarkFrame'], true);
    expect(secondArguments['title'], 'Diary Test');
    expect(secondArguments['iconPath'], r'C:\icons\window_icon.png');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets(
      'sync keeps preferDarkFrame when title or icon changes trigger updates',
      (tester) async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });

    final mode = ValueNotifier<ThemeMode>(ThemeMode.dark);
    final fakeDisplayName = _FakeAppDisplayNameController('Diary Test');
    final fakeIcon = _FakeAppIconController(
      const AppIconSelection(
        mode: AppIconMode.preset,
        preset: AppIconPreset.orbital,
        windowIconPath: r'C:\icons\window_icon.png',
        revision: 1,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDisplayNameControllerProvider.overrideWith(() => fakeDisplayName),
          appIconControllerProvider.overrideWith(() => fakeIcon),
        ],
        child: _ThemeHost(mode: mode),
      ),
    );
    await tester.pumpAndSettle();
    calls.clear();

    fakeDisplayName.emit('Diary Renamed');
    await tester.pumpAndSettle();
    final titleCallArgs = calls.last.arguments! as Map<Object?, Object?>;
    expect(titleCallArgs['title'], 'Diary Renamed');
    expect(titleCallArgs['preferDarkFrame'], true);

    fakeIcon.emit(
      const AppIconSelection(
        mode: AppIconMode.custom,
        preset: AppIconPreset.orbital,
        windowIconPath: r'C:\icons\window_icon_new.png',
        revision: 2,
      ),
    );
    await tester.pumpAndSettle();
    final iconCallArgs = calls.last.arguments! as Map<Object?, Object?>;
    expect(iconCallArgs['iconPath'], r'C:\icons\window_icon_new.png');
    expect(iconCallArgs['preferDarkFrame'], true);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
}

class _ThemeHost extends StatelessWidget {
  const _ThemeHost({
    required this.mode,
  });

  final ValueNotifier<ThemeMode> mode;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: mode,
      builder: (context, themeMode, child) {
        return MaterialApp(
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: themeMode,
          supportedLocales: AppStrings.supportedLocales,
          locale: const Locale('en'),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: WindowIdentitySync(
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      child: const SizedBox.shrink(),
    );
  }
}

class _FakeAppDisplayNameController extends AppDisplayNameController {
  _FakeAppDisplayNameController(this._initialValue);

  final String? _initialValue;

  @override
  Future<String?> build() async {
    return _initialValue;
  }

  void emit(String? value) {
    state = AsyncData(value);
  }
}

class _FakeAppIconController extends AppIconController {
  _FakeAppIconController(this._initialValue);

  final AppIconSelection _initialValue;

  @override
  Future<AppIconSelection> build() async {
    return _initialValue;
  }

  void emit(AppIconSelection value) {
    state = AsyncData(value);
  }
}
