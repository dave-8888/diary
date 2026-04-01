# Diary MVP

Desktop-first Flutter diary app with local-first storage, startup passcode protection, and media-rich diary editing.

## Screenshots

### Home

![Home screen](docs/images/home.png)

Review recent diary entries, mood summary, and quick actions from the desktop home page.

### Write diary

![Diary editor](docs/images/editor.png)

Create rich diary entries with title, text, image import, camera capture, video recording, audio recording, location, and mood selection.

### AI diary assistant

![AI diary assistant](docs/images/editor-ai.png)

Analyze the current entry and surface a summary, emotional companionship, suggestions, and recommended tags alongside the editor.

### Settings

![Settings screen](docs/images/settings.png)

Manage theme, language, media visibility, startup passcode, app identity, and AI-related preferences in one place.

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

## Desktop packaging

Windows installer:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\build_windows_installer.ps1
```

macOS DMG (must be run on a Mac or macOS CI runner):

```bash
chmod +x ./tools/build_macos_installer.sh
./tools/build_macos_installer.sh
```

Build outputs:

- `dist/windows-installer/*.exe`
- `dist/macos-installer/*.dmg`

If you want both artifacts from CI, use the GitHub Actions workflow at `.github/workflows/build_desktop_installers.yml`.
