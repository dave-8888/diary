import 'package:diary_mvp/app/router.dart';
import 'package:diary_mvp/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DiaryApp extends ConsumerWidget {
  const DiaryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Diary MVP',
      theme: buildDiaryTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
