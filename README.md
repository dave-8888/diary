# Diary MVP

Desktop-first Flutter diary app with local-first storage, startup passcode protection, and media-rich diary editing.

## Implemented

- `drift` + SQLite persistence for diary entries and media records
- local file storage for imported images and recorded audio
- audio recording with `record`
- 6-digit startup passcode with local hashed storage
- unsaved-change reminders before leaving the editor
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
- `features/diary/services/` contains local settings and service integrations

## Run

```bash
flutter pub get
flutter run -d windows
```
