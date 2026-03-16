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

  String get appTitle => isChinese ? '\u6211\u7684\u65e5\u8bb0' : 'Diary';
  String get language => isChinese ? '\u8bed\u8a00' : 'Language';
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
  String get viewAll => isChinese ? '\u67e5\u770b\u5168\u90e8' : 'View all';
  String get previewEntry =>
      isChinese ? '\u9884\u89c8\u65e5\u8bb0' : 'Preview entry';
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
  String get firstEntryPrompt => isChinese
      ? 'MVP \u5df2\u51c6\u5907\u597d\uff0c\u5f00\u59cb\u5199\u7b2c\u4e00\u7bc7\u65e5\u8bb0\u5427\u3002'
      : 'The MVP is ready for your first diary entry.';
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

  String dayHeading(DateTime date) => '$today - ${formatDay(date)}';

  String latestSummary(DiaryEntry? entry) {
    if (entry == null) return startCapturingToday;
    return '${entry.mood.emoji} ${moodLabel(entry.mood)} - ${entry.title}';
  }

  String get whatHappenedToday => isChinese
      ? '\u4eca\u5929\u53d1\u751f\u4e86\u4ec0\u4e48\uff1f'
      : 'What happened today?';
  String get titleLabel => isChinese ? '\u6807\u9898' : 'Title';
  String get titleHint => isChinese
      ? '\u4f8b\u5982\uff1a\u516c\u56ed\u7684\u4e0b\u5348'
      : 'For example: Afternoon in the park';
  String get contentLabel => isChinese ? '\u5185\u5bb9' : 'Content';
  String get contentHint => isChinese
      ? '\u5199\u4e0b\u4eca\u5929\u53d1\u751f\u7684\u4e8b\u3001\u4f60\u7684\u611f\u53d7\uff0c\u4ee5\u53ca\u60f3\u7559\u4e0b\u7684\u8bb0\u5fc6...'
      : 'Write down what happened, how you felt, and what you want to remember...';
  String get locationLabel => isChinese ? '\u5730\u70b9' : 'Location';
  String get locationHint => isChinese
      ? '\u4f8b\u5982\uff1a\u5bb6 / \u516c\u53f8 / \u4e0a\u6d77'
      : 'For example: Home / Office / Shanghai';
  String get mood => isChinese ? '\u5fc3\u60c5' : 'Mood';
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
