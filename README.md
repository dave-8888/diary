# Diary MVP

[简体中文](./README.zh-CN.md) | English

Diary MVP is a desktop-first Flutter diary app focused on local-first storage, privacy-friendly personal writing, and media-rich journaling. It combines offline diary management with optional AI-assisted reflection, audio transcription, and migration tools for moving data between devices.

## Screenshots

> Note: The UI is still evolving, so screenshots and layout details may change in later versions.

### Home

![Home screen](docs/images/home.png)

Browse recent entries, locations, moods, and quick actions from the home page.

### Write diary

![Diary editor](docs/images/editor.png)

Create diary entries with title, content, mood, tags, location, images, video, and audio attachments.

### AI diary assistant

![AI diary assistant](docs/images/editor-ai.png)

Review AI-generated summaries, suggested tags, emotional support text, and follow-up prompts alongside the current draft.

### Trash

![Trash screen](docs/images/trash.png)

Preview deleted entries, restore items, and clean up the trash list when needed.

### Settings

![Settings screen](docs/images/settings.png)

Manage theme, language, startup passcode, media visibility, app identity, AI settings, and transcription settings.

## Features

- Local-first diary storage with `drift` + SQLite
- Desktop-oriented navigation and responsive layouts
- Rich diary editor with image import, camera capture, video recording, and audio recording
- Mood, tags, and location support for each entry
- Timeline view for browsing all entries
- Trash flow with preview, restore, multi-select, and permanent cleanup
- Single-entry export to Markdown and plain text with copied media files
- Full migration package export/import for entries, trash, media, tags, and mood library
- 6-digit startup passcode with local hashed storage
- Configurable AI analysis using OpenAI-compatible chat completion APIs
- Audio transcription using `whisper-1`
- Customizable theme, language, app display name, and app icon

## Tech Stack

- Flutter
- Riverpod
- GoRouter
- Drift + SQLite
- `record`, `camera`, `media_kit`, `audioplayers`

## Project Structure

```text
lib/
  app/
  core/storage/
  features/diary/
test/
tools/
docs/
```

- `lib/app/` contains app shell, routing, theme, localization, and startup lock
- `lib/core/storage/` contains local file storage helpers
- `lib/features/diary/data/local/` contains the database layer
- `lib/features/diary/presentation/` contains pages and widgets
- `lib/features/diary/services/` contains AI, export, migration, transcription, location, and settings services

## Getting Started

### Requirements

- Flutter SDK with Dart `>=3.4.0 <4.0.0`

### Install dependencies

```bash
flutter pub get
```

### Run on Windows

```bash
flutter run -d windows
```

### Run tests

```bash
flutter test
```

## AI and Transcription

AI analysis and audio transcription are optional.

- AI analysis can be configured in the app settings and supports OpenAI-compatible chat completion providers
- The app includes presets for Qwen / DashScope, OpenAI, Claude-compatible, Gemini-compatible, OpenRouter, and custom providers
- Audio transcription uses OpenAI `whisper-1`
- Keys can be saved in app settings, or passed at launch with Dart defines

Example:

```bash
flutter run -d windows ^
  --dart-define=DIARY_AI_API_KEY=your_ai_key ^
  --dart-define=OPENAI_API_KEY=your_openai_key
```

Environment fallback keys used by the app:

- `DIARY_AI_API_KEY`
- `DASHSCOPE_API_KEY` (legacy fallback)
- `OPENAI_API_KEY`

## Local Data Paths

App data is stored under the application documents directory:

- `diary_mvp/db/diary.db`
- `diary_mvp/user_data/diary/images/`
- `diary_mvp/user_data/diary/audio/`
- `diary_mvp/user_data/diary/video/`
- `diary_mvp/user_data/trash/`
- `diary_mvp/settings/`

## Packaging

### Windows installer

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\build_windows_installer.ps1
```

### macOS DMG

This must be run on macOS or a macOS CI runner.

```bash
chmod +x ./tools/build_macos_installer.sh
./tools/build_macos_installer.sh
```

Build outputs:

- `dist/windows-installer/*.exe`
- `dist/macos-installer/*.dmg`

If you need CI artifacts, use `.github/workflows/build_desktop_installers.yml`.

## License

This project is licensed under the [MIT License](./LICENSE).
