import 'package:diary_mvp/app/theme.dart';
import 'package:diary_mvp/app/localization/app_locale.dart';
import 'package:diary_mvp/features/diary/domain/diary_entry.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppStrings {
  const AppStrings(this.locale);

  final Locale locale;

  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  static AppStrings of(BuildContext context) {
    final resolved = resolveLocale(Localizations.localeOf(context));
    return AppStrings(resolved);
  }

  static Locale resolveLocale(Locale? locale) {
    if (locale?.languageCode == 'zh') {
      return const Locale('zh');
    }
    return const Locale('en');
  }

  bool get isChinese => locale.languageCode == 'zh';

  String get appTitle => '\u65e5\u8bb0';
  String get theme => isChinese ? '\u4e3b\u9898' : 'Theme';
  String get renameAppTitle =>
      isChinese ? '\u81ea\u5b9a\u4e49\u5e94\u7528\u540d' : 'Customize app name';
  String get renameAppTooltip =>
      isChinese ? '\u4fee\u6539\u5e94\u7528\u540d' : 'Rename app';
  String get appNameLabel => isChinese ? '\u5e94\u7528\u540d' : 'App name';
  String get appNameHint => isChinese
      ? '\u4f8b\u5982\uff1a\u65e5\u8bb0 / \u6211\u7684\u65e5\u8bb0'
      : 'For example: Diary / My Diary';
  String get resetAppName =>
      isChinese ? '\u6062\u590d\u9ed8\u8ba4' : 'Reset to default';
  String get appNameUpdated => isChinese
      ? '\u5e94\u7528\u540d\u5df2\u66f4\u65b0\u3002'
      : 'App name updated.';
  String get appNameReset => isChinese
      ? '\u5df2\u6062\u590d\u9ed8\u8ba4\u5e94\u7528\u540d\u3002'
      : 'App name reset to default.';
  String appNameUpdateFailed(Object error) => isChinese
      ? '\u4fdd\u5b58\u5e94\u7528\u540d\u5931\u8d25\uff1a$error'
      : 'Failed to save app name: $error';
  String get language => isChinese ? '\u8bed\u8a00' : 'Language';
  String get saveAction => isChinese ? '\u4fdd\u5b58' : 'Save';
  String get systemLanguage =>
      isChinese ? '\u8ddf\u968f\u7cfb\u7edf' : 'System';
  String get englishLanguage => 'English';
  String get chineseLanguage => '\u4e2d\u6587';

  String titleForLanguage(AppLanguage languageValue) {
    switch (languageValue) {
      case AppLanguage.system:
        return systemLanguage;
      case AppLanguage.english:
        return englishLanguage;
      case AppLanguage.chinese:
        return chineseLanguage;
    }
  }

  String titleForTheme(DiaryThemePreset themePreset) {
    switch (themePreset) {
      case DiaryThemePreset.daylight:
        return isChinese
            ? '\u767d\u5929\u4e3b\u9898\uff08\u9ed8\u8ba4\uff09'
            : 'Day Theme (Default)';
      case DiaryThemePreset.night:
        return isChinese ? '\u591c\u95f4\u4e3b\u9898' : 'Night Theme';
      case DiaryThemePreset.cyberpunk:
        return isChinese
            ? '\u8d5b\u535a\u670b\u514b\u4e3b\u9898'
            : 'Cyberpunk Theme';
      case DiaryThemePreset.hacker:
        return isChinese ? '\u9ed1\u5ba2\u4e3b\u9898' : 'Hacker Theme';
      case DiaryThemePreset.spaceLines:
        return isChinese
            ? '\u6781\u81f4\u7ebf\u6761\uff08\u592a\u7a7a\u4eba\u65e5\u5fd7\u7248\uff09'
            : 'Extreme Lines (Astronaut Log)';
    }
  }

  String heroLabelForTheme(DiaryThemePreset themePreset) {
    switch (themePreset) {
      case DiaryThemePreset.daylight:
        return isChinese ? '\u6668\u5149\u8bb0\u5f55' : 'DAYLIGHT LOG';
      case DiaryThemePreset.night:
        return isChinese ? '\u591c\u822a\u6a21\u5f0f' : 'NIGHT WATCH';
      case DiaryThemePreset.cyberpunk:
        return isChinese ? '\u9727\u8679\u56de\u8def' : 'NEON CIRCUIT';
      case DiaryThemePreset.hacker:
        return isChinese ? '\u7ec8\u7aef\u8bb0\u5f55' : 'TERMINAL LOG';
      case DiaryThemePreset.spaceLines:
        return spaceLogLabel;
    }
  }

  String get homeNav => isChinese ? '\u9996\u9875' : 'Home';
  String get writeNav => isChinese ? '\u5199\u65e5\u8bb0' : 'Write';
  String get timelineNav => isChinese ? '\u65f6\u95f4\u8f74' : 'Timeline';
  String get trashNav => isChinese ? '\u5783\u573e\u6876' : 'Trash';

  String get newEntry => isChinese ? '\u65b0\u5efa\u65e5\u8bb0' : 'New Entry';
  String get editEntry => isChinese ? '\u7f16\u8f91\u65e5\u8bb0' : 'Edit entry';
  String get deleteEntry =>
      isChinese ? '\u79fb\u5230\u5783\u573e\u6876' : 'Move to trash';
  String get today => isChinese ? '\u4eca\u5929' : 'Today';
  String get recentEntries =>
      isChinese ? '\u6700\u8fd1\u65e5\u8bb0' : 'Recent entries';
  String get allTags => isChinese ? '\u5168\u90e8\u6807\u7b7e' : 'All tags';
  String get filterByTag =>
      isChinese ? '\u6309\u6807\u7b7e\u7b5b\u9009' : 'Filter by tag';
  String get viewAll => isChinese ? '\u67e5\u770b\u5168\u90e8' : 'View all';
  String get previewEntry =>
      isChinese ? '\u9884\u89c8\u65e5\u8bb0' : 'Preview entry';
  String get migrationTitle =>
      isChinese ? '\u6570\u636e\u8fc1\u79fb' : 'Migration';
  String get migrationHint => isChinese
      ? '\u53ef\u4ee5\u5bfc\u51fa\u6574\u4e2a\u672c\u5730\u65e5\u8bb0\u6570\u636e\u5305\uff0c\u4e5f\u53ef\u4ee5\u4ece\u5df2\u5bfc\u51fa\u7684\u8fc1\u79fb\u5305\u6062\u590d\u5230\u8fd9\u53f0\u8bbe\u5907\u3002'
      : 'Export a full local migration package, or import one back onto this device.';
  String get currentDataLocation => isChinese
      ? '\u5f53\u524d\u6570\u636e\u4f4d\u7f6e'
      : 'Current data location';
  String get exportMigrationPackage =>
      isChinese ? '\u5bfc\u51fa\u8fc1\u79fb\u5305' : 'Export migration package';
  String get exportingMigrationPackage => isChinese
      ? '\u5bfc\u51fa\u8fc1\u79fb\u5305\u4e2d...'
      : 'Exporting package...';
  String get importMigrationPackage =>
      isChinese ? '\u5bfc\u5165\u8fc1\u79fb\u5305' : 'Import migration package';
  String get importingMigrationPackage => isChinese
      ? '\u5bfc\u5165\u8fc1\u79fb\u5305\u4e2d...'
      : 'Importing package...';
  String get exportMigrationHint => isChinese
      ? '\u4f1a\u628a\u65e5\u8bb0\u6570\u636e\u3001\u56fe\u7247\u3001\u5f55\u97f3\u3001\u89c6\u9891\u548c\u5783\u573e\u6876\u4e00\u8d77\u6253\u5305\u5bfc\u51fa\u3002'
      : 'Export diary data, images, audio, videos, and trash into one package.';
  String get importMigrationHint => isChinese
      ? '\u5bfc\u5165\u540e\u4f1a\u8986\u76d6\u5f53\u524d\u8bbe\u5907\u7684\u672c\u5730\u6570\u636e\uff0c\u9002\u5408\u6362\u7535\u8111\u6216\u6062\u590d\u5907\u4efd\u3002'
      : 'Importing replaces the current local data on this device, which is useful for moving to a new computer or restoring a backup.';
  String get selectMigrationExportFolder => isChinese
      ? '\u9009\u62e9\u8fc1\u79fb\u5305\u5bfc\u51fa\u76ee\u5f55'
      : 'Select export location';
  String get selectMigrationImportFolder => isChinese
      ? '\u9009\u62e9\u8fc1\u79fb\u5305\u76ee\u5f55'
      : 'Select migration package';
  String get migrationFolderNotSelected => isChinese
      ? '\u672a\u9009\u62e9\u8fc1\u79fb\u5305\u76ee\u5f55\u3002'
      : 'No migration folder selected.';
  String migrationExported(String path, int entryCount) => isChinese
      ? '\u5df2\u5bfc\u51fa $entryCount \u7bc7\u65e5\u8bb0\u5230\uff1a$path'
      : 'Exported $entryCount entries to: $path';
  String migrationExportFailed(Object error) => isChinese
      ? '\u5bfc\u51fa\u8fc1\u79fb\u5305\u5931\u8d25\uff1a$error'
      : 'Failed to export migration package: $error';
  String migrationImported(int entryCount) => isChinese
      ? '\u5df2\u5bfc\u5165 $entryCount \u7bc7\u65e5\u8bb0\u3002'
      : 'Imported $entryCount entries.';
  String migrationImportFailed(Object error) => isChinese
      ? '\u5bfc\u5165\u8fc1\u79fb\u5305\u5931\u8d25\uff1a$error'
      : 'Failed to import migration package: $error';
  String get importMigrationConfirmTitle => isChinese
      ? '\u786e\u8ba4\u5bfc\u5165\u8fc1\u79fb\u5305\uff1f'
      : 'Import this migration package?';
  String get importMigrationConfirmMessage => isChinese
      ? '\u5f53\u524d\u8bbe\u5907\u4e0a\u7684\u672c\u5730\u65e5\u8bb0\u3001\u5783\u573e\u6876\u548c\u5a92\u4f53\u6587\u4ef6\u4f1a\u88ab\u65b0\u6570\u636e\u8986\u76d6\u3002'
      : 'The current local diary data, trash, and media files on this device will be replaced.';
  String get confirmImportMigration =>
      isChinese ? '\u5f00\u59cb\u5bfc\u5165' : 'Import now';
  String get exportEntry =>
      isChinese ? '\u5bfc\u51fa\u65e5\u8bb0' : 'Export entry';
  String get exportingEntry =>
      isChinese ? '\u5bfc\u51fa\u4e2d...' : 'Exporting...';
  String get selectExportFolder => isChinese
      ? '\u9009\u62e9\u5bfc\u51fa\u76ee\u5f55'
      : 'Select export folder';
  String get exportFolderNotSelected => isChinese
      ? '\u672a\u9009\u62e9\u5bfc\u51fa\u76ee\u5f55\u3002'
      : 'No export folder selected.';
  String entryExported(String path) => isChinese
      ? '\u65e5\u8bb0\u5df2\u5bfc\u51fa\u5230\uff1a$path'
      : 'Entry exported to: $path';
  String entryExportFailed(Object error) => isChinese
      ? '\u5bfc\u51fa\u65e5\u8bb0\u5931\u8d25\uff1a$error'
      : 'Failed to export entry: $error';
  String get restoreEntry =>
      isChinese ? '\u6062\u590d\u65e5\u8bb0' : 'Restore entry';
  String get restoreSelected =>
      isChinese ? '\u6279\u91cf\u6062\u590d' : 'Restore selected';
  String get clearTrash =>
      isChinese ? '\u6c38\u4e45\u6e05\u7a7a' : 'Empty trash';
  String get restoreFromTrash =>
      isChinese ? '\u4ece\u5783\u573e\u6876\u6062\u590d' : 'Restore from trash';
  String get selectAll => isChinese ? '\u5168\u9009' : 'Select all';
  String get clearSelection =>
      isChinese ? '\u53d6\u6d88\u9009\u62e9' : 'Clear selection';
  String get trashEmpty => isChinese
      ? '\u5783\u573e\u6876\u91cc\u8fd8\u6ca1\u6709\u65e5\u8bb0\u3002'
      : 'Trash is empty.';
  String get trashedEntryHint => isChinese
      ? '\u53ef\u4ee5\u6253\u5f00\u9884\u89c8\uff0c\u4f46\u4e0d\u53ef\u7f16\u8f91\u3002'
      : 'You can preview trashed entries, but not edit them.';
  String selectedEntries(int count) =>
      isChinese ? '\u5df2\u9009\u4e2d $count \u7bc7' : '$count selected';
  String restoredEntries(int count) => isChinese
      ? '\u5df2\u6062\u590d $count \u7bc7\u65e5\u8bb0\u3002'
      : 'Restored $count entr${count == 1 ? 'y' : 'ies'}.';
  String restoreFailed(Object error) => isChinese
      ? '\u6062\u590d\u5931\u8d25\uff1a$error'
      : 'Restore failed: $error';
  String get clearTrashConfirmTitle => isChinese
      ? '\u786e\u8ba4\u6c38\u4e45\u6e05\u7a7a\u5783\u573e\u6876\uff1f'
      : 'Permanently empty trash?';
  String clearTrashConfirmMessage(int count) => isChinese
      ? '\u8fd9\u4f1a\u6c38\u4e45\u5220\u9664 $count \u7bc7\u65e5\u8bb0\u53ca\u5176\u56fe\u7247\u3001\u5f55\u97f3\u548c\u89c6\u9891\u6587\u4ef6\uff0c\u4e14\u65e0\u6cd5\u6062\u590d\u3002'
      : 'This permanently deletes $count entr${count == 1 ? 'y' : 'ies'} and all linked images, audio, and video files.';
  String get confirmClearTrash =>
      isChinese ? '\u6c38\u4e45\u6e05\u7a7a' : 'Empty trash';
  String trashCleared(int count) => isChinese
      ? '\u5df2\u6c38\u4e45\u5220\u9664 $count \u7bc7\u65e5\u8bb0\u3002'
      : 'Permanently deleted $count entr${count == 1 ? 'y' : 'ies'}.';
  String clearTrashFailed(Object error) => isChinese
      ? '\u6e05\u7a7a\u5783\u573e\u6876\u5931\u8d25\uff1a$error'
      : 'Empty trash failed: $error';
  String trashedAtLabel(DateTime date) => isChinese
      ? '\u5220\u9664\u65f6\u95f4\uff1a${formatDateTime(date)}'
      : 'Moved to trash: ${formatDateTime(date)}';
  String get startCapturingToday => isChinese
      ? '\u5f00\u59cb\u8bb0\u5f55\u4eca\u5929\u5427\uff0c\u628a\u6587\u5b57\u3001\u5fc3\u60c5\u548c\u58f0\u97f3\u90fd\u7559\u4e0b\u6765\u3002'
      : 'Start capturing today with words, mood, and voice.';
  String get spaceLogLabel =>
      isChinese ? '\u4efb\u52a1\u65e5\u5fd7' : 'MISSION LOG';
  String get firstEntryPrompt => isChinese
      ? '\u5f00\u59cb\u5199\u7b2c\u4e00\u7bc7\u65e5\u8bb0\u5427\u3002'
      : 'Start with your first diary entry.';
  String failedToLoadEntries(Object error) => isChinese
      ? '\u52a0\u8f7d\u65e5\u8bb0\u5931\u8d25\uff1a$error'
      : 'Failed to load entries: $error';
  String failedToLoadTimeline(Object error) => isChinese
      ? '\u52a0\u8f7d\u65f6\u95f4\u8f74\u5931\u8d25\uff1a$error'
      : 'Failed to load timeline: $error';
  String failedToLoadTrash(Object error) => isChinese
      ? '\u52a0\u8f7d\u5783\u573e\u6876\u5931\u8d25\uff1a$error'
      : 'Failed to load trash: $error';
  String get noEntriesYet => isChinese
      ? '\u8fd8\u6ca1\u6709\u65e5\u8bb0\uff0c\u5148\u4ece\u7b2c\u4e00\u7bc7\u5f00\u59cb\u5427\u3002'
      : 'No entries yet. Start with your first note.';
  String filteredByTag(String tag) =>
      isChinese ? '\u6b63\u5728\u67e5\u770b $tag' : 'Viewing $tag';
  String noEntriesForTag(String tag) => isChinese
      ? '\u8fd8\u6ca1\u6709\u5e26\u6709 $tag \u7684\u65e5\u8bb0\u3002'
      : 'No diary entries tagged with $tag yet.';
  String entryCountLabel(int count) => isChinese
      ? '\u65e5\u8bb0 $count \u7bc7'
      : '$count entr${count == 1 ? 'y' : 'ies'}';
  String tagStatusLabel(String? tag) => isChinese
      ? '\u6807\u7b7e\uff1a${tag ?? '\u5168\u90e8'}'
      : 'Tag: ${tag ?? 'All'}';
  String moodStatusLabel(DiaryMood moodValue) =>
      '${isChinese ? '\u60c5\u7eea' : 'Mood'}: ${moodLabel(moodValue)}';

  String dayHeading(DateTime date) => '$today - ${formatDay(date)}';

  String latestSummary(DiaryEntry? entry) {
    if (entry == null) return startCapturingToday;
    return '${entry.mood.emoji} ${moodLabel(entry.mood)} - ${entry.title}';
  }

  String get whatHappenedToday => isChinese
      ? '\u4eca\u5929\u53d1\u751f\u4e86\u4ec0\u4e48\uff1f'
      : 'What happened today?';
  String get untitledEntry =>
      isChinese ? '\u65e0\u6807\u9898\u65e5\u8bb0' : 'Untitled entry';
  String get titleLabel => isChinese ? '\u6807\u9898' : 'Title';
  String get titleHint => isChinese
      ? '\u4f8b\u5982\uff1a\u516c\u56ed\u7684\u4e0b\u5348'
      : 'For example: Afternoon in the park';
  String get contentLabel => isChinese ? '\u5185\u5bb9' : 'Content';
  String get contentHint => isChinese
      ? '\u5199\u4e0b\u4eca\u5929\u53d1\u751f\u7684\u4e8b\u3001\u4f60\u7684\u611f\u53d7\uff0c\u4ee5\u53ca\u60f3\u7559\u4e0b\u7684\u8bb0\u5fc6...'
      : 'Write down what happened, how you felt, and what you want to remember...';
  String get locationLabel => isChinese ? '\u5730\u70b9' : 'Location';
  String get createdAtLabel => isChinese ? '\u65f6\u95f4' : 'Created at';
  String get locationHint => isChinese
      ? '\u4f8b\u5982\uff1a\u5bb6 / \u516c\u53f8 / \u4e0a\u6d77'
      : 'For example: Home / Office / Shanghai';
  String get notProvided => isChinese ? '\u672a\u586b\u5199' : 'Not provided';
  String get useCurrentLocation => isChinese
      ? '\u83b7\u53d6\u5f53\u524d\u4f4d\u7f6e'
      : 'Use current location';
  String get locationUpdated => isChinese
      ? '\u5df2\u81ea\u52a8\u586b\u5165\u5f53\u524d\u4f4d\u7f6e\u3002'
      : 'Current location added.';
  String get locationServiceDisabled => isChinese
      ? '\u8bf7\u5148\u6253\u5f00\u7cfb\u7edf\u5b9a\u4f4d\u670d\u52a1\u3002'
      : 'Please turn on location services first.';
  String get locationPermissionDenied => isChinese
      ? '\u5b9a\u4f4d\u6743\u9650\u88ab\u62d2\u7edd\u3002'
      : 'Location permission denied.';
  String get locationPermissionDeniedForever => isChinese
      ? '\u5b9a\u4f4d\u6743\u9650\u5df2\u88ab\u6c38\u4e45\u7981\u7528\uff0c\u8bf7\u5230\u7cfb\u7edf\u8bbe\u7f6e\u4e2d\u5f00\u542f\u3002'
      : 'Location permission is permanently denied. Please enable it in system settings.';
  String locationLookupFailed(Object? error) => isChinese
      ? '\u83b7\u53d6\u4f4d\u7f6e\u5931\u8d25${error == null ? '' : '\uff1a$error'}'
      : 'Could not get location${error == null ? '' : ': $error'}';
  String get tagsLabel => isChinese ? '\u6807\u7b7e' : 'Tags';
  String get selectedTagsLabel =>
      isChinese ? '\u5f53\u524d\u65e5\u8bb0\u6807\u7b7e' : 'Selected tags';
  String get tagLibraryLabel =>
      isChinese ? '\u53ef\u590d\u7528\u6807\u7b7e' : 'Tag library';
  String get tagSidebarHint => isChinese
      ? '\u53ef\u4ee5\u65b0\u5efa\u53ef\u590d\u7528\u6807\u7b7e\uff0c\u4e5f\u53ef\u76f4\u63a5\u7ed9\u5f53\u524d\u65e5\u8bb0\u52fe\u9009\u3002'
      : 'Create reusable tags or quickly apply them to this entry.';
  String get tagHint => isChinese
      ? '\u4f8b\u5982\uff1a#\u751f\u6d3b / \u5de5\u4f5c / \u65c5\u884c'
      : 'For example: #life / work / travel';
  String get addTag => isChinese ? '\u6dfb\u52a0\u6807\u7b7e' : 'Add tag';
  String get noTagsYet => isChinese
      ? '\u8fd8\u6ca1\u6709\u53ef\u590d\u7528\u6807\u7b7e\u3002'
      : 'No reusable tags yet.';
  String get noSelectedTags => isChinese
      ? '\u5f53\u524d\u65e5\u8bb0\u6682\u65e0\u6807\u7b7e\u3002'
      : 'This entry has no tags yet.';
  String get noTagsValue => isChinese ? '\u65e0\u6807\u7b7e' : 'No tags';
  String get tagAdded => isChinese
      ? '\u6807\u7b7e\u5df2\u52a0\u5165\u6807\u7b7e\u5e93\u3002'
      : 'Tag added to the library.';
  String tagSaveFailed(Object error) => isChinese
      ? '\u4fdd\u5b58\u6807\u7b7e\u5931\u8d25\uff1a$error'
      : 'Failed to save tag: $error';
  String get removeTagFromLibrary => isChinese
      ? '\u4ece\u6807\u7b7e\u5e93\u5220\u9664'
      : 'Remove from tag library';
  String get deleteTagConfirmTitle => isChinese
      ? '\u786e\u8ba4\u5220\u9664\u8fd9\u4e2a\u6807\u7b7e\uff1f'
      : 'Delete this tag?';
  String deleteTagConfirmMessage(String tag) => isChinese
      ? '\u8fd9\u4f1a\u628a $tag \u4ece\u6807\u7b7e\u5e93\u79fb\u9664\uff0c\u5e76\u4ece\u6240\u6709\u65e5\u8bb0\u4e2d\u5220\u9664\u3002'
      : 'This removes $tag from the tag library and from all diary entries.';
  String get confirmDeleteTag =>
      isChinese ? '\u5220\u9664\u6807\u7b7e' : 'Delete tag';
  String get tagDeleted => isChinese
      ? '\u6807\u7b7e\u5df2\u4ece\u6807\u7b7e\u5e93\u79fb\u9664\u3002'
      : 'Tag removed from the library.';
  String deleteTagFailed(Object error) => isChinese
      ? '\u5220\u9664\u6807\u7b7e\u5931\u8d25\uff1a$error'
      : 'Failed to delete tag: $error';
  String failedToLoadTags(Object error) => isChinese
      ? '\u52a0\u8f7d\u6807\u7b7e\u5931\u8d25\uff1a$error'
      : 'Failed to load tags: $error';
  String get mood => isChinese ? '\u5fc3\u60c5' : 'Mood';
  String get contentSectionTitle => isChinese ? '\u5185\u5bb9' : 'Content';
  String get imagesSectionTitle => isChinese ? '\u56fe\u7247' : 'Images';
  String get audioSectionTitle => isChinese ? '\u97f3\u9891' : 'Audio';
  String get videoSectionTitle => isChinese ? '\u89c6\u9891' : 'Videos';
  String get emptyContentValue =>
      isChinese ? '\u6682\u65e0\u5185\u5bb9' : 'No content';
  String get mediaToolbar =>
      isChinese ? '\u5a92\u4f53\u5de5\u5177\u680f' : 'Media toolbar';
  String get importImage =>
      isChinese ? '\u5bfc\u5165\u56fe\u7247' : 'Import image';
  String get takePhoto => isChinese ? '\u62cd\u7167' : 'Take photo';
  String get recordVideo => isChinese ? '\u5f55\u89c6\u9891' : 'Record video';
  String get photoMode => isChinese ? '\u7167\u7247' : 'Photo';
  String get videoMode => isChinese ? '\u89c6\u9891' : 'Video';
  String get cameraCapture =>
      isChinese ? '\u76f8\u673a\u62cd\u6444' : 'Camera capture';
  String get previewPhoto =>
      isChinese ? '\u9884\u89c8\u7167\u7247' : 'Preview photo';
  String get previewVideo =>
      isChinese ? '\u9884\u89c8\u89c6\u9891' : 'Preview video';
  String get retakePhoto => isChinese ? '\u91cd\u62cd' : 'Retake';
  String get retakeVideo =>
      isChinese ? '\u91cd\u65b0\u5f55\u5236' : 'Record again';
  String get cropPhoto => isChinese ? '\u88c1\u526a' : 'Crop';
  String get usePhoto => isChinese ? '\u4f7f\u7528\u7167\u7247' : 'Use photo';
  String get useVideo => isChinese ? '\u4f7f\u7528\u89c6\u9891' : 'Use video';
  String get cancelCrop =>
      isChinese ? '\u53d6\u6d88\u88c1\u526a' : 'Cancel crop';
  String get applyCrop => isChinese ? '\u5e94\u7528\u88c1\u526a' : 'Apply crop';
  String get croppingPhoto =>
      isChinese ? '\u88c1\u526a\u4e2d...' : 'Cropping...';
  String get photoCropped => isChinese
      ? '\u7167\u7247\u88c1\u526a\u5b8c\u6210\u3002'
      : 'Photo cropped.';
  String cropFailed(Object error) => isChinese
      ? '\u88c1\u526a\u5931\u8d25\uff1a$error'
      : 'Crop failed: $error';
  String get cameraLoading => isChinese
      ? '\u6b63\u5728\u521d\u59cb\u5316\u76f8\u673a...'
      : 'Initializing camera...';
  String get cameraUnavailable => isChinese
      ? '\u672a\u68c0\u6d4b\u5230\u53ef\u7528\u76f8\u673a\u3002'
      : 'No camera available.';
  String get cameraPermissionDenied => isChinese
      ? '\u76f8\u673a\u6743\u9650\u88ab\u62d2\u7edd\u3002'
      : 'Camera permission denied.';
  String cameraInitializationFailed(Object error) => isChinese
      ? '\u76f8\u673a\u521d\u59cb\u5316\u5931\u8d25\uff1a$error'
      : 'Camera initialization failed: $error';
  String cameraCaptureFailed(Object error) => isChinese
      ? '\u62cd\u7167\u5931\u8d25\uff1a$error'
      : 'Capture failed: $error';
  String get switchCamera =>
      isChinese ? '\u5207\u6362\u6444\u50cf\u5934' : 'Switch camera';
  String get photoImported => isChinese
      ? '\u7167\u7247\u5df2\u6dfb\u52a0\u5230\u65e5\u8bb0\u3002'
      : 'Photo added to the entry.';
  String get videoImported => isChinese
      ? '\u89c6\u9891\u5df2\u6dfb\u52a0\u5230\u65e5\u8bb0\u3002'
      : 'Video added to the entry.';
  String get startVideoRecording =>
      isChinese ? '\u5f00\u59cb\u5f55\u89c6\u9891' : 'Start video recording';
  String get stopVideoRecording =>
      isChinese ? '\u505c\u6b62\u5f55\u5236' : 'Stop recording';
  String get recordingVideo =>
      isChinese ? '\u6b63\u5728\u5f55\u5236\u89c6\u9891' : 'Recording video';
  String get videoRecordingSaved => isChinese
      ? '\u89c6\u9891\u5df2\u4fdd\u5b58\u3002'
      : 'Video recording saved.';
  String get tapToPreviewVideo => isChinese
      ? '\u70b9\u51fb\u9884\u89c8\u64ad\u653e'
      : 'Tap to preview playback';
  String get videoSidebarTitle =>
      isChinese ? '\u89c6\u9891\u9884\u89c8' : 'Video previews';
  String get videoSidebarHint => isChinese
      ? '\u65b0\u5f55\u5236\u7684\u89c6\u9891\u4f1a\u663e\u793a\u5728\u8fd9\u91cc\uff0c\u653e\u5728\u53f3\u4fa7\uff0c\u4e0d\u5360\u7528\u6b63\u6587\u533a\u57df\u3002'
      : 'Recorded videos appear here on the right so they do not take over the writing area.';
  String get videoPreviewPageTitle =>
      isChinese ? '\u89c6\u9891\u64ad\u653e' : 'Video preview';
  String get noVideoSelected => isChinese
      ? '\u672a\u9009\u4e2d\u8981\u9884\u89c8\u7684\u89c6\u9891\u3002'
      : 'No video selected for preview.';
  String videoRecordingFailed(Object error) => isChinese
      ? '\u5f55\u5236\u89c6\u9891\u5931\u8d25\uff1a$error'
      : 'Video recording failed: $error';
  String get startRecording =>
      isChinese ? '\u5f00\u59cb\u5f55\u97f3' : 'Start recording';
  String get stopRecording =>
      isChinese ? '\u505c\u6b62\u5f55\u97f3' : 'Stop recording';
  String get transcribing =>
      isChinese ? '\u8f6c\u5199\u4e2d...' : 'Transcribing...';
  String get transcribeLatestAudio => isChinese
      ? '\u8f6c\u5199\u6700\u65b0\u5f55\u97f3'
      : 'Transcribe latest audio';
  String get playAudio => isChinese ? '\u64ad\u653e' : 'Play';
  String get pauseAudio => isChinese ? '\u6682\u505c' : 'Pause';
  String get audioReady => isChinese ? '\u53ef\u64ad\u653e' : 'Ready to play';
  String get audioPlaying => isChinese ? '\u64ad\u653e\u4e2d' : 'Playing';
  String get audioPaused => isChinese ? '\u5df2\u6682\u505c' : 'Paused';
  String playbackFailed(Object error) => isChinese
      ? '\u64ad\u653e\u5931\u8d25\uff1a$error'
      : 'Playback failed: $error';
  String get saving => isChinese ? '\u4fdd\u5b58\u4e2d...' : 'Saving...';
  String get deleting => isChinese
      ? '\u79fb\u5165\u5783\u573e\u6876\u4e2d...'
      : 'Moving to trash...';
  String get saveEntry => isChinese ? '\u4fdd\u5b58\u65e5\u8bb0' : 'Save entry';
  String get updateEntry =>
      isChinese ? '\u66f4\u65b0\u65e5\u8bb0' : 'Update entry';
  String importedImages(int count) => isChinese
      ? '\u5df2\u5bfc\u5165 $count \u5f20\u56fe\u7247\u3002'
      : 'Imported $count image file(s).';
  String get microphonePermissionDenied => isChinese
      ? '\u9ea6\u514b\u98ce\u6743\u9650\u88ab\u62d2\u7edd\u3002'
      : 'Microphone permission denied.';
  String get audioRecordingSaved => isChinese
      ? '\u5f55\u97f3\u5df2\u4fdd\u5b58\u3002'
      : 'Audio recording saved.';
  String get pleaseRecordAudioFirst => isChinese
      ? '\u8bf7\u5148\u5f55\u4e00\u6bb5\u97f3\u9891\u3002'
      : 'Please record audio first.';
  String get transcriptionInserted => isChinese
      ? '\u8f6c\u5199\u5185\u5bb9\u5df2\u63d2\u5165\u6b63\u6587\u3002'
      : 'Transcription inserted into entry content.';
  String get entrySaved => isChinese
      ? '\u65e5\u8bb0\u5df2\u4fdd\u5b58\u5230\u672c\u5730 SQLite\u3002'
      : 'Entry saved to local SQLite.';
  String get entryUpdated =>
      isChinese ? '\u65e5\u8bb0\u5df2\u66f4\u65b0\u3002' : 'Entry updated.';
  String entrySaveFailed(Object error) => isChinese
      ? '\u4fdd\u5b58\u65e5\u8bb0\u5931\u8d25\uff1a$error'
      : 'Save failed: $error';
  String get entryDeleted => isChinese
      ? '\u65e5\u8bb0\u5df2\u79fb\u5165\u5783\u573e\u6876\u3002'
      : 'Entry moved to trash.';
  String get deleteEntryConfirmTitle => isChinese
      ? '\u786e\u8ba4\u5c06\u8fd9\u7bc7\u65e5\u8bb0\u79fb\u5165\u5783\u573e\u6876\uff1f'
      : 'Move this entry to trash?';
  String deleteEntryConfirmMessage(String title) => isChinese
      ? '\u4f60\u4ecd\u53ef\u4ee5\u4ece\u5783\u573e\u6876\u6062\u590d\uff1a$title'
      : 'You can restore it later from trash: $title';
  String get cancelAction => isChinese ? '\u53d6\u6d88' : 'Cancel';
  String get confirmDelete =>
      isChinese ? '\u79fb\u5165\u5783\u573e\u6876' : 'Move to trash';
  String deleteEntryFailed(Object error) => isChinese
      ? '\u79fb\u5165\u5783\u573e\u6876\u5931\u8d25\uff1a$error'
      : 'Move to trash failed: $error';
  String get apiKeyMissing => isChinese
      ? '\u672a\u8bbe\u7f6e OPENAI_API_KEY\uff0c\u5df2\u8df3\u8fc7\u8f6c\u5199\u3002'
      : 'OPENAI_API_KEY not set. Skipping transcription.';
  String get audioFileMissing => isChinese
      ? '\u672a\u627e\u5230\u5f55\u97f3\u6587\u4ef6\u3002'
      : 'Audio file was not found.';
  String transcriptionRequestFailed(int? statusCode) => isChinese
      ? '\u8f6c\u5199\u8bf7\u6c42\u5931\u8d25${statusCode == null ? '' : '\uff08$statusCode\uff09'}\u3002'
      : 'Transcription request failed${statusCode == null ? '' : ' ($statusCode)'}.';
  String get noTranscriptionText => isChinese
      ? '\u672a\u8fd4\u56de\u8f6c\u5199\u6587\u672c\u3002'
      : 'No transcription text returned from API.';

  String moodLabel(DiaryMood moodValue) {
    switch (moodValue) {
      case DiaryMood.happy:
        return isChinese ? '\u5f00\u5fc3' : 'Happy';
      case DiaryMood.calm:
        return isChinese ? '\u5e73\u9759' : 'Calm';
      case DiaryMood.neutral:
        return isChinese ? '\u4e00\u822c' : 'Neutral';
      case DiaryMood.sad:
        return isChinese ? '\u96be\u8fc7' : 'Sad';
      case DiaryMood.angry:
        return isChinese ? '\u751f\u6c14' : 'Angry';
    }
  }

  String mediaLabel(
    DiaryMedia media, {
    String? baseName,
  }) {
    switch (media.type) {
      case MediaType.image:
        return isChinese
            ? '\u56fe\u7247${baseName == null ? '' : '\uff1a$baseName'}'
            : 'Image${baseName == null ? '' : ': $baseName'}';
      case MediaType.audio:
        if (isChinese) {
          final duration =
              media.durationLabel == null ? '' : ' ${media.durationLabel}';
          return '\u5f55\u97f3$duration${baseName == null ? '' : '\uff1a$baseName'}';
        }
        return media.durationLabel == null
            ? 'Audio${baseName == null ? '' : ': $baseName'}'
            : 'Audio ${media.durationLabel}${baseName == null ? '' : ': $baseName'}';
      case MediaType.video:
        if (isChinese) {
          final duration =
              media.durationLabel == null ? '' : ' ${media.durationLabel}';
          return '\u89c6\u9891$duration${baseName == null ? '' : '\uff1a$baseName'}';
        }
        return media.durationLabel == null
            ? 'Video${baseName == null ? '' : ': $baseName'}'
            : 'Video ${media.durationLabel}${baseName == null ? '' : ': $baseName'}';
    }
  }

  String formatDay(DateTime date) {
    return DateFormat('yyyy-MM-dd', locale.languageCode).format(date);
  }

  String formatDateTime(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm', locale.languageCode).format(date);
  }
}

extension AppStringsBuildContext on BuildContext {
  AppStrings get strings => AppStrings.of(this);
}
