import 'package:diary_mvp/features/diary/presentation/pages/camera_capture_page.dart';
import 'package:diary_mvp/features/diary/presentation/pages/editor_page.dart';
import 'package:diary_mvp/features/diary/presentation/pages/home_page.dart';
import 'package:diary_mvp/features/diary/presentation/pages/timeline_page.dart';
import 'package:diary_mvp/features/diary/presentation/pages/video_preview_page.dart';
import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
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
        builder: (context, state) => EditorPage(
          entry: state.extra as DiaryEntry?,
        ),
      ),
      GoRoute(
        path: '/camera',
        builder: (context, state) => CameraCapturePage(
          initialMode: state.uri.queryParameters['mode'] == 'video'
              ? CameraCaptureMode.video
              : CameraCaptureMode.photo,
        ),
      ),
      GoRoute(
        path: '/timeline',
        builder: (context, state) => const TimelinePage(),
      ),
      GoRoute(
        path: '/video-preview',
        builder: (context, state) => VideoPreviewPage(
          media: state.extra as DiaryMedia?,
        ),
      ),
    ],
  );
});
