# FocusFlow V0.2

FocusFlow is a local-first Flutter MVP for a student self-discipline app.

## Features

- Home dashboard with today's focus time, task progress, current task, and a 10-minute quick start.
- Todo module with add, edit, delete, complete, sort, and start-focus actions.
- Focus timer with quick, pomodoro, and deep-focus presets.
- Wall-clock based timer logic using `startTime + plannedDuration`.
- Early finish confirmation that records incomplete but real focus time.
- Statistics page based on `FocusRecord` data.
- Focus Search router for Google, Bing, Baidu, Bilibili, Zhihu, and Wikipedia.
- Local persistence for tasks and focus records with shared preferences.
- V0.2 settings page with daily goal, JSON export, and local data reset.
- Task filters, delete confirmation with undo, and custom deadline dates.
- Focus Search supports recent queries and custom study shortcuts.

## Run

Install Flutter, then run:

```bash
flutter pub get
flutter run
```

## Verify

```bash
flutter analyze
flutter test
```

## V0.2 Notes

Data is persisted locally with `shared_preferences` so tasks and focus records survive app restarts. Replace `lib/core/data/local_store.dart` with Drift or Isar later if querying, migrations, or larger datasets become important.
