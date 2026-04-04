import 'package:diary_mvp/features/diary/presentation/pages/camera_capture_page.dart';
import 'package:diary_mvp/features/diary/presentation/pages/editor_page.dart';
import 'package:diary_mvp/features/diary/presentation/pages/home_page.dart';
import 'package:diary_mvp/features/diary/presentation/pages/image_preview_page.dart';
import 'package:diary_mvp/features/diary/presentation/pages/migration_page.dart';
import 'package:diary_mvp/features/diary/presentation/pages/settings_page.dart';
import 'package:diary_mvp/features/diary/presentation/pages/trash_page.dart';
import 'package:diary_mvp/features/diary/presentation/pages/trash_preview_page.dart';
import 'package:diary_mvp/features/diary/presentation/pages/timeline_page.dart';
import 'package:diary_mvp/features/diary/presentation/pages/video_preview_page.dart';
import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => _buildSectionPage(
          state: state,
          child: const HomePage(),
        ),
      ),
      GoRoute(
        path: '/editor',
        pageBuilder: (context, state) => _buildSectionPage(
          state: state,
          child: EditorPage(
            entry: state.extra as DiaryEntry?,
          ),
        ),
      ),
      GoRoute(
        path: '/migration',
        pageBuilder: (context, state) => _buildDetailPage(
          state: state,
          child: const MigrationPage(),
        ),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => _buildSectionPage(
          state: state,
          child: const SettingsPage(),
        ),
      ),
      GoRoute(
        path: '/camera',
        pageBuilder: (context, state) => _buildDetailPage(
          state: state,
          child: CameraCapturePage(
            initialMode: state.uri.queryParameters['mode'] == 'video'
                ? CameraCaptureMode.video
                : CameraCaptureMode.photo,
          ),
        ),
      ),
      GoRoute(
        path: '/timeline',
        pageBuilder: (context, state) => _buildSectionPage(
          state: state,
          child: const TimelinePage(),
        ),
      ),
      GoRoute(
        path: '/trash',
        pageBuilder: (context, state) => _buildSectionPage(
          state: state,
          child: const TrashPage(),
        ),
        routes: [
          GoRoute(
            path: 'preview',
            pageBuilder: (context, state) => _buildDetailPage(
              state: state,
              child: TrashPreviewPage(
                entry: state.extra as DiaryEntry?,
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/video-preview',
        pageBuilder: (context, state) => _buildDetailPage(
          state: state,
          child: VideoPreviewPage(
            media: state.extra as DiaryMedia?,
          ),
        ),
      ),
      GoRoute(
        path: '/image-preview',
        pageBuilder: (context, state) => _buildDetailPage(
          state: state,
          child: ImagePreviewPage(
            media: state.extra as DiaryMedia?,
          ),
        ),
      ),
    ],
  );
});

CustomTransitionPage<void> _buildSectionPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 180),
    reverseTransitionDuration: const Duration(milliseconds: 140),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: Tween<double>(
          begin: 0.76,
          end: 1,
        ).animate(curvedAnimation),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.018),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        ),
      );
    },
  );
}

CustomTransitionPage<void> _buildDetailPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 170),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: Tween<double>(
          begin: 0.7,
          end: 1,
        ).animate(curvedAnimation),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.015, 0.02),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        ),
      );
    },
  );
}
