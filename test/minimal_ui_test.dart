import 'dart:io';

import 'package:diary_mvp/app/app_display_name.dart';
import 'package:diary_mvp/app/app_icon.dart';
import 'package:diary_mvp/app/localization/app_locale.dart';
import 'package:diary_mvp/app/localization/app_strings.dart';
import 'package:diary_mvp/app/startup_lock_gate.dart';
import 'package:diary_mvp/app/theme.dart';
import 'package:diary_mvp/features/diary/data/diary_repository.dart';
import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
import 'package:diary_mvp/features/diary/presentation/pages/editor_page.dart';
import 'package:diary_mvp/features/diary/presentation/pages/home_page.dart';
import 'package:diary_mvp/features/diary/presentation/pages/image_preview_page.dart';
import 'package:diary_mvp/features/diary/presentation/pages/settings_page.dart';
import 'package:diary_mvp/features/diary/presentation/pages/timeline_page.dart';
import 'package:diary_mvp/features/diary/presentation/pages/trash_page.dart';
import 'package:diary_mvp/features/diary/presentation/pages/video_preview_page.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/entry_list_preview.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/entry_readonly_view.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/image_media_grid.dart';
import 'package:diary_mvp/features/diary/presentation/widgets/tag_multi_select_dropdown.dart';
import 'package:diary_mvp/features/diary/services/diary_ai_settings.dart';
import 'package:diary_mvp/features/diary/services/diary_list_settings.dart';
import 'package:diary_mvp/features/diary/services/password_settings.dart';
import 'package:diary_mvp/features/diary/services/transcription_settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  const strings = AppStrings(Locale('en'));

  testWidgets('shared tag dropdown keeps label above empty placeholder',
      (tester) async {
    List<String> selectedTags = const <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(24),
                child: TagMultiSelectDropdown(
                  labelText: strings.filterByTag,
                  hintText: strings.allTags,
                  searchHintText: strings.searchTags,
                  clearSelectionText: strings.clearSelection,
                  noResultsText: strings.noMatchingTags,
                  options: const ['#life', '#work'],
                  selectedValues: selectedTags,
                  onSelectionChanged: (next) {
                    setState(() => selectedTags = next);
                  },
                ),
              ),
            );
          },
        ),
      ),
    );

    final labelFinder = find.text(strings.filterByTag);
    final hintFinder = find.text(strings.allTags);

    expect(labelFinder, findsOneWidget);
    expect(hintFinder, findsOneWidget);

    final labelRect = tester.getRect(labelFinder);
    final hintRect = tester.getRect(hintFinder);
    expect(labelRect.bottom, lessThan(hintRect.top));

    await tester.tap(hintFinder);
    await tester.pumpAndSettle();
    await tester.tap(find.text('#life'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.expand_less_rounded));
    await tester.pumpAndSettle();

    expect(find.text(strings.allTags), findsNothing);
    expect(find.text('#life'), findsOneWidget);
  });

  testWidgets('home page hides tag filter and keeps entry list visible',
      (tester) async {
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
    expect(find.text('#life'), findsWidgets);
  });

  testWidgets(
      'home page places the date filter to the right of the diary list on wide layouts',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FakeDiaryRepository(
      entries: [
        for (var index = 0; index < 12; index++)
          DiaryEntry(
            id: 'wide-layout-entry-$index',
            title: 'Wide layout $index',
            content: 'Desktop home page should split into two columns.',
            mood: DiaryMood.calm,
            createdAt: DateTime(2026, 3, 18, 9).subtract(
              Duration(days: index),
            ),
          ),
      ],
      moods: DiaryMood.values,
    );

    await pumpPage(
      tester,
      const HomePage(),
      path: '/',
      overrides: buildOverrides(repository: repository),
    );

    final listPanel = find.byKey(const ValueKey('home-entry-list-panel'));
    final countPill = find.byKey(const ValueKey('home-entry-count-pill'));
    final filterPanel =
        find.byKey(const ValueKey('home-calendar-filter-panel'));
    final rightSidebar = find.byKey(const ValueKey('home-right-sidebar'));
    final scrollView = find.byKey(const ValueKey('home-entry-scroll-view'));

    expect(listPanel, findsOneWidget);
    expect(countPill, findsOneWidget);
    expect(filterPanel, findsOneWidget);
    expect(rightSidebar, findsOneWidget);
    expect(scrollView, findsOneWidget);

    final listRect = tester.getRect(listPanel);
    final sidebarRect = tester.getRect(rightSidebar);
    final countRect = tester.getRect(countPill);
    final filterRect = tester.getRect(filterPanel);

    expect((listRect.top - sidebarRect.top).abs(), lessThan(1));
    expect(listRect.right, lessThan(sidebarRect.left));
    expect(listRect.right, lessThan(countRect.left));
    expect(countRect.bottom, lessThan(filterRect.top));

    final sidebarTopBeforeScroll = sidebarRect.top;
    await tester.drag(scrollView, const Offset(0, -400));
    await tester.pumpAndSettle();

    final sidebarRectAfterScroll = tester.getRect(rightSidebar);
    expect(sidebarRectAfterScroll.top, sidebarTopBeforeScroll);
  });

  testWidgets(
      'editor page keeps AI available, removes transcription, and hides empty video panel',
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
    expect(find.text(strings.transcribeLatestAudio), findsNothing);
  });

  testWidgets(
      'editor page keeps images and video in one media grid with overlay metadata',
      (tester) async {
    final repository = FakeDiaryRepository(
      moods: DiaryMood.values,
    );
    final capturedAt = DateTime(2026, 3, 18, 21, 5);

    await pumpPage(
      tester,
      EditorPage(
        entry: DiaryEntry(
          id: 'entry-with-visual-media',
          title: 'Visual media',
          content: 'One image and one video should stay together.',
          mood: DiaryMood.calm,
          createdAt: DateTime(2026, 3, 18, 9),
          media: [
            DiaryMedia(
              id: 'image-1',
              type: MediaType.image,
              path:
                  '${Directory.systemTemp.path}${Platform.pathSeparator}missing_editor_image_1.png',
            ),
            DiaryMedia(
              id: 'video-1',
              type: MediaType.video,
              path:
                  '${Directory.systemTemp.path}${Platform.pathSeparator}missing_editor_video_1.mp4',
              capturedAt: capturedAt,
              durationLabel: '00:23',
            ),
          ],
        ),
      ),
      path: '/editor',
      overrides: buildOverrides(repository: repository),
    );

    final imageTile = find.byKey(const ValueKey('image-media-tile-image-1'));
    final videoTile = find.byKey(const ValueKey('video-media-tile-video-1'));

    expect(imageTile, findsOneWidget);
    expect(videoTile, findsOneWidget);
    expect(find.text(strings.videoSidebarTitle), findsNothing);
    expect(
      find.descendant(
        of: videoTile,
        matching: find.text(strings.formatDateTime(capturedAt)),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: videoTile,
        matching: find.text('00:23'),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.descendant(
        of: videoTile,
        matching: find.byIcon(Icons.close_rounded),
      ),
    );
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('video-media-tile-video-1')), findsNothing);
    expect(
        find.byKey(const ValueKey('image-media-tile-image-1')), findsOneWidget);
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

  testWidgets(
      'editor page keeps AI actions aligned right and shows created time',
      (tester) async {
    final repository = FakeDiaryRepository(
      moods: DiaryMood.values,
    );
    final createdAt = DateTime(2026, 3, 16, 7, 45);

    await pumpPage(
      tester,
      EditorPage(
        entry: DiaryEntry(
          id: 'entry-layout-check',
          title: 'Layout check',
          content: 'Check the editor header layout.',
          mood: DiaryMood.calm,
          createdAt: createdAt,
          aiAnalysis: const DiaryEntryAiAnalysis(
            overviewText: 'Layout ready',
          ),
        ),
      ),
      path: '/editor',
      overrides: buildOverrides(repository: repository),
    );

    expect(
      find.text(
        '${strings.createdAtLabel} · ${strings.formatDateTime(createdAt)}',
      ),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.text(strings.diaryAiToolsTitle),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final aiCard = find
        .ancestor(
          of: find.text(strings.diaryAiToolsTitle),
          matching: find.byType(Card),
        )
        .first;
    final expandIcon = find.descendant(
      of: aiCard,
      matching: find.byIcon(Icons.expand_less),
    );
    final actionButton = find
        .ancestor(
          of: find.text(strings.reanalyzeDiaryWithAi),
          matching: find.byType(FilledButton),
        )
        .first;
    final cardRect = tester.getRect(aiCard);
    final expandRect = tester.getRect(expandIcon);
    final buttonRect = tester.getRect(actionButton);

    expect(buttonRect.left, greaterThan(expandRect.right));
    expect(cardRect.right - buttonRect.right, lessThan(32));
  });

  testWidgets('editor page adds tags on submit without add button',
      (tester) async {
    final repository = FakeDiaryRepository(
      moods: DiaryMood.values,
      tags: const ['#existing'],
    );

    await pumpPage(
      tester,
      const EditorPage(),
      path: '/editor',
      overrides: buildOverrides(repository: repository),
    );

    expect(find.text(strings.addTag), findsNothing);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('editor-tag-input')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('editor-tag-input')));
    await tester.enterText(
      find.byKey(const ValueKey('editor-tag-input')),
      'focus',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('#focus'), findsWidgets);
  });

  testWidgets('editor page removes reusable tag controls', (tester) async {
    final repository = FakeDiaryRepository(
      moods: DiaryMood.values,
      tags: const ['#existing'],
    );

    await pumpPage(
      tester,
      const EditorPage(),
      path: '/editor',
      overrides: buildOverrides(repository: repository),
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('editor-tag-input')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.byType(TagMultiSelectDropdown), findsNothing);
    expect(find.text(strings.tagLibraryLabel), findsNothing);
    expect(find.text(strings.selectedTagsLabel), findsOneWidget);
  });

  testWidgets('editor page lets users apply AI suggested tags', (tester) async {
    final repository = FakeDiaryRepository(
      moods: DiaryMood.values,
    );

    await pumpPage(
      tester,
      EditorPage(
        entry: DiaryEntry(
          id: 'ai-tag-entry',
          title: 'AI tags',
          content: 'Suggestions should be tappable.',
          mood: DiaryMood.calm,
          createdAt: DateTime(2026, 3, 19, 8),
          aiAnalysis: const DiaryEntryAiAnalysis(
            overviewText: 'Suggested focus tags.',
            suggestedTags: ['focus'],
          ),
        ),
      ),
      path: '/editor',
      overrides: buildOverrides(repository: repository),
    );

    await tester.scrollUntilVisible(
      find.text('#focus'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('#focus'), findsOneWidget);

    await tester.tap(find.text('#focus'));
    await tester.pumpAndSettle();

    expect(find.text('#focus'), findsNWidgets(2));
  });

  testWidgets('saving an entry keeps the editor page open', (tester) async {
    final repository = FakeDiaryRepository(
      moods: DiaryMood.values,
    );

    await pumpPage(
      tester,
      const EditorPage(),
      path: '/editor',
      overrides: buildOverrides(repository: repository),
    );

    await tester.enterText(find.byType(TextField).at(0), 'Saved draft');
    await tester.enterText(find.byType(TextField).at(1), 'Keep me here.');
    await tester.tap(find.byIcon(Icons.save_outlined));
    await tester.pumpAndSettle();

    expect(find.text(strings.whatHappenedToday), findsOneWidget);
    expect(find.text(strings.entrySaved), findsOneWidget);
    expect((await repository.listEntries()).length, 1);
  });

  testWidgets('editor page saves with Ctrl+S', (tester) async {
    final repository = FakeDiaryRepository(
      moods: DiaryMood.values,
    );

    await pumpPage(
      tester,
      const EditorPage(),
      path: '/editor',
      overrides: buildOverrides(repository: repository),
    );

    await tester.tap(find.byType(TextField).at(0));
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(0), 'Shortcut save');
    await tester.enterText(
        find.byType(TextField).at(1), 'Saved from keyboard.');

    await pressControlShortcut(tester, LogicalKeyboardKey.keyS);
    await tester.pumpAndSettle();

    expect(find.text(strings.entrySaved), findsOneWidget);
    expect((await repository.listEntries()).length, 1);
  });

  testWidgets('editor page undoes text edits with Ctrl+Z', (tester) async {
    final repository = FakeDiaryRepository(
      moods: DiaryMood.values,
    );

    await pumpPage(
      tester,
      const EditorPage(),
      path: '/editor',
      overrides: buildOverrides(repository: repository),
    );

    final titleField = find.byType(TextField).at(0);
    await tester.tap(titleField);
    await tester.pump();
    await tester.enterText(titleField, 'Undo me');
    await tester.pump();

    expect(editableTextController(tester, 0).text, 'Undo me');

    await pressControlShortcut(tester, LogicalKeyboardKey.keyZ);
    await tester.pump();

    expect(editableTextController(tester, 0).text, isEmpty);
  });

  testWidgets('saving a new entry twice updates the same entry',
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

    await tester.enterText(find.byType(TextField).at(0), 'Saved draft');
    await tester.enterText(find.byType(TextField).at(1), 'Keep me here.');
    await tester.tap(find.byIcon(Icons.save_outlined));
    await tester.pumpAndSettle();

    expect((await repository.listEntries()).length, 1);

    await tester.tap(find.byIcon(Icons.save_outlined));
    await tester.pumpAndSettle();

    expect(find.text(strings.entryUpdated), findsOneWidget);
    expect((await repository.listEntries()).length, 1);
  });

  testWidgets('editor page warns before switching pages with unsaved changes',
      (tester) async {
    final repository = FakeDiaryRepository(
      moods: DiaryMood.values,
    );

    await pumpEditorNavigationApp(
      tester,
      initialLocation: '/editor',
      overrides: buildOverrides(repository: repository),
    );

    await tester.enterText(find.byType(TextField).at(0), 'Unsaved draft');
    await tester.tap(find.text(strings.homeNav));
    await tester.pumpAndSettle();

    expect(find.text(strings.unsavedChangesTitle), findsOneWidget);
    expect(find.text(strings.unsavedChangesMessage), findsOneWidget);

    await tester.tap(find.text(strings.stayOnPage));
    await tester.pumpAndSettle();
    expect(find.text(strings.whatHappenedToday), findsOneWidget);

    await tester.tap(find.text(strings.homeNav));
    await tester.pumpAndSettle();
    await tester.tap(find.text(strings.leaveWithoutSaving));
    await tester.pumpAndSettle();

    expect(find.text(strings.unsavedChangesTitle), findsNothing);
    expect(find.text(strings.recentEntries), findsOneWidget);
  });

  testWidgets('home page keeps only the first image and video on one media row',
      (tester) async {
    final content = List.filled(
      24,
      'A long reflection that should wrap across several lines.',
    ).join(' ');
    final repository = FakeDiaryRepository(
      entries: [
        DiaryEntry(
          id: 'both',
          title: 'Mixed media',
          content: content,
          mood: DiaryMood.calm,
          createdAt: DateTime(2026, 3, 18, 9),
          tags: const ['#mixed'],
          media: [
            DiaryMedia(
              id: 'image-1',
              type: MediaType.image,
              path:
                  '${Directory.systemTemp.path}${Platform.pathSeparator}missing_compact_image_1.png',
            ),
            DiaryMedia(
              id: 'image-2',
              type: MediaType.image,
              path:
                  '${Directory.systemTemp.path}${Platform.pathSeparator}missing_compact_image_2.png',
            ),
            DiaryMedia(
              id: 'video-1',
              type: MediaType.video,
              path:
                  '${Directory.systemTemp.path}${Platform.pathSeparator}missing_compact_video_1.mp4',
              capturedAt: DateTime(2026, 2, 1, 14, 30),
              durationLabel: '00:42',
            ),
            DiaryMedia(
              id: 'video-2',
              type: MediaType.video,
              path:
                  '${Directory.systemTemp.path}${Platform.pathSeparator}missing_compact_video_2.mp4',
            ),
          ],
        ),
        DiaryEntry(
          id: 'single',
          title: 'Single media',
          content: content,
          mood: DiaryMood.happy,
          createdAt: DateTime(2026, 3, 17, 9),
          tags: const ['#single'],
          media: [
            DiaryMedia(
              id: 'image-3',
              type: MediaType.image,
              path:
                  '${Directory.systemTemp.path}${Platform.pathSeparator}missing_compact_image_3.png',
            ),
          ],
        ),
      ],
      moods: DiaryMood.values,
    );

    await pumpPage(
      tester,
      const HomePage(),
      path: '/',
      overrides: buildOverrides(repository: repository),
    );

    expect(find.byKey(const ValueKey('entry-compact-image-image-1')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('entry-compact-image-image-2')),
        findsNothing);
    expect(find.byKey(const ValueKey('entry-compact-video-video-1')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('entry-compact-video-video-2')),
        findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('entry-compact-video-video-1')),
        matching: find.text('2026-02-01'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('entry-compact-video-video-1')),
        matching: find.text('00:42'),
      ),
      findsOneWidget,
    );
    final imageRect = tester.getRect(
      find.byKey(const ValueKey('entry-compact-image-image-1')),
    );
    final videoRect = tester.getRect(
      find.byKey(const ValueKey('entry-compact-video-video-1')),
    );

    final bothContent = tester.widget<Text>(
      find.byKey(
        const ValueKey('entry-content-preview-both'),
        skipOffstage: false,
      ),
    );
    final singleContent = tester.widget<Text>(
      find.byKey(
        const ValueKey('entry-content-preview-single'),
        skipOffstage: false,
      ),
    );

    expect((imageRect.top - videoRect.top).abs(), lessThan(1));
    expect(imageRect.right, lessThan(videoRect.left));
    expect(bothContent.maxLines, singleContent.maxLines);
  });

  testWidgets('timeline page uses the same one-row media layout',
      (tester) async {
    final repository = FakeDiaryRepository(
      entries: [
        DiaryEntry(
          id: 'timeline-entry',
          title: 'Timeline media',
          content: 'Timeline should also keep media on one line.',
          mood: DiaryMood.calm,
          createdAt: DateTime(2026, 3, 18, 9),
          media: [
            DiaryMedia(
              id: 'timeline-image-1',
              type: MediaType.image,
              path:
                  '${Directory.systemTemp.path}${Platform.pathSeparator}missing_timeline_image_1.png',
            ),
            DiaryMedia(
              id: 'timeline-video-1',
              type: MediaType.video,
              path:
                  '${Directory.systemTemp.path}${Platform.pathSeparator}missing_timeline_video_1.mp4',
            ),
          ],
        ),
      ],
      moods: DiaryMood.values,
    );

    await pumpPage(
      tester,
      const TimelinePage(),
      path: '/timeline',
      overrides: buildOverrides(repository: repository),
    );

    final imageRect = tester.getRect(
      find.byKey(const ValueKey('entry-compact-image-timeline-image-1')),
    );
    final videoRect = tester.getRect(
      find.byKey(const ValueKey('entry-compact-video-timeline-video-1')),
    );

    expect((imageRect.top - videoRect.top).abs(), lessThan(1));
    expect(imageRect.right, lessThan(videoRect.left));
  });

  testWidgets(
      'home page hides image and video previews when diary list media is disabled',
      (tester) async {
    final repository = FakeDiaryRepository(
      entries: [
        DiaryEntry(
          id: 'hidden-media-entry',
          title: 'Hidden media',
          content: 'Only text should remain in the list preview.',
          mood: DiaryMood.calm,
          createdAt: DateTime(2026, 3, 18, 9),
          media: [
            DiaryMedia(
              id: 'hidden-image-1',
              type: MediaType.image,
              path:
                  '${Directory.systemTemp.path}${Platform.pathSeparator}missing_hidden_image_1.png',
            ),
            DiaryMedia(
              id: 'hidden-video-1',
              type: MediaType.video,
              path:
                  '${Directory.systemTemp.path}${Platform.pathSeparator}missing_hidden_video_1.mp4',
            ),
          ],
        ),
      ],
      moods: DiaryMood.values,
    );

    await pumpPage(
      tester,
      const HomePage(),
      path: '/',
      overrides: buildOverrides(
        repository: repository,
        diaryListSettingsStorage: FakeDiaryListSettingsStorage(false),
      ),
    );

    expect(find.byKey(const ValueKey('entry-compact-image-hidden-image-1')),
        findsNothing);
    expect(find.byKey(const ValueKey('entry-compact-video-hidden-video-1')),
        findsNothing);
    expect(
      find.byKey(
        const ValueKey('entry-content-preview-hidden-media-entry'),
        skipOffstage: false,
      ),
      findsOneWidget,
    );
  });

  testWidgets(
      'compact list preview stacks media block above content on narrow widths',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(620, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: buildDiaryTheme(DiaryThemePreset.daylight),
        supportedLocales: AppStrings.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(
          body: SizedBox(
            width: 620,
            child: EntryListPreview(
              entry: DiaryEntry(
                id: 'narrow-layout',
                title: 'Narrow layout',
                content:
                    'The media row should stay horizontal while the text moves below it.',
                mood: DiaryMood.calm,
                createdAt: DateTime(2026, 3, 18, 9),
                media: [
                  DiaryMedia(
                    id: 'narrow-image-1',
                    type: MediaType.image,
                    path:
                        '${Directory.systemTemp.path}${Platform.pathSeparator}missing_narrow_image_1.png',
                  ),
                  DiaryMedia(
                    id: 'narrow-video-1',
                    type: MediaType.video,
                    path:
                        '${Directory.systemTemp.path}${Platform.pathSeparator}missing_narrow_video_1.mp4',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final imageRect = tester.getRect(
      find.byKey(const ValueKey('entry-compact-image-narrow-image-1')),
    );
    final videoRect = tester.getRect(
      find.byKey(const ValueKey('entry-compact-video-narrow-video-1')),
    );
    final contentRect = tester.getRect(
      find.byKey(
        const ValueKey('entry-content-preview-narrow-layout'),
        skipOffstage: false,
      ),
    );
    final narrowContent = tester.widget<Text>(
      find.byKey(
        const ValueKey('entry-content-preview-narrow-layout'),
        skipOffstage: false,
      ),
    );

    expect((imageRect.top - videoRect.top).abs(), lessThan(1));
    expect(imageRect.right, lessThan(videoRect.left));
    expect(contentRect.top, greaterThan(imageRect.bottom));
    expect(narrowContent.maxLines, 4);
  });

  testWidgets('trash page keeps compact previews with tags and actions',
      (tester) async {
    final repository = FakeDiaryRepository(
      moods: DiaryMood.values,
      trashedEntries: [
        DiaryEntry(
          id: 'trash-entry',
          title: 'Trashed memory',
          content: 'This entry should still show a compact preview.',
          mood: DiaryMood.sad,
          createdAt: DateTime(2026, 3, 15, 21),
          trashedAt: DateTime(2026, 3, 16, 8),
          tags: const ['#archive'],
          media: [
            DiaryMedia(
              id: 'trash-image-1',
              type: MediaType.image,
              path:
                  '${Directory.systemTemp.path}${Platform.pathSeparator}missing_trash_image_1.png',
            ),
            DiaryMedia(
              id: 'trash-image-2',
              type: MediaType.image,
              path:
                  '${Directory.systemTemp.path}${Platform.pathSeparator}missing_trash_image_2.png',
            ),
            DiaryMedia(
              id: 'trash-video-1',
              type: MediaType.video,
              path:
                  '${Directory.systemTemp.path}${Platform.pathSeparator}missing_trash_video_1.mp4',
            ),
            DiaryMedia(
              id: 'trash-video-2',
              type: MediaType.video,
              path:
                  '${Directory.systemTemp.path}${Platform.pathSeparator}missing_trash_video_2.mp4',
            ),
          ],
        ),
      ],
    );

    await pumpPage(
      tester,
      const TrashPage(),
      path: '/trash',
      overrides: buildOverrides(repository: repository),
    );

    expect(
      find.byKey(const ValueKey('entry-compact-image-trash-image-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('entry-compact-image-trash-image-2')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('entry-compact-video-trash-video-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('entry-compact-video-trash-video-2')),
      findsNothing,
    );
    final imageRect = tester.getRect(
      find.byKey(const ValueKey('entry-compact-image-trash-image-1')),
    );
    final videoRect = tester.getRect(
      find.byKey(const ValueKey('entry-compact-video-trash-video-1')),
    );

    expect((imageRect.top - videoRect.top).abs(), lessThan(1));
    expect(imageRect.right, lessThan(videoRect.left));
    expect(find.text('#archive'), findsOneWidget);
    expect(find.text(strings.previewEntry), findsOneWidget);
    expect(find.text(strings.restoreEntry), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.circle), findsOneWidget);
  });

  testWidgets('trash page permanently clears only selected entries',
      (tester) async {
    final repository = FakeDiaryRepository(
      moods: DiaryMood.values,
      trashedEntries: [
        DiaryEntry(
          id: 'trash-entry-1',
          title: 'Selected trash',
          content: 'Only this one should be permanently deleted.',
          mood: DiaryMood.sad,
          createdAt: DateTime(2026, 3, 15, 21),
          trashedAt: DateTime(2026, 3, 16, 8),
        ),
        DiaryEntry(
          id: 'trash-entry-2',
          title: 'Remaining trash',
          content: 'This one should stay in the trash.',
          mood: DiaryMood.calm,
          createdAt: DateTime(2026, 3, 14, 21),
          trashedAt: DateTime(2026, 3, 16, 9),
        ),
      ],
    );

    await pumpPage(
      tester,
      const TrashPage(),
      path: '/trash',
      overrides: buildOverrides(repository: repository),
    );

    final clearTrashButton =
        find.widgetWithText(CupertinoButton, strings.clearTrash).first;

    await tester.tap(clearTrashButton);
    await tester.pumpAndSettle();
    expect(find.text(strings.clearTrashConfirmTitle), findsNothing);

    await tester.tap(find.byIcon(CupertinoIcons.circle).first);
    await tester.pumpAndSettle();

    expect(find.text(strings.selectedEntries(1)), findsOneWidget);

    await tester.tap(clearTrashButton);
    await tester.pumpAndSettle();

    expect(find.text(strings.clearTrashConfirmTitle), findsOneWidget);
    expect(find.text(strings.clearTrashConfirmMessage(1)), findsOneWidget);

    await tester.tap(
      find.widgetWithText(CupertinoDialogAction, strings.confirmClearTrash),
    );
    await tester.pumpAndSettle();

    expect(find.text(strings.trashCleared(1)), findsOneWidget);
    expect(find.text('Selected trash'), findsNothing);
    expect(find.text('Remaining trash'), findsOneWidget);
    expect((await repository.listTrashedEntries()).map((entry) => entry.id),
        ['trash-entry-2']);
  });

  testWidgets(
      'entry readonly view keeps images and video in one shared media grid',
      (tester) async {
    final capturedAt = DateTime(2026, 3, 12, 8, 15);

    await pumpReadonlyView(
      tester,
      DiaryEntry(
        id: 'readonly-mixed-media',
        title: 'Readonly mixed media',
        content: 'Preview image and video together.',
        mood: DiaryMood.calm,
        createdAt: DateTime(2026, 3, 12, 8),
        media: [
          DiaryMedia(
            id: 'image-readonly-1',
            type: MediaType.image,
            path:
                '${Directory.systemTemp.path}${Platform.pathSeparator}missing_readonly_image_1.png',
          ),
          DiaryMedia(
            id: 'video-readonly-1',
            type: MediaType.video,
            path:
                '${Directory.systemTemp.path}${Platform.pathSeparator}missing_readonly_video_1.mp4',
            capturedAt: capturedAt,
            durationLabel: '01:14',
          ),
        ],
      ),
    );

    final imageTile =
        find.byKey(const ValueKey('image-media-tile-image-readonly-1'));
    final videoTile =
        find.byKey(const ValueKey('video-media-tile-video-readonly-1'));

    expect(imageTile, findsOneWidget);
    expect(videoTile, findsOneWidget);
    expect(find.text(strings.videoSidebarTitle), findsNothing);
    expect(
      find.descendant(
        of: videoTile,
        matching: find.text(strings.formatDateTime(capturedAt)),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: videoTile,
        matching: find.text('01:14'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('settings page keeps collapsible sections collapsed by default',
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

    expect(find.text(strings.appNameLabel), findsNothing);
    expect(find.text(strings.addMood), findsNothing);
    expect(find.text(strings.currentWindowIcon), findsNothing);
    expect(find.text(strings.newPasscodeLabel), findsNothing);
    expect(find.text(strings.setPasscodeAction), findsNothing);
    expect(find.text(strings.diaryAiProviderLabel), findsNothing);

    await tester.scrollUntilVisible(
      find.text(strings.appIdentityTitle),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(strings.appIdentityTitle));
    await tester.pumpAndSettle();
    expect(find.text(strings.appNameLabel), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text(strings.passwordSettingsTitle),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(strings.passwordSettingsTitle));
    await tester.pumpAndSettle();
    expect(find.text(strings.setPasscodeAction), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text(strings.moodLibraryTitle),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(strings.moodLibraryTitle));
    await tester.pumpAndSettle();
    expect(find.text(strings.addMood), findsOneWidget);
    expect(find.byKey(const ValueKey('mood-library-wrap')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('mood-library-item-${DiaryMood.happyId}')),
      findsOneWidget,
    );
    expect(find.byType(ListTile), findsNothing);

    await tester.scrollUntilVisible(
      find.text(strings.diaryAiSettingsTitle),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(strings.diaryAiSettingsTitle));
    await tester.pumpAndSettle();
    expect(find.text(strings.diaryAiProviderLabel), findsOneWidget);
    expect(find.text(strings.diaryAiBaseUrlLabel), findsOneWidget);
    expect(find.text(strings.diaryAiModelLabel), findsOneWidget);
  });

  testWidgets('settings page saves diary AI provider config', (tester) async {
    final repository = FakeDiaryRepository(
      moods: DiaryMood.values,
    );
    final diaryAiSettingsStorage = FakeDiaryAiSettingsStorage();

    await pumpPage(
      tester,
      const SettingsPage(),
      path: '/settings',
      overrides: buildOverrides(
        repository: repository,
        diaryAiSettingsStorage: diaryAiSettingsStorage,
      ),
    );

    await tester.scrollUntilVisible(
      find.text(strings.diaryAiSettingsTitle),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(strings.diaryAiSettingsTitle));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text(DiaryAiProviderPreset.gemini.label),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(DiaryAiProviderPreset.gemini.label));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('settings-diary-ai-base-url')),
          )
          .controller!
          .text,
      DiaryAiProviderPreset.gemini.defaultBaseUrl,
    );
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('settings-diary-ai-model')),
          )
          .controller!
          .text,
      DiaryAiProviderPreset.gemini.defaultModel,
    );

    await tester.enterText(
      find.byKey(const ValueKey('settings-diary-ai-api-key')),
      'gem-key',
    );
    await tester.tap(find.byKey(const ValueKey('settings-diary-ai-save')));
    await tester.pumpAndSettle();

    final saved = await diaryAiSettingsStorage.readConfig();
    expect(saved.preset, DiaryAiProviderPreset.gemini);
    expect(
        saved.normalizedBaseUrl, DiaryAiProviderPreset.gemini.defaultBaseUrl);
    expect(saved.normalizedModel, DiaryAiProviderPreset.gemini.defaultModel);
    expect(saved.normalizedApiKey, 'gem-key');
    expect(find.text(strings.diaryAiConfigUpdated), findsOneWidget);
  });

  testWidgets('settings page can set a new startup password', (tester) async {
    final repository = FakeDiaryRepository(
      moods: DiaryMood.values,
    );
    final passwordStorage = FakePasswordSettingsStorage();

    await pumpPage(
      tester,
      const SettingsPage(),
      path: '/settings',
      overrides: buildOverrides(
        repository: repository,
        passwordSettingsStorage: passwordStorage,
      ),
    );

    await tester.scrollUntilVisible(
      find.text(strings.passwordSettingsTitle),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(strings.passwordSettingsTitle));
    await tester.pumpAndSettle();

    await tester.tap(find.text(strings.setPasscodeAction));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('settings-passcode-new')),
      'hello-123',
    );
    await tester.enterText(
      find.byKey(const ValueKey('settings-passcode-confirm')),
      'hello-123',
    );
    await tester.tap(
      find.byKey(const ValueKey('settings-passcode-dialog-submit')),
    );
    await tester.pumpAndSettle();

    final stored = await passwordStorage.read();
    expect(find.text(strings.passcodeSaved), findsOneWidget);
    expect(stored.hasPassword, isTrue);
    expect(verifyPassword('hello-123', stored), isTrue);
  });

  testWidgets('settings page can toggle diary list media visibility',
      (tester) async {
    final repository = FakeDiaryRepository(
      moods: DiaryMood.values,
    );
    final diaryListSettingsStorage = FakeDiaryListSettingsStorage();

    await pumpPage(
      tester,
      const SettingsPage(),
      path: '/settings',
      overrides: buildOverrides(
        repository: repository,
        diaryListSettingsStorage: diaryListSettingsStorage,
      ),
    );

    await tester.scrollUntilVisible(
      find.text(strings.diaryListSettingsTitle),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(
      await diaryListSettingsStorage.readShowVisualMedia(),
      isTrue,
    );

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    expect(
      await diaryListSettingsStorage.readShowVisualMedia(),
      isFalse,
    );
    expect(find.text(strings.diaryListShowVisualMediaUpdated), findsOneWidget);
  });

  testWidgets('settings page requires the current password before changing it',
      (tester) async {
    final repository = FakeDiaryRepository(
      moods: DiaryMood.values,
    );
    final hashed = hashPassword('hello-123');
    final passwordStorage = FakePasswordSettingsStorage(
      PasswordSettingsState(
        enabled: true,
        salt: hashed.salt,
        passwordHash: hashed.passwordHash,
      ),
    );

    await pumpPage(
      tester,
      const SettingsPage(),
      path: '/settings',
      overrides: buildOverrides(
        repository: repository,
        passwordSettingsStorage: passwordStorage,
      ),
    );

    await tester.scrollUntilVisible(
      find.text(strings.passwordSettingsTitle),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(strings.passwordSettingsTitle));
    await tester.pumpAndSettle();

    await tester.tap(find.text(strings.changePasscodeAction));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('settings-passcode-current')),
      'wrong-password',
    );
    await tester.enterText(
      find.byKey(const ValueKey('settings-passcode-new')),
      'updated-secret',
    );
    await tester.enterText(
      find.byKey(const ValueKey('settings-passcode-confirm')),
      'updated-secret',
    );
    await tester.tap(
      find.byKey(const ValueKey('settings-passcode-dialog-submit')),
    );
    await tester.pumpAndSettle();

    expect(find.text(strings.currentPasscodeIncorrect), findsOneWidget);
    expect(verifyPassword('hello-123', await passwordStorage.read()), isTrue);
  });

  testWidgets('settings page can disable the startup passcode', (tester) async {
    final repository = FakeDiaryRepository(
      moods: DiaryMood.values,
    );
    final hashed = hashPassword('hello-123');
    final passwordStorage = FakePasswordSettingsStorage(
      PasswordSettingsState(
        enabled: true,
        salt: hashed.salt,
        passwordHash: hashed.passwordHash,
      ),
    );

    await pumpPage(
      tester,
      const SettingsPage(),
      path: '/settings',
      overrides: buildOverrides(
        repository: repository,
        passwordSettingsStorage: passwordStorage,
      ),
    );

    await tester.scrollUntilVisible(
      find.text(strings.passwordSettingsTitle),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(strings.passwordSettingsTitle));
    await tester.pumpAndSettle();

    await tester.tap(
      find.widgetWithText(OutlinedButton, strings.disablePasscode),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(FilledButton, strings.confirmDisablePasscode),
    );
    await tester.pumpAndSettle();

    expect(find.text(strings.passcodeDisabled), findsOneWidget);
    expect((await passwordStorage.read()).hasPassword, isFalse);
  });

  testWidgets('startup lock gate shows the passcode screen when enabled',
      (tester) async {
    final repository = FakeDiaryRepository(
      entries: [
        DiaryEntry(
          id: 'locked-entry',
          title: 'Locked entry',
          content: 'Should stay hidden until unlocked.',
          mood: DiaryMood.calm,
          createdAt: DateTime(2026, 3, 19, 10),
        ),
      ],
      moods: DiaryMood.values,
    );
    final hashed = hashPassword('hello-123');
    final passwordStorage = FakePasswordSettingsStorage(
      PasswordSettingsState(
        enabled: true,
        salt: hashed.salt,
        passwordHash: hashed.passwordHash,
      ),
    );

    await pumpPage(
      tester,
      const HomePage(),
      path: '/',
      overrides: buildOverrides(
        repository: repository,
        passwordSettingsStorage: passwordStorage,
      ),
      withStartupLockGate: true,
    );
    await tester.pumpAndSettle();

    expect(find.text(strings.unlockAppTitle), findsOneWidget);
    expect(
        find.byKey(const ValueKey('startup-passcode-field')), findsOneWidget);
    expect(find.text(strings.recentEntries), findsNothing);
  });

  testWidgets('startup lock gate unlocks the app with the correct passcode',
      (tester) async {
    final repository = FakeDiaryRepository(
      entries: [
        DiaryEntry(
          id: 'unlock-entry',
          title: 'Unlock me',
          content: 'Visible after unlocking.',
          mood: DiaryMood.calm,
          createdAt: DateTime(2026, 3, 19, 10),
        ),
      ],
      moods: DiaryMood.values,
    );
    final hashed = hashPassword('hello-123');
    final passwordStorage = FakePasswordSettingsStorage(
      PasswordSettingsState(
        enabled: true,
        salt: hashed.salt,
        passwordHash: hashed.passwordHash,
      ),
    );

    await pumpPage(
      tester,
      const HomePage(),
      path: '/',
      overrides: buildOverrides(
        repository: repository,
        passwordSettingsStorage: passwordStorage,
      ),
      withStartupLockGate: true,
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('startup-passcode-field')),
      'hello-123',
    );
    await tester.tap(find.widgetWithText(FilledButton, strings.unlockAction));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text(strings.unlockAppTitle), findsNothing);
    expect(find.text(strings.recentEntries), findsOneWidget);
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

  testWidgets('mixed media grid forwards video taps to the preview callback',
      (tester) async {
    DiaryMedia? tappedMedia;
    final video = DiaryMedia(
      id: 'video-grid-1',
      type: MediaType.video,
      path:
          '${Directory.systemTemp.path}${Platform.pathSeparator}missing_grid_video_1.mp4',
      capturedAt: DateTime(2026, 3, 11, 17, 45),
      durationLabel: '00:08',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildDiaryTheme(DiaryThemePreset.daylight),
        supportedLocales: AppStrings.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(
          body: ImageMediaGrid(
            media: [video],
            minColumns: 1,
            maxColumns: 1,
            onPreviewRequested: (media) => tappedMedia = media,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester
        .tap(find.byKey(const ValueKey('video-media-tile-video-grid-1')));
    await tester.pump();

    expect(tappedMedia?.id, 'video-grid-1');
  });
}

Future<void> pumpPage(
  WidgetTester tester,
  Widget child, {
  required String path,
  required List<Override> overrides,
  bool withStartupLockGate = false,
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
      GoRoute(
        path: '/video-preview',
        builder: (context, state) => VideoPreviewPage(
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
        builder: (context, appChild) {
          final content = appChild ?? const SizedBox.shrink();
          if (!withStartupLockGate) {
            return content;
          }
          return AppStartupLockGate(child: content);
        },
      ),
    ),
  );

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

Future<void> pressControlShortcut(
  WidgetTester tester,
  LogicalKeyboardKey key,
) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
}

TextEditingController editableTextController(
  WidgetTester tester,
  int index,
) {
  return tester
      .widget<EditableText>(find.byType(EditableText).at(index))
      .controller;
}

Future<void> pumpEditorNavigationApp(
  WidgetTester tester, {
  required String initialLocation,
  required List<Override> overrides,
}) async {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomePage()),
      GoRoute(
        path: '/editor',
        builder: (context, state) => EditorPage(
          entry: state.extra as DiaryEntry?,
        ),
      ),
      GoRoute(
          path: '/settings', builder: (context, state) => const SettingsPage()),
      GoRoute(path: '/timeline', builder: (context, state) => const HomePage()),
      GoRoute(path: '/trash', builder: (context, state) => const TrashPage()),
      GoRoute(
        path: '/image-preview',
        builder: (context, state) => ImagePreviewPage(
          media: state.extra as DiaryMedia?,
        ),
      ),
      GoRoute(
        path: '/video-preview',
        builder: (context, state) => VideoPreviewPage(
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

Future<void> pumpReadonlyView(
  WidgetTester tester,
  DiaryEntry entry,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildDiaryTheme(DiaryThemePreset.daylight),
      supportedLocales: AppStrings.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Scaffold(
        body: ListView(
          children: [
            EntryReadonlyView(entry: entry),
          ],
        ),
      ),
    ),
  );

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

List<Override> buildOverrides({
  required FakeDiaryRepository repository,
  FakeDiaryListSettingsStorage? diaryListSettingsStorage,
  FakePasswordSettingsStorage? passwordSettingsStorage,
  FakeDiaryAiSettingsStorage? diaryAiSettingsStorage,
}) {
  final effectiveDiaryListSettingsStorage =
      diaryListSettingsStorage ?? FakeDiaryListSettingsStorage();
  final effectivePasswordSettingsStorage =
      passwordSettingsStorage ?? FakePasswordSettingsStorage();
  final effectiveDiaryAiSettingsStorage =
      diaryAiSettingsStorage ?? FakeDiaryAiSettingsStorage();

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
      (ref) => effectiveDiaryAiSettingsStorage,
    ),
    diaryListSettingsStorageProvider.overrideWith(
      (ref) => effectiveDiaryListSettingsStorage,
    ),
    passwordSettingsStorageProvider.overrideWith(
      (ref) => effectivePasswordSettingsStorage,
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
  })  : _entries = List<DiaryEntry>.from(entries ?? const []),
        _trashedEntries = List<DiaryEntry>.from(trashedEntries ?? const []),
        _tags = List<String>.from(tags ?? const []),
        _moods = List<DiaryMood>.from(moods ?? DiaryMood.values);

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
    final entry = DiaryEntry(
      id: 'entry-${_entries.length + 1}',
      title: title.trim().isEmpty ? 'Untitled entry' : title.trim(),
      content: content.trim(),
      mood: mood,
      createdAt: DateTime(2026, 3, 19, 12),
      location: location.trim().isEmpty ? null : location.trim(),
      tags: List<String>.from(tags),
      media: List<DiaryMedia>.from(media),
      aiAnalysis: aiAnalysis,
    );
    _entries.insert(0, entry);
    return entry;
  }

  @override
  Future<void> deleteEntry(String id) async {
    _entries.removeWhere((item) => item.id == id);
    _trashedEntries.removeWhere((item) => item.id == id);
  }

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
  Future<void> saveEntry(DiaryEntry entry) async {
    final targetEntries = entry.trashedAt == null ? _entries : _trashedEntries;
    final otherEntries = entry.trashedAt == null ? _trashedEntries : _entries;
    final existingIndex =
        targetEntries.indexWhere((item) => item.id == entry.id);
    if (existingIndex >= 0) {
      targetEntries[existingIndex] = entry;
      otherEntries.removeWhere((item) => item.id == entry.id);
      return;
    }
    otherEntries.removeWhere((item) => item.id == entry.id);
    targetEntries.insert(0, entry);
  }

  @override
  Future<void> saveMood(DiaryMood mood) async {}

  @override
  Future<void> saveTag(String tag) async {
    if (_tags.any((item) => item.toLowerCase() == tag.toLowerCase())) {
      return;
    }
    _tags.insert(0, tag);
  }

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
    final updated = entry.copyWith(
      title: title.trim().isEmpty ? 'Untitled entry' : title.trim(),
      content: content.trim(),
      mood: mood,
      location: location.trim().isEmpty ? null : location.trim(),
      tags: List<String>.from(tags),
      media: List<DiaryMedia>.from(media),
      aiAnalysis: aiAnalysis,
    );
    await saveEntry(updated);
    return updated;
  }

  @override
  Future<void> deleteTag(String tag) async {
    _tags.removeWhere((item) => item.toLowerCase() == tag.toLowerCase());
  }
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
  FakeDiaryAiSettingsStorage([
    DiaryAiProviderConfig? config,
  ]) : _config = config ??
            DiaryAiProviderConfig.forPreset(DiaryAiProviderPreset.dashScope);

  DiaryAiProviderConfig _config;
  bool _visibility = true;
  bool _emotionalCompanionVisibility = true;
  bool _problemSuggestionVisibility = true;

  @override
  Future<DiaryAiProviderConfig> readConfig() async => _config;

  @override
  Future<String?> read() async => _config.normalizedApiKey;

  @override
  Future<bool> readEmotionalCompanionVisibility() async =>
      _emotionalCompanionVisibility;

  @override
  Future<bool> readProblemSuggestionVisibility() async =>
      _problemSuggestionVisibility;

  @override
  Future<bool> readVisibility() async => _visibility;

  @override
  Future<void> write(String? apiKey) async {
    _config = _config.copyWith(apiKey: apiKey);
  }

  @override
  Future<void> writeConfig(DiaryAiProviderConfig config) async {
    _config = config.copyWith(
      baseUrl: config.normalizedBaseUrl,
      model: config.normalizedModel,
      apiKey: config.normalizedApiKey,
    );
  }

  @override
  Future<void> writeEmotionalCompanionVisibility(bool enabled) async {
    _emotionalCompanionVisibility = enabled;
  }

  @override
  Future<void> writeProblemSuggestionVisibility(bool enabled) async {
    _problemSuggestionVisibility = enabled;
  }

  @override
  Future<void> writeVisibility(bool enabled) async {
    _visibility = enabled;
  }
}

class FakeDiaryListSettingsStorage extends DiaryListSettingsStorage {
  FakeDiaryListSettingsStorage([
    bool value = true,
  ]) : _showVisualMedia = value;

  bool _showVisualMedia;

  @override
  Future<bool> readShowVisualMedia() async => _showVisualMedia;

  @override
  Future<void> writeShowVisualMedia(bool enabled) async {
    _showVisualMedia = enabled;
  }
}

class FakePasswordSettingsStorage extends PasswordSettingsStorage {
  FakePasswordSettingsStorage([
    PasswordSettingsState? value,
  ]) : _value = value ?? const PasswordSettingsState.disabled();

  PasswordSettingsState _value;

  @override
  Future<PasswordSettingsState> read() async => _value;

  @override
  Future<void> write(PasswordSettingsState settings) async {
    _value = settings;
  }
}

class FakeTranscriptionApiKeyStorage extends TranscriptionApiKeyStorage {
  @override
  Future<String?> read() async => null;

  @override
  Future<void> write(String? apiKey) async {}
}
