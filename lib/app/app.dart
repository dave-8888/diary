import 'package:diary_mvp/app/localization/app_locale.dart';
import 'package:diary_mvp/app/localization/app_strings.dart';
import 'package:diary_mvp/app/router.dart';
import 'package:diary_mvp/app/startup_lock_gate.dart';
import 'package:diary_mvp/app/theme.dart';
import 'package:diary_mvp/app/window_identity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DiaryApp extends ConsumerWidget {
  const DiaryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(appLocaleProvider);
    final themeAsync = ref.watch(appThemeControllerProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => AppStrings.of(context).appTitle,
      theme: buildDiaryTheme(resolveThemePreset(themeAsync)),
      routerConfig: router,
      locale: locale,
      supportedLocales: AppStrings.supportedLocales,
      localeResolutionCallback: (localeValue, supportedLocales) {
        return AppStrings.resolveLocale(localeValue);
      },
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      builder: (context, child) {
        return WindowIdentitySync(
          child: AppStartupLockGate(
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
