import 'package:diary_mvp/features/diary/presentation/pages/editor_page.dart';
import 'package:diary_mvp/features/diary/presentation/pages/home_page.dart';
import 'package:diary_mvp/features/diary/presentation/pages/timeline_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/editor',
        builder: (context, state) => const EditorPage(),
      ),
      GoRoute(
        path: '/timeline',
        builder: (context, state) => const TimelinePage(),
      ),
    ],
  );
});
