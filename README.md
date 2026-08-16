# FocusFlow V0.1

FocusFlow is a local-first Flutter MVP for a student self-discipline app.

## Features

- Home dashboard with today's focus time, task progress, current task, and a 10-minute quick start.
- Todo module with add, edit, delete, complete, sort, and start-focus actions.
- Focus timer with quick, pomodoro, and deep-focus presets.
- Wall-clock based timer logic using `startTime + plannedDuration`.
- Early finish confirmation that records incomplete but real focus time.
- Statistics page based on `FocusRecord` data.
- Focus Search router for Google, Bing, Baidu, Bilibili, Zhihu, and Wikipedia.

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

## V0.1 Notes

Data is currently stored in an in-memory local store so the app flow can be built and reviewed quickly. Replace `lib/core/data/local_store.dart` with Drift or Isar when persistent storage is needed.
