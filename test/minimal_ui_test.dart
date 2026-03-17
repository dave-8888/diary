import 'dart:io';

import 'package:diary_mvp/app/app_display_name.dart';
import 'package:diary_mvp/app/app_icon.dart';
import 'package:diary_mvp/app/localization/app_locale.dart';
import 'package:diary_mvp/app/localization/app_strings.dart';
import 'package:diary_mvp/app/theme.dart';
import 'package:diary_mvp/features/diary/data/diary_repository.dart';
import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
import 'package:diary_mvp/features/diary/presentation/pages/editor_page.dart';
import 'package:diary_mvp/features/diary/presentation/pages/home_page.dart';
import 'package:diary_mvp/features/diary/presentation/pages/image_preview_page.dart';
import 'package:diary_mvp/features/diary/presentation/pages/settings_page.dart';
import 'package:diary_mvp/features/diary/services/diary_ai_settings.dart';
import 'package:diary_mvp/features/diary/services/transcription_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  const strings = AppStrings(Locale('en'));

  testWidgets('home page uses compact tag filter chips', (tester) async {
    final repository = FakeDiaryRepository(
      entries: [
        DiaryEntry(
          id: '1',
          title: 'Park walk',
          content: 'A calm afternoon.',
          mood: DiaryMood.calm,
          createdAt: DateTime(2026, 3, 17, 9),
          tags: const ['#life'],
        ),
      ],
      tags: const ['#life'],
    );

    await pumpPage(
      tester,
      const HomePage(),
      path: '/',
      overrides: buildOverrides(repository: repository),
    );

    expect(find.text(strings.filterByTag), findsNothing);
    expect(find.text(strings.entryCountLabel(1)), findsOneWidget);
    expect(find.text(strings.tagStatusLabel(null)), findsOneWidget);
    expect(find.text('#life'), findsWidgets);
  });

  testWidgets('editor page keeps AI available and hides empty video panel',
      (tester) async {
    final repository = FakeDiaryRepository(
      moods: DiaryMood.values,
    );

    await pumpPage(
      tester,
      const EditorPage(),
      path: '/editor',
      overrides: buildOverrides(repository: repository),
    );

    await tester.scrollUntilVisible(
      find.text(strings.diaryAiToolsTitle),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text(strings.diaryAiToolsTitle), findsOneWidget);
    expect(find.text(strings.analyzeDiaryWithAi), findsOneWidget);
    expect(find.text(strings.noAiSuggestionYet), findsNothing);
    expect(find.text(strings.videoSidebarTitle), findsNothing);
  });

  testWidgets('editor page restores saved AI analysis in the requested order',
      (tester) async {
    final repository = FakeDiaryRepository(
      moods: DiaryMood.values,
    );
    final analyzedAt = DateTime(2026, 3, 17, 20, 30);

    await pumpPage(
      tester,
      EditorPage(
        entry: DiaryEntry(
          id: 'entry-with-ai',
          title: 'With AI',
          content: 'A reflective day.',
          mood: DiaryMood.calm,
          createdAt: DateTime(2026, 3, 17, 11),
          aiAnalysis: DiaryEntryAiAnalysis(
            overviewText: 'Evening walk\nI finally slowed down and breathed.',
            suggestedTags: const ['#walk', '#relax'],
            emotionalSupportText: 'You gave yourself some room to rest.',
            questionSuggestionText: 'Try protecting one quiet hour tonight.',
            analyzedAt: analyzedAt,
          ),
        ),
      ),
      path: '/editor',
      overrides: buildOverrides(repository: repository),
    );

    await tester.scrollUntilVisible(
      find.text(strings.diaryAiToolsTitle),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text(strings.reanalyzeDiaryWithAi), findsOneWidget);
    expect(find.text(strings.aiAnalyzedAtLabel(analyzedAt)), findsOneWidget);
    expect(find.text(strings.aiOverviewSectionTitle), findsOneWidget);
    expect(
      find.text('Evening walk\nI finally slowed down and breathed.'),
      findsOneWidget,
    );
    expect(find.text('You gave yourself some room to rest.'), findsOneWidget);
    expect(find.text('Try protecting one quiet hour tonight.'), findsOneWidget);
    expect(find.text('#walk'), findsOneWidget);

    final aiCard = find
        .ancestor(
          of: find.text(strings.diaryAiToolsTitle),
          matching: find.byType(Card),
        )
        .first;
    final titleRect = tester.getRect(find.text(strings.diaryAiToolsTitle));
    final tooltipRect = tester.getRect(
      find.descendant(
        of: aiCard,
        matching: find.byIcon(Icons.info_outline),
      ),
    );
    expect(tooltipRect.left - titleRect.right, lessThan(24));

    final overviewY =
        tester.getTopLeft(find.text(strings.aiOverviewSectionTitle)).dy;
    final companionY =
        tester.getTopLeft(find.text(strings.emotionalCompanionSectionTitle)).dy;
    final tipsY =
        tester.getTopLeft(find.text(strings.problemSuggestionSectionTitle)).dy;
    final tagsY = tester.getTopLeft(find.text(strings.aiSuggestedTagsLabel)).dy;

    expect(overviewY, lessThan(companionY));
    expect(companionY, lessThan(tipsY));
    expect(tipsY, lessThan(tagsY));
  });

  testWidgets('editor page hides analysis time for legacy AI analysis',
      (tester) async {
    final repository = FakeDiaryRepository(
      moods: DiaryMood.values,
    );

    await pumpPage(
      tester,
      EditorPage(
        entry: DiaryEntry(
          id: 'legacy-ai-entry',
          title: 'Legacy AI',
          content: 'Old analysis without a timestamp.',
          mood: DiaryMood.calm,
          createdAt: DateTime(2026, 3, 17, 9),
          aiAnalysis: const DiaryEntryAiAnalysis(
            overviewText: 'Legacy summary',
            suggestedTags: ['#legacy'],
          ),
        ),
      ),
      path: '/editor',
      overrides: buildOverrides(repository: repository),
    );

    await tester.scrollUntilVisible(
      find.text(strings.diaryAiToolsTitle),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text(strings.reanalyzeDiaryWithAi), findsOneWidget);
    expect(find.textContaining('Last analyzed:'), findsNothing);
  });

  testWidgets('settings page keeps advanced sections collapsed by default',
      (tester) async {
    final repository = FakeDiaryRepository(
      moods: DiaryMood.values,
    );

    await pumpPage(
      tester,
      const SettingsPage(),
      path: '/settings',
      overrides: buildOverrides(repository: repository),
    );

    expect(find.text(strings.currentWindowIcon), findsNothing);
    expect(find.text(strings.aliyunApiKeyLabel), findsNothing);
    expect(find.text(strings.openAiApiKeyLabel), findsNothing);

    await tester.scrollUntilVisible(
      find.text(strings.diaryAiSettingsTitle),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(strings.diaryAiSettingsTitle));
    await tester.pumpAndSettle();
    expect(find.text(strings.aliyunApiKeyLabel), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text(strings.transcriptionSettingsTitle),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(strings.transcriptionSettingsTitle));
    await tester.pumpAndSettle();
    expect(find.text(strings.openAiApiKeyLabel), findsOneWidget);
  });

  testWidgets('editor images open the dedicated preview page', (tester) async {
    final repository = FakeDiaryRepository(
      moods: DiaryMood.values,
    );
    final imagePath =
        '${Directory.systemTemp.path}${Platform.pathSeparator}missing_preview_image.png';

    await pumpPage(
      tester,
      EditorPage(
        entry: DiaryEntry(
          id: 'entry-with-image',
          title: 'With image',
          content: 'Preview this photo.',
          mood: DiaryMood.calm,
          createdAt: DateTime(2026, 3, 17, 10),
          media: [
            DiaryMedia(
              id: 'image-1',
              type: MediaType.image,
              path: imagePath,
            ),
          ],
        ),
      ),
      path: '/editor',
      overrides: buildOverrides(repository: repository),
    );

    await tester.tap(find.byKey(const ValueKey('image-media-tile-image-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(strings.imagePreviewPageTitle), findsOneWidget);
    expect(find.text(strings.previewPhoto), findsOneWidget);
  });
}

Future<void> pumpPage(
  WidgetTester tester,
  Widget child, {
  required String path,
  required List<Override> overrides,
}) async {
  final router = GoRouter(
    initialLocation: path,
    routes: [
      GoRoute(path: '/', builder: (context, state) => child),
      GoRoute(path: '/editor', builder: (context, state) => child),
      GoRoute(path: '/settings', builder: (context, state) => child),
      GoRoute(path: '/timeline', builder: (context, state) => child),
      GoRoute(path: '/trash', builder: (context, state) => child),
      GoRoute(path: '/migration', builder: (context, state) => child),
      GoRoute(
        path: '/image-preview',
        builder: (context, state) => ImagePreviewPage(
          media: state.extra as DiaryMedia?,
        ),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        routerConfig: router,
        theme: buildDiaryTheme(DiaryThemePreset.daylight),
        supportedLocales: AppStrings.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
      ),
    ),
  );

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

List<Override> buildOverrides({
  required FakeDiaryRepository repository,
}) {
  return [
    diaryRepositoryProvider.overrideWith((ref) => repository),
    appThemeStorageProvider.overrideWith(
      (ref) => FakeAppThemeStorage(DiaryThemePreset.daylight),
    ),
    appIconStorageProvider.overrideWith(
      (ref) => FakeAppIconStorage(
        const AppIconSelection(
          mode: AppIconMode.preset,
          preset: AppIconPreset.orbital,
          windowIconPath: '',
          revision: 0,
        ),
      ),
    ),
    appDisplayNameStorageProvider.overrideWith(
      (ref) => FakeAppDisplayNameStorage('Diary'),
    ),
    appLanguageStorageProvider.overrideWith(
      (ref) => FakeAppLanguageStorage(AppLanguage.english),
    ),
    diaryAiSettingsStorageProvider.overrideWith(
      (ref) => FakeDiaryAiSettingsStorage(),
    ),
    diaryAiApiKeyStorageProvider.overrideWith(
      (ref) => FakeDiaryAiSettingsStorage(),
    ),
    transcriptionApiKeyStorageProvider.overrideWith(
      (ref) => FakeTranscriptionApiKeyStorage(),
    ),
  ];
}

class FakeDiaryRepository implements DiaryRepository {
  FakeDiaryRepository({
    List<DiaryEntry>? entries,
    List<DiaryEntry>? trashedEntries,
    List<String>? tags,
    List<DiaryMood>? moods,
  })  : _entries = entries ?? const [],
        _trashedEntries = trashedEntries ?? const [],
        _tags = tags ?? const [],
        _moods = moods ?? DiaryMood.values;

  final List<DiaryEntry> _entries;
  final List<DiaryEntry> _trashedEntries;
  final List<String> _tags;
  final List<DiaryMood> _moods;

  @override
  Future<DiaryEntry> createEntry({
    required String title,
    required String content,
    required DiaryMood mood,
    required String location,
    required List<String> tags,
    required List<DiaryMedia> media,
    DiaryEntryAiAnalysis? aiAnalysis,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteEntry(String id) async {}

  @override
  Future<List<DiaryEntry>> listEntries() async => _entries;

  @override
  Future<List<DiaryMood>> listMoodLibrary() async => _moods;

  @override
  Future<List<String>> listTagLibrary() async => _tags;

  @override
  Future<List<DiaryEntry>> listTrashedEntries() async => _trashedEntries;

  @override
  Future<void> resetMoodLibraryToDefaults() async {}

  @override
  Future<void> saveEntry(DiaryEntry entry) async {}

  @override
  Future<void> saveMood(DiaryMood mood) async {}

  @override
  Future<void> saveTag(String tag) async {}

  @override
  Future<DiaryEntry> updateEntry({
    required DiaryEntry entry,
    required String title,
    required String content,
    required DiaryMood mood,
    required String location,
    required List<String> tags,
    required List<DiaryMedia> media,
    DiaryEntryAiAnalysis? aiAnalysis,
  }) async {
    return entry;
  }

  @override
  Future<void> deleteTag(String tag) async {}
}

class FakeAppThemeStorage extends AppThemeStorage {
  FakeAppThemeStorage(this.value);

  final DiaryThemePreset value;

  @override
  Future<DiaryThemePreset> read() async => value;

  @override
  Future<void> write(DiaryThemePreset theme) async {}
}

class FakeAppIconStorage extends AppIconStorage {
  FakeAppIconStorage(this.selection);

  final AppIconSelection selection;

  @override
  Future<AppIconSelection> read() async => selection;

  @override
  Future<AppIconSelection> reset() async => selection;

  @override
  Future<AppIconSelection> writeCustomImage(String sourcePath) async =>
      selection;

  @override
  Future<AppIconSelection> writePreset(AppIconPreset preset) async => selection;
}

class FakeAppDisplayNameStorage extends AppDisplayNameStorage {
  FakeAppDisplayNameStorage(this.value);

  final String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String? value) async {}
}

class FakeAppLanguageStorage extends AppLanguageStorage {
  FakeAppLanguageStorage(this.value);

  final AppLanguage value;

  @override
  Future<AppLanguage> read() async => value;

  @override
  Future<void> write(AppLanguage language) async {}
}

class FakeDiaryAiSettingsStorage extends DiaryAiSettingsStorage {
  @override
  Future<String?> read() async => null;

  @override
  Future<bool> readEmotionalCompanionVisibility() async => true;

  @override
  Future<bool> readProblemSuggestionVisibility() async => true;

  @override
  Future<bool> readVisibility() async => true;

  @override
  Future<void> write(String? apiKey) async {}

  @override
  Future<void> writeEmotionalCompanionVisibility(bool enabled) async {}

  @override
  Future<void> writeProblemSuggestionVisibility(bool enabled) async {}

  @override
  Future<void> writeVisibility(bool enabled) async {}
}

class FakeTranscriptionApiKeyStorage extends TranscriptionApiKeyStorage {
  @override
  Future<String?> read() async => null;

  @override
  Future<void> write(String? apiKey) async {}
}
