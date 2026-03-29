# Memo (记事薄)

A personal diary and task management app built with Flutter. Memo lets you keep a daily journal alongside per-day todo lists, all stored locally on your device with full export/import support.

## Screenshots

<!-- Add screenshots here -->
<!-- ![Calendar view](screenshots/calendar.png) -->
<!-- ![Document view](screenshots/document.png) -->
<!-- ![Task list](screenshots/tasks.png) -->

## Features

1. **Calendar view** -- Browse entries by month with visual indicators for days that have content or incomplete todos.
2. **Daily journal** -- Write free-form text notes for any date.
3. **Per-day todo lists** -- Add, edit, reorder, and delete todo items attached to each diary entry.
4. **Multi-status todos** -- Cycle through four states: incomplete, completed, excellent, and cancelled.
5. **Full-text search** -- Search across all notes and todo items at once.
6. **Filter incomplete todos** -- View outstanding tasks filtered by year and/or month.
7. **Task list view** -- See all entries and their todos in a scrollable list (newest first).
8. **Export data** -- Export the entire database to a JSON file and share it.
9. **Import data** -- Restore from a previously exported JSON backup; existing entries for the same date are merged.
10. **Bilingual UI** -- Full English and Chinese (简体中文) localization; the app follows the device language automatically.

## Getting Started

### Prerequisites

| Tool | Version |
|------|---------|
| Flutter SDK | 3.29+ (Dart SDK ^3.7.2) |
| Android SDK | API 21+ (minSdk) |
| Java / JDK | 11 |
| Kotlin | Bundled with AGP |

Verify your environment:

```bash
flutter doctor
```

### Clone and run

```bash
git clone https://github.com/thenewpotato/memo-app.git
cd memo-app
flutter pub get
flutter run
```

### Build APKs

Debug APK:

```bash
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

Release APK:

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

Split per-ABI for smaller downloads:

```bash
flutter build apk --split-per-abi
```

### Running on emulator vs physical device

**Emulator** -- Launch an AVD from Android Studio or the command line, then:

```bash
flutter run
```

**Physical device** -- Enable USB debugging on the device, connect via USB, then:

```bash
flutter devices          # confirm the device is listed
flutter run -d <device>  # or just `flutter run` if only one device is connected
```

## Project Structure

```
lib/
├── main.dart                  # App entry point, MaterialApp setup, home screen with bottom nav
├── db/
│   └── database_helper.dart   # SQLite database (sqflite): schema, CRUD, search, export/import
├── l10n/
│   └── app_localizations.dart # EN/ZH string maps, localization delegate
├── models/
│   ├── diary_entry.dart       # DiaryEntry data class (id, date, textContent, timestamps)
│   └── todo_item.dart         # TodoItem data class + TodoStatus enum (incomplete/completed/excellent/cancelled)
├── screens/
│   ├── backup_screen.dart     # Export (share JSON) and import (file picker) UI
│   ├── calendar_screen.dart   # Monthly calendar with entry/todo indicators
│   ├── document_screen.dart   # Single-day view: notes editor + todo list
│   ├── filter_screen.dart     # Incomplete-todo filter by year/month
│   ├── search_screen.dart     # Full-text search across entries and todos
│   └── task_list_screen.dart  # Scrollable list of all entries with their todos
└── widgets/
    ├── calendar_widget.dart   # Reusable calendar grid widget
    └── todo_item_widget.dart  # Single todo row with status icon, text, delete
```

## Localization

The app ships with English (`en`) and Chinese (`zh`). Translations live in a single file:

```
lib/l10n/app_localizations.dart
```

Strings are stored in `_localizedValues`, a `Map<String, Map<String, String>>` keyed by language code. To add or modify translations:

1. Open `lib/l10n/app_localizations.dart`.
2. Add your key/value pair to both the `'en'` and `'zh'` maps.
3. Add a getter for the new key in the `AppLocalizations` class body.
4. Use it in widgets via `AppLocalizations.of(context).yourKey`.

To add a new language, add another entry to the map (e.g., `'ja': { ... }`), register the locale in `supportedLocales` in `main.dart`, and update `isSupported()` in the delegate.

## Data Storage

All data is stored locally using **SQLite** via the `sqflite` package. The database file is named `diary_app.db` and is located in the platform's default databases directory (on Android, typically `/data/data/com.diary.diary_app/databases/`).

### Schema

**`diary_entries`** -- One row per date.

| Column | Type | Notes |
|--------|------|-------|
| id | INTEGER | Primary key, auto-increment |
| date | TEXT | `yyyy-MM-dd`, unique |
| text_content | TEXT | Free-form journal text |
| created_at | TEXT | ISO 8601 timestamp |
| updated_at | TEXT | ISO 8601 timestamp |

**`todo_items`** -- Belongs to a diary entry.

| Column | Type | Notes |
|--------|------|-------|
| id | INTEGER | Primary key, auto-increment |
| entry_id | INTEGER | FK to `diary_entries.id` (cascade delete) |
| content | TEXT | Todo text |
| status | INTEGER | 0=incomplete, 1=completed, 2=excellent, 3=cancelled |
| sort_order | INTEGER | Display order within the entry |
| created_at | TEXT | ISO 8601 timestamp |

## Export / Import Format

Backups are JSON files with this structure:

```json
{
  "app": "diary_app",
  "version": 1,
  "exported_at": "2026-03-28T12:00:00.000",
  "entries": [
    {
      "date": "2026-03-28",
      "text_content": "Today was a good day.",
      "created_at": "...",
      "updated_at": "...",
      "todos": [
        {
          "content": "Buy groceries",
          "status": 1,
          "sort_order": 0,
          "created_at": "..."
        }
      ]
    }
  ]
}
```

- **Export** generates this JSON and opens the system share sheet so you can save or send the file.
- **Import** reads a `.json` file picked via the system file picker. If an entry for the same date already exists, it is overwritten (existing todos for that date are replaced).

## License

This is a private project. All rights reserved.
