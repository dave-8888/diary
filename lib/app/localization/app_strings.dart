import 'package:diary_mvp/app/app_icon.dart';
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
  String get settingsTitle => isChinese ? '\u8bbe\u7f6e' : 'Settings';
  String get settingsTooltip =>
      isChinese ? '\u6253\u5f00\u8bbe\u7f6e' : 'Open settings';
  String get diaryAiVisibilityLabel =>
      isChinese ? '\u0041\u0049\u5206\u6790' : 'AI analysis';
  String get diaryAiVisibilityHint => isChinese
      ? '\u63a7\u5236\u5199\u65e5\u8bb0\u9875\u9762\u662f\u5426\u5c55\u793a AI \u5206\u6790\u52a9\u624b\u3002'
      : 'Control whether the AI analysis assistant is shown on the editor page.';
  String get enabledLabel => isChinese ? '\u5f00\u542f' : 'On';
  String get disabledLabel => isChinese ? '\u5173\u95ed' : 'Off';
  String diaryAiVisibilityStatus(bool enabled) =>
      '$diaryAiVisibilityLabel\uff1a${enabled ? enabledLabel : disabledLabel}';
  String get diaryAiVisibilityUpdated => isChinese
      ? 'AI \u5206\u6790\u663e\u793a\u72b6\u6001\u5df2\u66f4\u65b0\u3002'
      : 'AI analysis visibility updated.';
  String diaryAiVisibilityUpdateFailed(Object error) => isChinese
      ? '\u66f4\u65b0 AI \u5206\u6790\u663e\u793a\u72b6\u6001\u5931\u8d25\uff1a$error'
      : 'Failed to update AI analysis visibility: $error';
  String get emotionalCompanionLabel =>
      isChinese ? '\u60c5\u7eea\u966a\u4f34' : 'Emotional companion';
  String get emotionalCompanionHint => isChinese
      ? '\u5728 AI \u5206\u6790\u7ed3\u679c\u4e2d\u589e\u52a0\u60c5\u7eea\u5206\u7c7b\u3001\u5b89\u629a\u56de\u590d\u3001\u98ce\u683c\u81ea\u9002\u5e94\u548c\u91cd\u8981\u60c5\u7eea\u589e\u5f3a\u53cd\u9988\u3002'
      : 'Add emotion classification, comforting replies, adaptive style, and enhanced feedback for important emotions to AI results.';
  String emotionalCompanionStatus(bool enabled) =>
      '$emotionalCompanionLabel\uff1a${enabled ? enabledLabel : disabledLabel}';
  String get emotionalCompanionUpdated => isChinese
      ? '\u60c5\u7eea\u966a\u4f34\u663e\u793a\u72b6\u6001\u5df2\u66f4\u65b0\u3002'
      : 'Emotional companion visibility updated.';
  String emotionalCompanionUpdateFailed(Object error) => isChinese
      ? '\u66f4\u65b0\u60c5\u7eea\u966a\u4f34\u663e\u793a\u72b6\u6001\u5931\u8d25\uff1a$error'
      : 'Failed to update emotional companion visibility: $error';
  String get problemSuggestionLabel =>
      isChinese ? 'AI \u95ee\u9898\u5efa\u8bae' : 'AI problem suggestions';
  String get problemSuggestionHint => isChinese
      ? '\u5728 AI \u5206\u6790\u7ed3\u679c\u4e2d\u589e\u52a0\u56f0\u6270\u8bc6\u522b\u548c\u95ee\u9898\u5206\u6790\uff0c\u5e76\u907f\u514d\u8bf4\u6559\u5f0f\u56de\u7b54\u3002'
      : 'Add distress identification and problem analysis to AI results while avoiding preachy responses.';
  String problemSuggestionStatus(bool enabled) =>
      '$problemSuggestionLabel\uff1a${enabled ? enabledLabel : disabledLabel}';
  String get problemSuggestionUpdated => isChinese
      ? 'AI \u95ee\u9898\u5efa\u8bae\u663e\u793a\u72b6\u6001\u5df2\u66f4\u65b0\u3002'
      : 'AI problem suggestion visibility updated.';
  String problemSuggestionUpdateFailed(Object error) => isChinese
      ? '\u66f4\u65b0 AI \u95ee\u9898\u5efa\u8bae\u663e\u793a\u72b6\u6001\u5931\u8d25\uff1a$error'
      : 'Failed to update AI problem suggestion visibility: $error';
  String get language => isChinese ? '\u8bed\u8a00' : 'Language';
  String get themeSettingsHint => isChinese
      ? '\u5207\u6362\u5e94\u7528\u4e3b\u9898\uff0c\u4e0d\u540c\u4e3b\u9898\u4f1a\u6709\u4e0d\u540c\u7684\u9996\u9875\u5934\u56fe\u548c\u80cc\u666f\u98ce\u683c\u3002'
      : 'Switch the app theme. Each theme comes with its own home hero and background style.';
  String get themeUpdated =>
      isChinese ? '\u4e3b\u9898\u5df2\u66f4\u65b0\u3002' : 'Theme updated.';
  String themeUpdateFailed(Object error) => isChinese
      ? '\u4fdd\u5b58\u4e3b\u9898\u5931\u8d25\uff1a$error'
      : 'Failed to save theme: $error';
  String get languageSettingsHint => isChinese
      ? '\u9009\u62e9\u5e94\u7528\u754c\u9762\u8bed\u8a00\uff0c\u4e5f\u53ef\u4ee5\u8ddf\u968f\u7cfb\u7edf\u3002'
      : 'Choose the app language or follow the system setting.';
  String get diaryListSettingsTitle =>
      isChinese ? '\u65e5\u8bb0\u5217\u8868' : 'Diary list';
  String get diaryListSettingsHint => isChinese
      ? '\u63a7\u5236\u9996\u9875\u3001\u65f6\u95f4\u8f74\u548c\u5783\u573e\u6876\u5217\u8868\u4e2d\u662f\u5426\u663e\u793a\u56fe\u7247\u4e0e\u89c6\u9891\u9884\u89c8\u3002'
      : 'Control whether image and video previews are shown in diary lists on Home, Timeline, and Trash.';
  String get diaryListShowVisualMediaLabel => isChinese
      ? '\u663e\u793a\u56fe\u7247\u548c\u89c6\u9891'
      : 'Show images and videos';
  String get diaryListShowVisualMediaHint => isChinese
      ? '\u5173\u95ed\u540e\uff0c\u65e5\u8bb0\u5217\u8868\u5c06\u9690\u85cf\u56fe\u7247\u4e0e\u89c6\u9891\u9884\u89c8\uff0c\u4f46\u4e0d\u5f71\u54cd\u6b63\u6587\u548c\u97f3\u9891\u3002'
      : 'When off, diary lists hide image and video previews without affecting text or audio.';
  String get diaryListShowVisualMediaUpdated => isChinese
      ? '\u65e5\u8bb0\u5217\u8868\u5a92\u4f53\u663e\u793a\u8bbe\u7f6e\u5df2\u66f4\u65b0\u3002'
      : 'Diary list media visibility updated.';
  String diaryListShowVisualMediaUpdateFailed(Object error) => isChinese
      ? '\u66f4\u65b0\u65e5\u8bb0\u5217\u8868\u5a92\u4f53\u663e\u793a\u8bbe\u7f6e\u5931\u8d25\uff1a$error'
      : 'Failed to update diary list media visibility: $error';
  String get languageUpdated =>
      isChinese ? '\u8bed\u8a00\u5df2\u66f4\u65b0\u3002' : 'Language updated.';
  String languageUpdateFailed(Object error) => isChinese
      ? '\u4fdd\u5b58\u8bed\u8a00\u5931\u8d25\uff1a$error'
      : 'Failed to save language: $error';
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
      case DiaryThemePreset.girlPink:
        return isChinese ? '\u5c11\u5973\u7c89' : 'Girl Pink';
      case DiaryThemePreset.barbieShockPink:
        return isChinese
            ? '\u6b7b\u4ea1\u82ad\u6bd4\u7c89'
            : 'Barbie Shock Pink';
      case DiaryThemePreset.kidPink:
        return isChinese
            ? '\u5feb\u4e50\u7684\u5c0f\u5b69\u7c89'
            : 'Happy Kid Pink';
      case DiaryThemePreset.happyBoy:
        return isChinese ? '\u5feb\u4e50\u7684\u7537\u5b69' : 'Happy Boy';
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

  String titleForAppIcon(AppIconPreset preset) {
    switch (preset) {
      case AppIconPreset.orbital:
        return isChinese ? '\u8f68\u9053\u65e5\u5fd7' : 'Orbital Log';
      case AppIconPreset.sunrise:
        return isChinese ? '\u6668\u5149\u8bb0\u4e8b' : 'Sunrise Note';
      case AppIconPreset.neonPulse:
        return isChinese ? '\u9727\u8679\u8109\u51b2' : 'Neon Pulse';
      case AppIconPreset.terminalCore:
        return isChinese ? '\u7ec8\u7aef\u6838\u5fc3' : 'Terminal Core';
      case AppIconPreset.navigator:
        return isChinese ? '\u661f\u822a\u6307\u9488' : 'Star Navigator';
    }
  }

  String heroLabelForTheme(DiaryThemePreset themePreset) {
    switch (themePreset) {
      case DiaryThemePreset.daylight:
        return isChinese ? '\u6668\u5149\u8bb0\u5f55' : 'DAYLIGHT LOG';
      case DiaryThemePreset.girlPink:
        return isChinese ? '\u7c89\u8272\u5fc3\u4e8b' : 'ROSE LETTER';
      case DiaryThemePreset.barbieShockPink:
        return isChinese ? '\u70ed\u7c89\u5931\u63a7' : 'HOT PINK ALERT';
      case DiaryThemePreset.kidPink:
        return isChinese ? '\u7cd6\u679c\u5192\u9669' : 'CANDY PLAY';
      case DiaryThemePreset.happyBoy:
        return isChinese ? '\u84dd\u5929\u4ff1\u4e50\u90e8' : 'SUNNY CLUB';
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
  String get appIdentityTitle =>
      isChinese ? '\u5e94\u7528\u6807\u8bc6' : 'App identity';
  String get appIdentityHint => isChinese
      ? '\u81ea\u5b9a\u4e49\u5e94\u7528\u540d\uff0c\u5e76\u7528\u540c\u4e00\u5957\u56fe\u6807\u540c\u6b65\u5e94\u7528\u5185\u548c Windows \u5916\u5c42\u7a97\u53e3\u3002'
      : 'Customize the app name, and keep the in-app and Windows outer icon in sync with one icon setting.';
  String get appNameDesktopHint => isChinese
      ? '\u4fdd\u5b58\u540e\u4f1a\u540c\u6b65\u66f4\u65b0\u5e94\u7528\u5185\u540d\u79f0\u548c Windows \u6807\u9898\u680f\u540d\u79f0\u3002'
      : 'Saving here updates both the in-app name and the Windows title bar name.';
  String get appIconTitle =>
      isChinese ? '\u5e94\u7528\u56fe\u6807' : 'App icon';
  String get appIconHint => isChinese
      ? '\u53ef\u4ee5\u9009\u62e9\u9884\u8bbe\u56fe\u6807\uff0c\u4e5f\u53ef\u4ee5\u4e0a\u4f20 PNG / JPG / WebP / BMP \u56fe\u7247\u4f5c\u4e3a\u81ea\u5b9a\u4e49\u56fe\u6807\u3002\u8bbe\u7f6e\u540e\uff0c\u5e94\u7528\u5185\u548c Windows \u5916\u5c42\u56fe\u6807\u4f1a\u4e00\u8d77\u66f4\u65b0\u3002'
      : 'Choose a preset icon or upload a PNG / JPG / WebP / BMP image as a custom icon. The in-app and Windows outer icon will update together.';
  String get resetAppIcon => isChinese
      ? '\u6062\u590d\u9ed8\u8ba4\u5e94\u7528\u56fe\u6807'
      : 'Reset app icon';
  String get appIconUpdated => isChinese
      ? '\u5e94\u7528\u56fe\u6807\u5df2\u66f4\u65b0\uff0c\u5e94\u7528\u5185\u548c Windows \u5916\u5c42\u5df2\u540c\u6b65\u3002'
      : 'App icon updated and synced to the Windows outer window.';
  String get appIconReset => isChinese
      ? '\u5df2\u6062\u590d\u9ed8\u8ba4\u56fe\u6807\u3002'
      : 'App icon reset to default.';
  String appIconUpdateFailed(Object error) => isChinese
      ? '\u4fdd\u5b58\u5e94\u7528\u56fe\u6807\u5931\u8d25\uff1a$error'
      : 'Failed to save app icon: $error';
  String get windowIconTitle =>
      isChinese ? 'Windows \u5916\u5c42\u56fe\u6807' : 'Windows outer icon';
  String get windowIconHint => isChinese
      ? '\u53ef\u4ee5\u9009\u62e9 PNG / JPG / WebP / BMP \u56fe\u7247\uff0c\u5e94\u7528\u4f1a\u81ea\u52a8\u88c1\u526a\u6210\u65b9\u5f62\u5e76\u7f29\u653e\u5230 256x256\uff0c\u7528\u4e8e\u6807\u9898\u680f\u548c\u4efb\u52a1\u680f\u9884\u89c8\u3002'
      : 'Choose a PNG / JPG / WebP / BMP image. The app will crop it to a square and resize it to 256x256 for the title bar and taskbar preview.';
  String get windowIconPlatformHint => isChinese
      ? '\u76ee\u524d\u53ea\u6709 Windows \u684c\u9762\u7aef\u652f\u6301\u5b9e\u65f6\u66f4\u65b0\u5916\u5c42\u7a97\u53e3\u56fe\u6807\u3002'
      : 'Live outer window icon updates are currently available on Windows desktop only.';
  String get buildWindowIconHint => isChinese
      ? '\u5982\u679c\u4f60\u5e0c\u671b `exe` \u9ed8\u8ba4\u56fe\u6807\u4e5f\u4e00\u8d77\u66f4\u65b0\uff0c\u53ef\u4ee5\u628a\u5f53\u524d\u5916\u5c42\u56fe\u6807\u540c\u6b65\u5230 Windows \u6784\u5efa\u8d44\u6e90\u3002\u9700\u8981\u91cd\u65b0 `flutter run/build windows` \u540e\u751f\u6548\u3002'
      : 'If you also want the default `exe` icon to change, sync the current outer icon into the Windows build resources. Rebuild with `flutter run/build windows` afterward.';
  String get buildWindowIconUnavailableHint => isChinese
      ? '\u5f53\u524d\u6ca1\u6709\u68c0\u6d4b\u5230 Windows \u9879\u76ee\u6e90\u7801\u76ee\u5f55\uff0c\u65e0\u6cd5\u76f4\u63a5\u4fee\u6539\u6784\u5efa\u9ed8\u8ba4\u56fe\u6807\u3002'
      : 'The Windows project source directory was not detected, so the build-time default icon cannot be updated here.';
  String get pickWindowIcon =>
      isChinese ? '\u9009\u62e9\u56fe\u7247' : 'Choose image';
  String get resetWindowIcon => isChinese
      ? '\u6062\u590d\u9ed8\u8ba4\u5916\u5c42\u56fe\u6807'
      : 'Reset outer icon';
  String get syncBuildWindowIcon => isChinese
      ? '\u540c\u6b65\u4e3a Windows \u9ed8\u8ba4\u56fe\u6807'
      : 'Sync as Windows default icon';
  String get resetBuildWindowIcon => isChinese
      ? '\u6062\u590d Windows \u9ed8\u8ba4\u6784\u5efa\u56fe\u6807'
      : 'Reset Windows build icon';
  String get currentWindowIcon =>
      isChinese ? '\u5f53\u524d\u5e94\u7528\u56fe\u6807' : 'Current app icon';
  String get defaultWindowIcon => isChinese
      ? '\u9ed8\u8ba4\u7cfb\u7edf\u56fe\u6807'
      : 'Default system icon';
  String get windowIconUpdated => isChinese
      ? 'Windows \u5916\u5c42\u56fe\u6807\u5df2\u66f4\u65b0\u3002'
      : 'Windows outer icon updated.';
  String get windowIconReset => isChinese
      ? '\u5df2\u6062\u590d\u9ed8\u8ba4 Windows \u5916\u5c42\u56fe\u6807\u3002'
      : 'Windows outer icon reset to default.';
  String windowIconUpdateFailed(Object error) => isChinese
      ? '\u4fdd\u5b58 Windows \u5916\u5c42\u56fe\u6807\u5931\u8d25\uff1a$error'
      : 'Failed to save the Windows outer icon: $error';
  String get buildWindowIconApplied => isChinese
      ? 'Windows \u6784\u5efa\u9ed8\u8ba4\u56fe\u6807\u5df2\u540c\u6b65\uff0c\u91cd\u65b0 build/run \u540e\u751f\u6548\u3002'
      : 'The Windows build default icon has been synced. Rebuild or rerun to apply it.';
  String get buildWindowIconReset => isChinese
      ? 'Windows \u6784\u5efa\u9ed8\u8ba4\u56fe\u6807\u5df2\u6062\u590d\u3002'
      : 'The Windows build default icon has been restored.';
  String buildWindowIconFailed(Object error) => isChinese
      ? '\u540c\u6b65 Windows \u6784\u5efa\u56fe\u6807\u5931\u8d25\uff1a$error'
      : 'Failed to sync the Windows build icon: $error';
  String get diaryAiSettingsTitle => isChinese ? '日记 AI' : 'Diary AI';
  String get diaryAiSettingsHint => isChinese
      ? '在这里配置阿里云百炼 API Key，用于日记总结、情绪识别、标签提取和标题生成。'
      : 'Configure your Alibaba Cloud DashScope API key here for diary summaries, mood detection, tag extraction, and title generation.';
  String get aliyunApiKeyLabel =>
      isChinese ? '阿里云百炼 API Key' : 'Alibaba Cloud DashScope API Key';
  String get aliyunApiKeyHint =>
      isChinese ? '输入 sk-... 形式的 Key' : 'Enter a key like sk-...';
  String get diaryAiApiKeyUpdated =>
      isChinese ? '阿里云 AI Key 已更新。' : 'Alibaba Cloud AI key updated.';
  String get diaryAiApiKeyReset =>
      isChinese ? '已移除本地阿里云 AI Key。' : 'Local Alibaba Cloud AI key removed.';
  String diaryAiApiKeyUpdateFailed(Object error) => isChinese
      ? '保存阿里云 AI Key 失败：$error'
      : 'Failed to save the Alibaba Cloud AI key: $error';
  String get diaryAiApiKeyEnvironmentHint => isChinese
      ? '当前没有本地 Key；如果启动时提供了 DASHSCOPE_API_KEY，也会自动使用。'
      : 'If no local key is saved, the app will still use DASHSCOPE_API_KEY when provided at launch.';
  String get usingDiaryAiEnvironmentApiKey => isChinese
      ? '当前正在使用启动参数中的阿里云 AI Key。'
      : 'Currently using the Alibaba Cloud AI key provided at launch.';
  String get transcriptionSettingsTitle =>
      isChinese ? 'AI \u8f6c\u5199' : 'AI transcription';
  String get transcriptionSettingsHint => isChinese
      ? '\u5728\u8fd9\u91cc\u914d\u7f6e OpenAI API Key\uff0c\u5f55\u97f3\u8f6c\u6587\u5b57\u4f1a\u4f18\u5148\u4f7f\u7528\u672c\u5730\u4fdd\u5b58\u7684 Key\u3002'
      : 'Configure your OpenAI API key here. Audio transcription will use the saved key first.';
  String get openAiApiKeyLabel =>
      isChinese ? 'OpenAI API Key' : 'OpenAI API Key';
  String get openAiApiKeyHint => isChinese
      ? '\u8f93\u5165 sk-... \u5f62\u5f0f\u7684 Key'
      : 'Enter a key like sk-...';
  String get resetApiKey =>
      isChinese ? '\u79fb\u9664\u672c\u5730 Key' : 'Remove local key';
  String get apiKeyUpdated =>
      isChinese ? 'API Key \u5df2\u66f4\u65b0\u3002' : 'API key updated.';
  String get apiKeyReset => isChinese
      ? '\u5df2\u79fb\u9664\u672c\u5730 API Key\u3002'
      : 'Local API key removed.';
  String apiKeyUpdateFailed(Object error) => isChinese
      ? '\u4fdd\u5b58 API Key \u5931\u8d25\uff1a$error'
      : 'Failed to save API key: $error';
  String get apiKeyEnvironmentHint => isChinese
      ? '\u5f53\u524d\u6ca1\u6709\u672c\u5730 Key\uff0c\u82e5\u542f\u52a8\u65f6\u8bbe\u7f6e\u4e86 OPENAI_API_KEY\uff0c\u4e5f\u4f1a\u81ea\u52a8\u4f7f\u7528\u3002'
      : 'If no local key is saved, the app will still use OPENAI_API_KEY when provided at launch.';
  String get usingEnvironmentApiKey => isChinese
      ? '\u5f53\u524d\u6b63\u5728\u4f7f\u7528\u542f\u52a8\u53c2\u6570\u4e2d\u7684 API Key\u3002'
      : 'Currently using the API key provided at launch.';
  String get passwordSettingsTitle => isChinese ? '\u5bc6\u7801' : 'Password';
  String get passwordSettingsHint => isChinese
      ? '\u8bbe\u7f6e\u542f\u52a8\u5bc6\u7801\uff0c\u5e94\u7528\u6253\u5f00\u65f6\u9700\u5148\u89e3\u9501\uff0c\u652f\u6301\u6587\u672c\u3001\u6570\u5b57\u548c\u7b26\u53f7\u3002'
      : 'Set a startup password to unlock the app when it opens. Letters, numbers, and symbols are supported.';
  String passwordStatus(bool enabled) =>
      '$passwordSettingsTitle\uff1a${enabled ? enabledLabel : disabledLabel}';
  String get currentPasscodeLabel =>
      isChinese ? '\u5f53\u524d\u5bc6\u7801' : 'Current password';
  String get newPasscodeLabel =>
      isChinese ? '\u65b0\u5bc6\u7801' : 'New password';
  String get confirmPasscodeLabel =>
      isChinese ? '\u786e\u8ba4\u5bc6\u7801' : 'Confirm password';
  String get passcodeLabel => isChinese ? '\u5bc6\u7801' : 'Password';
  String get passcodeHint =>
      isChinese ? '\u8f93\u5165\u5bc6\u7801' : 'Enter password';
  String get setPasscodeAction =>
      isChinese ? '\u8bbe\u7f6e\u5bc6\u7801' : 'Set password';
  String get changePasscodeAction =>
      isChinese ? '\u4fee\u6539\u5bc6\u7801' : 'Change password';
  String get passcodeSaved =>
      isChinese ? '\u5bc6\u7801\u5df2\u4fdd\u5b58\u3002' : 'Password saved.';
  String get passcodeUpdated =>
      isChinese ? '\u5bc6\u7801\u5df2\u66f4\u65b0\u3002' : 'Password updated.';
  String get passcodeDisabled => isChinese
      ? '\u5bc6\u7801\u5df2\u5173\u95ed\u3002'
      : 'Password turned off.';
  String passcodeSaveFailed(Object error) => isChinese
      ? '\u4fdd\u5b58\u5bc6\u7801\u5931\u8d25\uff1a$error'
      : 'Failed to save the password: $error';
  String get passcodeCannotBeEmpty => isChinese
      ? '\u5bc6\u7801\u4e0d\u80fd\u4e3a\u7a7a\u3002'
      : 'Password cannot be empty.';
  String get passcodeMismatch => isChinese
      ? '\u4e24\u6b21\u8f93\u5165\u7684\u5bc6\u7801\u4e0d\u4e00\u81f4\u3002'
      : 'The two passwords do not match.';
  String get currentPasscodeIncorrect => isChinese
      ? '\u5f53\u524d\u5bc6\u7801\u4e0d\u6b63\u786e\u3002'
      : 'Current password is incorrect.';
  String get disablePasscode =>
      isChinese ? '\u5173\u95ed\u5bc6\u7801' : 'Turn off password';
  String get disablePasscodeTitle => isChinese
      ? '\u5173\u95ed\u542f\u52a8\u5bc6\u7801\uff1f'
      : 'Turn off the startup password?';
  String get disablePasscodeMessage => isChinese
      ? '\u5173\u95ed\u540e\uff0c\u4e0b\u6b21\u542f\u52a8\u5c06\u4e0d\u518d\u9700\u8981\u89e3\u9501\u3002'
      : 'After turning it off, the app will no longer require unlocking on startup.';
  String get confirmDisablePasscode =>
      isChinese ? '\u5173\u95ed\u5bc6\u7801' : 'Turn off password';
  String get unlockAppTitle =>
      isChinese ? '\u89e3\u9501\u65e5\u8bb0' : 'Unlock diary';
  String get unlockAppHint => isChinese
      ? '\u8bf7\u8f93\u5165\u5bc6\u7801\u4ee5\u7ee7\u7eed\u3002'
      : 'Enter your password to continue.';
  String get unlockAction => isChinese ? '\u89e3\u9501' : 'Unlock';
  String get unlockFailed => isChinese
      ? '\u5bc6\u7801\u9519\u8bef\uff0c\u8bf7\u91cd\u8bd5\u3002'
      : 'Incorrect password. Please try again.';
  String passwordInitializationFailed(Object error) => isChinese
      ? '\u521d\u59cb\u5316\u5bc6\u7801\u72b6\u6001\u5931\u8d25\uff1a$error'
      : 'Failed to initialize the password state: $error';
  String get moodLibraryTitle =>
      isChinese ? '\u60c5\u7eea\u5e93' : 'Mood library';
  String get moodLibraryHint => isChinese
      ? '\u81ea\u7531\u65b0\u589e\u548c\u7f16\u8f91\u60c5\u7eea\uff0c\u4e5f\u53ef\u4e00\u952e\u6062\u590d\u9ed8\u8ba4\u60c5\u7eea\u3002'
      : 'Add and edit moods freely, or restore the default set with one click.';
  String get addMood => isChinese ? '\u6dfb\u52a0\u60c5\u7eea' : 'Add mood';
  String get editMood => isChinese ? '\u7f16\u8f91\u60c5\u7eea' : 'Edit mood';
  String get moodNameLabel =>
      isChinese ? '\u60c5\u7eea\u540d\u79f0' : 'Mood name';
  String get moodNameHint => isChinese
      ? '\u4f8b\u5982\uff1a\u5145\u6ee1\u5e0c\u671b'
      : 'For example: Hopeful';
  String get moodEmojiLabel => isChinese ? 'Emoji' : 'Emoji';
  String get moodEmojiHint =>
      isChinese ? '\u4f8b\u5982\uff1a✨ / 😌' : 'For example: ✨ / 😌';
  String get restoreDefaultMoods => isChinese
      ? '\u6062\u590d\u9ed8\u8ba4\u60c5\u7eea'
      : 'Restore default moods';
  String get restoreDefaultMoodsTitle => isChinese
      ? '\u6062\u590d\u9ed8\u8ba4\u60c5\u7eea\uff1f'
      : 'Restore default moods?';
  String get restoreDefaultMoodsMessage => isChinese
      ? '\u8fd9\u4f1a\u79fb\u9664\u6240\u6709\u81ea\u5b9a\u4e49\u60c5\u7eea\uff0c\u5e76\u5c06\u7f3a\u5931\u7684\u60c5\u7eea\u6062\u590d\u6210\u9ed8\u8ba4\u914d\u7f6e\u3002'
      : 'This removes all custom moods and restores the default mood set.';
  String get moodSaved =>
      isChinese ? '\u60c5\u7eea\u5df2\u66f4\u65b0\u3002' : 'Mood updated.';
  String get moodCreated =>
      isChinese ? '\u5df2\u6dfb\u52a0\u65b0\u60c5\u7eea\u3002' : 'Mood added.';
  String moodSaveFailed(Object error) => isChinese
      ? '\u4fdd\u5b58\u60c5\u7eea\u5931\u8d25\uff1a$error'
      : 'Failed to save mood: $error';
  String failedToLoadMoods(Object error) => isChinese
      ? '\u52a0\u8f7d\u60c5\u7eea\u5931\u8d25\uff1a$error'
      : 'Failed to load moods: $error';
  String get moodsReset => isChinese
      ? '\u5df2\u6062\u590d\u9ed8\u8ba4\u60c5\u7eea\u3002'
      : 'Default moods restored.';
  String moodResetFailed(Object error) => isChinese
      ? '\u6062\u590d\u60c5\u7eea\u5931\u8d25\uff1a$error'
      : 'Failed to restore moods: $error';
  String get moodLibraryEmpty => isChinese
      ? '\u6682\u65f6\u8fd8\u6ca1\u6709\u53ef\u7528\u60c5\u7eea\u3002'
      : 'No moods available yet.';
  String get defaultMoodBadge =>
      isChinese ? '\u9ed8\u8ba4\u60c5\u7eea' : 'Default mood';
  String get customMoodBadge =>
      isChinese ? '\u81ea\u5b9a\u4e49\u60c5\u7eea' : 'Custom mood';
  String get openMigrationPage => isChinese
      ? '\u6253\u5f00\u6570\u636e\u8fc1\u79fb'
      : 'Open migration tools';

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
  String get diaryAiToolsTitle => isChinese ? 'AI 日记助手' : 'AI diary assistant';
  String get diaryAiToolsHint => isChinese
      ? '一键生成日记总结、识别情绪、提取标签，并推荐标题。'
      : 'Generate a diary summary, detect mood, extract tags, and suggest a title in one step.';
  String get analyzeDiaryWithAi => isChinese ? '开始分析' : 'Start analysis';
  String get reanalyzeDiaryWithAi => isChinese ? '重新分析' : 'Reanalyze';
  String get analyzingDiaryWithAi => isChinese ? 'AI 分析中...' : 'Analyzing...';
  String aiAnalyzedAtLabel(DateTime date) => isChinese
      ? '上次分析：${formatDateTime(date)}'
      : 'Last analyzed: ${formatDateTime(date)}';
  String get aiSummaryLabel => isChinese ? '日记总结' : 'Summary';
  String get aiGeneratedTitleLabel => isChinese ? '推荐标题' : 'Suggested title';
  String get aiDetectedMoodLabel => isChinese ? '识别情绪' : 'Detected mood';
  String get aiSuggestedTagsLabel => isChinese ? '推荐标签' : 'Suggested tags';
  String get emotionalCompanionSectionTitle =>
      isChinese ? '\u60c5\u7eea\u966a\u4f34' : 'Emotional companion';
  String get emotionCategoryLabel =>
      isChinese ? '\u60c5\u7eea\u5206\u7c7b' : 'Emotion category';
  String get comfortReplyLabel =>
      isChinese ? '\u5b89\u629a\u56de\u590d' : 'Comforting reply';
  String get companionStyleLabel =>
      isChinese ? '\u98ce\u683c\u81ea\u9002\u5e94' : 'Adaptive style';
  String get priorityFeedbackLabel => isChinese
      ? '\u91cd\u8981\u60c5\u7eea\u589e\u5f3a\u53cd\u9988'
      : 'Enhanced feedback';
  String get emotionalCompanionEmpty => isChinese
      ? '\u5f53\u524d\u8fd9\u6761\u65e5\u8bb0\u8fd8\u6ca1\u6709\u751f\u6210\u966a\u4f34\u53cd\u9988\u3002'
      : 'No emotional companion feedback has been generated yet.';
  String get noPriorityFeedback => isChinese
      ? '\u5f53\u524d\u60c5\u7eea\u6682\u4e0d\u9700\u8981\u989d\u5916\u589e\u5f3a\u53cd\u9988\u3002'
      : 'No extra enhanced feedback is needed for this emotion right now.';
  String get problemSuggestionSectionTitle => isChinese ? 'AI 小建议' : 'AI tips';
  String get distressIdentificationLabel =>
      isChinese ? '\u56f0\u6270\u8bc6\u522b' : 'Distress identification';
  String get problemAnalysisLabel =>
      isChinese ? '\u95ee\u9898\u5206\u6790' : 'Problem analysis';
  String get problemSuggestionEmpty =>
      isChinese ? '当前这条日记还没有生成 AI 小建议。' : 'No AI tips have been generated yet.';
  String get noAiSuggestionYet => isChinese
      ? '\u6682\u65e0 AI \u5efa\u8bae\u3002'
      : 'No AI suggestions yet.';
  String get aiAnalysisReady =>
      isChinese ? 'AI 建议已生成。' : 'AI suggestions are ready.';
  String get applyAllAiSuggestions => isChinese ? '全部应用' : 'Apply all';
  String get applyAiTitle => isChinese ? '应用标题' : 'Apply title';
  String get applyAiMood => isChinese ? '应用情绪' : 'Apply mood';
  String get applyAiTags => isChinese ? '应用标签' : 'Apply tags';
  String get aiSuggestionsApplied =>
      isChinese ? '已应用 AI 标题、情绪和标签。' : 'Applied the AI title, mood, and tags.';
  String get aiTitleApplied =>
      isChinese ? '已应用 AI 标题。' : 'Applied the AI title.';
  String get aiMoodApplied => isChinese ? '已应用 AI 情绪。' : 'Applied the AI mood.';
  String get aiTagsApplied => isChinese ? '已应用 AI 标签。' : 'Applied the AI tags.';
  String get aiSummaryEmpty =>
      isChinese ? 'AI 这次没有生成总结。' : 'AI did not return a summary this time.';
  String get aiGeneratedTitleEmpty =>
      isChinese ? 'AI 这次没有给出标题建议。' : 'AI did not suggest a title this time.';
  String get aiNoTagsSuggested =>
      isChinese ? 'AI 这次没有提取到明显标签。' : 'AI did not find clear tags this time.';
  String get untitledEntry =>
      isChinese ? '\u65e0\u6807\u9898\u65e5\u8bb0' : 'Untitled entry';
  String get titleLabel => isChinese ? '\u6807\u9898' : 'Title';
  String get titleHint => isChinese
      ? '\u4f8b\u5982\uff1a\u516c\u56ed\u7684\u4e0b\u5348'
      : 'For example: Afternoon in the park';
  String get contentLabel => isChinese ? '\u5185\u5bb9' : 'Content';
  String get contentHint => isChinese
      ? '\u4f8b\u5982\uff1a\u4e0b\u73ed\u8def\u4e0a\u4e0b\u96e8\uff0c\u5fc3\u60c5\u53cd\u800c\u5f88\u5e73\u9759\u3002'
      : 'For example: It rained on the way home, and I felt surprisingly calm.';
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
  String get imagePreviewPageTitle =>
      isChinese ? '\u56fe\u7247\u9884\u89c8' : 'Image preview';
  String get noImageSelected => isChinese
      ? '\u672a\u9009\u4e2d\u8981\u9884\u89c8\u7684\u56fe\u7247\u3002'
      : 'No image selected for preview.';
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
  String get unsavedChangesTitle => isChinese
      ? '\u8fd8\u6709\u672a\u4fdd\u5b58\u7684\u5185\u5bb9'
      : 'Unsaved changes';
  String get unsavedChangesMessage => isChinese
      ? '\u5f53\u524d\u65e5\u8bb0\u8fd8\u6ca1\u6709\u4fdd\u5b58\uff0c\u79bb\u5f00\u540e\u8fd9\u4e9b\u4fee\u6539\u4f1a\u4e22\u5931\u3002'
      : 'This diary has unsaved changes. Leaving now will discard them.';
  String get stayOnPage =>
      isChinese ? '\u7ee7\u7eed\u7f16\u8f91' : 'Keep editing';
  String get leaveWithoutSaving =>
      isChinese ? '\u4e0d\u4fdd\u5b58\u79bb\u5f00' : 'Leave without saving';
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
      ? '\u8fd8\u6ca1\u6709\u914d\u7f6e OpenAI API Key\uff0c\u5df2\u8df3\u8fc7\u8f6c\u5199\u3002'
      : 'No OpenAI API key configured. Skipping transcription.';
  String get diaryAiApiKeyMissing => isChinese
      ? '还没有配置阿里云 AI Key，暂时无法进行 AI 分析。'
      : 'No Alibaba Cloud AI key configured. Cannot run diary AI analysis.';
  String get diaryAiInputRequired => isChinese
      ? '请先输入标题、正文、地点或标签中的任意一项。'
      : 'Please enter at least a title, content, location, or tags first.';
  String diaryAiRequestFailed(int? statusCode) => isChinese
      ? 'AI 分析请求失败${statusCode == null ? '' : '（$statusCode）'}。'
      : 'Diary AI request failed${statusCode == null ? '' : ' ($statusCode)'}.';
  String get diaryAiInvalidResponse => isChinese
      ? 'AI 返回结果无法识别，请重试。'
      : 'The AI response could not be understood. Please try again.';
  String get audioFileMissing => isChinese
      ? '\u672a\u627e\u5230\u5f55\u97f3\u6587\u4ef6\u3002'
      : 'Audio file was not found.';
  String transcriptionRequestFailed(int? statusCode) => isChinese
      ? '\u8f6c\u5199\u8bf7\u6c42\u5931\u8d25${statusCode == null ? '' : '\uff08$statusCode\uff09'}\u3002'
      : 'Transcription request failed${statusCode == null ? '' : ' ($statusCode)'}.';
  String get noTranscriptionText => isChinese
      ? '\u672a\u8fd4\u56de\u8f6c\u5199\u6587\u672c\u3002'
      : 'No transcription text returned from API.';

  String defaultMoodLabel(String moodId) {
    switch (moodId) {
      case DiaryMood.happyId:
        return isChinese ? '\u5f00\u5fc3' : 'Happy';
      case DiaryMood.calmId:
        return isChinese ? '\u5e73\u9759' : 'Calm';
      case DiaryMood.neutralId:
        return isChinese ? '\u4e00\u822c' : 'Neutral';
      case DiaryMood.sadId:
        return isChinese ? '\u96be\u8fc7' : 'Sad';
      case DiaryMood.angryId:
        return isChinese ? '\u751f\u6c14' : 'Angry';
      default:
        return moodId;
    }
  }

  String moodLabel(DiaryMood moodValue) {
    final customLabel = moodValue.label.trim();
    if (customLabel.isNotEmpty) {
      return customLabel;
    }
    return defaultMoodLabel(moodValue.id);
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

  String get aiOverviewSectionTitle =>
      isChinese ? '\u7efc\u5408\u603b\u7ed3' : 'Overview';

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
