# Diary MVP

Desktop-first Flutter diary app with local-first storage and AI transcription entry.

## Implemented

- `drift` + SQLite persistence for diary entries and media records
- local file storage for imported images and recorded audio
- audio recording with `record`
- transcription entry with OpenAI Audio API (optional via env define)
- responsive navigation (`NavigationRail` on desktop, `NavigationBar` on narrow layouts)

## Data and media paths

The app writes data under app documents:

- `diary_mvp/db/diary.db`
- `diary_mvp/user_data/diary/images/*`
- `diary_mvp/user_data/diary/audio/*`

## Project structure

```text
lib/
  app/
  core/storage/
  features/diary/
```

- `app/` contains app shell, theme, and routes
- `core/storage/` contains local file path management
- `features/diary/data/local/` contains drift database access
- `features/diary/services/` contains transcription integration

## Run

```bash
flutter pub get
flutter run -d windows
```

## Optional: enable OpenAI transcription

Pass an API key at runtime:

```bash
flutter run -d windows --dart-define=OPENAI_API_KEY=your_key_here
```

If no key is provided, the transcription button remains a valid entry point and will show a skip message.
