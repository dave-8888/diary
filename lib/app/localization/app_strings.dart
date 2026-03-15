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

  String get appTitle => isChinese ? '我的日记' : 'Diary';
  String get language => isChinese ? '语言' : 'Language';
  String get systemLanguage => isChinese ? '跟随系统' : 'System';
  String get englishLanguage => 'English';
  String get chineseLanguage => '中文';

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

  String get homeNav => isChinese ? '首页' : 'Home';
  String get writeNav => isChinese ? '写日记' : 'Write';
  String get timelineNav => isChinese ? '时间轴' : 'Timeline';

  String get newEntry => isChinese ? '新建日记' : 'New Entry';
  String get today => isChinese ? '今天' : 'Today';
  String get recentEntries => isChinese ? '最近日记' : 'Recent entries';
  String get viewAll => isChinese ? '查看全部' : 'View all';
  String get startCapturingToday => isChinese
      ? '开始记录今天吧，把文字、心情和声音都留下来。'
      : 'Start capturing today with words, mood, and voice.';
  String get firstEntryPrompt => isChinese
      ? 'MVP 已准备好，开始写第一篇日记吧。'
      : 'The MVP is ready for your first diary entry.';
  String failedToLoadEntries(Object error) =>
      isChinese ? '加载日记失败：$error' : 'Failed to load entries: $error';
  String failedToLoadTimeline(Object error) =>
      isChinese ? '加载时间轴失败：$error' : 'Failed to load timeline: $error';
  String get noEntriesYet => isChinese
      ? '还没有日记，先从第一篇开始吧。'
      : 'No entries yet. Start with your first note.';

  String dayHeading(DateTime date) => '$today · ${formatDay(date)}';

  String latestSummary(DiaryEntry? entry) {
    if (entry == null) return startCapturingToday;
    return '${entry.mood.emoji} ${moodLabel(entry.mood)} · ${entry.title}';
  }

  String get whatHappenedToday =>
      isChinese ? '今天发生了什么？' : 'What happened today?';
  String get titleLabel => isChinese ? '标题' : 'Title';
  String get titleHint =>
      isChinese ? '例如：公园的下午' : 'For example: Afternoon in the park';
  String get contentLabel => isChinese ? '内容' : 'Content';
  String get contentHint => isChinese
      ? '写下今天发生的事、你的感受，以及想留下的记忆...'
      : 'Write down what happened, how you felt, and what you want to remember...';
  String get locationLabel => isChinese ? '地点' : 'Location';
  String get locationHint =>
      isChinese ? '例如：家 / 公司 / 上海' : 'For example: Home / Office / Shanghai';
  String get mood => isChinese ? '心情' : 'Mood';
  String get mediaToolbar => isChinese ? '媒体工具栏' : 'Media toolbar';
  String get importImage => isChinese ? '导入图片' : 'Import image';
  String get startRecording => isChinese ? '开始录音' : 'Start recording';
  String get stopRecording => isChinese ? '停止录音' : 'Stop recording';
  String get transcribing => isChinese ? '转写中...' : 'Transcribing...';
  String get transcribeLatestAudio =>
      isChinese ? '转写最新录音' : 'Transcribe latest audio';
  String get saving => isChinese ? '保存中...' : 'Saving...';
  String get saveEntry => isChinese ? '保存日记' : 'Save entry';
  String importedImages(int count) =>
      isChinese ? '已导入 $count 张图片。' : 'Imported $count image file(s).';
  String get microphonePermissionDenied =>
      isChinese ? '麦克风权限被拒绝。' : 'Microphone permission denied.';
  String get audioRecordingSaved =>
      isChinese ? '录音已保存。' : 'Audio recording saved.';
  String get pleaseRecordAudioFirst =>
      isChinese ? '请先录一段音频。' : 'Please record audio first.';
  String get transcriptionInserted =>
      isChinese ? '转写内容已插入正文。' : 'Transcription inserted into entry content.';
  String get entrySaved =>
      isChinese ? '日记已保存到本地 SQLite。' : 'Entry saved to local SQLite.';
  String get apiKeyMissing => isChinese
      ? '未设置 OPENAI_API_KEY，已跳过转写。'
      : 'OPENAI_API_KEY not set. Skipping transcription.';
  String get audioFileMissing =>
      isChinese ? '未找到录音文件。' : 'Audio file was not found.';
  String transcriptionRequestFailed(int? statusCode) => isChinese
      ? '转写请求失败${statusCode == null ? '' : '（$statusCode）'}。'
      : 'Transcription request failed${statusCode == null ? '' : ' ($statusCode)'}.';
  String get noTranscriptionText =>
      isChinese ? '未返回转写文本。' : 'No transcription text returned from API.';

  String moodLabel(DiaryMood moodValue) {
    switch (moodValue) {
      case DiaryMood.happy:
        return isChinese ? '开心' : 'Happy';
      case DiaryMood.calm:
        return isChinese ? '平静' : 'Calm';
      case DiaryMood.neutral:
        return isChinese ? '一般' : 'Neutral';
      case DiaryMood.sad:
        return isChinese ? '难过' : 'Sad';
      case DiaryMood.angry:
        return isChinese ? '生气' : 'Angry';
    }
  }

  String mediaLabel(
    DiaryMedia media, {
    String? baseName,
  }) {
    switch (media.type) {
      case MediaType.image:
        return isChinese
            ? '图片${baseName == null ? '' : '：$baseName'}'
            : 'Image${baseName == null ? '' : ': $baseName'}';
      case MediaType.audio:
        if (isChinese) {
          final duration =
              media.durationLabel == null ? '' : ' ${media.durationLabel}';
          return '录音$duration${baseName == null ? '' : '：$baseName'}';
        }
        return media.durationLabel == null
            ? 'Audio${baseName == null ? '' : ': $baseName'}'
            : 'Audio ${media.durationLabel}${baseName == null ? '' : ': $baseName'}';
      case MediaType.video:
        return isChinese
            ? '视频${baseName == null ? '' : '：$baseName'}'
            : 'Video${baseName == null ? '' : ': $baseName'}';
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
